//
//  FootNote.swift
//  ChatUpp
//
//  Created by Andrei Pripa on 7/3/25.
//

//MARK: - [1].

/// We disable insertion animation, because we need to both
/// animate insertion of message and scroll to bottom at the same time.
/// If we dont do this, conflict occurs and results in glitches
/// Instead we will animate contentOffset
/// This is not the case if table content is scrolled,
/// meaning, cell is not visible


//MARK: - [2].
/// When additional messages are fetched,
/// and they contain very last/recent message,
/// it will not be added through code above,
/// because it already exists in realm
/// This dirty fix adds last (recent) message to realm
/// so that it becomes managed

//MARK: - [3].
/// wait for initial table scroll to finish,
/// before fetching and inserting messages
/// (some times messages are fetched and inserted in table view
/// faster than scroll is finished, resulting in a glitch)

//MARK: - [4].
/// There are two listeners that are set to recent message
/// one in this view model, and second in ChatRoom view model.
/// This cause timing bug with adding new received recent message.
/// So we do not update recent message here if ChatRoomVC is currently opened.
/// We will do it if chat room vc is closed

//MARK: - [5].
/// If first index path at row 0 and section 0 is not visible
/// we should insert rows/sections with animation 0.0
/// this makes table view to not shift its contentOffset after insertion

//MARK: - [6].
/// Firebase listeners, in regards to it's remove of documents feature,
/// works inconsitent.
/// If chat is already opened and listener is already attached to messages,
/// it will detect changes/removals, as long as you stay in chat and don't remove listener.
/// However, this is not the case if chat is closed and documents were removed.
/// On opening chat, and attaching listener it will some times give removed docs
/// and some times not.
/// We can't rely on this behavior so we introduce our own removed messages checker,
/// which will compare messages from local db with those from remote db,
/// and remove those that are not present in remote but are in local.

//MARK: - [7].
/// If unseen messages count from realm are equal to that from firebase,
/// it means that we have all unseen messages up to recent one,
/// so we can safely attach listener to upcoming messages.
/// If realms unseen count is bigger, it still safe to attach listener
/// because it means that some messages were removed from remote db,
/// before synchronization with local was made,
/// but we still can grab last message and listen up from it by id
/// (or timestamp if last message was removed. See how addListenerToUpcomingMessages works)

//MARK: - [8].
/// When we don't posses the range of messages from the last paginated one
/// till the chat recent message, then there is a gap of messages in our local db that needs to be fetched from remote db.
/// So we need to dropLast (chat recent message) to not display it in caht and
/// fetch/paginate from remote db until we hit recent message to display

//MARK: - [9].
/// each title message comes from a user that created this title
/// (i.e when entered group), so instead of checking each message of group,
/// we can check messages if they are title type, and from them grab sender ID
/// and see if we have this sender (user) locally, to display their avatar along the message

//MARK: - [10].
/// IMPORTANT: Keep this case order for iteration on image creation
/// For more info see how 'createImageSamples' function
/// from ImageSampleRepository works
/// 
//MARK: - [11].
/// When user B (the one that is not self) removes chat, it will become invalid,
/// however listener of messages will still receive removed messages.
/// In this case, we dont need to perform any updates with received messages.

//MARK: - [12].
/// If message seen status was updated locally during network off,
/// we should not just add the firestore message to realm
/// because it will override it and message will be set to seen status false,
/// again. So we update firestore message seen status before adding to realm

//MARK: - [13]
/// When pagination of messages happens, it offsets content of table view
/// to the very first cell. After that it wil be adjustead back,
/// but during this phase we dont want to catche the smalles index path,
/// so we just ignore updates ignore updates

//MARK: - [14]
/// Because render of animations can still be in process,
/// we need to queue destruction of animations on actor (StickerAnimationManager) where render takes place.
/// This way animations will be destroyed only after final render will come to it's end.
///

//MARK: - [15]
///
/// KeyboardService is used only to get the height of the keyboard from current device that the app is running on

//MARK: - [16]
//
/// This code is a workaround to avoid content offset shift on new rows/sections insertion
/// EXPLANETION:
/// On new cells/sections insertion, if tableView contentOffset y is at the inital position y (-97.6...),
/// tableView will animate scrolling to the last inserted cell, we want this to avoid,
/// So we offset a bit content, which will result in content remaining at the same position after insertion


