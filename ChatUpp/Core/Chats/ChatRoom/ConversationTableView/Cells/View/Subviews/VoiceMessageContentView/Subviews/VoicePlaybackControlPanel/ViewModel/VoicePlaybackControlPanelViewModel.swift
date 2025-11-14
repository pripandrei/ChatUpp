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
    @Published private(set) var waveformSamples: [Float] = []
    @Published private(set) var isPlaying: Bool = false
    @Published private var currentPlaybackTime: TimeInterval = 0.0
    @Published private var audioTotalDuration: TimeInterval = 0.0
    @Published var playbackProgress: CGFloat = 0.0
    @Published var shouldUpdateProgress: Bool = true
    
    private let audioManager = AudioSessionManager.shared
    private let audioFileURL: URL
    private var cancellables: Set<AnyCancellable> = []
    
    var remainingTime: String
    {
        return (audioTotalDuration - currentPlaybackTime).mmSS
    }
    
    init(audioFileURL: URL, audioSamples: [Float])
    {
        self.audioFileURL = audioFileURL
        self.waveformSamples = audioSamples
        Task
        {
            let duration = await audioManager.getAudioDuration(from: audioFileURL)
            await MainActor.run { self.audioTotalDuration = CMTimeGetSeconds(duration) }
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
}
