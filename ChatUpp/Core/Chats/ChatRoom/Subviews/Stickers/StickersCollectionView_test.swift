//
//  StickersCollectionView_test.swift
//  ChatUpp
//
//  Created by Andrei Pripa on 9/21/25.
//

import UIKit
import librlottie

// Needed for concurrency
extension OpaquePointer: @unchecked @retroactive Sendable {}

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


// MARK: - StickersCollectionView
final class StickersCollectionView: UIView
{
//    private let animations: [String] = {
//        return Stickers.Category.allCases
//            .flatMap { $0.pack.map { $0.deletingPathExtension().lastPathComponent } }
//    }()

    private let stickerViewModels: [StickerRLottieCellViewModel] = {
        return Stickers.Category.allCases
            .flatMap { $0.pack.map { StickerRLottieCellViewModel(stickerName: $0.deletingPathExtension().lastPathComponent) } }
    }()
    
    
    private var collectionView: UICollectionView!
    private var displayLink: CADisplayLink?
    private var frameSkipCounter = 0

    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = ColorManager.stickerViewBackgroundColor
        setupCollectionView()
        startAnimationLoop()
    }

    required init?(coder: NSCoder) {
        fatalError("Could not init stickerView")
    }

    deinit {
        stopAnimationLoop()
//        Task {
//            await StickersAnimationManager.shared.clearCache()
//        }
        
        /// Because render of animations can still be in process,
        /// we need to queue destruction of animations on actor (StickerAnimationManager) where render takes place.
        /// This way animations will be destroyed only after final render will come to it's end.
        let vms = stickerViewModels
        Task {
            await StickerAnimationManager.shared.destroyAnimation
            {
                for vm in vms
                {
                    vm.destroyAnimation()
                }
            }
        }
        print("Sticker collection DEINIT")
    }

    override func layoutSubviews() {
        if let layout = collectionView.collectionViewLayout as? UICollectionViewFlowLayout {
            let spacing: CGFloat = 10
            let itemWidth = (bounds.width - spacing * 5) / 4
            layout.itemSize = CGSize(width: itemWidth, height: itemWidth)
            layout.minimumLineSpacing = spacing
            layout.minimumInteritemSpacing = spacing
            layout.sectionInset = UIEdgeInsets(top: spacing,
                                               left: spacing,
                                               bottom: 0,
                                               right: spacing)
        }
    }

    private func setupCollectionView() {
        let layout = UICollectionViewFlowLayout()
        collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.backgroundColor = .clear
        collectionView.dataSource = self
        collectionView.delegate = self
        collectionView.register(StickerRLottieCell.self, forCellWithReuseIdentifier: StickerRLottieCell.identifier)

        addSubview(collectionView)

        collectionView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            collectionView.topAnchor.constraint(equalTo: topAnchor),
            collectionView.bottomAnchor.constraint(equalTo: bottomAnchor),
            collectionView.leadingAnchor.constraint(equalTo: leadingAnchor),
            collectionView.trailingAnchor.constraint(equalTo: trailingAnchor)
        ])
    }

    // MARK: - Animation Loop
    func startAnimationLoop() {
        let proxy = DisplayLinkProxy(target: self, selector: #selector(renderFrame))
        displayLink = CADisplayLink(target: proxy, selector: #selector(DisplayLinkProxy.onDisplayLink(_:)))
        displayLink?.add(to: .main, forMode: .common)
    }

    private func stopAnimationLoop() {
        displayLink?.invalidate()
        displayLink = nil
    }

    @objc private func renderFrame() {
        // Frame skip (render every 2nd tick → ~30 FPS)
        frameSkipCounter += 1
        if frameSkipCounter % 2 != 0 { return }

        let visibleIndexPaths = collectionView.indexPathsForVisibleItems
        for indexPath in visibleIndexPaths {
            if let cell = collectionView.cellForItem(at: indexPath) as? StickerRLottieCell {
                cell.lottieView.renderNextFrame()
            }
        }
    }
}

// MARK: - UICollectionViewDataSource
extension StickersCollectionView: UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView,
                        numberOfItemsInSection section: Int) -> Int
    {
        return stickerViewModels.count
    }

    func collectionView(_ collectionView: UICollectionView,
                        cellForItemAt indexPath: IndexPath) -> UICollectionViewCell
    {
        let cell = collectionView.dequeueReusableCell(
            withReuseIdentifier: StickerRLottieCell.identifier,
            for: indexPath
        ) as! StickerRLottieCell
        
        cell.configure(withViewModel: self.stickerViewModels[indexPath.item])
        
        return cell
    }
}

