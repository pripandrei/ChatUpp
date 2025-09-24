//
//  StickerContentView.swift
//  ChatUpp
//
//  Created by Andrei Pripa on 9/19/25.
//

import UIKit
import Combine

final class StickerContentView: UIView
{
    private var stickerRLottieView: RLLottieView = .init(renderSize: .init(width: 300, height: 300))
    private var displayLink: CADisplayLink?
    
    private let stickerComponentsView: MessageComponentsView = .init()
    
    private var cancellables = Set<AnyCancellable>()
    
    convenience init()
    {
        self.init(frame: .zero)
        setupSticker()
        setupStickerComponentsView()
    }
    
    private func setupStickerComponentsView()
    {
        addSubview(stickerComponentsView)
        stickerComponentsView.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            stickerComponentsView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -8),
            stickerComponentsView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: 3),
        ])
    }
    
    private func setupSticker()
    {
        addSubview(stickerRLottieView)
        stickerRLottieView.translatesAutoresizingMaskIntoConstraints = false
        
        // Height is set in ChatRoomViewController -> heightForRowAt
        NSLayoutConstraint.activate([
            stickerRLottieView.topAnchor.constraint(equalTo: topAnchor),
            stickerRLottieView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -10),
            stickerRLottieView.bottomAnchor.constraint(equalTo: bottomAnchor),
//            stickerLottieView.heightAnchor.constraint(equalToConstant: 170),
            stickerRLottieView.widthAnchor.constraint(equalTo: stickerRLottieView.heightAnchor),
        ])
    }
    
    func setupBinding(publisher: AnyPublisher<Bool, Never>)
    {
        publisher.sink { isSeen in
            if isSeen { self.updateMessageSeenStatus() }
        }.store(in: &cancellables)
    }
    
//    func configure(withStickerPath path: String)
    func configure(with viewModel: MessageContainerViewModel)
    {
        guard let message = viewModel.message else { return }
        
        setupBinding(publisher: viewModel.messageSeenStatusChangedSubject.eraseToAnyPublisher())
        
        stickerRLottieView.loadAnimation(named: message.sticker!)
        stickerRLottieView.setVisible(true)
//        DisplayLinkManager.shered.addObject(stickerRLottieView)
        
        stickerComponentsView.configure(viewModel: viewModel.messageComponentsViewModel)
        startAnimationLoop()
    }
    
    deinit {
        print("sticker view deinit")
//        DisplayLinkManager.shered.cleanup(stickerRLottieView)
        stickerRLottieView.setVisible(false)
        stopAnimationLoop()
        stickerRLottieView.destroyAnimation()
        stickerComponentsView.cleanupContent()
    }
}

extension StickerContentView
{
    private func updateMessageSeenStatus()
    {
        executeAfter(seconds: 3.0, block: {
            self.stickerComponentsView.messageComponentsStackView.setNeedsLayout()
            self.stickerComponentsView.configureMessageSeenStatus()
            
            UIView.animate(withDuration: 0.3) {
                self.superview?.layoutIfNeeded()
            }
        })
    }
}

