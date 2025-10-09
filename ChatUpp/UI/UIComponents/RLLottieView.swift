//
//  Untitled.swift
//  ChatUpp
//
//  Created by Andrei Pripa on 9/22/25.
//

import UIKit
import librlottie
import Gzip

// MARK: - RLLottieView
class RLLottieView: UIView, ObjectRenderable
{
    private var animation: OpaquePointer?
    private var totalFrames: Int = 0
    private let renderSize: CGSize 
    private var buffer: UnsafeMutablePointer<UInt32>?
    private var isVisible = false
    private var renderInProgress = false
    private var startTime: CFTimeInterval = 0
    private var randomOffset: TimeInterval = 0

    // cached graphics objects
    private let cachedColorSpace: CGColorSpace
    private let cachedBitmapInfo: CGBitmapInfo

    // generation token
    private var generation: Int = 0

    init(renderSize: CGSize = .init(width: 200, height: 200))
    {
        self.renderSize = renderSize
        self.cachedColorSpace = CGColorSpaceCreateDeviceRGB()
        self.cachedBitmapInfo = CGBitmapInfo(
            rawValue: CGBitmapInfo.byteOrder32Little.rawValue |
            CGImageAlphaInfo.premultipliedFirst.rawValue
        )
        super.init(frame: .zero)
        
        let pixelCount = Int(renderSize.width * renderSize.height)
        buffer = UnsafeMutablePointer<UInt32>.allocate(capacity: pixelCount)
        buffer?.initialize(repeating: 0, count: pixelCount)
    }
        
        // Convenience initializer
    override convenience init(frame: CGRect)
    {
        self.init(renderSize: .init(width: 200, height: 200))
        self.frame = frame
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func loadAnimation(named: String, _ completion: ((OpaquePointer) -> Void)? = nil)
    {
        Task.detached(priority: .userInitiated) { [weak self] in
            guard let animation = self?.getAnimation(name: named) else { return }
            
            await MainActor.run { [weak self] in
                self?.loadAnimation(animation: animation)
                completion?(animation)
            }
        }
    }
    
    func loadAnimation(animation: OpaquePointer)
    {
        generation &+= 1
        let currentGen = generation
        
        self.animation = nil
        layer.contents = nil
        guard self.generation == currentGen else { return }
        
        self.animation = animation
        self.totalFrames = Int(lottie_animation_get_totalframe(animation))
        self.startTime = CACurrentMediaTime()
        self.randomOffset = TimeInterval.random(in: 0..<2.0)
    }

    private nonisolated func getAnimation(name: String) -> OpaquePointer?
    {
        let fileName = name + ".json"
        let animationExist = CacheManager.shared.doesFileExist(at: fileName)
        let animationPath = animationExist ? CacheManager.shared.getURL(for: fileName)?.path() : nil
        
        if let animationPath
        {
            return lottie_animation_from_file(animationPath)
        }
        
        guard let tgsPath = Bundle.main.path(forResource: name, ofType: "tgs"),
              let tgsData = try? Data(contentsOf: .init(filePath: tgsPath)),
              let unzippedData = try? tgsData.gunzipped()
        else {
            print("❌ Failed to unzip \(name).tgs")
            return nil
        }
        
        if let path = Bundle.main.path(forResource: name, ofType: "json") {
            print(path)
        }
        
        CacheManager.shared.saveData(unzippedData, toPath: name + ".json")
        
        guard let jsonPath = CacheManager.shared.getURL(for: name + ".json")?.path() else
        { return nil }
        
        return lottie_animation_from_file(jsonPath)
    }

    func renderNextFrame()
    {
        guard isVisible,
              let animation,
              let buffer,
              !renderInProgress,
              totalFrames > 0 else { return }

        renderInProgress = true
        let gen = generation
        let localBuffer = buffer
        let localAnim = animation

        let elapsed = CACurrentMediaTime() - startTime + randomOffset
        let duration = Double(totalFrames) / Double(lottie_animation_get_framerate(localAnim))
        let progress = fmod(elapsed, duration) / duration
        let currentFrame = Int(progress * Double(totalFrames))

        Task { [weak self] in
            guard let self, self.generation == gen else { return }
            await StickerAnimationManager.shared.render(animation: localAnim,
                                                         frame: currentFrame,
                                                         buffer: localBuffer,
                                                         size: self.renderSize)

            self.createAndDisplayImage(from: localBuffer)
            self.renderInProgress = false
        }
    }

    // MARK: - Reset
    func reset()
    {
        generation &+= 1  // invalidate all pending renders
        animation = nil
        isVisible = false
        renderInProgress = false
        layer.contents = nil
    }
    
    func destroyAnimation()
    {
        Task {
            await StickerAnimationManager.shared.destroyAnimation
            {
                guard let anim = animation else { return }
                lottie_animation_render_flush(anim)
                lottie_animation_destroy(anim)
            }
            self.reset()
        }
    }

    deinit {
        buffer?.deallocate()
//        print("RLLottieView deinit")
    }

    // MARK: - Helpers
    private func createAndDisplayImage(from cgBuffer: UnsafeMutableRawPointer)
    {
        guard let context = CGContext(data: cgBuffer,
                                      width: Int(renderSize.width),
                                      height: Int(renderSize.height),
                                      bitsPerComponent: 8,
                                      bytesPerRow: Int(renderSize.width) * 4,
                                      space: cachedColorSpace,
                                      bitmapInfo: cachedBitmapInfo.rawValue),
              let cgImage = context.makeImage() else { return }

        DispatchQueue.main.async { [weak self] in
            self?.layer.contents = cgImage
        }
    }

    func setVisible(_ visible: Bool) {
        isVisible = visible
    }
}

protocol ObjectRenderable: AnyObject
{
    func renderNextFrame()
}