// MARK: - UICollectionViewDelegate
extension StickersCollectionView: UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView,
                        willDisplay cell: UICollectionViewCell,
                        forItemAt indexPath: IndexPath) {
        (cell as? StickerRLottieCell)?.lottieView.setVisible(true)
    }

    func collectionView(_ collectionView: UICollectionView,
                        didEndDisplaying cell: UICollectionViewCell,
                        forItemAt indexPath: IndexPath) {
        (cell as? StickerRLottieCell)?.lottieView.setVisible(false)
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath)
    {
        collectionView.deselectItem(at: indexPath, animated: false)
        
        let stickerName = self.stickerViewModels[indexPath.item].stickerName
        ChatManager.shared.newStickerSubject.send(stickerName)
    }
}

final class StickerRLottieCellViewModel
{
    let stickerName: String
    var stickerAnimation: OpaquePointer?
    
    init(stickerName: String) {
        self.stickerName = stickerName
    }
    
    func destroyAnimation()
    {
        lottie_animation_render_flush(stickerAnimation)
        lottie_animation_destroy(stickerAnimation)
        stickerAnimation = nil
    }
    
    deinit {
        print("LottieCellViewModel DEINIT")
    }
}

// MARK: - LottieCell
class StickerRLottieCell: UICollectionViewCell
{
    static let identifier = "LottieCell"
    let lottieView = RLLottieView()
    var viewModel: StickerRLottieCellViewModel!

    override init(frame: CGRect) {
        super.init(frame: frame)
        contentView.addSubview(lottieView)
        lottieView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            lottieView.topAnchor.constraint(equalTo: contentView.topAnchor),
            lottieView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
            lottieView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            lottieView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor)
        ])
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func configure(withViewModel cellVM: StickerRLottieCellViewModel)
    {
        self.viewModel = cellVM
        
        if let animation = cellVM.stickerAnimation {
            lottieView.loadAnimation(animation: animation)
        } else {
            lottieView.loadAnimation(named: cellVM.stickerName) { lottieAnimation in
                cellVM.stickerAnimation = lottieAnimation
            }
        }
    }

    override func prepareForReuse()
    {
        super.prepareForReuse()
        lottieView.reset()
    }
}

// MARK: - RLLottieView
class RLLottieView: UIView
{
    private(set) var animationName: String?
    
    private var animation: OpaquePointer?
    private var totalFrames: Int = 0
    private let renderSize: CGSize // ↓ Reduced size
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

    // MARK: - Load Animation
//    func loadAnimation(named name: String)
//    {
//        generation &+= 1
//        let currentGen = generation
//
//        animationName = name
//        animation = nil
//        layer.contents = nil
//
//        Task { [weak self] in
//            guard let self else { return }
//            
//            if let anim = await StickersAnimationManager.shared.getAnimation(named: name) {
//                guard self.generation == currentGen else { return }
//
//                self.animation = anim
//                self.totalFrames = Int(lottie_animation_get_totalframe(anim))
//                self.startTime = CACurrentMediaTime()
//                self.randomOffset = TimeInterval.random(in: 0..<2.0)
////                self.renderFirstFrame(gen: currentGen)
//            }
//        }
//    }
    
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
        
        //        animationName = name
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
        guard let path = Bundle.main.path(forResource: name, ofType: "json"),
              let anim = lottie_animation_from_file(path) else {
            return nil
        }
        return anim
    }
    
//    private func renderFirstFrame(gen: Int) {
//        guard let animation, let buffer else { return }
//
//        Task {
//            guard self.generation == gen else { return }
//            await RenderActor.shared.render(animation: animation,
//                                            frame: 0,
//                                            buffer: buffer,
//                                            size: self.renderSize)
//            self.createAndDisplayImage(from: buffer)
//            self.renderInProgress = false
//        }
//    }

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
        animationName = nil
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
                print("animation exist and should be destroyed ")
                lottie_animation_render_flush(anim)
                lottie_animation_destroy(anim)
            }
            self.reset()
        }
    }

    deinit {
        buffer?.deallocate()
        print("RLLottieView deinit")
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

// MARK: - DisplayLinkProxy
final class DisplayLinkProxy
{
    weak var target: AnyObject?
    let selector: Selector
    
    init(target: AnyObject, selector: Selector) {
        self.selector = selector
        self.target = target
    }
    
    @objc func onDisplayLink(_ link: CADisplayLink) {
        _ = target?.perform(selector, with: link)
    }
}
