//
//  AudioPlayerManager.swift
//  ChatUpp
//
//  Created by Andrei Pripa on 10/22/25.
//

import SwiftUI
import AVFoundation
import Combine
import Accelerate

enum AudioSamplesLevel
{
    case low, medium, high
}

extension AudioSessionManager: AVAudioRecorderDelegate
{
    func audioRecorderDidFinishRecording(_ recorder: AVAudioRecorder, successfully flag: Bool)
    {
        if flag
        {
            print("finish rec successfully")
        } else {
            print("record failed")
        }
    }
}

// MARK: - Audio Session Manager
class AudioSessionManager: NSObject, SwiftUI.ObservableObject
{
    static let shared = AudioSessionManager()
    
    @Published private(set) var isAudioPlaying = false
    @Published private(set) var currentPlaybackTime: TimeInterval = 0.0
    @Published private(set) var currentRecordingTime: TimeInterval = 0.0
    @Published private(set) var currentlyLoadedAudioURL: URL?

    private var audioPlayer: AVAudioPlayer?
    private var audioRecorder: AVAudioRecorder?
    private var audioSession: AVAudioSession?
    
    private var cancellables = Set<AnyCancellable>()
    private var timerCancellable: AnyCancellable?
    
    // Lifecycle
    private override init()
    {
        super.init()
        setupAudioSession()
    }
    
    deinit {
        stopPlayback()
        stopRecording()
    }
    
    // Session setup
    private func setupAudioSession()
    {
        self.audioSession = AVAudioSession.sharedInstance()
        do {
            try audioSession?.setCategory(.playAndRecord,
                                         mode: .default)
            try audioSession?.setActive(true)
        } catch {
            print("Failed to set up audio session: \(error)")
        }
    }
    
    // Utilities
    func getAudioDuration(from url: URL) async -> CMTime
    {
        do {
            return try await AVURLAsset(url: url).load(.duration)
        } catch {
            print("Could not load audio asset: \(error)")
        }
        return .invalid
    }
    
    private func createAudioURL() -> URL
    {
        let path = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)[0]
        let fileName = "voiceRec_\(Date().timeIntervalSince1970).m4a"
        print("The path audio is stored: ", path.appendingPathComponent(fileName))
        return path.appendingPathComponent(fileName)
    }
    
    func extractSamples(from url: URL, targetSampleCount: Int) -> [CGFloat]
    {
        do {
            let file = try AVAudioFile(forReading: url)
            let format = file.processingFormat
            let totalSamples = AVAudioFrameCount(file.length)
            
            guard totalSamples > 0 else { return [] }
            
            // Read entire file (unavoidable, but optimize what comes next)
            let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: totalSamples)!
            try file.read(into: buffer)
            
            guard let floatData = buffer.floatChannelData?[0] else { return [] }
            
            let samplesPerPixel = Int(totalSamples) / targetSampleCount
            var samples: [CGFloat] = []
            samples.reserveCapacity(targetSampleCount) // Pre-allocate memory
            
            // Use strided iteration and vDSP for max amplitude calculation
            for i in 0..<targetSampleCount {
                let startIndex = i * samplesPerPixel
                let count = min(samplesPerPixel, Int(totalSamples) - startIndex)
                
                // Use vDSP for vectorized max absolute value (MUCH faster)
                var maxAmplitude: Float = 0
                floatData.advanced(by: startIndex).withMemoryRebound(to: Float.self, capacity: count) { ptr in
                    vDSP_maxmgv(ptr, 1, &maxAmplitude, vDSP_Length(count))
                }
                
                samples.append(CGFloat(min(1.0, maxAmplitude * 2)))
            }
            
            return samples
        } catch {
            print("Failed to extract waveform: \(error)")
            return (0..<targetSampleCount).map { _ in CGFloat.random(in: 0.2...1.0) }
        }
    }

    private func stopTimer() {
        timerCancellable?.cancel()
        timerCancellable = nil
    }
//
//    private func getSampleCountForDuration(_ duration: TimeInterval) -> Int
//    {
//        switch duration
//        {
//        case 0...3: return 20
//        case 3...6: return 25
//        case 6...12: return 30
//        case 12...20: return 40
//        case 20...30: return 50
//        default: return 60
//        }
//    }
}

// MARK: - Recording
extension AudioSessionManager
{
    func startRecording()
    {
        let audioURL = createAudioURL()
        
        let settings = [
            AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
            AVSampleRateKey: 12000,
            AVNumberOfChannelsKey: 1,
            AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
        ]
        
        do {
            self.audioRecorder = try AVAudioRecorder(url: audioURL, settings: settings)
            self.audioRecorder?.delegate = self
            self.audioRecorder?.record()
            self.startRecordingTimer()
        } catch {
            print("Could not initiate audio recording: \(error)")
        }
    }
    
