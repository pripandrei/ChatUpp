//
//  AudioControlPanel.swift
//  ChatUpp
//
//  Created by Andrei Pripa on 10/21/25.
//

import SwiftUI
import AVFoundation
import Combine


// MARK: - Audio control panel
struct VoicePlaybackControlPanelView: View
{
    @StateObject var viewModel: VoicePlaybackControlPanelViewModel
    private let colorScheme: ColorScheme

    init(audioFileURL: URL,
         audioSamples: [Float],
         colorScheme: ColorScheme)
    {
        _viewModel = StateObject(wrappedValue: .init(audioFileURL: audioFileURL,
                                                     audioSamples: audioSamples))
        self.colorScheme = colorScheme
    }
    
    var body: some View
    {
        GeometryReader { geometry in
            
            VStack(spacing: 0)
            {
                HStack(spacing: 0)
                {
                    Button(action: {
                        viewModel.togglePlayPause()
                    }) {
                        Image(systemName: viewModel.isPlaying ? "pause.circle.fill" : "play.circle.fill")
                            .resizable()
                            .scaledToFit()
                            .frame(height: geometry.size.height * 0.8)
                            .foregroundColor(colorScheme.playButtonColor)
                            .rotationEffect(.degrees(viewModel.isPlaying ? 180 : 0))
                            .animation(.bouncy(duration: 0.3), value: viewModel.isPlaying)
                    }
                    .buttonStyle(NoHighlightButtonStyle())

                    VStack(spacing: 4)
                    {
                        WaveformScrubber(
                            progress: $viewModel.playbackProgress,
                            shouldUpdateProgress: $viewModel.shouldUpdateProgress,
                            samples: viewModel.waveformSamples,
                            filledColor: colorScheme.filledColor,
                            unfilledColor: colorScheme.unfilledColor
                        ) { newProgress in
                            viewModel.seek(to: newProgress)
                        }
                        .frame(height: geometry.size.height * 0.3)
                        .padding(.top,5)
                        
                        Text(viewModel.remainingTime)
                            .font(.system(size: 11))
                            .foregroundColor(Color(ChatUpp.ColorScheme.incomingMessageComponentsTextColor))
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 10)
                    .onTapGesture {
                        viewModel.togglePlayPause()
                    }
                    
                }
                .frame(width: geometry.size.width, height: geometry.size.height)
            }
        }
        .background(colorScheme.backgroundColor)
        .clipped()
//        .drawingGroup() 
    }
}

extension VoicePlaybackControlPanelView
{
    struct ColorScheme
    {
        let backgroundColor: Color
        let filledColor: Color
        let unfilledColor: Color
        let playButtonColor: Color
    }
}

struct NoHighlightButtonStyle: ButtonStyle
{
    func makeBody(configuration: Configuration) -> some View
    {
        configuration.label
            .opacity(1)
    }
}

#Preview {
    let url = Bundle.main.url(forResource: "Wolfgang", withExtension: "mp3")
    let samples = AudioSessionManager.shared.extractSamples(from: url ?? .desktopDirectory, targetSampleCount: 40)
    VoicePlaybackControlPanelView(audioFileURL: url ?? .desktopDirectory, audioSamples: samples, colorScheme: .init(backgroundColor: .accentColor, filledColor: .accentColor, unfilledColor: .accentColor, playButtonColor: .accentColor))
}

