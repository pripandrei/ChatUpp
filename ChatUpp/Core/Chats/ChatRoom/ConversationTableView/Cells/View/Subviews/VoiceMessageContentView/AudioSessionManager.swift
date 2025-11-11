//
//  AudioPlayerManager.swift
//  ChatUpp
//
//  Created by Andrei Pripa on 10/22/25.
//

import SwiftUI
import AVFoundation


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
            print("finish rec success")
        } else {
            print("record failed")
        }
    }
}

// MARK: - Audio Session Manager
class AudioSessionManager: NSObject, SwiftUI.ObservableObject
{
    static let shared = AudioSessionManager()
    
//    @Published var playbackProgress: CGFloat = 0.0
    @Published var isAudioPlaying = false
//    @Published var shouldUpdateProgress: Bool = true
//    @Published var waveformSamples: [CGFloat] = []
//    @Published var audioTotalDuration: TimeInterval = 0.0
    @Published var currentPlaybackTime: TimeInterval = 0.0
    @Published var currentRecordingTime: TimeInterval = 0.0
    
    @Published var currentlyLoadedAudioURL: URL?
    
    private var audioPlayer: AVAudioPlayer?
    private var audioRecorder: AVAudioRecorder?
    private var audioSession: AVAudioSession?
    private var timer: Timer?
    
    private override init()
    {
        super.init()
        setupAudioSession()
    }
    
    private func startRecordingTimer()
    {
        self.timer = Timer.scheduledTimer(withTimeInterval: 0.01,
                                          repeats: true,
                                          block: { _ in
            self.currentRecordingTime = self.audioRecorder?.currentTime ?? 0.0
        })
    }
    
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
    
    private func createAudioURL() -> URL
    {
        let path = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)[0]
        let fileName = "voiceRec_\(Date().timeIntervalSince1970).m4a"
        print("The path audio is stored: ", path.appendingPathComponent(fileName))
        return path.appendingPathComponent(fileName)
    }
    
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
    
    func getAudioDuration(from url: URL) async -> CMTime
    {
        do {
            return try await AVURLAsset(url: url).load(.duration)
        } catch {
            print("Could not load audio asset: \(error)")
        }
        return .invalid
    }
    
    // Load audio from file
    func loadAudio(url: URL)
    {
        do {
//            guard let url2 = Bundle.main.url(forResource: "tokyo_lounge", withExtension: "m4a") else { return }
            
            audioPlayer = try AVAudioPlayer(contentsOf: url)
            audioPlayer?.prepareToPlay()
//            audioTotalDuration = audioPlayer?.duration ?? 0
            currentlyLoadedAudioURL = url
//            // Generate waveform samples
//            generateWaveform(from: url)
        } catch {
            print("Failed to load audio: \(error)")
        }
    }
    
    func extractSamples(from url: URL,
                        targetSampleCount: Int) -> [CGFloat]
    {
        do {
            let file = try AVAudioFile(forReading: url)
            let format = file.processingFormat
            let totalSamples = AVAudioFrameCount(file.length)
            
            guard totalSamples > 0 else { return [] }
            
            let samplesPerPixel = Int(totalSamples) / targetSampleCount
            let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: totalSamples)!
            
            try file.read(into: buffer)
            
            guard let floatData = buffer.floatChannelData?[0] else { return [] }
            
            var samples: [CGFloat] = []
            
            for i in 0..<targetSampleCount
            {
                let startIndex = i * samplesPerPixel
                let endIndex = min(startIndex + samplesPerPixel, Int(totalSamples))
                
                var maxAmplitude: Float = 0
                for j in startIndex..<endIndex {
                    maxAmplitude = max(maxAmplitude, abs(floatData[j]))
                }
                
                // Normalize to 0...1 range
                samples.append(CGFloat(min(1.0, maxAmplitude * 2)))
            }
            
            return samples
        } catch {
            print("Failed to extract waveform: \(error)")
            // Return placeholder samples
            return (0..<targetSampleCount).map { _ in CGFloat.random(in: 0.2...1.0) }
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
    
    func togglePlayPause()
    {
        if isAudioPlaying {
            pause()
        } else {
            play()
        }
    }
    
    func play(audioURL: URL, startingAtTime time: TimeInterval = 0.0)
    {
        if audioURL != self.currentlyLoadedAudioURL
        {
            /// do not change order
            stopPlayback()
//            currentPlaybackTime = time
            loadAudio(url: audioURL)
//            play()
            self.currentlyLoadedAudioURL = audioURL
        }
//        else {
        updateCurrentPlaybackTime(time: time)
        togglePlayPause()
//        }
    }
    
//    func play(audioURL: URL, startingAtTime time: TimeInterval = 0.0)
//    {
//        if audioURL != self.currentlyLoadedAudioURL
//        {
//            /// do not change order
//            stopPlayback()
//            currentPlaybackTime = time
//            loadAudio(url: audioURL)
////            play()
//            self.currentlyLoadedAudioURL = audioURL
//        }
////        else {
//        updateCurrentPlaybackTime(time: time)
//        togglePlayPause()
////        }
//    }
    
    private func stopPlayback()
    {
        audioPlayer?.stop()
        audioPlayer = nil
        isAudioPlaying = false
        currentlyLoadedAudioURL = nil
//        currentPlaybackTime = 0.0
        stopTimer()
    }

    func updateCurrentPlaybackTime(time: TimeInterval)
    {
        audioPlayer?.currentTime = time
    }
    
    private func startPlaybackTimer()
    {
        stopTimer()
        timer = Timer.scheduledTimer(withTimeInterval: 0.05, repeats: true) { [weak self] _ in
            self?.updatePlaybackTime()
        }
    }
    
    private func stopTimer() {
        timer?.invalidate()
        timer = nil
    }
    
    private func updatePlaybackTime()
    {
        guard let player = audioPlayer /*, shouldUpdateProgress*/ else { return }
        self.currentPlaybackTime = player.currentTime
        
//        if audioTotalDuration > 0
//        {
//            playbackProgress = CGFloat(currentPlaybackTime / audioTotalDuration)
//        }
        
        if !player.isPlaying && isAudioPlaying
        {
            // Playback finished
            isAudioPlaying = false
            stopTimer()
//            playbackProgress = 0
            currentPlaybackTime = 0
            player.currentTime = 0
        }
    }
    
    // Load audio from bundle
//    func loadAudio(filename: String, fileExtension: String = "m4a")
//    {
//        guard let url = Bundle.main.url(forResource: filename,
//                                        withExtension: fileExtension) else
//        {
//            print("Audio file not found in bundle")
//            return
//        }
//        loadAudio(url: url)
//    }
    
    
//    func formatTime(_ time: TimeInterval) -> String
//    {
//        let minutes = Int(time) / 60
//        let seconds = Int(time) % 60
//        return String(format: "%d:%02d", minutes, seconds)
//    }
    
    //    func seek(to progress: CGFloat)
    //    {
    ////        guard let player = audioPlayer else { return }
    //
    //        let newTime = TimeInterval(progress) * audioTotalDuration
    ////        player.currentTime = newTime
    //        self.playbackProgress = progress
    //        self.currentPlaybackTime = newTime
    //    }
        
    
    deinit {
        stopTimer()
    }
    
    private func getSampleCountForDuration(_ duration: TimeInterval) -> Int
    {
        switch duration
        {
        case 0...3: return 20
        case 3...6: return 25
        case 6...12: return 30
        case 12...20: return 40
        case 20...30: return 50
        default: return 60
        }
    }
}
