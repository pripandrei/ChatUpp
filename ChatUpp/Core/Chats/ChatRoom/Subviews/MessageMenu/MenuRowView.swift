//
//  MenuRowView.swift
//  ChatUpp
//
//  Created by Andrei Pripa on 10/22/26.
//

import UIKit

/// One visual row inside `MessageMenuCardView`: a leading symbol + title,
/// with a translucent highlight while press-selected.
///
/// It is intentionally a plain view, not a control: selection is gesture
/// driven at the card level (the finger may slide across rows while pressed,
/// like a system context menu), and `MessageMenuCardView` keeps the
/// selection tracker's touches flowing into the glass hierarchy so Liquid
/// Glass keeps its interactive behavior underneath the rows.
final class MenuRowView: UIView
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
        highlightOverlay.alpha = 0
        highlightOverlay.translatesAutoresizingMaskIntoConstraints = false
        addSubview(highlightOverlay)

        let titleLabel = UILabel()
        titleLabel.text = option.title
        titleLabel.font = .systemFont(ofSize: 18)
        titleLabel.textColor = option.isDestructive ? .systemRed : .white
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        addSubview(titleLabel)

        let iconView = UIImageView(image: option.image?.withConfiguration(
            UIImage.SymbolConfiguration(pointSize: 18, weight: .medium)))
        iconView.tintColor = option.isDestructive ? .systemRed : .white
        /// .center: the symbol renders at its configured point size. (.scaleAspectFit
        /// upscales any smaller glyph back to the slot size, hiding pointSize changes)
        iconView.contentMode = .center
        iconView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(iconView)

        NSLayoutConstraint.activate([
            iconView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 26),
            iconView.centerYAnchor.constraint(equalTo: centerYAnchor),
            iconView.widthAnchor.constraint(equalToConstant: 24),
            iconView.heightAnchor.constraint(equalToConstant: 24),

            titleLabel.leadingAnchor.constraint(equalTo: iconView.trailingAnchor, constant: 14),
            titleLabel.centerYAnchor.constraint(equalTo: centerYAnchor),
            titleLabel.trailingAnchor.constraint(lessThanOrEqualTo: trailingAnchor, constant: -28),

            highlightOverlay.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 10),
            highlightOverlay.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -10),
            highlightOverlay.topAnchor.constraint(equalTo: topAnchor, constant: 1),
            highlightOverlay.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -1),
        ])
    }

    required init?(coder: NSCoder)
    {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews()
    {
        super.layoutSubviews()
        /// the highlight is a full pill: radius is half its height, which is
        /// the maximum rounding for the given row size
        highlightOverlay.layer.cornerRadius = highlightOverlay.bounds.height / 2
    }

    /// Drives the highlight from the card's selection tracker.
    func setPressed(_ pressed: Bool)
    {
        UIView.animate(withDuration: 0.12)
        {
            self.highlightOverlay.alpha = pressed ? 0.1 : 0
        }
    }

    /// Runs the option's side effect and notifies the card.
    func performSelection()
    {
        option.action()
        onRowTapped?()
    }
}