//
//  Untitled.swift
//  ChatUpp
//
//  Created by Andrei Pripa on 9/22/25.
////
//
//import UIKit
//import librlottie
//import Gzip
//
//// MARK: - RLLottieView
//class RLLottieView: UIView, ObjectRenderable
//{
//    private var animation: OpaquePointer?
//    private var totalFrames: Int = 0
//    private let renderSize: CGSize
//    private var buffer: UnsafeMutablePointer<UInt32>?
//    private var isVisible = false
//    private var renderInProgress = false
//    private var startTime: CFTimeInterval = 0
//    private var randomOffset: TimeInterval = 0
//
//    // cached graphics objects
//    private let cachedColorSpace: CGColorSpace
//    private let cachedBitmapInfo: CGBitmapInfo
//    private var cachedContext: CGContext?
//    // generation token
//    private var generation: Int = 0
//
//    init(renderSize: CGSize = .init(width: 200, height: 200))
//    {
//        self.renderSize = renderSize
//        self.cachedColorSpace = CGColorSpaceCreateDeviceRGB()
//        self.cachedBitmapInfo = CGBitmapInfo(
//            rawValue: CGBitmapInfo.byteOrder32Little.rawValue |
//            CGImageAlphaInfo.premultipliedFirst.rawValue
//        )
//        super.init(frame: .zero)
//        
//        let pixelCount = Int(renderSize.width * renderSize.height)
//        buffer = UnsafeMutablePointer<UInt32>.allocate(capacity: pixelCount)
//        buffer?.initialize(repeating: 0, count: pixelCount)
//        
//        if let buffer = buffer {
//            cachedContext = CGContext(
//                data: buffer,
//                width: Int(renderSize.width),
//                height: Int(renderSize.height),
//                bitsPerComponent: 8,
//                bytesPerRow: Int(renderSize.width) * 4,
//                space: cachedColorSpace,
//                bitmapInfo: cachedBitmapInfo.rawValue
//            )
//        }
//    }
//        
//        // Convenience initializer
//    override convenience init(frame: CGRect)
//    {
//        self.init(renderSize: .init(width: 200, height: 200))
//        self.frame = frame
//    }
//
//    required init?(coder: NSCoder) {
//        fatalError("init(coder:) has not been implemented")
//    }
//
//    func loadAnimation(named: String, _ completion: ((OpaquePointer) -> Void)? = nil)
//    {
//        Task.detached(priority: .userInitiated) { [weak self] in
//            guard let animation = self?.getAnimation(name: named) else { return }
//            
//            await MainActor.run { [weak self] in
//                self?.loadAnimation(animation: animation)
//                completion?(animation)
//            }
//        }
//    }
//    
//    func loadAnimation(animation: OpaquePointer)
//    {
//        generation &+= 1
//        let currentGen = generation
//        
//        self.animation = nil
//        layer.contents = nil
//        guard self.generation == currentGen else { return }
//        
//        self.animation = animation
//        self.totalFrames = Int(lottie_animation_get_totalframe(animation))
//        self.startTime = CACurrentMediaTime()
//        self.randomOffset = TimeInterval.random(in: 0..<2.0)
//    }
//
//    private nonisolated func getAnimation(name: String) -> OpaquePointer?
//    {
//        let fileName = name + ".json"
//        let animationExist = CacheManager.shared.doesFileExist(at: fileName)
//        let animationPath = animationExist ? CacheManager.shared.getURL(for: fileName)?.path() : nil
//        
//        if let animationPath
//        {
//            return lottie_animation_from_file(animationPath)
//        }
//        
//        guard let tgsPath = Bundle.main.path(forResource: name, ofType: "tgs"),
//              let tgsData = try? Data(contentsOf: .init(filePath: tgsPath)),
//              let unzippedData = try? tgsData.gunzipped()
//        else {
//            print("❌ Failed to unzip \(name).tgs")
//            return nil
//        }
//        
//        if let path = Bundle.main.path(forResource: name, ofType: "json") {
//            print(path)
//        }
//        
//        CacheManager.shared.saveData(unzippedData, toPath: name + ".json")
//        
//        guard let jsonPath = CacheManager.shared.getURL(for: name + ".json")?.path() else
//        { return nil }
//        
//        return lottie_animation_from_file(jsonPath)
//    }
//
//    func renderNextFrame()
//    {
//        guard isVisible,
//              let animation,
//              let buffer,
//              !renderInProgress,
//              totalFrames > 0 else { return }
//
//        renderInProgress = true
//        let gen = generation
//        let localBuffer = buffer
//        let localAnim = animation
//
//        let elapsed = CACurrentMediaTime() - startTime + randomOffset
//        let duration = Double(totalFrames) / Double(lottie_animation_get_framerate(localAnim))
//        let progress = fmod(elapsed, duration) / duration
//        let currentFrame = Int(progress * Double(totalFrames))
//
//        Task { [weak self] in
//            guard let self, self.generation == gen else { return }
//            await StickerAnimationManager.shared.render(animation: localAnim,
//                                                         frame: currentFrame,
//                                                         buffer: localBuffer,
//                                                         size: self.renderSize)
//
//            self.createAndDisplayImage(from: localBuffer)
//            self.renderInProgress = false
//        }
//    }
//
//    // MARK: - Reset
//    func reset()
//    {
//        generation &+= 1  // invalidate all pending renders
//        animation = nil
//        isVisible = false
//        renderInProgress = false
//        layer.contents = nil
//    }
//    
//    func destroyAnimation()
//    {
//        Task {
//            await StickerAnimationManager.shared.destroyAnimation
//            {
//                guard let anim = animation else { return }
//                lottie_animation_render_flush(anim)
//                lottie_animation_destroy(anim)
//            }
//            self.reset()
//        }
//    }
//
//    deinit {
//        buffer?.deallocate()
////        print("RLLottieView deinit")
//    }
//
//    // MARK: - Helpers
//    private func createAndDisplayImage(from cgBuffer: UnsafeMutableRawPointer)
//        {
//            // Reuse cached context - MUCH faster!
//            guard let cgImage = cachedContext?.makeImage() else { return }
//            
//            DispatchQueue.main.async { [weak self] in
//                self?.layer.contents = cgImage
//            }
//        }
//
//    func setVisible(_ visible: Bool) {
//        isVisible = visible
//    }
//}
//
//protocol ObjectRenderable: AnyObject
//{
//    func renderNextFrame()
//}




