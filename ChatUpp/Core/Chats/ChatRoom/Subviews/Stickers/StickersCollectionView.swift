//
//  Untitled.swift
//  RLottieTest
//
//  Created by Andrei Pripa on 9/9/25.
//

import UIKit
import librlottie

final class DisplayLinkProxy
{
    weak var target: AnyObject?
    let selector: Selector
    
    init(target: AnyObject, selector: Selector)
    {
        self.selector = selector
        self.target = target
    }
    
    @objc func onDisplayLink(_ link: CADisplayLink)
    {
        _ = target?.perform(selector, with: link)
    }
}

class ViewController2: UIViewController
{
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .brown
        let stickersCollectionView = StickersCollectionView(frame: view.bounds)
        view.addSubview(stickersCollectionView)
    }
}

final class StickersCollectionView: UIView
{
    private let animations: [String] = {
        return Stickers.Category.allCases
            .flatMap { $0.pack.map { $0.deletingPathExtension().lastPathComponent } }
    }()
    
    private var collectionView: UICollectionView!
    private var displayLink: CADisplayLink?
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        backgroundColor = ColorManager.stickerViewBackgroundColor
        setupCollectionView()
        startAnimationLoop()
    }
    
    required init?(coder: NSCoder) {
        fatalError("Could not init stickerView")
    }
    
//    override func willRemoveSubview(_ subview: UIView) {
//        super.willRemoveSubview(subview)
//    }
    
    deinit {
        stopAnimationLoop()
        print("Sticker collection DEINIT")
    }
    
    override func layoutSubviews()
    {
        if let layout = collectionView.collectionViewLayout as? UICollectionViewFlowLayout
        {
            let spacing: CGFloat = 10
            let itemWidth = (bounds.width - spacing * 5) / 4
            layout.itemSize = CGSize(width: itemWidth, height: itemWidth)
            layout.minimumLineSpacing = spacing
            layout.minimumInteritemSpacing = spacing
            layout.sectionInset = UIEdgeInsets(top: spacing,
                                               left: spacing,
                                               bottom: 0,
                                               right: spacing)
            startAnimationLoop()
        }
    }
    
    func setupCollectionView()
    {
        let layout = UICollectionViewFlowLayout()
        collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.backgroundColor = .white
        collectionView.dataSource = self
        collectionView.delegate = self
        collectionView.register(LottieCell.self, forCellWithReuseIdentifier: LottieCell.identifier)
        collectionView.backgroundColor = .clear

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
    func startAnimationLoop()
    {
        /// create proxy for displayLink to bypass strong reference to target self
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
        let visibleIndexPaths = collectionView.indexPathsForVisibleItems
        for indexPath in visibleIndexPaths {
            if let cell = collectionView.cellForItem(at: indexPath) as? LottieCell {
                cell.lottieView.renderNextFrame()
            }
        }
    }
}

// MARK: - UICollectionViewDataSource
extension StickersCollectionView: UICollectionViewDataSource
{
    func collectionView(_ collectionView: UICollectionView,
                        numberOfItemsInSection section: Int) -> Int {
        return animations.count
    }

    func collectionView(_ collectionView: UICollectionView,
                        cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(
            withReuseIdentifier: LottieCell.identifier,
            for: indexPath
        ) as! LottieCell
        cell.configure(withAnimationNamed: animations[indexPath.item])
        return cell
    }
}

// MARK: - UICollectionViewDelegate
extension StickersCollectionView: UICollectionViewDelegateFlowLayout
{
    // MARK: - Visibility Management
    func collectionView(_ collectionView: UICollectionView,
                        willDisplay cell: UICollectionViewCell,
                        forItemAt indexPath: IndexPath)
    {
        (cell as? LottieCell)?.lottieView.setVisible(true)
    }

    func collectionView(_ collectionView: UICollectionView,
                        didEndDisplaying cell: UICollectionViewCell,
                        forItemAt indexPath: IndexPath)
    {
        (cell as? LottieCell)?.lottieView.setVisible(false)
    }
}

// MARK: - LottieCell
class LottieCell: UICollectionViewCell {
    static let identifier = "LottieCell"
    let lottieView = RLLottieView()

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

    func configure(withAnimationNamed name: String) {
        lottieView.loadAnimation(named: name)
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        lottieView.reset()
    }
    
    deinit {
        print("LottieCell collection DEINIT")
    }
}



// MARK: - RLLottieView
class RLLottieView: UIView
{
    private var animationName: String?
    private var animation: OpaquePointer?
    private var frameNumber: Int = 0
    private var totalFrames: Int = 0
    private let renderSize = CGSize(width: 200, height: 200)
    private var buffer: UnsafeMutablePointer<UInt32>?
    private var isVisible = false
    private var renderInProgress = false
    private var startTime: CFTimeInterval = 0
    private var randomOffset: TimeInterval = 0

    // Cached graphics objects
    private let cachedColorSpace: CGColorSpace
    private let cachedBitmapInfo: CGBitmapInfo

    private let renderQueue = DispatchQueue(label: "lottie.render.queue",
                                            qos: .userInitiated)

