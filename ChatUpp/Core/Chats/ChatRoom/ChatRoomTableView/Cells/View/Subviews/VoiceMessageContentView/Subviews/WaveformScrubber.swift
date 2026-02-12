//
//  WaveformScrubber.swift
//  ChatUpp
//
//  Created by Andrei Pripa on 10/23/25.
//

import SwiftUI
import UIKit

struct WaveformScrubber: View
{
    @Binding var progress: CGFloat
    @Binding var shouldUpdateProgress: Bool
    
    var samples: [Float]
    var filledColor: Color
    var unfilledColor: Color
    var onSeek: ((CGFloat) -> Void)?
    
    var body: some View
    {
        GeometryReader { geo in
            let width = geo.size.width
            let height = geo.size.height
            
            // Calculate bar width and spacing based on available width
            let totalBars = CGFloat(samples.count)
            let barWidth = totalBars > 0 ? width / (totalBars * 1.5) : 0
            let spacing = barWidth * 0.5
            
            ZStack(alignment: .leading)
            {
                // Unfilled waveform (background)
                WaveformShape(
                    samples: samples,
                    spacing: Float(spacing),
                    width: Float(barWidth)
                )
                .fill(unfilledColor)
                .frame(width: width, height: height)
                
                // Filled waveform (foreground) - masked by progress
                WaveformShape(
                    samples: samples,
                    spacing: Float(spacing),
                    width: Float(barWidth)
                )
                .fill(filledColor)
                .frame(width: width, height: height)
                .mask(
                    Rectangle()
                        .frame(width: width * progress)
                        .frame(maxWidth: .infinity, alignment: .leading)
                )
                .animation(.spring(duration: 0.15), value: progress)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
            .overlay(
                HorizontalDragView { location in
                    let x = max(0, min(location.x, width))
                    let newProgress = x / width
                    self.progress = newProgress
                    self.shouldUpdateProgress = false
                } onDragEnded: { location in
                    let x = max(0, min(location.x, width))
                    let newProgress = x / width
                    self.shouldUpdateProgress = true
                    onSeek?(newProgress)
                }
            )
        }
    }
}

fileprivate struct WaveformShape: Shape
{
    var samples: [Float]
    var spacing: Float
    var width: Float
    
    nonisolated func path(in rect: CGRect) -> Path
    {
        Path { path in
            var x: CGFloat = 0
            
            for sample in samples
            {
                let height = max(CGFloat(sample) * rect.height, 3.5)
                let barRect = CGRect(
                    x: x,
                    y: (rect.height - height),
                    width: CGFloat(width),
                    height: height
                )
                
                // Add rounded rectangle
                path.addRoundedRect(in: barRect, cornerSize: CGSize(width: 3, height: 3))
                
                x += CGFloat(spacing + width)
            }
        }
    }
}

// MARK: - Horizontal Drag View
struct HorizontalDragView: UIViewRepresentable
{
    let onHorizontalDrag: (CGPoint) -> Void
    let onDragEnded: (CGPoint) -> Void
    
    func makeUIView(context: Context) -> UIView {
        let view = UIView()
        view.backgroundColor = .clear
        view.isUserInteractionEnabled = true
        
        let panGesture = UIPanGestureRecognizer(
            target: context.coordinator,
            action: #selector(Coordinator.handlePan(_:))
        )
        panGesture.delegate = context.coordinator
        view.addGestureRecognizer(panGesture)
        
        return view
    }
    
    func updateUIView(_ uiView: UIView, context: Context)
    {
        context.coordinator.onHorizontalDrag = onHorizontalDrag
        context.coordinator.onDragEnded = onDragEnded
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(onHorizontalDrag: onHorizontalDrag, onDragEnded: onDragEnded)
    }
    
    class Coordinator: NSObject, UIGestureRecognizerDelegate
    {
        var onHorizontalDrag: (CGPoint) -> Void
        var onDragEnded: (CGPoint) -> Void
        
        init(onHorizontalDrag: @escaping (CGPoint) -> Void, onDragEnded: @escaping (CGPoint) -> Void) {
            self.onHorizontalDrag = onHorizontalDrag
            self.onDragEnded = onDragEnded
        }
        
        @objc func handlePan(_ gesture: UIPanGestureRecognizer)
        {
            guard let view = gesture.view else { return }
            let location = gesture.location(in: view)
            
            switch gesture.state
            {
            case .began, .changed:
                onHorizontalDrag(location)
            case .ended, .cancelled:
                onDragEnded(location)
            default:
                break
            }
        }
        
        func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool
        {
            guard let pan = gestureRecognizer as? UIPanGestureRecognizer,
                  let view = pan.view else { return true }
            
            let velocity = pan.velocity(in: view)
            
            // Only begin if horizontal velocity is greater than vertical
            return abs(velocity.x) > abs(velocity.y)
        }
        
        func gestureRecognizer(
            _ gestureRecognizer: UIGestureRecognizer,
            shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer
        ) -> Bool
        {
            // Don't recognize simultaneously - exclusive horizontal control
            return false
        }
    }
}