    func isRecording() -> Bool
    {
        return self.audioRecorder?.isRecording ?? false
    }
    
    func stopRecording(withAudioRecDeletion shouldDelete: Bool = false)
    {
        self.audioRecorder?.stop()
        
        if shouldDelete
        {
            let deleted = self.audioRecorder?.deleteRecording()
            print("Deletion of file status: \(deleted ?? false)")
        }
        self.stopTimer()
        self.audioRecorder = nil
    }
    
    func getRecordedAudioURL() -> URL?
    {
        return audioRecorder?.url
    }
    
    private func startRecordingTimer()
    {
        self.timerCancellable = Timer.publish(every: 0.01, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                self?.currentRecordingTime = self?.audioRecorder?.currentTime ?? 0.0
            }
    }
}

// MARK: - Playback
extension AudioSessionManager
{
    func loadAudio(url: URL)
    {
        do {
            audioPlayer = try AVAudioPlayer(contentsOf: url)
            audioPlayer?.prepareToPlay()
            currentlyLoadedAudioURL = url
        } catch {
            print("Failed to load audio: \(error)")
        }
    }
    
    func play(audioURL: URL, startingAtTime time: TimeInterval = 0.0)
    {
        if audioURL != self.currentlyLoadedAudioURL
        {
            currentlyLoadedAudioURL = nil
            stopPlayback()
            loadAudio(url: audioURL)
        }
        updateCurrentPlaybackTime(time: time)
        togglePlayPause()
    }
    
    func togglePlayPause()
    {
        if isAudioPlaying {
            pause()
        } else {
            play()
        }
    }

    private func play() {
        audioPlayer?.play()
        isAudioPlaying = true
        startPlaybackTimer()
    }
    
    private func pause() {
        audioPlayer?.pause()
        isAudioPlaying = false
        stopTimer()
    }
    
    func updateCurrentPlaybackTime(time: TimeInterval)
    {
        audioPlayer?.currentTime = time
        currentPlaybackTime = time
    }
    
    private func startPlaybackTimer()
    {
        stopTimer()
        
        timerCancellable = Timer.publish(every: 0.05, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                guard let self,
                      let player = self.audioPlayer else { return }
                self.currentPlaybackTime = player.currentTime
                if !player.isPlaying {
                    self.stopPlayback()
                }
            }
    }
    
    private func stopPlayback()
    {
        audioPlayer?.stop()
        isAudioPlaying = false
        currentPlaybackTime = 0.0
        stopTimer()
    }
}
//
//
//func extractSamples(from url: URL, targetSampleCount: Int) -> [CGFloat] {
//    do {
//        let file = try AVAudioFile(forReading: url)
//        let totalSamples = AVAudioFrameCount(file.length)
//        
//        guard totalSamples > 0 else { return [] }
//        
//        // Create downsampled format (e.g., 8kHz mono)
//        guard let downsampledFormat = AVAudioFormat(
//            commonFormat: .pcmFormatFloat32,
//            sampleRate: 8000,
//            channels: 1,
//            interleaved: false
//        ) else { return [] }
//        
//        let converter = AVAudioConverter(from: file.processingFormat, to: downsampledFormat)!
//        
//        // Calculate downsampled length
//        let ratio = downsampledFormat.sampleRate / file.processingFormat.sampleRate
//        let downsampledLength = AVAudioFrameCount(Double(totalSamples) * ratio)
//        
//        let downsampledBuffer = AVAudioPCMBuffer(
//            pcmFormat: downsampledFormat,
//            frameCapacity: downsampledLength
//        )!
//        
//        // Read and convert in one go (much faster than original format)
//        let inputBuffer = AVAudioPCMBuffer(
//            pcmFormat: file.processingFormat,
//            frameCapacity: totalSamples
//        )!
//        
//        try file.read(into: inputBuffer)
//        
//        var error: NSError?
//        converter.convert(to: downsampledBuffer, error: &error) { _, outStatus in
//            outStatus.pointee = .haveData
//            return inputBuffer
//        }
//        
//        guard let floatData = downsampledBuffer.floatChannelData?[0] else { return [] }
//        
//        // Now process the much smaller buffer
//        let samplesPerPixel = Int(downsampledLength) / targetSampleCount
//        var samples: [CGFloat] = []
//        
//        for i in 0..<targetSampleCount {
//            let startIndex = i * samplesPerPixel
//            let endIndex = min(startIndex + samplesPerPixel, Int(downsampledLength))
//            
//            var maxAmplitude: Float = 0
//            for j in startIndex..<endIndex {
//                maxAmplitude = max(maxAmplitude, abs(floatData[j]))
//            }
//            
//            samples.append(CGFloat(min(1.0, maxAmplitude * 2)))
//        }
//        
//        return samples
//    } catch {
//        print("Failed to extract waveform: \(error)")
//        return (0..<targetSampleCount).map { _ in CGFloat.random(in: 0.2...1.0) }
//    }
//}



