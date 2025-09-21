//
//  ChatManager.swift
//  ChatUpp
//
//  Created by Andrei Pripa on 8/16/25.
//

import Foundation
import Combine

final class ChatManager
{
    static let shared = ChatManager()
    
    private init() {}
    
    @Published private(set) var totalUnseenMessageCount: Int = 0
    @Published private(set) var newCreatedChat: Chat?
    @Published private(set) var joinedGroupChat: Chat?
    @Published private(set) var newStickerSubject = PassthroughSubject<String,Never>()

    func incrementUnseenMessageCount(by value: Int)
    {
        totalUnseenMessageCount += value
    }
    
    func decrementUnseenMessageCount(by value: Int)
    {
        totalUnseenMessageCount = max(0, totalUnseenMessageCount - value)
    }
    
    func broadcastNewCreatedChat(_ chat: Chat)
    {
        newCreatedChat = chat
    }
    
    func broadcastJoinedGroupChat(_ chat: Chat)
    {
        joinedGroupChat = chat
    }
    
    func addNewSticker(_ path: String)
    {
        newStickerSubject.send(path)
    }
}
//
//import UIKit
//import librlottie
//
//// Needed for concurrency
//extension OpaquePointer: @unchecked @retroactive Sendable {}
//
//// MARK: - Render Actor
//actor RenderActor
//{
//    static let shared = RenderActor()
//    
//    func render(
//        animation: OpaquePointer,
//        frame: Int,
//        buffer: UnsafeMutablePointer<UInt32>,
//        size: CGSize
//    ) {
//        lottie_animation_render(
//            animation,
//            size_t(frame),
//            buffer,
//            size_t(size.width),
//            size_t(size.height),
//            size_t(Int(size.width) * MemoryLayout<UInt32>.size)
//        )
//    }
//    
//    func destroyAnimation(_ block: () -> Void)
//    {
//        block()
//    }
//}
//
//// MARK: - Stickers Animation Manager
//actor StickersAnimationManager
//{
//    static let shared = StickersAnimationManager()
//    private(set) var cache: [String: OpaquePointer] = [:]
//
//    func getAnimation(named name: String, _ shouldCache: Bool = false) -> OpaquePointer? {
//        if let anim = cache[name] {
//            return anim
//        }
//        
//        guard let path = Bundle.main.path(forResource: name, ofType: "json"),
//              let anim = lottie_animation_from_file(path) else {
//            return nil
//        }
//        if shouldCache {
//            cache[name] = anim
//        }
//        return anim
//    }
//
//    func clearCache() {
//        for (_, anim) in cache {
//            lottie_animation_destroy(anim)
//        }
//        cache.removeAll()
//    }
//
//    deinit {
//        for (_, anim) in cache {
//            lottie_animation_destroy(anim)
//        }
//    }
//    func render(
//        animation: OpaquePointer,
//        frame: Int,
//        buffer: UnsafeMutablePointer<UInt32>,
//        size: CGSize
//    ) {
//        lottie_animation_render(
//            animation,
//            size_t(frame),
//            buffer,
//            size_t(size.width),
//            size_t(size.height),
//            size_t(Int(size.width) * MemoryLayout<UInt32>.size)
//        )
//    }
//}
//
//final class StickersAnimationStorage
//{
//    let animationsName: [String] = {
//        return Stickers.Category.allCases
//            .flatMap { $0.pack.map { $0.deletingPathExtension().lastPathComponent } }
//    }()
//    
//    private(set) var animations: [String: OpaquePointer] = [:]
//    
//    func getAnimation(withName name: String) -> OpaquePointer?
//    {
//        if let animation = animations[name] { return animation }
//
//        guard let path = Bundle.main.path(forResource: name, ofType: "json"),
//              let animation = lottie_animation_from_file(path) else {
//            return nil
//        }
//        self.animations[name] = animation
//        return animation
//    }
//}
//
//// MARK: - StickersCollectionView
//final class StickersCollectionView: UIView
//{
//    let storage = StickersAnimationStorage()
//    private var collectionView: UICollectionView!
//    private var displayLink: CADisplayLink?
//    private var frameSkipCounter = 0
//
//    override init(frame: CGRect) {
//        super.init(frame: frame)
//        backgroundColor = ColorManager.stickerViewBackgroundColor
//        setupCollectionView()
//        startAnimationLoop()
//    }
//
//    required init?(coder: NSCoder) {
//        fatalError("Could not init stickerView")
//    }
//
//    deinit {
//        stopAnimationLoop()
//        Task {
//            await StickersAnimationManager.shared.clearCache()
//        }
//        print("Sticker collection DEINIT")
//    }
//
//    override func layoutSubviews() {
//        if let layout = collectionView.collectionViewLayout as? UICollectionViewFlowLayout {
//            let spacing: CGFloat = 10
//            let itemWidth = (bounds.width - spacing * 5) / 4
//            layout.itemSize = CGSize(width: itemWidth, height: itemWidth)
//            layout.minimumLineSpacing = spacing
//            layout.minimumInteritemSpacing = spacing
//            layout.sectionInset = UIEdgeInsets(top: spacing,
//                                               left: spacing,
//                                               bottom: 0,
//                                               right: spacing)
//        }
//    }
//
//    private func setupCollectionView() {
//        let layout = UICollectionViewFlowLayout()
//        collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
//        collectionView.backgroundColor = .clear
//        collectionView.dataSource = self
//        collectionView.delegate = self
//        collectionView.register(LottieCell.self, forCellWithReuseIdentifier: LottieCell.identifier)
//
//        addSubview(collectionView)
//
//        collectionView.translatesAutoresizingMaskIntoConstraints = false
//        NSLayoutConstraint.activate([
//            collectionView.topAnchor.constraint(equalTo: topAnchor),
//            collectionView.bottomAnchor.constraint(equalTo: bottomAnchor),
//            collectionView.leadingAnchor.constraint(equalTo: leadingAnchor),
//            collectionView.trailingAnchor.constraint(equalTo: trailingAnchor)
//        ])
//    }
//
//    // MARK: - Animation Loop
//    func startAnimationLoop() {
//        let proxy = DisplayLinkProxy(target: self, selector: #selector(renderFrame))
//        displayLink = CADisplayLink(target: proxy, selector: #selector(DisplayLinkProxy.onDisplayLink(_:)))
//        displayLink?.add(to: .main, forMode: .common)
//    }
//
//    private func stopAnimationLoop() {
//        displayLink?.invalidate()
//        displayLink = nil
//    }
//
//    @objc private func renderFrame() {
//        // Frame skip (render every 2nd tick → ~30 FPS)
//        frameSkipCounter += 1
//        if frameSkipCounter % 2 != 0 { return }
//
//        let visibleIndexPaths = collectionView.indexPathsForVisibleItems
//        for indexPath in visibleIndexPaths {
//            if let cell = collectionView.cellForItem(at: indexPath) as? LottieCell {
//                cell.lottieView.renderNextFrame()
//            }
//        }
//    }
//}
//
//// MARK: - UICollectionViewDataSource
//extension StickersCollectionView: UICollectionViewDataSource {
//    func collectionView(_ collectionView: UICollectionView,
//                        numberOfItemsInSection section: Int) -> Int {
//        return storage.animationsName.count
//    }
//
//    func collectionView(_ collectionView: UICollectionView,
//                        cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
//        let cell = collectionView.dequeueReusableCell(
//            withReuseIdentifier: LottieCell.identifier,
//            for: indexPath
//        ) as! LottieCell
//        
//        Task.detached(priority: .userInitiated) {
//            let name = await self.storage.animationsName[indexPath.item]
//            guard let animation = await self.storage.getAnimation(withName: name) else {return}
//            await cell.configure(withAnimation: animation)
//        }
//        return cell
//    }
//}
//
//// MARK: - UICollectionViewDelegate
//extension StickersCollectionView: UICollectionViewDelegateFlowLayout {
//    func collectionView(_ collectionView: UICollectionView,
//                        willDisplay cell: UICollectionViewCell,
//                        forItemAt indexPath: IndexPath) {
//        (cell as? LottieCell)?.lottieView.setVisible(true)
//    }
//
//    func collectionView(_ collectionView: UICollectionView,
//                        didEndDisplaying cell: UICollectionViewCell,
//                        forItemAt indexPath: IndexPath) {
//        (cell as? LottieCell)?.lottieView.setVisible(false)
//    }
//    
//    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath)
//    {
//        collectionView.deselectItem(at: indexPath, animated: false)
//        
////        let cell = collectionView.cellForItem(at: indexPath) as! LottieCell
////
////        guard let stickerName = cell.lottieView.animationName else {return}
//        let stickerName = self.storage.animationsName[indexPath.item]
//        ChatManager.shared.newStickerSubject.send(stickerName)
//    }
//}
//
//// MARK: - LottieCell
//class LottieCell: UICollectionViewCell
//{
//    static let identifier = "LottieCell"
//    let lottieView = RLLottieView()
//
//    override init(frame: CGRect) {
//        super.init(frame: frame)
//        contentView.addSubview(lottieView)
//        lottieView.translatesAutoresizingMaskIntoConstraints = false
//        NSLayoutConstraint.activate([
//            lottieView.topAnchor.constraint(equalTo: contentView.topAnchor),
//            lottieView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
//            lottieView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
//            lottieView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor)
//        ])
//    }
//
//    required init?(coder: NSCoder) {
//        fatalError("init(coder:) has not been implemented")
//    }
//
//    func configure(withAnimationNamed name: String) {
//        lottieView.loadAnimation(named: name)
//    }
//    
//    func configure(withAnimation animation: OpaquePointer) {
//        lottieView.setAnimation(animation: animation)
//    }
//
//    override func prepareForReuse() {
//        super.prepareForReuse()
//        lottieView.reset()
//    }
//}
//
//// MARK: - RLLottieView
//class RLLottieView: UIView
//{
//    private(set) var animationName: String?
//    
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
//
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
//    // MARK: - Load Animation
////    func loadAnimation(named name: String, shouldCache: Bool = false)
////    {
////        generation &+= 1
////        let currentGen = generation
////
////        animationName = name
////        animation = nil
////        layer.contents = nil
////
////        Task { [weak self] in
////            guard let self else { return }
////
////            if let anim = await StickersAnimationManager.shared.getAnimation(named: name, shouldCache) {
////                guard self.generation == currentGen else { return }
////
////                self.animation = anim
////                self.totalFrames = Int(lottie_animation_get_totalframe(anim))
////                self.startTime = CACurrentMediaTime()
////                self.randomOffset = TimeInterval.random(in: 0..<2.0)
//////                self.renderFirstFrame(gen: currentGen)
////            }
////        }
////    }
////
//    
//    func setAnimation(animation: OpaquePointer)
//    {
//        generation &+= 1
//        let currentGen = generation
//
////        animationName = name
//        self.animation = nil
//        layer.contents = nil
//        
//        guard self.generation == currentGen else { return }
//        
//        self.animation = animation
//        self.totalFrames = Int(lottie_animation_get_totalframe(animation))
//        self.startTime = CACurrentMediaTime()
//        self.randomOffset = TimeInterval.random(in: 0..<2.0)
//        
////        Task.detached() { [weak self] in
////            guard let self else { return }
////
////            //            if let anim = self.getAnimation(withName: name)
////            //            {
////            guard await self.generation == currentGen else { return }
////
////            await MainActor.run
////            {
////                self.animation = animation
////                self.totalFrames = Int(lottie_animation_get_totalframe(animation))
////                self.startTime = CACurrentMediaTime()
////                self.randomOffset = TimeInterval.random(in: 0..<2.0)
////            }
////            //            }
////        }
//    }
//    
//    func loadAnimation(named name: String)
//    {
//        generation &+= 1
//        let currentGen = generation
//
//        animationName = name
//        animation = nil
//        layer.contents = nil
//
//        Task.detached() { [weak self] in
//            guard let self else { return }
//
//            if let anim = self.getAnimation(withName: name)
//            {
//                guard await self.generation == currentGen else { return }
//
//                await MainActor.run {
//                    self.animation = anim
//                    self.totalFrames = Int(lottie_animation_get_totalframe(anim))
//                    self.startTime = CACurrentMediaTime()
//                    self.randomOffset = TimeInterval.random(in: 0..<2.0)
//                }
//            }
//        }
//    }
//
//    nonisolated private func getAnimation(withName name: String) -> OpaquePointer?
//    {
//        print(Thread.isMainThread)
//        guard let path = Bundle.main.path(forResource: name, ofType: "json"),
//              let anim = lottie_animation_from_file(path) else {
//            return nil
//        }
//        return anim
//    }
//    
//
////    private func renderFirstFrame(gen: Int) {
////        guard let animation, let buffer else { return }
////
////        Task {
////            guard self.generation == gen else { return }
////            await RenderActor.shared.render(animation: animation,
////                                            frame: 0,
////                                            buffer: buffer,
////                                            size: self.renderSize)
////            self.createAndDisplayImage(from: buffer)
////            self.renderInProgress = false
////        }
////    }
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
//            await RenderActor.shared.render(animation: localAnim,
//                                            frame: currentFrame,
//                                            buffer: localBuffer,
//                                            size: self.renderSize)
//            
//            self.createAndDisplayImage(from: localBuffer)
//            self.renderInProgress = false
//        }
//    }
//
//
//    // MARK: - Reset
//    func reset()
//    {
//        generation &+= 1  // invalidate all pending renders
//        animation = nil
//        animationName = nil
//        isVisible = false
//        renderInProgress = false
//        layer.contents = nil
//    }
//    
//    func destroyAnimation()
//    {
//        Task {
//            await RenderActor.shared.destroyAnimation {
//                guard let anim = animation else { return }
//                print("animation exist and should be destroyed ")
//                lottie_animation_render_flush(anim)
//                lottie_animation_destroy(anim)
//            }
//            self.reset()
//        }
//    }
//
//    deinit {
//        buffer?.deallocate()
//        print("Rlottie deinited")
//    }
//
//    // MARK: - Helpers
//    private func createAndDisplayImage(from cgBuffer: UnsafeMutableRawPointer)
//    {
//        guard let context = CGContext(data: cgBuffer,
//                                      width: Int(renderSize.width),
//                                      height: Int(renderSize.height),
//                                      bitsPerComponent: 8,
//                                      bytesPerRow: Int(renderSize.width) * 4,
//                                      space: cachedColorSpace,
//                                      bitmapInfo: cachedBitmapInfo.rawValue),
//              let cgImage = context.makeImage() else { return }
//
//        DispatchQueue.main.async { [weak self] in
//            self?.layer.contents = cgImage
//        }
//    }
//
//    func setVisible(_ visible: Bool) {
//        isVisible = visible
//    }
//}
//
//// MARK: - DisplayLinkProxy
//final class DisplayLinkProxy {
//    weak var target: AnyObject?
//    let selector: Selector
//    
//    init(target: AnyObject, selector: Selector) {
//        self.selector = selector
//        self.target = target
//    }
//    
//    @objc func onDisplayLink(_ link: CADisplayLink) {
//        _ = target?.perform(selector, with: link)
//    }
//}
//

