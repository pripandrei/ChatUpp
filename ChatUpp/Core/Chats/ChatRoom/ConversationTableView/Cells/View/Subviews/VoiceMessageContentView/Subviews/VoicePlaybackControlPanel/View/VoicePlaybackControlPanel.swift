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

    init(audioFileURL: URL, audioSamples: [Float])
    {
        _viewModel = StateObject(wrappedValue: .init(audioFileURL: audioFileURL,
                                                     audioSamples: audioSamples))
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
                            .foregroundColor(.white)
                            .rotationEffect(.degrees(viewModel.isPlaying ? 180 : 0))
                            .animation(.bouncy(duration: 0.3), value: viewModel.isPlaying)
                    }
                    .buttonStyle(.plain)

                    VStack(spacing: 4)
                    {
                        WaveformScrubber(
                            progress: $viewModel.playbackProgress,
                            shouldUpdateProgress: $viewModel.shouldUpdateProgress,
                            samples: viewModel.waveformSamples
//                            filledColor: .white,
//                            unfilledColor: .pink.opacity(0.6)
                        ) { newProgress in
                            viewModel.seek(to: newProgress)
                        }
                        .frame(height: geometry.size.height * 0.3)
                        .padding(.top,5)
                        
//                        Text(viewModel.formatTime(viewModel.audioTotalDuration - viewModel.currentPlaybackTime))
                        Text(viewModel.remainingTime)
                            .font(.system(size: 12))
                            .foregroundColor(Color(ColorManager.incomingMessageComponentsTextColor))
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 10)
                }
                .frame(width: geometry.size.width, height: geometry.size.height)
            }
        }
        .background(Color(ColorManager.outgoingMessageBackgroundColor))
        .clipped()
    }
}

#Preview {
    let url = Bundle.main.url(forResource: "Wolfgang", withExtension: "mp3")
    let samples = AudioSessionManager.shared.extractSamples(from: url ?? .desktopDirectory, targetSampleCount: 40)
    VoicePlaybackControlPanelView(audioFileURL: url ?? .desktopDirectory, audioSamples: samples)
}








/// Test version2
//
//struct AudioControlPanel2: View
//{
//    @State private var samples: [Float] = []
//    let url = Bundle.main.url(forResource: "Wolfgang", withExtension: ".mp3")!
//    
//    var body: some View
//    {
//        Text("AudioControlPanel")
//        
//        ZStack
//        {
//            WaveformShape(samples: [1.0, 0.55 , 0.92, 0.23, 0.44])
//                .fill(Color(.amethyst))
//                .frame(width: .infinity, height: 80.0)
//                
//        }
//        .padding(.horizontal, 20)
//    }
//    
//    struct AudioInfo
//    {
//        var duration: TimeInterval
//    }
//}
//
//extension AudioControlPanel2
//{
////    private func initializeAudioFile(_size: CGSize)
////    {
////        guard samples.isEmpty else { return }
////
////        Task.detached(priority: .high)
////        {
////            do
////            {
////                let audioFile = try AVAudioFile(forReading: url)
////                let audioInfo = extractAudioInfo (audioFile)
////                samples = try extractAudioSamples (audioFile)
////                let downSampleCount = Int(Float(size.width) / (config.spacing + config.shapeWidth))
////            }
////            catch {
////                print(error.localizedDescription)
////            }
////        }
////    }
//    
//    nonisolated func extractAudioSamples(_ file: AVAudioFile) async throws -> [Float]
//    {
//        let format = file.processingFormat
//        let frameCount = UInt32(file.length)
//        
//        guard let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: frameCount)
//        else {
//            return []
//        }
//        
//        try file.read (into: buffer)
//        
//        if let channel = buffer.floatChannelData
//        {
//            let samples = Array(UnsafeBufferPointer(start: channel[0], count: Int (buffer.frameLength)))
//            return samples
//            
//        }
//        
//        return []
//    }
//    
//    nonisolated func extractAudioInfo(_ file: AVAudioFile) -> AudioInfo
//    {
//        let format = file.processingFormat
//        let sampleRate = format.sampleRate
//        let duration = file.length / Int64(sampleRate)
//        return .init(duration: TimeInterval(duration))
//    }
//}
//
//
//fileprivate struct WaveformShape: Shape
//{
//    var samples: [Float]
//    var spacing: Float = 2
//    var width: Float = 2
//    
//    nonisolated func path(in rect: CGRect) -> Path
//    {
//        Path { path in
//            var x: CGFloat = 0
//            
//            for sample in samples
//            {
//                let height = max (CGFloat (sample) * rect.height, 1)
//                path.addRect(CGRect(
//                    origin: .init(x: x + CGFloat(width), y: -height / 2),
//                    size: .init(width: CGFloat(width), height: height)
//                ))
//                x += CGFloat (spacing + width)
//            }
//        }
//        .offsetBy(dx: 0, dy: rect.height / 2)
//    }
//}
