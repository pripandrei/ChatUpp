//
//  ColorManager.swift
//  ChatUpp
//
//  Created by Andrei Pripa on 2/9/25.
//

import UIKit
import SkeletonView

struct ColorManager
{
//    static let oldMainAppColor: UIColor = #colorLiteral(red: 0.1411764771, green: 0.3960784376, blue: 0.5647059083, alpha: 1)
    static let appBackgroundColor: UIColor = #colorLiteral(red: 0.2099263668, green: 0.151156038, blue: 0.2217666507, alpha: 1)
    static let appBackgroundColor2: UIColor = #colorLiteral(red: 0.1236810908, green: 0.08473216742, blue: 0.1324510276, alpha: 1)
    static let navigationBarBackgroundColor: UIColor = #colorLiteral(red: 0.2569749951, green: 0.1936042905, blue: 0.2717022896, alpha: 1)
//    #colorLiteral(red: 0.2135980725, green: 0.1503953636, blue: 0.2242289484, alpha: 1)
    static let navigationSearchFieldBackgroundColor: UIColor = #colorLiteral(red: 0.1695529222, green: 0.1113216504, blue: 0.1723338962, alpha: 1)
    static let tabBarBackgroundColor: UIColor = #colorLiteral(red: 0.2214901745, green: 0.1582537889, blue: 0.2320964336, alpha: 1)
    static let tabBarSelectedItemsTintColor: UIColor = actionButtonsTintColor
    static let tabBarNormalItemsTintColor: UIColor = #colorLiteral(red: 0.5385198593, green: 0.4843533039, blue: 0.5624566674, alpha: 1)
    static let cellSelectionBackgroundColor: UIColor = #colorLiteral(red: 0.1026760712, green: 0.07338444144, blue: 0.1081472859, alpha: 1)
    static let listCellBackgroundColor: UIColor = #colorLiteral(red: 0.2667922974, green: 0.1890299022, blue: 0.2787306905, alpha: 1)
    static let actionButtonsTintColor: UIColor = #colorLiteral(red: 0.8031871915, green: 0.4191343188, blue: 0.9248215556, alpha: 1)
    static let mainAppBackgroundColorGradientTop: UIColor = #colorLiteral(red: 0.468229115, green: 0.2259758115, blue: 0.5086464882, alpha: 1)
    static let mainAppBackgroundColorGradientBottom: UIColor = #colorLiteral(red: 0.468229115, green: 0.2259758115, blue: 0.5086464882, alpha: 1)
    
    static let textFieldPlaceholderColor: UIColor = #colorLiteral(red: 0.4450023174, green: 0.4215864837, blue: 0.4220157266, alpha: 1)
    static let textFieldTextColor: UIColor = .white
    static let messageTextFieldBackgroundColor: UIColor = #colorLiteral(red: 0.1236810908, green: 0.08473216742, blue: 0.1324510276, alpha: 1)
    
    static let inputBarMessageContainerBackgroundColor: UIColor = #colorLiteral(red: 0.2306482196, green: 0.1865905523, blue: 0.2809014618, alpha: 1)
    static let sendMessageButtonBackgroundColor: UIColor = #colorLiteral(red: 0.8080032468, green: 0.4144457579, blue: 0.9248802066, alpha: 1)
    
    static let unseenMessagesBadgeBackgroundColor: UIColor = #colorLiteral(red: 0.8423270583, green: 0.4228419662, blue: 0.9524703622, alpha: 1)
    static let unseenMessagesBadgeTextColor: UIColor = .white
    
    static let incomingMessageBackgroundColor: UIColor = #colorLiteral(red: 0.2260040045, green: 0.1867897213, blue: 0.2767668962, alpha: 1)
    static let outgoingMessageBackgroundColor: UIColor = #colorLiteral(red: 0.5294494033, green: 0.1983171999, blue: 0.5416952372, alpha: 1)
    static let incomingMessageComponentsTextColor: UIColor = #colorLiteral(red: 0.6161918044, green: 0.5466015935, blue: 0.627902925, alpha: 1)
    static let outgoingMessageComponentsTextColor: UIColor = #colorLiteral(red: 0.7367274165, green: 0.5783247948, blue: 0.7441712618, alpha: 1)
    static let outgoingReplyToMessageBackgroundColor: UIColor = #colorLiteral(red: 0.561234951, green: 0.2880425751, blue: 0.5783820748, alpha: 1)
    static let incomingReplyToMessageBackgroundColor: UIColor = #colorLiteral(red: 0.3370774055, green: 0.2437606049, blue: 0.363655651, alpha: 1)
    static let messageEventBackgroundColor: UIColor = #colorLiteral(red: 0.2021965683, green: 0.2685731351, blue: 0.3312993646, alpha: 1)
    static let messageSeenStatusIconColor: UIColor = outgoingMessageComponentsTextColor
    static let messageLinkColor: UIColor = #colorLiteral(red: 0, green: 0.6172372699, blue: 0.9823173881, alpha: 1)
    static let stickerViewBackgroundColor: UIColor = #colorLiteral(red: 0.1257298887, green: 0.2089383006, blue: 0.2593249977, alpha: 1)
//    static let stickerViewBackgroundColor: UIColor = #colorLiteral(red: 0.20829162, green: 0.1772045493, blue: 0.2476014197, alpha: 1)
    
    static let skeletonItemColor: UIColor = #colorLiteral(red: 0.3543712497, green: 0.2847208381, blue: 0.3677620888, alpha: 1)
    static let skeletonAnimationColor: UIColor = #colorLiteral(red: 0.6587312222, green: 0.6021129489, blue: 0.779224813, alpha: 1)
    