//
//
//
//
//import UIKit
//import librlottie
//
//// Needed for concurrency
//extension OpaquePointer: @unchecked @retroactive Sendable {}
//
//// MARK: - Render Actor
//actor RenderActor
//{
//    static let shared = RenderActor()
//    
//    var activeTasks = 0
//    
//    func render(
//        animation: OpaquePointer,
//        frame: Int,
//        buffer: UnsafeMutablePointer<UInt32>,
//        size: CGSize
//    ) {
////        defer { activeTasks -= 1 }
////
////        activeTasks += 1
//        print("helloo111")
//        lottie_animation_render(
//            animation,
//            size_t(frame),
//            buffer,
//            size_t(size.width),
//            size_t(size.height),
//            size_t(Int(size.width) * MemoryLayout<UInt32>.size)
//        )
//    }
//    
//    func destroyAnimation(_ block: () async -> Void) async
//    {
//        await block()
//        print("was destroyed")
//    }
//}
//
//// MARK: - Stickers Animation Manager
//actor StickersAnimationManager
//{
//    static let shared = StickersAnimationManager()
//    private(set) var cache: [String: OpaquePointer] = [:]
//
//    func getAnimation(named name: String, _ shouldCache: Bool = false) -> OpaquePointer? {
//        if let anim = cache[name] {
//            return anim
//        }
//        
//        guard let path = Bundle.main.path(forResource: name, ofType: "json"),
//              let anim = lottie_animation_from_file(path) else {
//            return nil
//        }
//        if shouldCache {
//            cache[name] = anim
//        }
//        return anim
//    }
//
//    func clearCache() {
//        for (_, anim) in cache {
//            lottie_animation_destroy(anim)
//        }
//        cache.removeAll()
//    }
//
//    deinit {
//        for (_, anim) in cache {
//            lottie_animation_destroy(anim)
//        }
//    }
//    func render(
//        animation: OpaquePointer,
//        frame: Int,
//        buffer: UnsafeMutablePointer<UInt32>,
//        size: CGSize
//    ) {
//        lottie_animation_render(
//            animation,
//            size_t(frame),
//            buffer,
//            size_t(size.width),
//            size_t(size.height),
//            size_t(Int(size.width) * MemoryLayout<UInt32>.size)
//        )
//    }
//}
//
//// MARK: - StickersCollectionView
//final class StickersCollectionView: UIView
//{
//    private let animationsName: [String] = {
//        return Stickers.Category.allCases
//            .flatMap { $0.pack.map { $0.deletingPathExtension().lastPathComponent } }
//    }()
//    
////    private let animationsName: [String] = StickersAnimationStorage.shared.animationsName
//
//    private var collectionView: UICollectionView!
//    private var displayLink: CADisplayLink?
//    private var frameSkipCounter = 0
//
//    override init(frame: CGRect) {
//        super.init(frame: frame)
//        backgroundColor = ColorManager.stickerViewBackgroundColor
//        setupCollectionView()
//        startAnimationLoop()
//    }
//
//    required init?(coder: NSCoder) {
//        fatalError("Could not init stickerView")
//    }
//
//    deinit {
//        stopAnimationLoop()
////        Task {
////            await StickersAnimationManager.shared.clearCache()
////            StickersAnimationStorage.shared.animations.forEach { (name, animation) in
////                lottie_animation_destroy(animation)
////            }
////            StickersAnimationStorage.shared.animations.removeAll()
////            StickersAnimationStorage.shared.destroyAllAnimations()
//        Task {
//            print("active tasks", await RenderActor.shared.activeTasks)
//            await RenderActor.shared.destroyAnimation {
////                 await StickersAnimationStorage.shared.destroyAllAnimations()
//                for animation in await TestStorage.shared.animations {
//                    lottie_animation_render_flush(animation.value)
//                    lottie_animation_destroy(animation.value)
//                }
//                await MainActor.run {
//                    TestStorage.shared.animations.removeAll()
//                }
//            }
////            await RenderActor.shared.destroyAnimation {
////                for animation in TestStorage.shared.animations
////                {
////                    lottie_animation_destroy(animation.value)
////                }
////                TestStorage.shared.animations.removeAll()
//////                TestStorage.shared.animations.forEach { (_, animation) in
//////                    lottie_animation_destroy(animation)
//////                }
////            }
//        }
////        }
//        print("Sticker collection DEINIT")
//    }
//
//    override func layoutSubviews() {
//        if let layout = collectionView.collectionViewLayout as? UICollectionViewFlowLayout {
//            let spacing: CGFloat = 10
//            let itemWidth = (bounds.width - spacing * 5) / 4
//            layout.itemSize = CGSize(width: itemWidth, height: itemWidth)
//            layout.minimumLineSpacing = spacing
//            layout.minimumInteritemSpacing = spacing
//            layout.sectionInset = UIEdgeInsets(top: spacing,
//                                               left: spacing,
//                                               bottom: 0,
//                                               right: spacing)
//        }
//    }
//
//    private func setupCollectionView() {
//        let layout = UICollectionViewFlowLayout()
//        collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
//        collectionView.backgroundColor = .clear
//        collectionView.dataSource = self
//        collectionView.delegate = self
//        collectionView.register(LottieCell.self, forCellWithReuseIdentifier: LottieCell.identifier)
//
//        addSubview(collectionView)
//
//        collectionView.translatesAutoresizingMaskIntoConstraints = false
//        NSLayoutConstraint.activate([
//            collectionView.topAnchor.constraint(equalTo: topAnchor),
//            collectionView.bottomAnchor.constraint(equalTo: bottomAnchor),
//            collectionView.leadingAnchor.constraint(equalTo: leadingAnchor),
//            collectionView.trailingAnchor.constraint(equalTo: trailingAnchor)
//        ])
//    }
//
//    // MARK: - Animation Loop
//    func startAnimationLoop() {
//        let proxy = DisplayLinkProxy(target: self, selector: #selector(renderFrame))
//        displayLink = CADisplayLink(target: proxy, selector: #selector(DisplayLinkProxy.onDisplayLink(_:)))
//        displayLink?.add(to: .main, forMode: .common)
//    }
//
//    private func stopAnimationLoop() {
//        displayLink?.invalidate()
//        displayLink = nil
//    }
//
//    @objc private func renderFrame() {
//        // Frame skip (render every 2nd tick → ~30 FPS)
//        frameSkipCounter += 1
//        if frameSkipCounter % 2 != 0 { return }
//
//        let visibleIndexPaths = collectionView.indexPathsForVisibleItems
//        for indexPath in visibleIndexPaths {
//            if let cell = collectionView.cellForItem(at: indexPath) as? LottieCell {
//                cell.lottieView.renderNextFrame()
//            }
//        }
//    }
//}
//
//// MARK: - UICollectionViewDataSource
//extension StickersCollectionView: UICollectionViewDataSource {
//    func collectionView(_ collectionView: UICollectionView,
//                        numberOfItemsInSection section: Int) -> Int {
//        return animationsName.count
//    }
//
//    func collectionView(_ collectionView: UICollectionView,
//                        cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
//        let cell = collectionView.dequeueReusableCell(
//            withReuseIdentifier: LottieCell.identifier,
//            for: indexPath
//        ) as! LottieCell
//        cell.configure(withAnimationNamed: animationsName[indexPath.item])
//        return cell
//    }
//}
//
//// MARK: - UICollectionViewDelegate
//extension StickersCollectionView: UICollectionViewDelegateFlowLayout {
//    func collectionView(_ collectionView: UICollectionView,
//                        willDisplay cell: UICollectionViewCell,
//                        forItemAt indexPath: IndexPath) {
//        (cell as? LottieCell)?.lottieView.setVisible(true)
//    }
//
//    func collectionView(_ collectionView: UICollectionView,
//                        didEndDisplaying cell: UICollectionViewCell,
//                        forItemAt indexPath: IndexPath) {
//        (cell as? LottieCell)?.lottieView.setVisible(false)
//    }
//    
//    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath)
//    {
//        collectionView.deselectItem(at: indexPath, animated: false)
//        
////        let cell = collectionView.cellForItem(at: indexPath) as! LottieCell
////
////        guard let stickerName = cell.lottieView.animationName else {return}
//        let stickerName = self.animationsName[indexPath.item]
//        ChatManager.shared.newStickerSubject.send(stickerName)
//    }
//}
//
//// MARK: - LottieCell
//class LottieCell: UICollectionViewCell
//{
//    static let identifier = "LottieCell"
//    let lottieView = RLLottieView()
//
//    override init(frame: CGRect) {
//        super.init(frame: frame)
//        contentView.addSubview(lottieView)
//        lottieView.translatesAutoresizingMaskIntoConstraints = false
//        NSLayoutConstraint.activate([
//            lottieView.topAnchor.constraint(equalTo: contentView.topAnchor),
//            lottieView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
//            lottieView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
//            lottieView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor)
//        ])
//    }
//
//    required init?(coder: NSCoder) {
//        fatalError("init(coder:) has not been implemented")
//    }
//
//    func configure(withAnimationNamed name: String) {
//        lottieView.loadAnimation(named: name, shouldCache: true)
//    }
//
//    override func prepareForReuse() {
//        super.prepareForReuse()
//        lottieView.reset()
//    }
//}
//
//// MARK: - RLLottieView
//class RLLottieView: UIView
//{
//    private(set) var animationName: String?
//    
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
//
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
//    // MARK: - Load Animation
////    func loadAnimation(named name: String, shouldCache: Bool = false)
////    {
////        generation &+= 1
////        let currentGen = generation
////
////        animationName = name
////        animation = nil
////        layer.contents = nil
////
////        Task { [weak self] in
////            guard let self else { return }
////
////            if let anim = await StickersAnimationManager.shared.getAnimation(named: name, shouldCache) {
////                guard self.generation == currentGen else { return }
////
////                self.animation = anim
////                self.totalFrames = Int(lottie_animation_get_totalframe(anim))
////                self.startTime = CACurrentMediaTime()
////                self.randomOffset = TimeInterval.random(in: 0..<2.0)
//////                self.renderFirstFrame(gen: currentGen)
////            }
////        }
////    }
////
//    func loadAnimation(named name: String, shouldCache: Bool = false)
//    {
//        generation &+= 1
//        let currentGen = generation
//
//        animationName = name
//        animation = nil
//        layer.contents = nil
//
//        Task.detached() { [weak self] in
//            
//            guard let self else { return }
//
////            if let anim = await StickersAnimationStorage.shared.getAnimation(withName: name)
//            if let anim = getAnimation(withName: name)
//            {
////                if shouldCache {
////                    await StickersAnimationStorage.shared.cacheAnimation(withName: name, animation: anim)
////                }
//                guard await self.generation == currentGen else { return }
//
//                await MainActor.run {
//                    self.animation = anim
//                    self.totalFrames = Int(lottie_animation_get_totalframe(anim))
//                    self.startTime = CACurrentMediaTime()
//                    self.randomOffset = TimeInterval.random(in: 0..<2.0)
//                }
//            }
//        }
//    }
//
//    nonisolated private func getAnimation(withName name: String)  -> OpaquePointer?
//    {
////        if let animation = await TestStorage.shared.animations[name] {return animation}
//        
//        guard let path = Bundle.main.path(forResource: name, ofType: "json"),
//              let anim = lottie_animation_from_file(path) else {
//            return nil
//        }
////        Task { @MainActor in
////            TestStorage.shared.animations[name] = anim
////        }
//        return anim
//    }
//    
//
////    private func renderFirstFrame(gen: Int) {
////        guard let animation, let buffer else { return }
////
////        Task {
////            guard self.generation == gen else { return }
////            await RenderActor.shared.render(animation: animation,
////                                            frame: 0,
////                                            buffer: buffer,
////                                            size: self.renderSize)
////            self.createAndDisplayImage(from: buffer)
////            self.renderInProgress = false
////        }
////    }
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
////            print("name from render ", self.animationName)
//            await RenderActor.shared.render(animation: localAnim,
//                                            frame: currentFrame,
//                                            buffer: localBuffer,
//                                            size: self.renderSize)
//            
//            self.createAndDisplayImage(from: localBuffer)
//            self.renderInProgress = false
//        }
//    }
//
//
//    // MARK: - Reset
//    func reset()
//    {
//        generation &+= 1  // invalidate all pending renders
//        animation = nil
//        animationName = nil
//        isVisible = false
//        renderInProgress = false
//        layer.contents = nil
//    }
//    
//    func destroyAnimation()
//    {
////        Task {
////            await RenderActor.shared.destroyAnimation {
//                guard let anim = animation else { return }
//                print("animation exist and should be destroyed ")
//                print("the name is ", self.animationName)
//                lottie_animation_render_flush(anim)
//                lottie_animation_destroy(anim)
////            }
//            self.reset()
////        }
//    }
//
//    deinit {
//        destroyAnimation()
//        buffer?.deallocate()
//        print("Rlottie deinited")
//    }
//
//    // MARK: - Helpers
//    private func createAndDisplayImage(from cgBuffer: UnsafeMutableRawPointer)
//    {
//        guard let context = CGContext(data: cgBuffer,
//                                      width: Int(renderSize.width),
//                                      height: Int(renderSize.height),
//                                      bitsPerComponent: 8,
//                                      bytesPerRow: Int(renderSize.width) * 4,
//                                      space: cachedColorSpace,
//                                      bitmapInfo: cachedBitmapInfo.rawValue),
//              let cgImage = context.makeImage() else { return }
//
//        DispatchQueue.main.async { [weak self] in
//            self?.layer.contents = cgImage
//        }
//    }
//
//    func setVisible(_ visible: Bool) {
//        isVisible = visible
//    }
//}
//
//// MARK: - DisplayLinkProxy
//final class DisplayLinkProxy {
//    weak var target: AnyObject?
//    let selector: Selector
//    
//    init(target: AnyObject, selector: Selector) {
//        self.selector = selector
//        self.target = target
//    }
//    
//    @objc func onDisplayLink(_ link: CADisplayLink) {
//        _ = target?.perform(selector, with: link)
//    }
//}
//
//actor StickersAnimationStorage
//{
//    static let shared = StickersAnimationStorage()
//    
//    private init() {}
//    
//    let animationsName: [String] = {
//        return Stickers.Category.allCases
//            .flatMap { $0.pack.map { $0.deletingPathExtension().lastPathComponent } }
//    }()
//
//    private(set) var animations: [String: OpaquePointer] = [:]
//
//    func getAnimation(withName name: String) -> OpaquePointer?
//    {
//        if let animation = animations[name] { return animation }
//
//        guard let path = Bundle.main.path(forResource: name, ofType: "json"),
//              let animation = lottie_animation_from_file(path) else {
//            return nil
//        }
////        self.animations[name] = animation
//        return animation
//    }
//    
//    func cacheAnimation(withName name: String, animation: OpaquePointer)
//    {
//        if animations[name] == nil {
//            animations[name] = animation
//        }
//    }
//    
//    func destroyAllAnimations()
//    {
//        animations.forEach { (_, animation) in
//            lottie_animation_destroy(animation)
//        }
//        animations.removeAll()
//    }
//}
//
//
//class TestStorage
//{
//    static let shared = TestStorage()
//    
//    private init() {}
//    
//    @MainActor
//    var animations: [String: OpaquePointer] = [:]
//    
//    
//}
//import UIKit
//import librlottie
//
//// Needed for concurrency
//extension OpaquePointer: @unchecked @retroactive Sendable {}
//
//// MARK: - Render Actor
//actor RenderActor
//{
//    static let shared = RenderActor()
//    
//    func render(
//        animation: OpaquePointer,
//        frame: Int,
//        buffer: UnsafeMutablePointer<UInt32>,
//        size: CGSize
//    ) {
//        lottie_animation_render(
//            animation,
//            size_t(frame),
//            buffer,
//            size_t(size.width),
//            size_t(size.height),
//            size_t(Int(size.width) * MemoryLayout<UInt32>.size)
//        )
//    }
//    
//    func destroyAnimation(_ block: () -> Void)
//    {
//        block()
//    }
//}
//
//// MARK: - Stickers Animation Manager
//actor StickersAnimationManager
//{
//    static let shared = StickersAnimationManager()
//    private(set) var cache: [String: OpaquePointer] = [:]
//
//    func getAnimation(named name: String, _ shouldCache: Bool = false) -> OpaquePointer? {
//        if let anim = cache[name] {
//            return anim
//        }
//        
//        guard let path = Bundle.main.path(forResource: name, ofType: "json"),
//              let anim = lottie_animation_from_file(path) else {
//            return nil
//        }
//        if shouldCache {
//            cache[name] = anim
//        }
//        return anim
//    }
//
//    func clearCache() {
//        for (_, anim) in cache {
//            lottie_animation_destroy(anim)
//        }
//        cache.removeAll()
//    }
//
//    deinit {
//        for (_, anim) in cache {
//            lottie_animation_destroy(anim)
//        }
//    }
//    func render(
//        animation: OpaquePointer,
//        frame: Int,
//        buffer: UnsafeMutablePointer<UInt32>,
//        size: CGSize
//    ) {
//        lottie_animation_render(
//            animation,
//            size_t(frame),
//            buffer,
//            size_t(size.width),
//            size_t(size.height),
//            size_t(Int(size.width) * MemoryLayout<UInt32>.size)
//        )
//    }
//}
//
//// MARK: - StickersCollectionView
//final class StickersCollectionView: UIView
//{
////    private let animations: [String] = {
////        return Stickers.Category.allCases
////            .flatMap { $0.pack.map { $0.deletingPathExtension().lastPathComponent } }
////    }()
//    
//    private let animationsName: [String] = StickersAnimationStorage.shared.animationsName
//
//    private var collectionView: UICollectionView!
//    private var displayLink: CADisplayLink?
//    private var frameSkipCounter = 0
//
//    override init(frame: CGRect) {
//        super.init(frame: frame)
//        backgroundColor = ColorManager.stickerViewBackgroundColor
//        setupCollectionView()
//        startAnimationLoop()
//    }
//
//    required init?(coder: NSCoder) {
//        fatalError("Could not init stickerView")
//    }
//
//    deinit {
//        stopAnimationLoop()
////        Task {
////            await StickersAnimationManager.shared.clearCache()
////            StickersAnimationStorage.shared.animations.forEach { (name, animation) in
////                lottie_animation_destroy(animation)
////            }
////            StickersAnimationStorage.shared.animations.removeAll()
////            StickersAnimationStorage.shared.destroyAllAnimations()
//        Task {
//            await RenderActor.shared.destroyAnimation {
//                StickersAnimationStorage.shared.destroyAllAnimations()
//            }
//        }
////        }
//        print("Sticker collection DEINIT")
//    }
//
//    override func layoutSubviews() {
//        if let layout = collectionView.collectionViewLayout as? UICollectionViewFlowLayout {
//            let spacing: CGFloat = 10
//            let itemWidth = (bounds.width - spacing * 5) / 4
//            layout.itemSize = CGSize(width: itemWidth, height: itemWidth)
//            layout.minimumLineSpacing = spacing
//            layout.minimumInteritemSpacing = spacing
//            layout.sectionInset = UIEdgeInsets(top: spacing,
//                                               left: spacing,
//                                               bottom: 0,
//                                               right: spacing)
//        }
//    }
//
//    private func setupCollectionView() {
//        let layout = UICollectionViewFlowLayout()
//        collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
//        collectionView.backgroundColor = .clear
//        collectionView.dataSource = self
//        collectionView.delegate = self
//        collectionView.register(LottieCell.self, forCellWithReuseIdentifier: LottieCell.identifier)
//
//        addSubview(collectionView)
//
//        collectionView.translatesAutoresizingMaskIntoConstraints = false
//        NSLayoutConstraint.activate([
//            collectionView.topAnchor.constraint(equalTo: topAnchor),
//            collectionView.bottomAnchor.constraint(equalTo: bottomAnchor),
//            collectionView.leadingAnchor.constraint(equalTo: leadingAnchor),
//            collectionView.trailingAnchor.constraint(equalTo: trailingAnchor)
//        ])
//    }
//
//    // MARK: - Animation Loop
//    func startAnimationLoop() {
//        let proxy = DisplayLinkProxy(target: self, selector: #selector(renderFrame))
//        displayLink = CADisplayLink(target: proxy, selector: #selector(DisplayLinkProxy.onDisplayLink(_:)))
//        displayLink?.add(to: .main, forMode: .common)
//    }
//
//    private func stopAnimationLoop() {
//        displayLink?.invalidate()
//        displayLink = nil
//    }
//
//    @objc private func renderFrame() {
//        // Frame skip (render every 2nd tick → ~30 FPS)
//        frameSkipCounter += 1
//        if frameSkipCounter % 2 != 0 { return }
//
//        let visibleIndexPaths = collectionView.indexPathsForVisibleItems
//        for indexPath in visibleIndexPaths {
//            if let cell = collectionView.cellForItem(at: indexPath) as? LottieCell {
//                cell.lottieView.renderNextFrame()
//            }
//        }
//    }
//}
//
//// MARK: - UICollectionViewDataSource
//extension StickersCollectionView: UICollectionViewDataSource {
//    func collectionView(_ collectionView: UICollectionView,
//                        numberOfItemsInSection section: Int) -> Int {
//        return animationsName.count
//    }
//
//    func collectionView(_ collectionView: UICollectionView,
//                        cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
//        let cell = collectionView.dequeueReusableCell(
//            withReuseIdentifier: LottieCell.identifier,
//            for: indexPath
//        ) as! LottieCell
//        cell.configure(withAnimationNamed: animationsName[indexPath.item])
//        return cell
//    }
//}
//
//// MARK: - UICollectionViewDelegate
//extension StickersCollectionView: UICollectionViewDelegateFlowLayout {
//    func collectionView(_ collectionView: UICollectionView,
//                        willDisplay cell: UICollectionViewCell,
//                        forItemAt indexPath: IndexPath) {
//        (cell as? LottieCell)?.lottieView.setVisible(true)
//    }
//
//    func collectionView(_ collectionView: UICollectionView,
//                        didEndDisplaying cell: UICollectionViewCell,
//                        forItemAt indexPath: IndexPath) {
//        (cell as? LottieCell)?.lottieView.setVisible(false)
//    }
//    
//    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath)
//    {
//        collectionView.deselectItem(at: indexPath, animated: false)
//        
////        let cell = collectionView.cellForItem(at: indexPath) as! LottieCell
////
////        guard let stickerName = cell.lottieView.animationName else {return}
//        let stickerName = self.animationsName[indexPath.item]
//        ChatManager.shared.newStickerSubject.send(stickerName)
//    }
//}
//
//// MARK: - LottieCell
//class LottieCell: UICollectionViewCell
//{
//    static let identifier = "LottieCell"
//    let lottieView = RLLottieView()
//
//    override init(frame: CGRect) {
//        super.init(frame: frame)
//        contentView.addSubview(lottieView)
//        lottieView.translatesAutoresizingMaskIntoConstraints = false
//        NSLayoutConstraint.activate([
//            lottieView.topAnchor.constraint(equalTo: contentView.topAnchor),
//            lottieView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
//            lottieView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
//            lottieView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor)
//        ])
//    }
//
//    required init?(coder: NSCoder) {
//        fatalError("init(coder:) has not been implemented")
//    }
//
//    func configure(withAnimationNamed name: String) {
//        lottieView.loadAnimation(named: name, shouldCache: true)
//    }
//
//    override func prepareForReuse() {
//        super.prepareForReuse()
//        lottieView.reset()
//    }
//}
//
//// MARK: - RLLottieView
//class RLLottieView: UIView
//{
//    private(set) var animationName: String?
//    
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
//
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
//    // MARK: - Load Animation
////    func loadAnimation(named name: String, shouldCache: Bool = false)
////    {
////        generation &+= 1
////        let currentGen = generation
////
////        animationName = name
////        animation = nil
////        layer.contents = nil
////
////        Task { [weak self] in
////            guard let self else { return }
////
////            if let anim = await StickersAnimationManager.shared.getAnimation(named: name, shouldCache) {
////                guard self.generation == currentGen else { return }
////
////                self.animation = anim
////                self.totalFrames = Int(lottie_animation_get_totalframe(anim))
////                self.startTime = CACurrentMediaTime()
////                self.randomOffset = TimeInterval.random(in: 0..<2.0)
//////                self.renderFirstFrame(gen: currentGen)
////            }
////        }
////    }
////
//    func loadAnimation(named name: String, shouldCache: Bool = false)
//    {
//        generation &+= 1
//        let currentGen = generation
//
//        animationName = name
//        animation = nil
//        layer.contents = nil
//
//        Task.detached() { [weak self] in
//            
//            guard let self else { return }
//
//            if let anim = await StickersAnimationStorage.shared.getAnimation(withName: name)
//            {
//                if shouldCache {
//                    await StickersAnimationStorage.shared.cacheAnimation(withName: name, animation: anim)
//                }
//                guard await self.generation == currentGen else { return }
//
//                await MainActor.run {
//                    self.animation = anim
//                    self.totalFrames = Int(lottie_animation_get_totalframe(anim))
//                    self.startTime = CACurrentMediaTime()
//                    self.randomOffset = TimeInterval.random(in: 0..<2.0)
//                }
//                
//                
//            }
//        }
//    }
//
////    nonisolated private func getAnimation(withName name: String) -> OpaquePointer?
////    {
////        print(Thread.isMainThread)
////        guard let path = Bundle.main.path(forResource: name, ofType: "json"),
////              let anim = lottie_animation_from_file(path) else {
////            return nil
////        }
////        return anim
////    }
//    
//
////    private func renderFirstFrame(gen: Int) {
////        guard let animation, let buffer else { return }
////
////        Task {
////            guard self.generation == gen else { return }
////            await RenderActor.shared.render(animation: animation,
////                                            frame: 0,
////                                            buffer: buffer,
////                                            size: self.renderSize)
////            self.createAndDisplayImage(from: buffer)
////            self.renderInProgress = false
////        }
////    }
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
//            await RenderActor.shared.render(animation: localAnim,
//                                            frame: currentFrame,
//                                            buffer: localBuffer,
//                                            size: self.renderSize)
//            
//            self.createAndDisplayImage(from: localBuffer)
//            self.renderInProgress = false
//        }
//    }
//
//
//    // MARK: - Reset
//    func reset()
//    {
//        generation &+= 1  // invalidate all pending renders
//        animation = nil
//        animationName = nil
//        isVisible = false
//        renderInProgress = false
//        layer.contents = nil
//    }
//    
//    func destroyAnimation()
//    {
//        Task {
//            await RenderActor.shared.destroyAnimation {
//                guard let anim = animation else { return }
//                print("animation exist and should be destroyed ")
//                lottie_animation_render_flush(anim)
//                lottie_animation_destroy(anim)
//            }
//            self.reset()
//        }
//    }
//
//    deinit {
//        buffer?.deallocate()
//        print("Rlottie deinited")
//    }
//
//    // MARK: - Helpers
//    private func createAndDisplayImage(from cgBuffer: UnsafeMutableRawPointer)
//    {
//        guard let context = CGContext(data: cgBuffer,
//                                      width: Int(renderSize.width),
//                                      height: Int(renderSize.height),
//                                      bitsPerComponent: 8,
//                                      bytesPerRow: Int(renderSize.width) * 4,
//                                      space: cachedColorSpace,
//                                      bitmapInfo: cachedBitmapInfo.rawValue),
//              let cgImage = context.makeImage() else { return }
//
//        DispatchQueue.main.async { [weak self] in
//            self?.layer.contents = cgImage
//        }
//    }
//
//    func setVisible(_ visible: Bool) {
//        isVisible = visible
//    }
//}
//
//// MARK: - DisplayLinkProxy
//final class DisplayLinkProxy {
//    weak var target: AnyObject?
//    let selector: Selector
//    
//    init(target: AnyObject, selector: Selector) {
//        self.selector = selector
//        self.target = target
//    }
//    
//    @objc func onDisplayLink(_ link: CADisplayLink) {
//        _ = target?.perform(selector, with: link)
//    }
//}
//
//actor StickersAnimationStorage
//{
//    static let shared = StickersAnimationStorage()
//    
//    private init() {}
//    
//    let animationsName: [String] = {
//        return Stickers.Category.allCases
//            .flatMap { $0.pack.map { $0.deletingPathExtension().lastPathComponent } }
//    }()
//
//    private(set) var animations: [String: OpaquePointer] = [:]
//
//    func getAnimation(withName name: String) -> OpaquePointer?
//    {
//        if let animation = animations[name] { return animation }
//
//        guard let path = Bundle.main.path(forResource: name, ofType: "json"),
//              let animation = lottie_animation_from_file(path) else {
//            return nil
//        }
////        self.animations[name] = animation
//        return animation
//    }
//    
//    func cacheAnimation(withName name: String, animation: OpaquePointer)
//    {
//        if animations[name] == nil {
//            animations[name] = animation
//        }
//    }
//    
//    func destroyAllAnimations()
//    {
//        animations.forEach { (_, animation) in
//            lottie_animation_destroy(animation)
//        }
//        animations.removeAll()
//    }
//}
