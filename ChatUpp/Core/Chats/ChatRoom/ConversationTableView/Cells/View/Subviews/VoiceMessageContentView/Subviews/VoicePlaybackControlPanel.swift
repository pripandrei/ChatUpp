//
//  AudioControlPanel.swift
//  ChatUpp
//
//  Created by Andrei Pripa on 10/21/25.
//

import SwiftUI
import AVFoundation


// MARK: - Audio control panel
struct AudioControlPanelView: View
{
    @StateObject private var audioManager = AudioPlayerManager()
    @State var audioFileURL: URL
    
    var body: some View
    {
        VStack(spacing: 0)
        {
            HStack(spacing: 0)
            {
                Button(action: {
                    audioManager.togglePlayPause()
                }) {
                    Image(systemName: audioManager.isPlaying ? "pause.circle.fill" : "play.circle.fill")
                        .resizable()
                        .frame(width: 64, height: 64)
                        .foregroundColor(.white)
                    
                }
                .buttonStyle(.plain)

                VStack
                {
                    WaveformScrubber(
                        progress: $audioManager.progress,
                        shouldUpdateProgress: $audioManager.shouldUpdateProgress,
                        samples: audioManager.waveformSamples,
                        filledColor: .blue,
                        unfilledColor: .gray
                    ) { newProgress in
                        audioManager.seek(to: newProgress)
                    }
                    .frame(height: 40)
                    
                    HStack {
                        Text(audioManager.formatTime(audioManager.duration - audioManager.currentTime))
                            .font(.subheadline)
                            .foregroundColor(Color(#colorLiteral(red: 0.9197804332, green: 0.9238422513, blue: 0.9495783448, alpha: 1)))
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 10)
            }
            .frame(height: 64)
            
//            Button("Load Sample Audio")
//            {
//                // Option 1: Load from bundle
//                audioManager.loadAudio(filename: "123ff", fileExtension: "m4a")
//                
//                // Option 2: Load from URL
//                // if let url = URL(string: "https://example.com/audio.mp3") {
//                //     audioManager.loadAudio(url: url)
//                // }
//            }
//            .padding()
        }
        .onAppear(perform: {
            audioManager.loadAudio(url: self.audioFileURL)
        })
        .background(Color(ColorManager.outgoingMessageBackgroundColor))
//        .clipShape(.rect(cornerRadius: 12))
        .padding()
    }
}

#Preview {
    AudioControlPanelView(audioFileURL: .desktopDirectory)
//    AudioControlPanel()
}
//








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
