//
//  VoicePlaybackControlPanelViewModel.swift
//  ChatUpp
//
//  Created by Andrei Pripa on 11/12/25.
//

import SwiftUI
import AVFoundation
import Combine
  
final class VoicePlaybackControlPanelViewModel: SwiftUI.ObservableObject
{
    @Published private(set) var waveformSamples: [CGFloat] = []
    @Published private(set) var isPlaying: Bool = false
    @Published private(set) var currentPlaybackTime: TimeInterval = 0.0
    @Published var playbackProgress: CGFloat = 0.0
    @Published var shouldUpdateProgress: Bool = true
    
    private let audioManager = AudioSessionManager.shared
    private let audioFileURL: URL
    private var cancellables: Set<AnyCancellable> = []
        
    var audioTotalDuration: TimeInterval = 0.0
    
    init(audioFileURL: URL)
    {
        self.audioFileURL = audioFileURL
        generateWaveform(from: audioFileURL)
        Task
        {
            let duration = await audioManager.getAudioDuration(from: audioFileURL)
            self.audioTotalDuration = CMTimeGetSeconds(duration)
        }
        setupBinding()
    }
    
    private func setupBinding()
    {
        audioManager.$currentlyLoadedAudioURL
            .combineLatest(audioManager.$isAudioPlaying)
            .dropFirst()
            .sink { [weak self] currentAudioURL, isPlaying in
                guard let self else {return}
                
                if currentAudioURL == self.audioFileURL
                {
                    self.isPlaying = isPlaying
                } else {
                    self.isPlaying = false
                }
            }
            .store(in: &cancellables)

        audioManager.$currentPlaybackTime
            .sink { [weak self] playbackTime in
                guard let self else {return}
                
                if self.audioFileURL == self.audioManager.currentlyLoadedAudioURL
                {
                    print("PlayBack time:  ", playbackTime)
                    self.currentPlaybackTime = playbackTime
                    
                    if shouldUpdateProgress
                    {
                        self.playbackProgress = CGFloat(playbackTime / self.audioTotalDuration)
                        print("PlayBack progress:  ", self.playbackProgress)
                    }
                }
            }.store(in: &cancellables)
    }
    
    // Generate waveform samples from audio file
    private func generateWaveform(from url: URL)
    {
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            
            guard let samples = self?.audioManager.extractSamples(from: url,
                                                                  targetSampleCount: 40)
            else { return }
            
            DispatchQueue.main.async {
                self?.waveformSamples = samples
            }
        }
    }
    
    func togglePlayPause()
    {
        if audioManager.isRecording()
        {
            audioManager.recordCancellationSubject.send()
        }
        
        audioManager.play(audioURL: audioFileURL,
                          startingAtTime: currentPlaybackTime)
    }
    
    func seek(to progress: CGFloat)
    {
        let newTime = TimeInterval(progress) * audioTotalDuration
        if self.audioFileURL == audioManager.currentlyLoadedAudioURL
        {
            audioManager.updateCurrentPlaybackTime(time: newTime)
        }
        playbackProgress = progress
        currentPlaybackTime = newTime
    }
    
    func formatTime(_ time: TimeInterval) -> String
    {
        let minutes = Int(time) / 60
        let seconds = Int(time) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
}
