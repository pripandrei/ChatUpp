//
//  WaveformScrubber.swift
//  ChatUpp
//
//  Created by Andrei Pripa on 10/23/25.
//

import SwiftUI

struct WaveformScrubber: View
{
    @Binding var progress: CGFloat
    @Binding var shouldUpdateProgress: Bool
    @GestureState private var isDragging = false
    
    var samples: [CGFloat]
    var filledColor: Color = .blue
    var unfilledColor: Color = .gray
    var onSeek: ((CGFloat) -> Void)?
    
    var body: some View
    {
        GeometryReader { geo in
            let width = geo.size.width
            let height = geo.size.height
            let barWidth = samples.isEmpty ? 0 : width / CGFloat(samples.count)
            
            HStack(alignment: .bottom, spacing: barWidth * 0.4) {
                ForEach(Array(samples.enumerated()), id: \.offset) { index, sample in
                    let barHeight = sample * height
                    let isFilled = CGFloat(index) / CGFloat(samples.count) <= progress
                    
                    Rectangle()
                        .fill(isFilled ? filledColor : unfilledColor.opacity(0.4))
                        .frame(width: barWidth * 0.6,
                               height: max(1, max(barHeight, 3.5)))
                        .cornerRadius(3)
                        .animation(.spring(duration: 0.15), value: progress)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
            .contentShape(Rectangle())
            .gesture(
                DragGesture(minimumDistance: 0)
                    .updating($isDragging) { _, state, _ in
                        state = true
                    }
                    .onChanged { value in
                        let x = max(0, min(value.location.x, width))
                        let newProgress = x / width
                        self.progress = newProgress
                        self.shouldUpdateProgress = false
                        //                        onSeek?(newProgress)
                    }
                    .onEnded { value in
                        let x = max(0, min(value.location.x, width))
                        let newProgress = x / width
                        self.shouldUpdateProgress = true
                        onSeek?(newProgress)
                    }
            )
        }
    }
}
