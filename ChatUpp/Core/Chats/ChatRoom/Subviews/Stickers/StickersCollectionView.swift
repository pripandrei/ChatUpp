import UIKit
import librlottie

// Needed for concurrency
extension OpaquePointer: @unchecked @retroactive Sendable {}

// MARK: - Render Actor
actor RenderActor {
    static let shared = RenderActor()
    
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
}

// MARK: - Stickers Animation Manager
actor StickersAnimationManager {
    static let shared = StickersAnimationManager()
    private(set) var cache: [String: OpaquePointer] = [:]

    func getAnimation(named name: String) -> OpaquePointer? {
        if let anim = cache[name] {
            return anim
        }
        guard let path = Bundle.main.path(forResource: name, ofType: "json"),
              let anim = lottie_animation_from_file(path) else {
            return nil
        }
        cache[name] = anim
        return anim
    }

    func clearCache() {
        for (_, anim) in cache {
            lottie_animation_destroy(anim)
        }
        cache.removeAll()
    }

    deinit {
        for (_, anim) in cache {
            lottie_animation_destroy(anim)
        }
    }
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
}

// MARK: - StickersCollectionView
final class StickersCollectionView: UIView {
    private let animations: [String] = {
        return Stickers.Category.allCases
            .flatMap { $0.pack.map { $0.deletingPathExtension().lastPathComponent } }
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
        Task {
            await StickersAnimationManager.shared.clearCache()
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
        collectionView.register(LottieCell.self, forCellWithReuseIdentifier: LottieCell.identifier)

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
            if let cell = collectionView.cellForItem(at: indexPath) as? LottieCell {
                cell.lottieView.renderNextFrame()
            }
        }
    }
}

// MARK: - UICollectionViewDataSource
extension StickersCollectionView: UICollectionViewDataSource {
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
extension StickersCollectionView: UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView,
                        willDisplay cell: UICollectionViewCell,
                        forItemAt indexPath: IndexPath) {
        (cell as? LottieCell)?.lottieView.setVisible(true)
    }

    func collectionView(_ collectionView: UICollectionView,
                        didEndDisplaying cell: UICollectionViewCell,
                        forItemAt indexPath: IndexPath) {
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
}

// MARK: - RLLottieView
class RLLottieView: UIView {
    private var animationName: String?
    private var animation: OpaquePointer?
    private var totalFrames: Int = 0
    private let renderSize = CGSize(width: 200, height: 200) // ↓ Reduced size
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
    func loadAnimation(named name: String) {
        generation &+= 1
        let currentGen = generation

        animationName = name
        animation = nil
        layer.contents = nil

        Task { [weak self] in
            guard let self else { return }
            if let anim = await StickersAnimationManager.shared.getAnimation(named: name) {
                guard self.generation == currentGen else { return }

                self.animation = anim
                self.totalFrames = Int(lottie_animation_get_totalframe(anim))
                self.startTime = CACurrentMediaTime()
                self.randomOffset = TimeInterval.random(in: 0..<2.0)
                self.renderFirstFrame(gen: currentGen)
            }
        }
    }

    private func renderFirstFrame(gen: Int) {
        guard let animation, let buffer else { return }

        Task {
            guard self.generation == gen else { return }
            await RenderActor.shared.render(animation: animation,
                                            frame: 0,
                                            buffer: buffer,
                                            size: self.renderSize)
            self.createAndDisplayImage(from: buffer)
            self.renderInProgress = false
        }
    }

    func renderNextFrame() {
        guard isVisible,
              let animation,
              let buffer,
              !renderInProgress,
              totalFrames > 0 else { return }

        renderInProgress = true
        let gen = generation
        let localBuffer = buffer  // ✅ keep safe reference
        let localAnim = animation

        let elapsed = CACurrentMediaTime() - startTime + randomOffset
        let duration = Double(totalFrames) / Double(lottie_animation_get_framerate(localAnim))
        let progress = fmod(elapsed, duration) / duration
        let currentFrame = Int(progress * Double(totalFrames))

        Task { [weak self] in
            guard let self, self.generation == gen else { return }
            await StickersAnimationManager.shared.render(animation: localAnim,
                                                         frame: currentFrame,
                                                         buffer: localBuffer,
                                                         size: self.renderSize)

            self.createAndDisplayImage(from: localBuffer)
            self.renderInProgress = false
        }
    }


    // MARK: - Reset
    func reset() {
        generation &+= 1  // invalidate all pending renders
        animation = nil
        animationName = nil
        isVisible = false
        renderInProgress = false
        layer.contents = nil
    }

    deinit {
        buffer?.deallocate()
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
final class DisplayLinkProxy {
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
