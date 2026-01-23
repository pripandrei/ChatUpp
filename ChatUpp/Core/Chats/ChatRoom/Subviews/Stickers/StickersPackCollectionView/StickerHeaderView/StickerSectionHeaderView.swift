//
//  StickerSectionHeaderView.swift
//  ChatUpp
//
//  Created by Andrei Pripa on 9/27/25.
//

import UIKit

class StickerSectionHeaderView: UICollectionReusableView
{
    static let reuseIdentifier = "StickerSectionHeaderView"

    private let titleLabel: UILabel = {
        let label = UILabel()
        label.textColor = .gray
        label.font = .boldSystemFont(ofSize: 16)
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    override init(frame: CGRect)
    {
        super.init(frame: frame)
        
        addSubview(titleLabel)
        
        NSLayoutConstraint.activate([
            titleLabel.centerYAnchor.constraint(equalTo: centerYAnchor),
            titleLabel.centerXAnchor.constraint(equalTo: centerXAnchor)
        ])
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func configure(title: String)
    {
        titleLabel.text = title.uppercased()
    }
}
