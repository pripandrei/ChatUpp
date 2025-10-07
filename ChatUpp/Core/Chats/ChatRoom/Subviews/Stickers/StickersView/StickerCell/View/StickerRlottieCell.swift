//
//  StickerRlottieCell.swift
//  ChatUpp
//
//  Created by Andrei Pripa on 9/22/25.
//

import UIKit

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