//MARK: - Render animation
extension StickerContentView
{
    //  Animation Loop
    func startAnimationLoop()
    {
        let proxy = DisplayLinkProxy(target: self, selector: #selector(renderFrame))
        displayLink = CADisplayLink(target: proxy, selector: #selector(DisplayLinkProxy.onDisplayLink(_:)))
        displayLink?.add(to: .main, forMode: .common)
    }

    private func stopAnimationLoop() {
        displayLink?.invalidate()
        displayLink = nil
    }

    @objc private func renderFrame() {
        stickerRLottieView.renderNextFrame()
    }
}


//final class StickerContentView: UIView
//{
////    var stickerView: UIView = UIView()
//    var stickerAnimationView: LottieAnimationView!
////    var stickerAnimationView: LottieAnimationView = LottieAnimationView()
//    
//    convenience init()
//    {
//        self.init(frame: .zero)
//        setupSticker()
//    }
//    
//    private func setupSticker()
//    {
//        self.stickerAnimationView = LottieAnimationView(configuration: .init(renderingEngine: .mainThread))
//        addSubview(stickerAnimationView)
////        stickerAnimationView.backgroundColor = .red
//        stickerAnimationView.translatesAutoresizingMaskIntoConstraints = false
//        
//        NSLayoutConstraint.activate([
//            stickerAnimationView.topAnchor.constraint(equalTo: topAnchor),
//            stickerAnimationView.trailingAnchor.constraint(equalTo: trailingAnchor),
//            stickerAnimationView.bottomAnchor.constraint(equalTo: bottomAnchor),
//            stickerAnimationView.heightAnchor.constraint(equalToConstant: 170),
//            stickerAnimationView.widthAnchor.constraint(equalTo: stickerAnimationView.heightAnchor),
//        ])
//    }
//    
//    func configure(withStickerPath path: String)
//    {
////        executeAfter(seconds: 0.1) { [weak self] in
////            let leaty = LottieAnimationLayer(animation: LottieAnimation.named(path))
////            leaty.animation = LottieAnimation.named(path)
////            self?.stickerAnimationView.animation = LottieAnimation.named(path)
////            self?.stickerAnimationView.contentMode = .scaleAspectFit
////            self?.stickerAnimationView.loopMode = .loop
////            self?.stickerAnimationView.play()
////        }
//        
////        DispatchQueue.global(qos: .userInitiated).async
////        {
////            if let path = Bundle.main.path(forResource: path, ofType: "json"),
////               let data = try? Data(contentsOf: URL(fileURLWithPath: path)),
////               let animation = try? LottieAnimation.from(data: data) {
////
////                // Step 2 — Switch to main thread to display
//////                mainQueue { [weak self] in
////                    mainQueue { [weak self] in
////                        self?.stickerAnimationView.animation = animation
////                        self?.stickerAnimationView.loopMode = .loop
//////                        self?.stickerAnimationView.play()
////                        executeAfter(seconds: 0.5) { [weak self] in
////                            self?.stickerAnimationView.play()
////                        }
////                    }
////                    //                    self?.stickerAnimationView.animationSpeed = 0.8
////                    //                    self?.stickerAnimationView.mainThreadRenderingEngineShouldForceDisplayUpdateOnEachFrame = false
//////                }
////            }
////        }
//        
//        stickerAnimationView.animation = LottieAnimation.named(path)
//        stickerAnimationView.contentMode = .scaleAspectFit
//        stickerAnimationView.loopMode = .loop
//        
//        executeAfter(seconds: 0.5) { [weak self] in
//            self?.stickerAnimationView.play()
//        }
//    }
//    
////    var lottieLayer = LottieAnimationLayer()
//    
//    func cleanup()
//    {
//        stickerAnimationView?.stop()
//        stickerAnimationView?.currentProgress = 1
//        stickerAnimationView?.animation = nil
//        stickerAnimationView = nil
//        
//    }
//    
//    deinit {
//        print("sticker view deinit")
//        cleanup()
//    }
//}









//
////  StickerContentView.swift
////  ChatUpp
////
////  Created by Andrei Pripa on 9/19/25.
////
//
//import UIKit
////import Lottie
//import librlottie
//
//final class StickerContentView: UIView
//{
////    var stickerView: UIView = UIView()
//    var stickerLottieView: RLLottieView = .init(renderSize: .init(width: 300, height: 300))
////    private var displayLink: CADisplayLink?
//    
//    convenience init()
//    {
//        self.init(frame: .zero)
//        setupSticker()
////        startAnimationLoop()
//    }
//    
//    private func setupSticker()
//    {
//        addSubview(stickerLottieView)
//        stickerLottieView.translatesAutoresizingMaskIntoConstraints = false
//        
//        NSLayoutConstraint.activate([
//            stickerLottieView.topAnchor.constraint(equalTo: topAnchor),
//            stickerLottieView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -10),
//            stickerLottieView.bottomAnchor.constraint(equalTo: bottomAnchor),
//            stickerLottieView.heightAnchor.constraint(equalToConstant: 170),
//            stickerLottieView.widthAnchor.constraint(equalTo: stickerLottieView.heightAnchor),
//        ])
//    }
//    
//    func configure(withStickerPath path: String)
//    {
//        stickerLottieView.loadAnimation(named: path)
//        stickerLottieView.setVisible(true)
//        DisplayLinkManager.shered.addObject(stickerLottieView)
////        startAnimationLoop()
//    }
//    
//    deinit {
//        print("sticker view deinit")
////        cleanup()
//        DisplayLinkManager.shered.stopAnimationLoop()
//        stickerLottieView.setVisible(false)
////        stopAnimationLoop()
//        stickerLottieView.destroyAnimation()
//        DisplayLinkManager.shered.cleanup(self.stickerLottieView)
////        stickerLottieView.reset()
//    }
//}
//
////MARK: - Render animation
//extension StickerContentView
//{
//    // MARK: - Animation Loop
////    func startAnimationLoop()
////    {
////        let proxy = DisplayLinkProxy(target: self, selector: #selector(renderFrame))
////        displayLink = CADisplayLink(target: proxy, selector: #selector(DisplayLinkProxy.onDisplayLink(_:)))
////        displayLink?.add(to: .main, forMode: .common)
////    }
////
////    private func stopAnimationLoop() {
////        displayLink?.invalidate()
////        displayLink = nil
////    }
//
////    @objc private func renderFrame() {
////        // Frame skip (render every 2nd tick → ~30 FPS)
//////        frameSkipCounter += 1
//////        if frameSkipCounter % 2 != 0 { return }
////
//////        let visibleIndexPaths = collectionView.indexPathsForVisibleItems
//////        for indexPath in visibleIndexPaths {
//////            if let cell = collectionView.cellForItem(at: indexPath) as? LottieCell {
////                stickerLottieView.renderNextFrame()
//////            }
//////        }
////    }
//}
//
//final class DisplayLinkManager
//{
//    static let shered = DisplayLinkManager()
//    
//    private init() {}
//    
//    private var displayLink: CADisplayLink?
//    
//    private var stickerObjects: Set<RLLottieView> = []
//    
//    // MARK: - Animation Loop
//    func startAnimationLoop()
//    {
//        let proxy = DisplayLinkProxy(target: self, selector: #selector(renderFrame))
//        displayLink = CADisplayLink(target: proxy, selector: #selector(DisplayLinkProxy.onDisplayLink(_:)))
//        displayLink?.add(to: .main, forMode: .common)
//    }
//    
//    func stopAnimationLoop() {
//        displayLink?.invalidate()
//        displayLink = nil
//    }
//    
//    @objc private func renderFrame() {
//        // Frame skip (render every 2nd tick → ~30 FPS)
//        //        frameSkipCounter += 1
//        //        if frameSkipCounter % 2 != 0 { return }
//        
//        //        let visibleIndexPaths = collectionView.indexPathsForVisibleItems
//        //        for indexPath in visibleIndexPaths {
//        //            if let cell = collectionView.cellForItem(at: indexPath) as? LottieCell {
////        stickerLottieView.renderNextFrame()
//        //            }
//        //        }
//        stickerObjects.forEach { lottie in
//            lottie.renderNextFrame()
//        }
//    }
//    
//    func addObject(_ object: RLLottieView)
//    {
//        if displayLink == nil {
//            startAnimationLoop()
//        }
//        stickerObjects.insert(object)
//    }
//    
//    func cleanup(_ object: RLLottieView)
//    {
//        stickerObjects.remove(object)
//    }
//}
//
//
////final class StickerContentView: UIView
////{
//////    var stickerView: UIView = UIView()
////    var stickerAnimationView: LottieAnimationView!
//////    var stickerAnimationView: LottieAnimationView = LottieAnimationView()
////
////    convenience init()
////    {
////        self.init(frame: .zero)
////        setupSticker()
////    }
////
////    private func setupSticker()
////    {
////        self.stickerAnimationView = LottieAnimationView(configuration: .init(renderingEngine: .mainThread))
////        addSubview(stickerAnimationView)
//////        stickerAnimationView.backgroundColor = .red
////        stickerAnimationView.translatesAutoresizingMaskIntoConstraints = false
////
////        NSLayoutConstraint.activate([
////            stickerAnimationView.topAnchor.constraint(equalTo: topAnchor),
////            stickerAnimationView.trailingAnchor.constraint(equalTo: trailingAnchor),
////            stickerAnimationView.bottomAnchor.constraint(equalTo: bottomAnchor),
////            stickerAnimationView.heightAnchor.constraint(equalToConstant: 170),
////            stickerAnimationView.widthAnchor.constraint(equalTo: stickerAnimationView.heightAnchor),
////        ])
////    }
////
////    func configure(withStickerPath path: String)
////    {
//////        executeAfter(seconds: 0.1) { [weak self] in
//////            let leaty = LottieAnimationLayer(animation: LottieAnimation.named(path))
//////            leaty.animation = LottieAnimation.named(path)
//////            self?.stickerAnimationView.animation = LottieAnimation.named(path)
//////            self?.stickerAnimationView.contentMode = .scaleAspectFit
//////            self?.stickerAnimationView.loopMode = .loop
//////            self?.stickerAnimationView.play()
//////        }
////
//////        DispatchQueue.global(qos: .userInitiated).async
//////        {
//////            if let path = Bundle.main.path(forResource: path, ofType: "json"),
//////               let data = try? Data(contentsOf: URL(fileURLWithPath: path)),
//////               let animation = try? LottieAnimation.from(data: data) {
//////
//////                // Step 2 — Switch to main thread to display
////////                mainQueue { [weak self] in
//////                    mainQueue { [weak self] in
//////                        self?.stickerAnimationView.animation = animation
//////                        self?.stickerAnimationView.loopMode = .loop
////////                        self?.stickerAnimationView.play()
//////                        executeAfter(seconds: 0.5) { [weak self] in
//////                            self?.stickerAnimationView.play()
//////                        }
//////                    }
//////                    //                    self?.stickerAnimationView.animationSpeed = 0.8
//////                    //                    self?.stickerAnimationView.mainThreadRenderingEngineShouldForceDisplayUpdateOnEachFrame = false
////////                }
//////            }
//////        }
////
////        stickerAnimationView.animation = LottieAnimation.named(path)
////        stickerAnimationView.contentMode = .scaleAspectFit
////        stickerAnimationView.loopMode = .loop
////
////        executeAfter(seconds: 0.5) { [weak self] in
////            self?.stickerAnimationView.play()
////        }
////    }
////
//////    var lottieLayer = LottieAnimationLayer()
////
////    func cleanup()
////    {
////        stickerAnimationView?.stop()
////        stickerAnimationView?.currentProgress = 1
////        stickerAnimationView?.animation = nil
////        stickerAnimationView = nil
////
////    }
////
////    deinit {
////        print("sticker view deinit")
////        cleanup()
////    }
////}
