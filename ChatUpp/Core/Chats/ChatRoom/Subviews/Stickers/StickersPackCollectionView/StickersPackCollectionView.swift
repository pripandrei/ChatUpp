//
//  StickersCollectionView_test.swift
//  ChatUpp
//
//  Created by Andrei Pripa on 9/21/25.
//

import UIKit

struct StickerPackSection
{
    let title: String
    let stickers: [String]
}

// MARK: - StickersCollectionView
final class StickersPackCollectionView: UIView
{
    private let stickerSections: [StickerPackSection] = {
        return Stickers.Category.allCases
            .map { category in
                let stickers = category.pack.map { $0 }
                return StickerPackSection(title: category.title, stickers: stickers)
            }
    }()
    
    private var collectionView: UICollectionView!

    override init(frame: CGRect)
    {
        super.init(frame: frame)
        backgroundColor = #colorLiteral(red: 0.1839679778, green: 0.1356598437, blue: 0.1883102357, alpha: 1)
        layer.borderWidth = 1.0
//        layer.borderColor = #colorLiteral(red: 0.470990181, green: 0.3475213647, blue: 0.4823801517, alpha: 1)
        layer.borderColor = #colorLiteral(red: 0.4230892658, green: 0.2921444178, blue: 0.4381959736, alpha: 1)
        layer.cornerRadius = 20
        clipsToBounds = true
        setupCollectionView()
    }

    required init?(coder: NSCoder) {
        fatalError("Could not init stickerView")
    }

    deinit {
//        stopAnimationLoop()
//
//        /// See FootNote.swift - [14]
//        let sections = stickerSections
//        Task {
//            await StickerAnimationManager.shared.destroyAnimation
//            {
//                for section in sections
//                {
//                    section.items.forEach { $0.destroyAnimation() }
//                }
//            }
//        }
//        print("Sticker collection DEINIT")
    }

    private func setupCollectionView()
    {
        let layout = makeLayout()
        collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.backgroundColor = .clear
        collectionView.verticalScrollIndicatorInsets = UIEdgeInsets(top: 10, left: 0, bottom: 10, right: 0)
        collectionView.dataSource = self
        collectionView.delegate = self
        collectionView.register(StickersPackCell.self, forCellWithReuseIdentifier: StickersPackCell.reuseID)
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
    
    private func makeLayout() -> UICollectionViewLayout
    {
        let spacing: CGFloat = 10
        let columns: CGFloat = 4

        // ITEM (explicit width per column)
        let itemSize = NSCollectionLayoutSize(
            widthDimension: .fractionalWidth(1.0 / columns),
            heightDimension: .fractionalWidth(1.0 / columns)
        )
        let item = NSCollectionLayoutItem(layoutSize: itemSize)
        item.contentInsets = NSDirectionalEdgeInsets(
            top: spacing / 2,
            leading: spacing / 2,
            bottom: spacing / 2,
            trailing: spacing / 2
        )

        // GROUP (single row)
        let groupSize = NSCollectionLayoutSize(
            widthDimension: .fractionalWidth(1.0),
            heightDimension: .fractionalWidth(1.0 / columns)
        )
        let group = NSCollectionLayoutGroup.horizontal(
            layoutSize: groupSize,
            subitems: [item]
        )

        // SECTION
        let section = NSCollectionLayoutSection(group: group)
        section.contentInsets = NSDirectionalEdgeInsets(
            top: 0,
            leading: spacing,
            bottom: 0,
            trailing: spacing
        )
        
        // HEADER
        let headerSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0),
                                                heightDimension: .absolute(40))
        
        let header = NSCollectionLayoutBoundarySupplementaryItem(layoutSize: headerSize,
                                                                 elementKind: UICollectionView.elementKindSectionHeader,
                                                                 alignment: .top)
        
        section.boundarySupplementaryItems = [header]
        
        return UICollectionViewCompositionalLayout(section: section)
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
        return stickerSections[section].stickers.count
    }

    func collectionView(_ collectionView: UICollectionView,
                        cellForItemAt indexPath: IndexPath) -> UICollectionViewCell
    {
        let cell = collectionView.dequeueReusableCell(
            withReuseIdentifier: StickersPackCell.reuseID,
            for: indexPath
        ) as! StickersPackCell
        
        let stickerName = self.stickerSections[indexPath.section].stickers[indexPath.item]
        cell.configure(name: stickerName)
        
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
    
//    func collectionView(_ collectionView: UICollectionView,
//                        layout collectionViewLayout: UICollectionViewLayout,
//                        referenceSizeForHeaderInSection section: Int) -> CGSize
//    {
//        return CGSize(width: collectionView.frame.width, height: 40.0)
//    }
}

// MARK: - Delegate
//
//extension StickersPackCollectionView: UICollectionViewDelegateFlowLayout
extension StickersPackCollectionView: UICollectionViewDelegate
{
    func collectionView(
        _ collectionView: UICollectionView,
        willDisplay cell: UICollectionViewCell,
        forItemAt indexPath: IndexPath)
    {
        (cell as? StickersPackCell)?.setVisible(true)
    }

    func collectionView(
        _ collectionView: UICollectionView,
        didEndDisplaying cell: UICollectionViewCell,
        forItemAt indexPath: IndexPath)
    {
        (cell as? StickersPackCell)?.setVisible(false)
    }
    
    func collectionView(
        _ collectionView: UICollectionView,
        didSelectItemAt indexPath: IndexPath
    )
    {
        collectionView.deselectItem(at: indexPath, animated: false)
        
        let stickerName = self.stickerSections[indexPath.section].stickers[indexPath.item]
        ChatManager.shared.newStickerSubject.send(stickerName)
    }
}
