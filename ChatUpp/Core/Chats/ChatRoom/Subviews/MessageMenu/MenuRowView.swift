//
//  MenuRowView.swift
//  ChatUpp
//
//  Created by Andrei Pripa on 10/22/26.
//

import UIKit

/// One tappable row inside `MessageMenuCardView`, laid out like the system
/// context menu rows: title on the leading side, symbol on the trailing side,
/// a translucent highlight while pressed.
final class MenuRowView: UIControl
{
    /// Called after the option's action ran; the card forwards it to the
    /// presenter so the overlay gets dismissed.
    var onRowTapped: (() -> Void)?

    private let option: MessageMenuOption
    private let highlightOverlay = UIView()

    init(option: MessageMenuOption, rowHeight: CGFloat)
    {
        self.option = option
        super.init(frame: .zero)
        translatesAutoresizingMaskIntoConstraints = false
        heightAnchor.constraint(equalToConstant: rowHeight).isActive = true

        highlightOverlay.backgroundColor = .white
        highlightOverlay.layer.cornerRadius = 10
        highlightOverlay.alpha = 0
        highlightOverlay.translatesAutoresizingMaskIntoConstraints = false
        addSubview(highlightOverlay)

        let titleLabel = UILabel()
        titleLabel.text = option.title
        titleLabel.font = .systemFont(ofSize: 17)
        titleLabel.textColor = option.isDestructive ? .systemRed : .white
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        addSubview(titleLabel)

        let iconView = UIImageView(image: option.image?.withConfiguration(
            UIImage.SymbolConfiguration(pointSize: 17, weight: .medium)))
        iconView.tintColor = option.isDestructive ? .systemRed : .secondaryLabel
        iconView.contentMode = .scaleAspectFit
        iconView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(iconView)

        NSLayoutConstraint.activate([
            titleLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
            titleLabel.centerYAnchor.constraint(equalTo: centerYAnchor),

            iconView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -14),
            iconView.centerYAnchor.constraint(equalTo: centerYAnchor),
            iconView.widthAnchor.constraint(equalToConstant: 24),
            iconView.heightAnchor.constraint(equalToConstant: 24),

            highlightOverlay.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 4),
            highlightOverlay.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -4),
            highlightOverlay.topAnchor.constraint(equalTo: topAnchor, constant: 1),
            highlightOverlay.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -1),
        ])

        addTarget(self, action: #selector(rowTapped), for: .touchUpInside)
    }

    required init?(coder: NSCoder)
    {
        fatalError("init(coder:) has not been implemented")
    }

    override var isHighlighted: Bool
    {
        didSet
        {
            UIView.animate(withDuration: 0.12)
            {
                self.highlightOverlay.alpha = self.isHighlighted ? 0.1 : 0
            }
        }
    }

    @objc private func rowTapped()
    {
        option.action()
        onRowTapped?()
    }
}
