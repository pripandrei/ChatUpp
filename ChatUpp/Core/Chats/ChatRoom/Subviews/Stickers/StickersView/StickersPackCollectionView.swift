//
//  StickersCollectionView_test.swift
//  ChatUpp
//
//  Created by Andrei Pripa on 9/21/25.
//

import UIKit
import librlottie

struct StickerPackSection
{
    let title: String
    let items: [StickerRLottieCellViewModel]
}

// MARK: - StickersCollectionView
final class StickersPackCollectionView: UIView
{
    private let stickerSections: [StickerPackSection] = {
        return Stickers.Category.allCases
            .map { category in
                if category.title == "Duck" {
                    print("Stop")
                }
                let stickers = category.pack.map { StickerRLottieCellViewModel(stickerName: $0.deletingPathExtension().lastPathComponent) }
                return StickerPackSection(title: category.title, items: stickers)
            }
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
        let sections = stickerSections
        Task {
            await StickerAnimationManager.shared.destroyAnimation
            {
                for section in sections
                {
                    section.items.forEach { $0.destroyAnimation() }
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
            layout.sectionInset = UIEdgeInsets(top: 0,
                                               left: spacing,
                                               bottom: 0,
                                               right: spacing)
        }
    }

    private func setupCollectionView()
    {
        let layout = UICollectionViewFlowLayout()
        collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.backgroundColor = .clear
        collectionView.dataSource = self
        collectionView.delegate = self
        collectionView.register(StickerRLottieCell.self, forCellWithReuseIdentifier: StickerRLottieCell.identifier)
        collectionView.register(StickerSectionHeaderView.self,
                                forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader,
                                withReuseIdentifier: StickerSectionHeaderView.reuseIdentifier)

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

extension StickersPackCollectionView: UICollectionViewDataSource
{
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return stickerSections.count
    }
    
    func collectionView(_ collectionView: UICollectionView,
                        numberOfItemsInSection section: Int) -> Int
    {
        return stickerSections[section].items.count
    }

    func collectionView(_ collectionView: UICollectionView,
                        cellForItemAt indexPath: IndexPath) -> UICollectionViewCell
    {
        let cell = collectionView.dequeueReusableCell(
            withReuseIdentifier: StickerRLottieCell.identifier,
            for: indexPath
        ) as! StickerRLottieCell
        
        let vm = self.stickerSections[indexPath.section].items[indexPath.item]
        cell.configure(withViewModel: vm)
        
        return cell
    }
    
    // Header view
    //
    func collectionView(_ collectionView: UICollectionView,
                        viewForSupplementaryElementOfKind kind: String,
                        at indexPath: IndexPath) -> UICollectionReusableView
    {
        guard kind == UICollectionView.elementKindSectionHeader else {
            return UICollectionReusableView()
        }
        
        if let supplementaryView = collectionView.dequeueReusableSupplementaryView(
            ofKind: kind,
            withReuseIdentifier: StickerSectionHeaderView.reuseIdentifier,
            for: indexPath) as? StickerSectionHeaderView
        {
            let title = stickerSections[indexPath.section].title
            supplementaryView.configure(title: title)
            return supplementaryView
        }
        return .init()
    }
    
    func collectionView(_ collectionView: UICollectionView,
                        layout collectionViewLayout: UICollectionViewLayout,
                        referenceSizeForHeaderInSection section: Int) -> CGSize
    {
        return CGSize(width: collectionView.frame.width, height: 40.0)
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
        
        let stickerName = self.stickerSections[indexPath.section].items[indexPath.item].stickerName
        ChatManager.shared.newStickerSubject.send(stickerName)
    }
}
