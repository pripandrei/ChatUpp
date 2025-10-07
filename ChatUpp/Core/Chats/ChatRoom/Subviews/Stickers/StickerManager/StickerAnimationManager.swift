//
//  StickerAnimationManager.swift
//  ChatUpp
//
//  Created by Andrei Pripa on 9/22/25.
//

import UIKit
import librlottie

// MARK: - Render Actor
actor StickerAnimationManager
{
    static let shared = StickerAnimationManager()
    
    private init() {}
    
    func render(
        animation: OpaquePointer,
        frame: Int,
        buffer: UnsafeMutablePointer<UInt32>,
        size: CGSize
    ) {
        lottie_animation_render(
            animation,
            size_t(frame),
            buffer,
            size_t(size.width),
            size_t(size.height),
            size_t(Int(size.width) * MemoryLayout<UInt32>.size)
        )
    }
    
    func destroyAnimation(_ block: () -> Void)
    {
        block()
    }
}
