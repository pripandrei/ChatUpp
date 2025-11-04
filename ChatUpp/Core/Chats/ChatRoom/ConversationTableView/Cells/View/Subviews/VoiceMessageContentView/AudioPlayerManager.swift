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

// MARK: - Audio Player Manager
class AudioPlayerManager: SwiftUI.ObservableObject
{
    @Published var progress: CGFloat = 0
    @Published var isPlaying = false
    @Published var duration: TimeInterval = 0
    @Published var currentTime: TimeInterval = 0
    @Published var waveformSamples: [CGFloat] = []
    @Published var shouldUpdateProgress: Bool = true
    
    private var audioPlayer: AVAudioPlayer?
    private var timer: Timer?
    
    init() {
        setupAudioSession()
    }
    
    private func setupAudioSession() {
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback,
                                                            mode: .default)
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            print("Failed to set up audio session: \(error)")
        }
    }
    
    // Load audio from file
    func loadAudio(url: URL) {
        do {
//            guard let url2 = Bundle.main.url(forResource: "tokyo_lounge", withExtension: "m4a") else { return }
            
            audioPlayer = try AVAudioPlayer(contentsOf: url)
            audioPlayer?.prepareToPlay()
            duration = audioPlayer?.duration ?? 0
            
            // Generate waveform samples
            generateWaveform(from: url)
        } catch {
            print("Failed to load audio: \(error)")
        }
    }
    
    // Load audio from bundle
    func loadAudio(filename: String, fileExtension: String = "m4a")
    {
        guard let url = Bundle.main.url(forResource: filename,
                                        withExtension: fileExtension) else
        {
            print("Audio file not found in bundle")
            return
        }
        loadAudio(url: url)
    }
    
    // Generate waveform samples from audio file
    private func generateWaveform(from url: URL)
    {
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            
            guard /*let targetCount = self?.getSampleCountForDuration(self?.duration ?? 0),*/
                  let samples = self?.extractWaveformSamples(from: url, targetSampleCount: 40)
            else { return }
            
            DispatchQueue.main.async {
                self?.waveformSamples = samples
            }
        }
    }
    
    private func extractWaveformSamples(from url: URL,
                                        targetSampleCount: Int) -> [CGFloat] {
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
    
    func play() {
        audioPlayer?.play()
        isPlaying = true
        startTimer()
    }
    
    func pause() {
        audioPlayer?.pause()
        isPlaying = false
        stopTimer()
    }
    
    func togglePlayPause()
    {
        if isPlaying {
            pause()
        } else {
            play()
        }
    }
    
    func seek(to progress: CGFloat)
    {
        guard let player = audioPlayer else { return }
        
        let newTime = TimeInterval(progress) * duration
        player.currentTime = newTime
        self.progress = progress
        self.currentTime = newTime
    }
    
    private func startTimer()
    {
        stopTimer()
        timer = Timer.scheduledTimer(withTimeInterval: 0.05, repeats: true) { [weak self] _ in
            self?.updateProgress()
        }
    }
    
    private func stopTimer() {
        timer?.invalidate()
        timer = nil
    }
    
    private func updateProgress()
    {
        guard let player = audioPlayer, shouldUpdateProgress else { return }
        currentTime = player.currentTime
        
        if duration > 0 {
            progress = CGFloat(currentTime / duration)
        }
        
        if !player.isPlaying && isPlaying
        {
            // Playback finished
            isPlaying = false
            stopTimer()
            progress = 0
            player.currentTime = 0
        }
    }
    
    func formatTime(_ time: TimeInterval) -> String
    {
        let minutes = Int(time) / 60
        let seconds = Int(time) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
    
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
