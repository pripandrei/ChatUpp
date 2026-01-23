//
//  FrameTicker.swift
//  ChatUpp
//
//  Created by Andrei Pripa on 1/23/26.
//

import Foundation
import QuartzCore

protocol FrameTickRecievable: AnyObject
{
    func didReceiveFrameTick(deltaTime: TimeInterval)
}

final class FrameTicker
{
    static let shared = FrameTicker()

    private var displayLink: CADisplayLink?
    private var observers = NSHashTable<AnyObject>.weakObjects()

    private init() {}

    func add(_ object: FrameTickRecievable) {
        observers.add(object)
        startIfNeeded()
    }

    func remove(_ object: FrameTickRecievable) {
        observers.remove(object)
        stopIfNeeded()
    }

    private func startIfNeeded()
    {
        guard displayLink == nil else { return }
        displayLink = CADisplayLink(target: self, selector: #selector(tick))
        displayLink?.preferredFrameRateRange = .init(minimum: 60,
                                                     maximum: 120,
                                                     preferred: 60)
        
        displayLink?.add(to: .main, forMode: .common)
    }

    private func stopIfNeeded()
    {
        if observers.allObjects.isEmpty {
            displayLink?.invalidate()
            displayLink = nil
        }
    }

    @objc private func tick(link: CADisplayLink)
    {
        let delta = link.targetTimestamp - link.timestamp
        
        for case let object? in observers.allObjects // skip nil values
        {
            (object as? FrameTickRecievable)?.didReceiveFrameTick(deltaTime: delta)
        }
    }
}


/// Only one, serial queue should be used for all stickers render !!!
///
enum ThorVGRenderQueue
{
    static let shared: DispatchQueue = .init(label: "thorvg.render.global.serial",
                                             qos: .userInitiated)
}
