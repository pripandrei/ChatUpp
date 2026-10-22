//
//  MessageMenuCardView.swift
//  ChatUpp
//
//  Created by Andrei Pripa on 10/22/26.
//

import UIKit

/// A static re-creation of the system context-menu card: a dark blurred,
/// rounded bar of rows (each with a title and a trailing symbol), separated
/// by hairlines between row groups. Rows run their action and then notify
/// the owner so the overlay can be dismissed.
final class MessageMenuCardView: UIView
{
    static let rowHeight: CGFloat = 44.0
    static let cornerRadius: CGFloat = 12.0
    private static let separatorHeight: CGFloat = 0.5

    /// Invoked every time one of the rows completes its action; the
    /// presenter uses it to dismiss the overlay.
    var onSelectionHandled: (() -> Void)?

    private let optionGroups: [[MessageMenuOption]]

    convenience init(frame: CGRect, optionGroups: [[MessageMenuOption]])
    {
        self.init(optionGroups: optionGroups)
        self.frame = frame
    }

    init(optionGroups: [[MessageMenuOption]])
    {
        self.optionGroups = optionGroups
        super.init(frame: .zero)
        backgroundColor = .clear
        setupShadow()
        setupContent()
    }

    required init?(coder: NSCoder)
    {
        fatalError("init(coder:) has not been implemented")
    }

    /// The size the card needs for its rows: width comes from the widest
    /// title (clamped to look like the system card), height from the rows
    /// and the separators between groups.
    static func preferredSize(for optionGroups: [[MessageMenuOption]]) -> CGSize
    {
        let font = UIFont.systemFont(ofSize: 17)

        var rowCount = 0
        var maxTitleWidth: CGFloat = 0
        for group in optionGroups
        {
            rowCount += group.count
            for option in group
            {
                let titleWidth = (option.title as NSString)
                    .size(withAttributes: [.font: font]).width
                maxTitleWidth = max(maxTitleWidth, ceil(titleWidth))
            }
        }

        // 16pt leading title inset + gap + 24pt icon slot + 14pt trailing inset
        let contentWidth = 16.0 + maxTitleWidth + 10.0 + 24.0 + 14.0
        let width = min(320.0, max(230.0, contentWidth))
        let height = CGFloat(rowCount) * rowHeight
            + CGFloat(max(optionGroups.count - 1, 0)) * separatorHeight
        return CGSize(width: width, height: height)
    }

    // MARK: Private setup

    private func setupShadow()
    {
        layer.shadowColor = UIColor.black.cgColor
        layer.shadowOpacity = 0.3
        layer.shadowOffset = CGSize(width: 0, height: 8)
        layer.shadowRadius = 24
    }

    private func setupContent()
    {
        let effectView = UIVisualEffectView(effect: UIBlurEffect(style: .systemThickMaterialDark))
        effectView.layer.cornerRadius = Self.cornerRadius
        effectView.layer.masksToBounds = true
        effectView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(effectView)

        let rowsStack = UIStackView()
        rowsStack.axis = .vertical
        rowsStack.alignment = .fill
        rowsStack.distribution = .fill
        rowsStack.layer.cornerRadius = Self.cornerRadius
        rowsStack.layer.masksToBounds = true
        rowsStack.translatesAutoresizingMaskIntoConstraints = false
        addSubview(rowsStack)

        NSLayoutConstraint.activate([
            effectView.leadingAnchor.constraint(equalTo: leadingAnchor),
            effectView.trailingAnchor.constraint(equalTo: trailingAnchor),
            effectView.topAnchor.constraint(equalTo: topAnchor),
            effectView.bottomAnchor.constraint(equalTo: bottomAnchor),

            rowsStack.leadingAnchor.constraint(equalTo: leadingAnchor),
            rowsStack.trailingAnchor.constraint(equalTo: trailingAnchor),
            rowsStack.topAnchor.constraint(equalTo: topAnchor),
            rowsStack.bottomAnchor.constraint(equalTo: bottomAnchor),
        ])

        for (groupIndex, group) in optionGroups.enumerated()
        {
            if groupIndex > 0
            {
                rowsStack.addArrangedSubview(makeSeparatorView())
            }
            for option in group
            {
                let row = MenuRowView(option: option, rowHeight: Self.rowHeight)
                row.onRowTapped = { [weak self] in
                    guard let self else { return }
                    self.onSelectionHandled?()
                }
                rowsStack.addArrangedSubview(row)
            }
        }
    }

    private func makeSeparatorView() -> UIView
    {
        let separator = UIView()
        separator.backgroundColor = UIColor.white.withAlphaComponent(0.16)
        separator.translatesAutoresizingMaskIntoConstraints = false
        separator.heightAnchor.constraint(equalToConstant: Self.separatorHeight).isActive = true
        return separator
    }
}