/// LOttie
///
/// //
//  Optimized RLLottieView.swift
//  ChatUpp
//
//  Optimized with vDSP and performance improvements
//
//
//import UIKit
//import librlottie
//import Gzip
//import Accelerate
//
//// MARK: - RLLottieView
//class RLLottieView: UIView, ObjectRenderable
//{
//    private var animation: OpaquePointer?
//    private var totalFrames: Int = 0
//    private let renderSize: CGSize
//    private var buffer: UnsafeMutablePointer<UInt32>?
//    private var isVisible = false
//    private var renderInProgress = false
//    private var startTime: CFTimeInterval = 0
//    private var randomOffset: TimeInterval = 0
//
//    // Cached graphics objects - REUSED across frames
//    private let cachedColorSpace: CGColorSpace
//    private let cachedBitmapInfo: CGBitmapInfo
//    private var cachedContext: CGContext?  // ✅ NEW: Reuse context!
//
//    // CADisplayLink for smooth animation
//    private var displayLink: CADisplayLink?
//    
//    // Generation token
//    private var generation: Int = 0
//    
//    // Frame rate control
//    private let targetFPS: Int = 30
//
//    init(renderSize: CGSize = .init(width: 200, height: 200))
//    {
//        self.renderSize = renderSize
//        self.cachedColorSpace = CGColorSpaceCreateDeviceRGB()
//        self.cachedBitmapInfo = CGBitmapInfo(
//            rawValue: CGBitmapInfo.byteOrder32Little.rawValue |
//            CGImageAlphaInfo.premultipliedFirst.rawValue
//        )
//        super.init(frame: .zero)
//        
//        let pixelCount = Int(renderSize.width * renderSize.height)
//        buffer = UnsafeMutablePointer<UInt32>.allocate(capacity: pixelCount)
//        
//        // ✅ OPTIMIZED: Use vDSP to clear buffer
//        clearBuffer()
//        
//        // ✅ NEW: Create and cache CGContext once
//        if let buffer = buffer {
//            cachedContext = CGContext(
//                data: buffer,
//                width: Int(renderSize.width),
//                height: Int(renderSize.height),
//                bitsPerComponent: 8,
//                bytesPerRow: Int(renderSize.width) * 4,
//                space: cachedColorSpace,
//                bitmapInfo: cachedBitmapInfo.rawValue
//            )
//        }
//    }
//        
//    // Convenience initializer
//    override convenience init(frame: CGRect)
//    {
//        self.init(renderSize: .init(width: 200, height: 200))
//        self.frame = frame
//    }
//
//    required init?(coder: NSCoder) {
//        fatalError("init(coder:) has not been implemented")
//    }
//
//    func loadAnimation(named: String, _ completion: ((OpaquePointer) -> Void)? = nil)
//    {
//        Task.detached(priority: .userInitiated) { [weak self] in
//            guard let animation = self?.getAnimation(name: named) else { return }
//            
//            await MainActor.run { [weak self] in
//                self?.loadAnimation(animation: animation)
//                completion?(animation)
//            }
//        }
//    }
//    
//    func loadAnimation(animation: OpaquePointer)
//    {
//        generation &+= 1
//        let currentGen = generation
//        
//        self.animation = nil
//        layer.contents = nil
//        guard self.generation == currentGen else { return }
//        
//        self.animation = animation
//        self.totalFrames = Int(lottie_animation_get_totalframe(animation))
//        self.startTime = CACurrentMediaTime()
//        self.randomOffset = TimeInterval.random(in: 0..<2.0)
//    }
//
//    private nonisolated func getAnimation(name: String) -> OpaquePointer?
//    {
//        let fileName = name + ".json"
//        let animationExist = CacheManager.shared.doesFileExist(at: fileName)
//        let animationPath = animationExist ? CacheManager.shared.getURL(for: fileName)?.path() : nil
//        
//        if let animationPath
//        {
//            return lottie_animation_from_file(animationPath)
//        }
//        
//        guard let tgsPath = Bundle.main.path(forResource: name, ofType: "tgs"),
//              let tgsData = try? Data(contentsOf: .init(filePath: tgsPath)),
//              let unzippedData = try? tgsData.gunzipped()
//        else {
//            print("❌ Failed to unzip \(name).tgs")
//            return nil
//        }
//        
//        if let path = Bundle.main.path(forResource: name, ofType: "json") {
//            print(path)
//        }
//        
//        CacheManager.shared.saveData(unzippedData, toPath: name + ".json")
//        
//        guard let jsonPath = CacheManager.shared.getURL(for: name + ".json")?.path() else
//        { return nil }
//        
//        return lottie_animation_from_file(jsonPath)
//    }
//
//    // ✅ NEW: CADisplayLink callback for smooth rendering
//    @objc private func displayLinkFired() {
//        renderNextFrame()
//    }
//
//    func renderNextFrame()
//    {
//        guard isVisible,
//              let animation,
//              let buffer,
//              !renderInProgress,
//              totalFrames > 0 else { return }
//
//        renderInProgress = true
//        let gen = generation
//        let localBuffer = buffer
//        let localAnim = animation
//
//        let elapsed = CACurrentMediaTime() - startTime + randomOffset
//        let duration = Double(totalFrames) / Double(lottie_animation_get_framerate(localAnim))
//        let progress = fmod(elapsed, duration) / duration
//        let currentFrame = Int(progress * Double(totalFrames))
//
//        Task { [weak self] in
//            guard let self, self.generation == gen else { return }
//            await StickerAnimationManager.shared.render(animation: localAnim,
//                                                         frame: currentFrame,
//                                                         buffer: localBuffer,
//                                                         size: self.renderSize)
//
//            self.createAndDisplayImage(from: localBuffer)
//            self.renderInProgress = false
//        }
//    }
//
//    // MARK: - Reset
//    func reset()
//    {
//        generation &+= 1  // Invalidate all pending renders
//        animation = nil
//        isVisible = false
//        renderInProgress = false
//        layer.contents = nil
//        stopDisplayLink()
//    }
//    
//    func destroyAnimation()
//    {
//        Task {
//            await StickerAnimationManager.shared.destroyAnimation
//            {
//                guard let anim = animation else { return }
//                lottie_animation_render_flush(anim)
//                lottie_animation_destroy(anim)
//            }
//            self.reset()
//        }
//    }
//
//    deinit {
//        stopDisplayLink()
//        buffer?.deallocate()
//        cachedContext = nil
////        print("RLLottieView deinit")
//    }
//
//    // MARK: - Helper Methods
//    
//    // ✅ OPTIMIZED: Reuse cached CGContext instead of creating new one every frame
//    private func createAndDisplayImage(from cgBuffer: UnsafeMutableRawPointer)
//    {
//        // Just create CGImage from cached context - MUCH faster!
//        guard let cgImage = cachedContext?.makeImage() else { return }
//
//        DispatchQueue.main.async { [weak self] in
//            self?.layer.contents = cgImage
//        }
//    }
//    
//    // ✅ NEW: vDSP-optimized buffer clearing
//    private func clearBuffer() {
//        guard let buffer else { return }
//        let count = Int(renderSize.width * renderSize.height)
//        
//        // Use vDSP to clear buffer (faster than initialize(repeating:))
//        memset(buffer, 0, count * MemoryLayout<UInt32>.stride)
//    }
//    
//    // ✅ NEW: Display link management for smooth 30/60 FPS rendering
//    private func startDisplayLink() {
//        guard displayLink == nil else { return }
//        
//        displayLink = CADisplayLink(target: self, selector: #selector(displayLinkFired))
//        displayLink?.preferredFramesPerSecond = targetFPS
//        displayLink?.add(to: .main, forMode: .common)
//    }
//    
//    private func stopDisplayLink() {
//        displayLink?.invalidate()
//        displayLink = nil
//    }
//
//    // ✅ IMPROVED: Automatically manage display link
//    func setVisible(_ visible: Bool) {
//        isVisible = visible
//        
//        if visible {
//            startDisplayLink()
//        } else {
//            stopDisplayLink()
//        }
//    }
//    
//    // ✅ BONUS: Optional buffer manipulation using vDSP
//    
//    /// Apply brightness adjustment to buffer (example of vDSP usage)
//    private func adjustBrightness(brightness: Float) {
//        guard let buffer else { return }
//        let count = Int(renderSize.width * renderSize.height)
//        
//        // Convert UInt32 to Float for processing
//        var floatBuffer = [Float](repeating: 0, count: count * 4) // RGBA
//        vDSP_vfltu32(buffer, 1, &floatBuffer, 1, vDSP_Length(count))
//        
//        // Add brightness value to all pixels
//        var brightnessValue = brightness
//        vDSP_vsadd(floatBuffer, 1, &brightnessValue, &floatBuffer, 1, vDSP_Length(count * 4))
//        
//        // Clamp values to 0-255 range
//        var min: Float = 0.0
//        var max: Float = 255.0
//        vDSP_vclip(floatBuffer, 1, &min, &max, &floatBuffer, 1, vDSP_Length(count * 4))
//        
//        // Convert back to UInt32
//        var resultBuffer = [UInt32](repeating: 0, count: count)
//        vDSP_vfixu32(floatBuffer, 1, &resultBuffer, 1, vDSP_Length(count))
//        
//        buffer.update(from: resultBuffer, count: count)
//    }
//    
//    /// Blend two animation frames (example of vDSP usage)
//    private func blendWithBuffer(sourceBuffer: UnsafeMutablePointer<UInt32>,  alpha: inout Float) {
//        guard let destBuffer = buffer else { return }
//        let count = Int(renderSize.width * renderSize.height)
//        
//        var sourceFloat = [Float](repeating: 0, count: count)
//        var destFloat = [Float](repeating: 0, count: count)
//        
//        // Convert to float
//        vDSP_vfltu32(sourceBuffer, 1, &sourceFloat, 1, vDSP_Length(count))
//        vDSP_vfltu32(destBuffer, 1, &destFloat, 1, vDSP_Length(count))
//        
//        // Blend: result = source * alpha + dest * (1 - alpha)
//        var result = [Float](repeating: 0, count: count)
//        var oneMinusAlpha = 1.0 - alpha
//        
//        var temp = [Float](repeating: 0, count: count)
//        vDSP_vsmul(sourceFloat, 1, &alpha, &temp, 1, vDSP_Length(count))
//        vDSP_vsma(destFloat, 1, &oneMinusAlpha, temp, 1, &result, 1, vDSP_Length(count))
//        
//        // Convert back
//        var resultUInt32 = [UInt32](repeating: 0, count: count)
//        vDSP_vfixu32(result, 1, &resultUInt32, 1, vDSP_Length(count))
//        
//        destBuffer.update(from: resultUInt32, count: count)
//    }
//}
//
//protocol ObjectRenderable: AnyObject
//{
//    func renderNextFrame()
//}
//