    override init(frame: CGRect) {
        cachedColorSpace = CGColorSpaceCreateDeviceRGB()
        cachedBitmapInfo = CGBitmapInfo(rawValue:
            CGBitmapInfo.byteOrder32Little.rawValue |
            CGImageAlphaInfo.premultipliedFirst.rawValue)
        super.init(frame: frame)

        let pixelCount = Int(renderSize.width * renderSize.height)
        buffer = UnsafeMutablePointer<UInt32>.allocate(capacity: pixelCount)
        buffer?.initialize(repeating: 0, count: pixelCount)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Load Animation
    func loadAnimation(named name: String)
    {
        animationName = name
        animation = nil
        layer.contents = nil

        Task { [weak self] in
            guard let self else {return}
            if let anim = await LottieAnimationManager.shared.getAnimation(named: name)
            {
                // Double-check cell is still expecting this animation
                guard self.animationName == name else { return }

                await LottieAnimationManager.shared.cacheAnimation(anim, named: name)

                self.animation = anim
                self.totalFrames = Int(lottie_animation_get_totalframe(anim))
                self.frameNumber = 0
                self.startTime = CACurrentMediaTime()
                self.randomOffset = TimeInterval.random(in: 0..<2.0)

                self.renderFirstFrame()
            }
        }
    }

    private func renderFirstFrame()
    {
        guard let animation = animation,
              let buffer = buffer else { return }
        
        renderQueue.async { [weak self] in
            guard let self = self,
                    let animation = self.animation,
                    let buffer = self.buffer else { return }

            lottie_animation_render(animation,
                                    0,
                                    buffer,
                                    size_t(self.renderSize.width),
                                    size_t(self.renderSize.height),
                                    size_t(Int(self.renderSize.width) * MemoryLayout<UInt32>.size))

            self.createAndDisplayImage(from: buffer)
            DispatchQueue.main.async { self.renderInProgress = false }
        }

    }

    func setVisible(_ visible: Bool) {
        isVisible = visible
    }

    func renderNextFrame() {
        guard isVisible,
              let animation = animation,
              let buffer = buffer,
              !renderInProgress,
              totalFrames > 0 else { return }

        renderInProgress = true

        let elapsed = CACurrentMediaTime() - startTime + randomOffset
        let duration = Double(totalFrames) / Double(lottie_animation_get_framerate(animation))
        let progress = fmod(elapsed, duration) / duration
        let currentFrame = Int(progress * Double(totalFrames))

        renderQueue.async { [weak self] in
            
            guard let self = self, let animation = self.animation, let buffer = self.buffer else { return }

            lottie_animation_render(animation,
                                    size_t(currentFrame),
                                    buffer,
                                    size_t(self.renderSize.width),
                                    size_t(self.renderSize.height),
                                    size_t(Int(self.renderSize.width) * MemoryLayout<UInt32>.size))

            self.createAndDisplayImage(from: buffer)
            DispatchQueue.main.async { self.renderInProgress = false }
        }
    }

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

    func reset() {
        isVisible = false
        renderInProgress = false
        frameNumber = 0
        animationName = nil
        animation = nil
        layer.contents = nil
    }

    deinit {
        buffer?.deallocate()
        print("RLLottieView Deinit!")
    }
}

extension OpaquePointer: @unchecked @retroactive Sendable {}
    
// MARK: - Animation Manager
actor LottieAnimationManager
{
    static let shared = LottieAnimationManager()

    private var cachedAnimations: [String: OpaquePointer] = [:]

    private init() {}

    // Async get with lazy loading
    func getAnimation(named name: String) async -> OpaquePointer?
    {
        if let cached = cachedAnimations[name] {
            return cached
        }

        // Do file loading off the actor context to avoid blocking
        return await withCheckedContinuation { continuation in
            DispatchQueue.global(qos: .userInitiated).async {
                var anim: OpaquePointer? = nil
                if let path = Bundle.main.path(forResource: name, ofType: "json") {
                    anim = lottie_animation_from_file(path)
                }

                Task { @MainActor in
                    continuation.resume(returning: anim)
                }
            }
        }
    }

    // Store animation
    func cacheAnimation(_ anim: OpaquePointer, named name: String) {
        cachedAnimations[name] = anim
    }

    // Cleanup everything
    func cleanup() {
        for (_, anim) in cachedAnimations {
            lottie_animation_destroy(anim)
        }
        cachedAnimations.removeAll()
    }

    deinit { cleanup() }
}


//MARK: layout items
//extension StickersCollectionView
//{
//    func createCollectionViewLayout() -> UICollectionViewLayout
//    {
//        let spacing: CGFloat = 10
//        
//        let layout = UICollectionViewCompositionalLayout { sectionIndex, environment -> NSCollectionLayoutSection? in
//            
//            // Each item takes 1/4 of the width minus spacing
//            let itemSize = NSCollectionLayoutSize(
//                widthDimension: .fractionalWidth(0.25),
//                heightDimension: .fractionalWidth(0.25) // square cells
//            )
//            
//            let item = NSCollectionLayoutItem(layoutSize: itemSize)
//            item.contentInsets = NSDirectionalEdgeInsets(
//                top: spacing / 2,
//                leading: spacing / 2,
//                bottom: spacing / 2,
//                trailing: spacing / 2
//            )
//            
//            // Group of 4 items horizontally
//            let groupSize = NSCollectionLayoutSize(
//                widthDimension: .fractionalWidth(1.0),
//                heightDimension: .fractionalWidth(0.25)
//            )
//
//            let group = NSCollectionLayoutGroup.horizontal(layoutSize: groupSize, repeatingSubitem: item, count: 4)
//            
//            let section = NSCollectionLayoutSection(group: group)
//            section.contentInsets = NSDirectionalEdgeInsets(
//                top: spacing,
//                leading: spacing,
//                bottom: spacing,
//                trailing: spacing
//            )
//            
//            return section
//        }
//        
//        return layout
//    }
//}