    private static let messageBackgroundColors: [UIColor] = [#colorLiteral(red: 0.8381425738, green: 0.3751247525, blue: 0.5768371224, alpha: 1), #colorLiteral(red: 0.2789569199, green: 0.7063412666, blue: 0.7922309637, alpha: 1), #colorLiteral(red: 0.1472819448, green: 0.5721367598, blue: 0.2217415869, alpha: 1), #colorLiteral(red: 0.7625821829, green: 0.4211770296, blue: 0.1522820294, alpha: 1), #colorLiteral(red: 0.7118884921, green: 0.3784905672, blue: 0.7786803842, alpha: 1)]
    
    static func color(for objectID: String) -> UIColor
    {
        let hashValue = objectID.hashValue
        let index = abs(hashValue) % messageBackgroundColors.count
        return messageBackgroundColors[index]
    }
}


//
//
////
////  Untitled.swift
////  RLottieTest
////
////  Created by Andrei Pripa on 9/9/25.
////
//
//import UIKit
//import librlottie
//
//
//final class DisplayLinkProxy
//{
//    weak var target: AnyObject?
//    let selector: Selector
//    
//    init(target: AnyObject, selector: Selector)
//    {
//        self.selector = selector
//        self.target = target
//    }
//    
//    @objc func onDisplayLink(_ link: CADisplayLink)
//    {
//        _ = target?.perform(selector, with: link)
//        print("Target")
//    }
//}
//
//final class StickersCollectionView: UIView
//{
//    private let animationManager: LottieAnimationManager = .init()   // <-- new
//    
//    private let animations: [String] = {
//        return Stickers.Category.allCases
//            .flatMap { $0.pack.map { $0.deletingPathExtension().lastPathComponent } }
//    }()
//    
//    private var collectionView: UICollectionView!
//    private var displayLink: CADisplayLink?
//    
//    override init(frame: CGRect) {
//        super.init(frame: frame)
//        
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
//        print("Sticker collection DEINIT")
//    }
//    
//    override func layoutSubviews()
//    {
//        if let layout = collectionView.collectionViewLayout as? UICollectionViewFlowLayout
//        {
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
//    func setupCollectionView()
//    {
//        let layout = UICollectionViewFlowLayout()
//        collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
//        collectionView.backgroundColor = .white
//        collectionView.dataSource = self
//        collectionView.delegate = self
//        collectionView.register(LottieCell.self, forCellWithReuseIdentifier: LottieCell.identifier)
//        collectionView.backgroundColor = .clear
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
//    private var proxy: DisplayLinkProxy?
//    // MARK: - Animation Loop
//    func startAnimationLoop()
//    {
//        let proxy = DisplayLinkProxy(target: self, selector: #selector(renderFrame))
//        let displayLink = CADisplayLink(target: proxy, selector: #selector(DisplayLinkProxy.onDisplayLink(_:)))
//        self.displayLink = displayLink
//        displayLink.add(to: .main, forMode: .common)
//    }
//
//    func stopAnimationLoop() {
//        displayLink?.invalidate()
//
//        displayLink = nil
//    }
//
//    @objc private func renderFrame()
//    {
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
//extension StickersCollectionView: UICollectionViewDataSource
//{
//    func collectionView(_ collectionView: UICollectionView,
//                        numberOfItemsInSection section: Int) -> Int {
//        return animations.count
//    }
//
//    func collectionView(_ collectionView: UICollectionView,
//                        cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
//        let cell = collectionView.dequeueReusableCell(
//            withReuseIdentifier: LottieCell.identifier,
//            for: indexPath
//        ) as! LottieCell
//        cell.configure(withAnimationNamed: animations[indexPath.item],
//                               manager: animationManager)   // <-- pass manager
//        return cell
//    }
//}
//
//// MARK: - UICollectionViewDelegate
//extension StickersCollectionView: UICollectionViewDelegateFlowLayout
//{
//    // MARK: - Visibility Management
//    func collectionView(_ collectionView: UICollectionView,
//                        willDisplay cell: UICollectionViewCell,
//                        forItemAt indexPath: IndexPath)
//    {
//        (cell as? LottieCell)?.lottieView.setVisible(true)
//    }
//
//    func collectionView(_ collectionView: UICollectionView,
//                        didEndDisplaying cell: UICollectionViewCell,
//                        forItemAt indexPath: IndexPath)
//    {
//        (cell as? LottieCell)?.lottieView.setVisible(false)
//    }
//}
//
//// MARK: - LottieCell
//class LottieCell: UICollectionViewCell {
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
//    func configure(withAnimationNamed name: String, manager: LottieAnimationManager) {
//           lottieView.loadAnimation(named: name, manager: manager)
//       }
//
//    override func prepareForReuse() {
//        super.prepareForReuse()
//        lottieView.reset()
//    }
//    
//    deinit {
//        print("LottieCell collection DEINIT")
//    }
//}
//
//
//// MARK: - RLLottieView
//class RLLottieView: UIView
//{
//    private var animationName: String?
//    private var animation: OpaquePointer?
//    private var frameNumber: Int = 0
//    private var totalFrames: Int = 0
//    private let renderSize = CGSize(width: 200, height: 200)
//    private var buffer: UnsafeMutablePointer<UInt32>?
//    private var isVisible = false
//    private var renderInProgress = false
//    private var startTime: CFTimeInterval = 0
//    private var randomOffset: TimeInterval = 0
//
//    // Cached graphics objects
//    private let cachedColorSpace: CGColorSpace
//    private let cachedBitmapInfo: CGBitmapInfo
//
//    private let renderQueue = DispatchQueue(label: "lottie.render.queue",
//                                            qos: .userInitiated)
//
//    override init(frame: CGRect) {
//        cachedColorSpace = CGColorSpaceCreateDeviceRGB()
//        cachedBitmapInfo = CGBitmapInfo(rawValue:
//            CGBitmapInfo.byteOrder32Little.rawValue |
//            CGImageAlphaInfo.premultipliedFirst.rawValue)
//        super.init(frame: frame)
//
//        let pixelCount = Int(renderSize.width * renderSize.height)
//        buffer = UnsafeMutablePointer<UInt32>.allocate(capacity: pixelCount)
//        buffer?.initialize(repeating: 0, count: pixelCount)
//    }
//
//    required init?(coder: NSCoder) {
//        fatalError("init(coder:) has not been implemented")
//    }
//
//    // MARK: - Load Animation
//    func loadAnimation(named name: String, manager: LottieAnimationManager) {
//            animationName = name
//            animation = nil
//            layer.contents = nil
//
//            Task { [weak self] in
//                guard let self else { return }
//                if let anim = await manager.getAnimation(named: name) {
//                    guard self.animationName == name else { return }
//
//
//                    self.animation = anim
//                    self.totalFrames = Int(lottie_animation_get_totalframe(anim))
//                    self.frameNumber = 0
//                    self.startTime = CACurrentMediaTime()
//                    self.randomOffset = TimeInterval.random(in: 0..<2.0)
//
//                    self.renderFirstFrame()
//                }
//            }
//        }
//
//    private func renderFirstFrame()
//    {
//        guard let animation = animation,
//              let buffer = buffer else { return }
//        
//            guard
//                    let animation = self.animation,
//                    let buffer = self.buffer else { return }
//            
//            lottie_animation_render(animation,
//                                    0,
//                                    buffer,
//                                    size_t(self.renderSize.width),
//                                    size_t(self.renderSize.height),
//                                    size_t(Int(self.renderSize.width) * MemoryLayout<UInt32>.size))
//            lottie_animation_render_flush(animation)
//            self.createAndDisplayImage(from: buffer)
//                self.renderInProgress = false
//
//    }
//
//    func setVisible(_ visible: Bool) {
//        isVisible = visible
//    }
//
//    func renderNextFrame() {
//        guard isVisible,
//              let animation = animation,
//              let buffer = buffer,
//              !renderInProgress,
//              totalFrames > 0 else { return }
//
//        renderInProgress = true
//
//        let elapsed = CACurrentMediaTime() - startTime + randomOffset
//        let duration = Double(totalFrames) / Double(lottie_animation_get_framerate(animation))
//        let progress = fmod(elapsed, duration) / duration
//        let currentFrame = Int(progress * Double(totalFrames))
//            
//            guard  let animation = self.animation, let buffer = self.buffer else { return }
//
//            
//            lottie_animation_render(animation,
//                                    size_t(currentFrame),
//                                    buffer,
//                                    size_t(self.renderSize.width),
//                                    size_t(self.renderSize.height),
//                                    size_t(Int(self.renderSize.width) * MemoryLayout<UInt32>.size))
//            lottie_animation_render_flush(animation)
//            self.createAndDisplayImage(from: buffer)
//                self.renderInProgress = false
////        }
//    }
//
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
//    func reset() {
//        if let animation = animation {
//            lottie_animation_destroy(animation)
//        }
//        animation = nil
//        animationName = nil
//        isVisible = false
//        renderInProgress = false
//        frameNumber = 0
//        layer.contents = nil
//    }
//
//    deinit {
//        if let animation = animation {
//            lottie_animation_destroy(animation)
//        }
//        buffer?.deallocate()
//        print("RLLottieView Deinit!")
//    }
//}
//
//extension OpaquePointer: @unchecked @retroactive Sendable {}
//    
//// MARK: - Animation Manager
//actor LottieAnimationManager
//{
//
//    // Async get with lazy loading
//    func getAnimation(named name: String) async -> OpaquePointer?
//    {
//        // Do file loading off the actor context to avoid blocking
//        return await withCheckedContinuation { continuation in
//            DispatchQueue.global(qos: .userInitiated).async {
//                var anim: OpaquePointer? = nil
//                if let path = Bundle.main.path(forResource: name, ofType: "json") {
//                    anim = lottie_animation_from_file(path)
//                }
//
//                Task { @MainActor in
//                    continuation.resume(returning: anim)
//                }
//            }
//        }
//    }
//
//    deinit {
//        print("LottieAnimationManager DEINIT")
//    }
//}
//
//
////MARK: layout items
////extension StickersCollectionView
////{
////    func createCollectionViewLayout() -> UICollectionViewLayout
////    {
////        let spacing: CGFloat = 10
////
////        let layout = UICollectionViewCompositionalLayout { sectionIndex, environment -> NSCollectionLayoutSection? in
////
////            // Each item takes 1/4 of the width minus spacing
////            let itemSize = NSCollectionLayoutSize(
////                widthDimension: .fractionalWidth(0.25),
////                heightDimension: .fractionalWidth(0.25) // square cells
////            )
////
////            let item = NSCollectionLayoutItem(layoutSize: itemSize)
////            item.contentInsets = NSDirectionalEdgeInsets(
////                top: spacing / 2,
////                leading: spacing / 2,
////                bottom: spacing / 2,
////                trailing: spacing / 2
////            )
////
////            // Group of 4 items horizontally
////            let groupSize = NSCollectionLayoutSize(
////                widthDimension: .fractionalWidth(1.0),
////                heightDimension: .fractionalWidth(0.25)
////            )
////
////            let group = NSCollectionLayoutGroup.horizontal(layoutSize: groupSize, repeatingSubitem: item, count: 4)
////
////            let section = NSCollectionLayoutSection(group: group)
////            section.contentInsets = NSDirectionalEdgeInsets(
////                top: spacing,
////                leading: spacing,
////                bottom: spacing,
////                trailing: spacing
////            )
////
////            return section
////        }
////
////        return layout
////    }
////}













//
////
////  Untitled.swift
////  RLottieTest
////
////  Created by Andrei Pripa on 9/9/25.
////
//
//import UIKit
//import librlottie
//
//
////class ViewController2: UIViewController
////{
////
////    override func viewDidLoad() {
////        super.viewDidLoad()
////        view.backgroundColor = .brown
////        let stickersCollectionView = StickersCollectionView(frame: view.bounds)
////        view.addSubview(stickersCollectionView)
////    }
////}
//
//final class DisplayLinkProxy
//{
//    weak var target: AnyObject?
//    let selector: Selector
//    
//    init(target: AnyObject, selector: Selector)
//    {
//        self.selector = selector
//        self.target = target
//    }
//    
//    @objc func onDisplayLink(_ link: CADisplayLink)
//    {
//        _ = target?.perform(selector, with: link)
//        print("Target")
//    }
//}
//
//final class StickersCollectionView: UIView
//{
//    private let animationManager: LottieAnimationManager = .init()   // <-- new
//    
//    private let animations: [String] = {
//        return Stickers.Category.allCases
//            .flatMap { $0.pack.map { $0.deletingPathExtension().lastPathComponent } }
//    }()
//    
//    private var collectionView: UICollectionView!
//    private var displayLink: CADisplayLink?
//    
//    override init(frame: CGRect) {
//        super.init(frame: frame)
//        
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
//        print("Sticker collection DEINIT")
//    }
//    
//    override func layoutSubviews()
//    {
//        if let layout = collectionView.collectionViewLayout as? UICollectionViewFlowLayout
//        {
//            let spacing: CGFloat = 10
//            let itemWidth = (bounds.width - spacing * 5) / 4
//            layout.itemSize = CGSize(width: itemWidth, height: itemWidth)
//            layout.minimumLineSpacing = spacing
//            layout.minimumInteritemSpacing = spacing
//            layout.sectionInset = UIEdgeInsets(top: spacing,
//                                               left: spacing,
//                                               bottom: 0,
//                                               right: spacing)
////            startAnimationLoop()
//        }
//    }
//    
//    func setupCollectionView()
//    {
//        let layout = UICollectionViewFlowLayout()
//        collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
//        collectionView.backgroundColor = .white
//        collectionView.dataSource = self
//        collectionView.delegate = self
//        collectionView.register(LottieCell.self, forCellWithReuseIdentifier: LottieCell.identifier)
//        collectionView.backgroundColor = .clear
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
//    private var proxy: DisplayLinkProxy?
//    // MARK: - Animation Loop
//    func startAnimationLoop()
//    {
////        stopAnimationLoop() // stop previous display link if any
//        let proxy = DisplayLinkProxy(target: self, selector: #selector(renderFrame))
////        self.proxy = proxy
//        let displayLink = CADisplayLink(target: proxy, selector: #selector(DisplayLinkProxy.onDisplayLink(_:)))
//        self.displayLink = displayLink
//        displayLink.add(to: .main, forMode: .common)
//    }
//
//    func stopAnimationLoop() {
//        displayLink?.invalidate()
////        proxy?.target = nil
////        proxy = nil
//        displayLink = nil
//    }
//
//    @objc private func renderFrame()
//    {
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
//extension StickersCollectionView: UICollectionViewDataSource
//{
//    func collectionView(_ collectionView: UICollectionView,
//                        numberOfItemsInSection section: Int) -> Int {
//        return animations.count
//    }
//
//    func collectionView(_ collectionView: UICollectionView,
//                        cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
//        let cell = collectionView.dequeueReusableCell(
//            withReuseIdentifier: LottieCell.identifier,
//            for: indexPath
//        ) as! LottieCell
////        cell.configure(withAnimationNamed: animations[indexPath.item])
//        cell.configure(withAnimationNamed: animations[indexPath.item],
//                               manager: animationManager)   // <-- pass manager
//        return cell
//    }
//}
//
//// MARK: - UICollectionViewDelegate
//extension StickersCollectionView: UICollectionViewDelegateFlowLayout
//{
//    // MARK: - Visibility Management
//    func collectionView(_ collectionView: UICollectionView,
//                        willDisplay cell: UICollectionViewCell,
//                        forItemAt indexPath: IndexPath)
//    {
//        (cell as? LottieCell)?.lottieView.setVisible(true)
//    }
//
//    func collectionView(_ collectionView: UICollectionView,
//                        didEndDisplaying cell: UICollectionViewCell,
//                        forItemAt indexPath: IndexPath)
//    {
//        (cell as? LottieCell)?.lottieView.setVisible(false)
//    }
//}
//
//// MARK: - LottieCell
//class LottieCell: UICollectionViewCell {
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
//    func configure(withAnimationNamed name: String, manager: LottieAnimationManager) {
//           lottieView.loadAnimation(named: name)
//       }
//
//    override func prepareForReuse() {
//        super.prepareForReuse()
//        lottieView.reset()
//    }
//    
//    deinit {
//        print("LottieCell collection DEINIT")
//    }
//}
//
//
//// MARK: - RLLottieView
//class RLLottieView: UIView {
//    private var animationName: String?
//    private var animation: OpaquePointer?
//    private var frameNumber: Int = 0
//    private var totalFrames: Int = 0
//    private let renderSize = CGSize(width: 200, height: 200)
//    private var buffer: UnsafeMutablePointer<UInt32>?
//    private var isVisible = false
//    private var renderInProgress = false
//    private var startTime: CFTimeInterval = 0
//    private var randomOffset: TimeInterval = 0
//
//    // Cached graphics objects
//    private let cachedColorSpace: CGColorSpace
//    private let cachedBitmapInfo: CGBitmapInfo
//
//    private let renderQueue = DispatchQueue(label: "lottie.render.queue",
//                                            qos: .userInitiated)
//
//    override init(frame: CGRect) {
//        cachedColorSpace = CGColorSpaceCreateDeviceRGB()
//        cachedBitmapInfo = CGBitmapInfo(rawValue:
//            CGBitmapInfo.byteOrder32Little.rawValue |
//            CGImageAlphaInfo.premultipliedFirst.rawValue)
//        super.init(frame: frame)
//
//        let pixelCount = Int(renderSize.width * renderSize.height)
//        buffer = UnsafeMutablePointer<UInt32>.allocate(capacity: pixelCount)
//        buffer?.initialize(repeating: 0, count: pixelCount)
//    }
//
//    required init?(coder: NSCoder) {
//        fatalError("init(coder:) has not been implemented")
//    }
//
//    // MARK: - Load Animation
//    func loadAnimation(named name: String) {
//        animationName = name
////        reset() // cleanup any old animation first
//
//        renderQueue.async { [weak self] in
//            guard let self else { return }
//
//            // Load synchronously on renderQueue
//            guard self.animationName == name else {return}
//            if let path = Bundle.main.path(forResource: name, ofType: "json"),
//               let anim = lottie_animation_from_file(path) {
//                self.animation = anim
//                self.totalFrames = Int(lottie_animation_get_totalframe(anim))
//                self.frameNumber = 0
//                self.startTime = CACurrentMediaTime()
//                self.randomOffset = TimeInterval.random(in: 0..<2.0)
//
//                self.renderFrame(0)
//            }
//        }
//    }
//
//    func setVisible(_ visible: Bool) {
//        isVisible = visible
//    }
//
//    func renderNextFrame() {
//        guard isVisible, !renderInProgress else { return }
//
//        renderInProgress = true
//        renderQueue.async { [weak self] in
//            guard let self,
//                  let animation = self.animation,
//                  let buffer = self.buffer,
//                  self.totalFrames > 0 else {
//                DispatchQueue.main.async { self?.renderInProgress = false }
//                return
//            }
//
//            let elapsed = CACurrentMediaTime() - self.startTime + self.randomOffset
//            let duration = Double(self.totalFrames) / Double(lottie_animation_get_framerate(animation))
//            let progress = fmod(elapsed, duration) / duration
//            let currentFrame = Int(progress * Double(self.totalFrames))
//
//            self.renderFrame(currentFrame)
//        }
//    }
//
//    // MARK: - Core rendering
//    private func renderFrame(_ frame: Int) {
//        guard let animation, let buffer else { return }
//
//        lottie_animation_render(animation,
//                                size_t(frame),
//                                buffer,
//                                size_t(renderSize.width),
//                                size_t(renderSize.height),
//                                size_t(Int(renderSize.width) * MemoryLayout<UInt32>.size))
//
//        let image = makeImage(from: buffer)
//        DispatchQueue.main.async { [weak self] in
//            self?.layer.contents = image
//            self?.renderInProgress = false
//        }
//    }
//
//    private func makeImage(from cgBuffer: UnsafeMutableRawPointer) -> CGImage? {
//        guard let context = CGContext(data: cgBuffer,
//                                      width: Int(renderSize.width),
//                                      height: Int(renderSize.height),
//                                      bitsPerComponent: 8,
//                                      bytesPerRow: Int(renderSize.width) * 4,
//                                      space: cachedColorSpace,
//                                      bitmapInfo: cachedBitmapInfo.rawValue) else {
//            return nil
//        }
//        return context.makeImage()
//    }
//
//    // MARK: - Cleanup
//    func reset() {
//        renderQueue.async { [weak self] in
//            guard let self else { return }
//            if let animation = self.animation {
//                lottie_animation_destroy(animation)
//                self.animation = nil
//            }
//            self.animationName = nil
//            self.isVisible = false
//            self.renderInProgress = false
//            self.frameNumber = 0
//            DispatchQueue.main.async {
//                self.layer.contents = nil
//            }
//        }
//    }
//
//    deinit {
//        buffer?.deallocate()
//        renderQueue.sync {
//            if let animation = animation {
//                lottie_animation_destroy(animation)
//            }
//            animation = nil
//        }
//        print("RLLottieView Deinit!")
//    }
//    
//    func getAnimation(named name: String) async -> OpaquePointer?
//    {
////        if let cached = cachedAnimations[name] {
////            return cached
////        }
//
//        // Do file loading off the actor context to avoid blocking
//        return await withCheckedContinuation { continuation in
//            DispatchQueue.global(qos: .userInitiated).async {
//                var anim: OpaquePointer? = nil
//                if let path = Bundle.main.path(forResource: name, ofType: "json") {
//                    anim = lottie_animation_from_file(path)
//                }
//
//                Task { @MainActor in
//                    continuation.resume(returning: anim)
//                }
//            }
//        }
//    }
//}
//
//extension OpaquePointer: @unchecked @retroactive Sendable {}
//    
//// MARK: - Animation Manager
//actor LottieAnimationManager
//{
////    static let shared = LottieAnimationManager()
//
//    private var cachedAnimations: [String: OpaquePointer] = [:]
//
////    private init() {}
//
//    // Async get with lazy loading
//    func getAnimation(named name: String) async -> OpaquePointer?
//    {
////        if let cached = cachedAnimations[name] {
////            return cached
////        }
//
//        // Do file loading off the actor context to avoid blocking
//        return await withCheckedContinuation { continuation in
//            DispatchQueue.global(qos: .userInitiated).async {
//                var anim: OpaquePointer? = nil
//                if let path = Bundle.main.path(forResource: name, ofType: "json") {
//                    anim = lottie_animation_from_file(path)
//                }
//
//                Task { @MainActor in
//                    continuation.resume(returning: anim)
//                }
//            }
//        }
//    }
//
//    // Store animation
//    func cacheAnimation(_ anim: OpaquePointer, named name: String) {
//        cachedAnimations[name] = anim
//    }
//
//    // Cleanup everything
//    func cleanup() {
//        for (_, anim) in cachedAnimations {
//            lottie_animation_destroy(anim)
//        }
//        cachedAnimations.removeAll()
//    }
//
//    deinit {
//        print("LottieAnimationManager DEINIT")
////        for (_, anim) in cachedAnimations {
////            lottie_animation_destroy(anim)
////        }
////        cachedAnimations.removeAll()
//    }
//}
//
//
////MARK: layout items
////extension StickersCollectionView
////{
////    func createCollectionViewLayout() -> UICollectionViewLayout
////    {
////        let spacing: CGFloat = 10
////
////        let layout = UICollectionViewCompositionalLayout { sectionIndex, environment -> NSCollectionLayoutSection? in
////
////            // Each item takes 1/4 of the width minus spacing
////            let itemSize = NSCollectionLayoutSize(
////                widthDimension: .fractionalWidth(0.25),
////                heightDimension: .fractionalWidth(0.25) // square cells
////            )
////
////            let item = NSCollectionLayoutItem(layoutSize: itemSize)
////            item.contentInsets = NSDirectionalEdgeInsets(
////                top: spacing / 2,
////                leading: spacing / 2,
////                bottom: spacing / 2,
////                trailing: spacing / 2
////            )
////
////            // Group of 4 items horizontally
////            let groupSize = NSCollectionLayoutSize(
////                widthDimension: .fractionalWidth(1.0),
////                heightDimension: .fractionalWidth(0.25)
////            )
////
////            let group = NSCollectionLayoutGroup.horizontal(layoutSize: groupSize, repeatingSubitem: item, count: 4)
////
////            let section = NSCollectionLayoutSection(group: group)
////            section.contentInsets = NSDirectionalEdgeInsets(
////                top: spacing,
////                leading: spacing,
////                bottom: spacing,
////                trailing: spacing
////            )
////
////            return section
////        }
////
////        return layout
////    }
////}





//////THIS ONE WITH ACTOR WORKS

//
//import UIKit
//import librlottie
//
//// MARK: - Shared Render Actor
//actor RenderActor {
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
//    func destroy(animation: OpaquePointer) {
//        lottie_animation_destroy(animation)
//    }
//}
//
//
//// Needed for concurrency
//extension OpaquePointer: @unchecked @retroactive Sendable {}
//
//// MARK: - StickersCollectionView
//final class StickersCollectionView: UIView {
////    private let animationManager: LottieAnimationManager = .init()
//
//    private let animations: [String] = {
//        return Stickers.Category.allCases
//            .flatMap { $0.pack.map { $0.deletingPathExtension().lastPathComponent } }
//    }()
//
//    private var collectionView: UICollectionView!
//    private var displayLink: CADisplayLink?
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
//    func setupCollectionView() {
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
//        let displayLink = CADisplayLink(target: self, selector: #selector(renderFrame))
//        self.displayLink = displayLink
//        displayLink.add(to: .main, forMode: .common)
//    }
//
//    func stopAnimationLoop() {
//        displayLink?.invalidate()
//        displayLink = nil
//    }
//
//    @objc private func renderFrame() {
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
//        return animations.count
//    }
//
//    func collectionView(_ collectionView: UICollectionView,
//                        cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
//        let cell = collectionView.dequeueReusableCell(
//            withReuseIdentifier: LottieCell.identifier,
//            for: indexPath
//        ) as! LottieCell
//        cell.configure(withAnimationNamed: animations[indexPath.item])
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
//}
//
//// MARK: - LottieCell
//class LottieCell: UICollectionViewCell {
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
//    override func prepareForReuse() {
//        super.prepareForReuse()
//        lottieView.reset()
//    }
//
//    deinit {
//        print("LottieCell DEINIT")
//    }
//}
//
//// MARK: - RLLottieView
//class RLLottieView: UIView {
//    private var animationName: String?
//    private var animation: OpaquePointer?
//    private var frameNumber: Int = 0
//    private var totalFrames: Int = 0
//    private let renderSize = CGSize(width: 200, height: 200)
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
//    // 👇 new
//    private var generation: Int = 0
//
//    override init(frame: CGRect) {
//        cachedColorSpace = CGColorSpaceCreateDeviceRGB()
//        cachedBitmapInfo = CGBitmapInfo(rawValue:
//            CGBitmapInfo.byteOrder32Little.rawValue |
//            CGImageAlphaInfo.premultipliedFirst.rawValue)
//        super.init(frame: frame)
//
//        let pixelCount = Int(renderSize.width * renderSize.height)
//        buffer = UnsafeMutablePointer<UInt32>.allocate(capacity: pixelCount)
//        buffer?.initialize(repeating: 0, count: pixelCount)
//    }
//
//    required init?(coder: NSCoder) {
//        fatalError("init(coder:) has not been implemented")
//    }
//
//    // MARK: - Load Animation
//    func loadAnimation(named name: String) {
//        generation &+= 1   // bump generation
//        let currentGen = generation
//
//        animationName = name
//        animation = nil
//        layer.contents = nil
//
//        Task { [weak self] in
//            guard let self else { return }
//            if let anim = await getAnimation(named: name) {
//                guard self.animationName == name,
//                      self.generation == currentGen else { return }
//
//                self.animation = anim
//                self.totalFrames = Int(lottie_animation_get_totalframe(anim))
//                self.frameNumber = 0
//                self.startTime = CACurrentMediaTime()
//                self.randomOffset = TimeInterval.random(in: 0..<2.0)
//                self.renderFirstFrame(gen: currentGen)
//            }
//        }
//    }
//
//    private func renderFirstFrame(gen: Int) {
//        guard let animation, let buffer else { return }
//
//        Task {
//            await RenderActor.shared.render(animation: animation,
//                                            frame: 0,
//                                            buffer: buffer,
//                                            size: renderSize)
//            guard self.generation == gen else { return }
//            self.createAndDisplayImage(from: buffer)
//            self.renderInProgress = false
//        }
//    }
//
//    func renderNextFrame() {
//        guard isVisible,
//              let animation,
//              let buffer,
//              !renderInProgress,
//              totalFrames > 0 else { return }
//
//        renderInProgress = true
//        let gen = generation
//
//        let elapsed = CACurrentMediaTime() - startTime + randomOffset
//        let duration = Double(totalFrames) / Double(lottie_animation_get_framerate(animation))
//        let progress = fmod(elapsed, duration) / duration
//        let currentFrame = Int(progress * Double(totalFrames))
//
//        Task {
//            await RenderActor.shared.render(animation: animation,
//                                            frame: currentFrame,
//                                            buffer: buffer,
//                                            size: renderSize)
//            guard self.generation == gen else { return }
//            self.createAndDisplayImage(from: buffer)
//            self.renderInProgress = false
//        }
//    }
//
//    // MARK: - Reset
//    func reset() {
//        generation &+= 1  // invalidate all pending renders
//        if let anim = animation {
//            Task { await RenderActor.shared.destroy(animation: anim) }
//        }
//        animation = nil
//        animationName = nil
//        isVisible = false
//        renderInProgress = false
//        frameNumber = 0
//        layer.contents = nil
//    }
//
//    deinit {
//        if let anim = animation {
//            Task { await RenderActor.shared.destroy(animation: anim) }
//        }
//        buffer?.deallocate()
//        print("RLLottieView Deinit!")
//    }
//    private func createAndDisplayImage(from cgBuffer: UnsafeMutableRawPointer) {
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
//
//    func getAnimation(named name: String) async -> OpaquePointer? {
//        return await withCheckedContinuation { continuation in
//            DispatchQueue.global(qos: .userInitiated).async {
//                var anim: OpaquePointer? = nil
//                if let path = Bundle.main.path(forResource: name, ofType: "json") {
//                    anim = lottie_animation_from_file(path)
//                }
//                continuation.resume(returning: anim)
//            }
//        }
//    }
//}


//
//
//
//import UIKit
//import librlottie
//
//// MARK: - Concurrency helper
//extension OpaquePointer: @unchecked @retroactive Sendable {}
//
//// MARK: - Render Actor
//actor RenderActor {
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
//}
//
//// MARK: - DisplayLink Proxy
//final class DisplayLinkProxy {
//    weak var target: AnyObject?
//    let selector: Selector
//    
//    init(target: AnyObject, selector: Selector) {
//        self.target = target
//        self.selector = selector
//    }
//    
//    @objc func onDisplayLink(_ link: CADisplayLink) {
//        _ = target?.perform(selector, with: link)
//    }
//}
//
//// MARK: - StickersCollectionView
//final class StickersCollectionView: UIView {
//    
//    // Animation cache
//    private var cache: [String: OpaquePointer] = [:]
//    
//    // All animation names
//    private let animations: [String] = {
//        return Stickers.Category.allCases
//            .flatMap { $0.pack.map { $0.deletingPathExtension().lastPathComponent } }
//    }()
//    
//    private var collectionView: UICollectionView!
//    private var displayLink: CADisplayLink?
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
////        executeAfter(seconds: 1.5) {
////        self.clearCache()
////        }
//        print("Sticker collection DEINIT")
//    }
//    
//    override func layoutSubviews() {
//        super.layoutSubviews()
//        guard let layout = collectionView.collectionViewLayout as? UICollectionViewFlowLayout else { return }
//        let spacing: CGFloat = 10
//        let itemWidth = (bounds.width - spacing * 5) / 4
//        layout.itemSize = CGSize(width: itemWidth, height: itemWidth)
//        layout.minimumLineSpacing = spacing
//        layout.minimumInteritemSpacing = spacing
//        layout.sectionInset = UIEdgeInsets(top: spacing, left: spacing, bottom: 0, right: spacing)
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
//        for cell in collectionView.visibleCells.compactMap({ $0 as? LottieCell }) {
//            cell.lottieView.renderNextFrame()
//        }
//    }
//    
//    // MARK: - Animation Cache Access
//    func getAnimation(named name: String, completion: @escaping (OpaquePointer?) -> Void) {
//        if let anim = cache[name] {
//            completion(anim)
//            return
//        }
//        
//        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
//            guard let path = Bundle.main.path(forResource: name, ofType: "json"),
//                  let anim = lottie_animation_from_file(path) else {
//                DispatchQueue.main.async { completion(nil) }
//                return
//            }
//            DispatchQueue.main.async {
//                self?.cache[name] = anim
//                completion(anim)
//            }
//        }
//    }
//    
//    func clearCache()
//    {
//        for (_, anim) in cache {
//            lottie_animation_destroy(anim)
//        }
//        cache.removeAll()
//    }
//}
//
//// MARK: - UICollectionViewDataSource
//extension StickersCollectionView: UICollectionViewDataSource {
//    func collectionView(_ collectionView: UICollectionView,
//                        numberOfItemsInSection section: Int) -> Int {
//        return animations.count
//    }
//    
//    func collectionView(_ collectionView: UICollectionView,
//                        cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
//        let cell = collectionView.dequeueReusableCell(
//            withReuseIdentifier: LottieCell.identifier,
//            for: indexPath
//        ) as! LottieCell
//        
//        let animationName = animations[indexPath.item]
//        cell.currentAnimationName = animationName
//        
//        getAnimation(named: animationName) { animation in
//            guard let animation else { return }
//            if cell.currentAnimationName == animationName {
//                cell.configure(withAnimation: animation, name: animationName)
//            }
//        }
//        
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
//}
//
//// MARK: - LottieCell
//class LottieCell: UICollectionViewCell {
//    static let identifier = "LottieCell"
//    
//    let lottieView = RLLottieView()
//    var currentAnimationName: String?
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
//    func configure(withAnimation animation: OpaquePointer, name: String) {
//        currentAnimationName = name
//        lottieView.loadAnimation(animation)
//    }
//    
//    override func prepareForReuse() {
//        super.prepareForReuse()
//        lottieView.reset()
//        currentAnimationName = nil
//    }
//    
//    deinit {
//        print("LottieCell DEINIT")
//    }
//}
//
//// MARK: - RLLottieView
//class RLLottieView: UIView {
//    private var animation: OpaquePointer?
//    private var totalFrames: Int = 0
//    private let renderSize = CGSize(width: 200, height: 200)
//    private var buffer: UnsafeMutablePointer<UInt32>?
//    private var isVisible = false
//    private var renderInProgress = false
//    private var startTime: CFTimeInterval = 0
//    private var randomOffset: TimeInterval = 0
//    
//    private let cachedColorSpace: CGColorSpace
//    private let cachedBitmapInfo: CGBitmapInfo
//    
//    private var generation: Int = 0
//    
//    var task: Task<Void, Never>?
//    
//    override init(frame: CGRect) {
//        cachedColorSpace = CGColorSpaceCreateDeviceRGB()
//        cachedBitmapInfo = CGBitmapInfo(rawValue:
//            CGBitmapInfo.byteOrder32Little.rawValue |
//            CGImageAlphaInfo.premultipliedFirst.rawValue)
//        super.init(frame: frame)
//        
//        let pixelCount = Int(renderSize.width * renderSize.height)
//        buffer = UnsafeMutablePointer<UInt32>.allocate(capacity: pixelCount)
//        buffer?.initialize(repeating: 0, count: pixelCount)
//    }
//    
//    required init?(coder: NSCoder) {
//        fatalError("init(coder:) has not been implemented")
//    }
//    
//    // MARK: - Load Animation
//    func loadAnimation(_ animation: OpaquePointer) {
//        generation &+= 1
//        let currentGen = generation
//        
//        self.animation = animation
//        layer.contents = nil
//        
//        Task { [weak self] in
//            guard let self = self else { return }
//            guard self.generation == currentGen else { return }
//            
//            self.totalFrames = Int(lottie_animation_get_totalframe(animation))
//            self.startTime = CACurrentMediaTime()
//            self.randomOffset = TimeInterval.random(in: 0..<2.0)
//            self.renderFirstFrame(gen: currentGen)
//        }
//    }
//    
//    private func renderFirstFrame(gen: Int) {
//        guard let animation, let buffer else { return }
//        Task {
//            await RenderActor.shared.render(animation: animation,
//                                            frame: 0,
//                                            buffer: buffer,
//                                            size: renderSize)
//            guard self.generation == gen else { return }
//            self.createAndDisplayImage(from: buffer)
//            self.renderInProgress = false
//        }
//    }
//    
//    func renderNextFrame() {
//        guard isVisible,
//              let animation,
//              let buffer,
//              !renderInProgress,
//              totalFrames > 0 else { return }
//        
//        renderInProgress = true
//        let gen = generation
//        
//        let elapsed = CACurrentMediaTime() - startTime + randomOffset
//        let duration = Double(totalFrames) / Double(lottie_animation_get_framerate(animation))
//        let progress = fmod(elapsed, duration) / duration
//        let currentFrame = Int(progress * Double(totalFrames))
//        
//        task?.cancel()
//        task = Task {
//            await RenderActor.shared.render(animation: animation,
//                                            frame: currentFrame,
//                                            buffer: buffer,
//                                            size: renderSize)
//            guard self.generation == gen else { return }
//            self.createAndDisplayImage(from: buffer)
//            self.renderInProgress = false
//        }
//    }
//    
//    func reset() {
//        generation &+= 1
//        animation = nil
//        task?.cancel()
//        task = nil
//        isVisible = false
//        renderInProgress = false
//        layer.contents = nil
//    }
//    
//    deinit {
//        buffer?.deallocate()
//        print("RLLottieView Deinit!")
//    }
//    
//    private func createAndDisplayImage(from cgBuffer: UnsafeMutableRawPointer) {
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
