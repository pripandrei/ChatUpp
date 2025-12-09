//
//  WaveformScrubber.swift
//  ChatUpp
//
//  Created by Andrei Pripa on 10/23/25.
//

import SwiftUI
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
            let barWidth = samples.isEmpty ? 0 : width / CGFloat(samples.count)
            
            HStack(alignment: .bottom, spacing: barWidth * 0.5) {
                ForEach(Array(samples.enumerated()), id: \.offset) { index, sample in
                    let barHeight = CGFloat(sample) * height
                    let isFilled = CGFloat(index) / CGFloat(samples.count) <= progress
                    
                    Rectangle()
                        .fill(isFilled ? filledColor : unfilledColor)
                        .frame(width: barWidth * 0.5,
                               height: max(1, max(barHeight, 3.5)))
                        .cornerRadius(3)
                        .animation(.spring(duration: 0.15), value: progress)
                }
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
