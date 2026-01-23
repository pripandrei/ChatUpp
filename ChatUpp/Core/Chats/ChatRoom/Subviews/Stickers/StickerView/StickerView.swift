//
//  StickerView.swift
//  ChatUpp
//
//  Created by Andrei Pripa on 1/23/26.
//


import UIKit
import Foundation
import ThorVGSwift
import Gzip

final class StickerView: UIView
{
    private let size: CGSize
    private let engine = Engine(numberOfThreads: 2)
    
    private var buffer: UnsafeMutablePointer<UInt32>?
    private var renderer: LottieRenderer?
    private var context: CGContext?

    private var numberOfFrames: Float = 0
    private var animationFrameRate: Float = 60
    private var currentFrameIndex: Float = 1
    
    private let imageLayer: CALayer = .init()

    init(size: CGSize = .init(width: 200, height: 200))
    {
        self.size = size
        super.init(frame: .zero)
        
        let bufferSize = Int(size.width * size.height)
        buffer = UnsafeMutablePointer<UInt32>.allocate(capacity: bufferSize)
        buffer?.initialize(repeating: 0, count: bufferSize)
        layer.addSublayer(imageLayer)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    deinit
    {
        cleanup()
        destroyBuffer()
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        imageLayer.frame = bounds
    }

    
    //MARK: - Setup lottie
    
    func setupSticker(_ name: String)
    {
        guard let path = getPath(for: name),
              let buffer else { return }

        do {
            let lottie = try Lottie(path: path)

            renderer = LottieRenderer(
                lottie,
                engine: engine,
                size: size,
                buffer: buffer,
                stride: Int(size.width),
                pixelFormat: .argb
            )

            numberOfFrames = lottie.numberOfFrames
            currentFrameIndex = 1
            context = nil

        } catch {
            print("Failed to load lottie:", error)
        }
    }
    
    /// Get sticker path
    ///
    private func getPath(for name: String) -> String?
    {
        let fileName = name + ".json"
        let pathExist = CacheManager.shared.doesFileExist(at: fileName)
        let stickerPath = pathExist ? CacheManager.shared.getURL(for: fileName)?.path() : nil
        
        if let stickerPath
        {
            // sticker is cached, return path
            return stickerPath
        }
        
        // sticker is not cached, get TGS file from bundle, convert to json and cache it
        guard let tgsPath = Bundle.main.path(forResource: name, ofType: "tgs"),
              let tgsData = try? Data(contentsOf: .init(filePath: tgsPath)),
              let unzippedData = try? tgsData.gunzipped()
        else {
            print("❌ Failed to unzip \(name).tgs")
            return nil
        }

        CacheManager.shared.saveData(unzippedData, toPath: fileName)
        return CacheManager.shared.getURL(for: fileName)?.path()
    }
    
    //MARK: - Render
    
    func render(deltaTime: CFTimeInterval)
    {
        autoreleasepool
        {
            guard let renderer, let buffer else { return }

            do {
                try renderer.render(
                    frameIndex: currentFrameIndex,
                    contentRect: CGRect(origin: .zero, size: size),
                    rotation: 0
                )

                if context == nil {
                    context = createContext(buffer: buffer)
                }

                guard let cgImage = context?.makeImage() else { return }

                DispatchQueue.main.async {
                    self.imageLayer.contents = cgImage
                }

                currentFrameIndex += Float(deltaTime) * animationFrameRate
                if currentFrameIndex > numberOfFrames {
                    currentFrameIndex -= numberOfFrames
                }

            } catch {
                print("ThorVG render error:", error)
            }
        }
    }
    
    // MARK: - CGContext
    
    private func createContext(buffer: UnsafeMutablePointer<UInt32>) -> CGContext?
    {
        let colorSpace = CGColorSpace(name: CGColorSpace.displayP3) ?? CGColorSpaceCreateDeviceRGB()
        let bitmapInfo = CGBitmapInfo.byteOrder32Little.rawValue |
                         CGImageAlphaInfo.premultipliedFirst.rawValue

        return CGContext(
            data: buffer,
            width: Int(size.width),
            height: Int(size.height),
            bitsPerComponent: 8,
            bytesPerRow: Int(size.width) * 4,
            space: colorSpace,
            bitmapInfo: bitmapInfo
        )
    }
    
    // MARK: - cleanup
    func cleanup(withBufferDestruction: Bool = false)
    {
        imageLayer.contents = nil
        renderer = nil
        context = nil
        currentFrameIndex = 1
        
        if withBufferDestruction
        {
            destroyBuffer()
        }
    }
    
    private func destroyBuffer()
    {
        buffer?.deinitialize(count: Int(size.width * size.height))
        buffer?.deallocate()
        buffer = nil
    }
}