//
//
//func extractSamples(from url: URL, targetSampleCount: Int) -> [CGFloat] {
//    do {
//        let asset = AVAsset(url: url)
//        let reader = try AVAssetReader(asset: asset)
//        
//        guard let track = asset.tracks(withMediaType: .audio).first else { return [] }
//        
//        let outputSettings: [String: Any] = [
//            AVFormatIDKey: kAudioFormatLinearPCM,
//            AVLinearPCMBitDepthKey: 16,
//            AVLinearPCMIsFloatKey: false,
//            AVLinearPCMIsBigEndianKey: false,
//            AVLinearPCMIsNonInterleaved: false
//        ]
//        
//        let output = AVAssetReaderTrackOutput(track: track, outputSettings: outputSettings)
//        reader.add(output)
//        reader.startReading()
//        
//        var samples: [CGFloat] = []
//        let samplesPerPixel = max(1, Int(track.asset?.duration.value ?? 0) / targetSampleCount / 100)
//        var sampleIndex = 0
//        
//        while let sampleBuffer = output.copyNextSampleBuffer() {
//            guard let blockBuffer = CMSampleBufferGetDataBuffer(sampleBuffer) else { continue }
//            
//            let length = CMBlockBufferGetDataLength(blockBuffer)
//            var data = Data(count: length)
//            
//            data.withUnsafeMutableBytes { ptr in
//                CMBlockBufferCopyDataBytes(blockBuffer, atOffset: 0, dataLength: length, destination: ptr.baseAddress!)
//            }
//            
//            let int16Data = data.withUnsafeBytes { $0.bindMemory(to: Int16.self) }
//            
//            for (index, sample) in int16Data.enumerated() where index % samplesPerPixel == 0 {
//                if sampleIndex % samplesPerPixel == 0 && samples.count < targetSampleCount {
//                    let normalized = CGFloat(abs(sample)) / CGFloat(Int16.max)
//                    samples.append(min(1.0, normalized * 2))
//                }
//                sampleIndex += 1
//            }
//        }
//        
//        return samples
//    } catch {
//        print("Failed to extract waveform: \(error)")
//        return (0..<targetSampleCount).map { _ in CGFloat.random(in: 0.2...1.0) }
//    }
//}


/// this >>>>
//func extractSamples(from url: URL, targetSampleCount: Int) -> [CGFloat] {
//    do {
//        let file = try AVAudioFile(forReading: url)
//        let format = file.processingFormat
//        let totalSamples = AVAudioFrameCount(file.length)
//        
//        guard totalSamples > 0 else { return [] }
//        
//        // Read entire file (unavoidable, but optimize what comes next)
//        let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: totalSamples)!
//        try file.read(into: buffer)
//        
//        guard let floatData = buffer.floatChannelData?[0] else { return [] }
//        
//        let samplesPerPixel = Int(totalSamples) / targetSampleCount
//        var samples: [CGFloat] = []
//        samples.reserveCapacity(targetSampleCount) // Pre-allocate memory
//        
//        // Use strided iteration and vDSP for max amplitude calculation
//        for i in 0..<targetSampleCount {
//            let startIndex = i * samplesPerPixel
//            let count = min(samplesPerPixel, Int(totalSamples) - startIndex)
//            
//            // Use vDSP for vectorized max absolute value (MUCH faster)
//            var maxAmplitude: Float = 0
//            floatData.advanced(by: startIndex).withMemoryRebound(to: Float.self, capacity: count) { ptr in
//                vDSP_maxmgv(ptr, 1, &maxAmplitude, vDSP_Length(count))
//            }
//            
//            samples.append(CGFloat(min(1.0, maxAmplitude * 2)))
//        }
//        
//        return samples
//    } catch {
//        print("Failed to extract waveform: \(error)")
//        return (0..<targetSampleCount).map { _ in CGFloat.random(in: 0.2...1.0) }
//    }
//}
