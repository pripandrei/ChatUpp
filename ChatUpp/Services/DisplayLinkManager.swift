//
//  DisplayLinkManager.swift
//  ChatUpp
//
//  Created by Andrei Pripa on 9/24/25.
//

import UIKit

final class DisplayLinkManager
{
    static let shered = DisplayLinkManager()

    private init() {}

    private var displayLink: CADisplayLink?
//    private var stickerObjects: Set<RLLottieView> = []
    private var renderObjects: Array<any ObjectRenderable> = []

    // MARK: - Animation Loop
    func startAnimationLoop()
    {
        let proxy = DisplayLinkProxy(target: self, selector: #selector(renderFrame))
        displayLink = CADisplayLink(target: proxy, selector: #selector(DisplayLinkProxy.onDisplayLink(_:)))
        displayLink?.add(to: .main, forMode: .common)
    }

    func stopAnimationLoop() {
        displayLink?.invalidate()
        displayLink = nil
    }

    @objc private func renderFrame()
    {
//        Frame skip (render every 2nd tick → ~30 FPS)
//        frameSkipCounter += 1
//        if frameSkipCounter % 2 != 0 { return }

//        stickerObjects.forEach { lottie in
        renderObjects.forEach { lottie in
            lottie.renderNextFrame()
        }
    }

    func addObject(_ object: any ObjectRenderable)
    {
        if displayLink == nil {
            startAnimationLoop()
        }
//        stickerObjects.insert(object)
        renderObjects.append(object)
    }

    func cleanup(_ object: any ObjectRenderable)
    {
        renderObjects.removeAll { $0 === object }
//        stickerObjects.remove(object)
        
//        if stickerObjects.isEmpty
        if renderObjects.isEmpty
        {
            displayLink?.invalidate()
            displayLink = nil
        }
    }
}
