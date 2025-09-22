//
//  StickersCollectionView_test.swift
//  ChatUpp
//
//  Created by Andrei Pripa on 9/21/25.
//

import UIKit
import librlottie

// MARK: - StickersCollectionView
final class StickersPackCollectionView: UIView
{
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

        /// See FootNote.swift - [14]
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

    override func layoutSubviews()
    {
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

    @objc private func renderFrame()
    {
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

// MARK: - DataSource

extension StickersPackCollectionView: UICollectionViewDataSource {
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

// MARK: - Delegate

extension StickersPackCollectionView: UICollectionViewDelegateFlowLayout {
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
