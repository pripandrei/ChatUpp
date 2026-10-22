//
//  MessageMenuCardView.swift
//  ChatUpp
//
//  Created by Andrei Pripa on 10/22/26.
//

import UIKit

/// A static re-creation of the system context-menu card: a dark blurred,
/// rounded bar of rows (each with a leading symbol and a title), separated
/// by hairlines between row groups. Rows run their action and then notify
/// the owner so the overlay can be dismissed.
///
/// On iOS 26+ the card is real Liquid Glass (`UIGlassEffect`) with
/// `isInteractive` on, so the glass responds to touches (press / bend) -
/// which requires the rows to live inside the effect view's `contentView`,
/// the only hierarchy through which the glass receives touch events.
final class MessageMenuCardView: UIView
{
    static let rowHeight: CGFloat = 48.0
    static let cornerRadius: CGFloat = 26.0
    private static let separatorHeight: CGFloat = 0.5
    /// min / max card width the title measurement can land between
    static let minimalWidth: CGFloat = 260.0

    /// Invoked every time one of the rows completes its action; the
    /// presenter uses it to dismiss the overlay.
    var onSelectionHandled: (() -> Void)?

    private let optionGroups: [[MessageMenuOption]]
    private let rowsStack = UIStackView()
    private var rows: [MenuRowView] = []
    /// The row currently highlighted by the finger while it slides across
    /// the rows; on lift, this row's selection is performed.
    private var pressedRow: MenuRowView?

    private lazy var selectionTracker: UILongPressGestureRecognizer =
    {
        let tracker = UILongPressGestureRecognizer(target: self,
                                                   action: #selector(handleSelectionTracker(_:)))
        tracker.minimumPressDuration = 0.01
        /// touches keep flowing into the glass hierarchy while the finger
        /// presses / slides, so interactive Liquid Glass underneath can keep
        /// reacting; the rows are plain views and do nothing on their own
        tracker.cancelsTouchesInView = false
        return tracker
    }()

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
        addGestureRecognizer(selectionTracker)
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

        // 20pt leading icon inset + 24pt icon slot + gap + trailing inset
        let contentWidth = 20.0 + 24.0 + 14.0 + maxTitleWidth + 22.0
        let width = min(320.0, max(Self.minimalWidth, contentWidth))
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

    /// Liquid Glass on iOS 26+, dark blurred material below.
    static func menuEffect() -> UIVisualEffect
    {
        if #available(iOS 26.0, *)
        {
            let glass = UIGlassEffect(style: .regular)
            glass.isInteractive = true
            /// Matches the system context-menu fill (the reference menu): a
            /// near-opaque dark plum surface, while the edges keep the glass
            /// refraction. Untinted glass reads far too transparent when it
            /// sits over bright message bubbles.
            glass.tintColor = UIColor(
                red: 44.0 / 255.0,
                green: 38.0 / 255.0,
                blue: 47.0 / 255.0,
                alpha: 0.92)
            return glass
        }
        return UIBlurEffect(style: .systemThickMaterialDark)
    }

    /// Whether the menu card renders Apple's Liquid Glass material.
    static var usesGlassEffect: Bool
    {
        if #available(iOS 26.0, *) { return true }
        return false
    }

    private func setupContent()
    {
        let effectView = UIVisualEffectView(effect: Self.menuEffect())
        effectView.layer.cornerRadius = Self.cornerRadius
        effectView.layer.masksToBounds = true
        effectView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(effectView)

        /// On <26 the dark material needs a slight dark tint to match the
        /// reference menu. On 26+ the Liquid Glass material already picks its
        /// depth from the blurred room behind the card - an extra dark layer
        /// would dull the refraction, so the glass stays untinted.
        if !Self.usesGlassEffect
        {
            let darkTint = UIView()
            darkTint.backgroundColor = .black
            darkTint.layer.cornerRadius = Self.cornerRadius
            darkTint.layer.masksToBounds = true
            darkTint.alpha = 0.2
            darkTint.translatesAutoresizingMaskIntoConstraints = false
            self.addSubview(darkTint)
            NSLayoutConstraint.activate([
                darkTint.leadingAnchor.constraint(equalTo: leadingAnchor),
                darkTint.trailingAnchor.constraint(equalTo: trailingAnchor),
                darkTint.topAnchor.constraint(equalTo: topAnchor),
                darkTint.bottomAnchor.constraint(equalTo: bottomAnchor),
            ])
        }

        /// Rows live inside the effect view's `contentView` (UIKit's
        /// sanctioned hierarchy) so that interactive glass - and the blurred
        /// material alike - remain the touch-owning visual layer underneath
        /// the rows.
        let rowsStack = self.rowsStack
        rowsStack.axis = .vertical
        rowsStack.alignment = .fill
        rowsStack.distribution = .fill
        rowsStack.layer.cornerRadius = Self.cornerRadius
        rowsStack.layer.masksToBounds = true
        rowsStack.translatesAutoresizingMaskIntoConstraints = false
        effectView.contentView.addSubview(rowsStack)

        NSLayoutConstraint.activate([
            effectView.leadingAnchor.constraint(equalTo: leadingAnchor),
            effectView.trailingAnchor.constraint(equalTo: trailingAnchor),
            effectView.topAnchor.constraint(equalTo: topAnchor),
            effectView.bottomAnchor.constraint(equalTo: bottomAnchor),

            rowsStack.leadingAnchor.constraint(equalTo: effectView.contentView.leadingAnchor),
            rowsStack.trailingAnchor.constraint(equalTo: effectView.contentView.trailingAnchor),
            rowsStack.topAnchor.constraint(equalTo: effectView.contentView.topAnchor),
            rowsStack.bottomAnchor.constraint(equalTo: effectView.contentView.bottomAnchor),
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
                rows.append(row)
                rowsStack.addArrangedSubview(row)
            }
        }
    }

    // MARK: Drag-select tracking

    /// While the finger is pressed the selection follows it across the rows
    /// (system context-menu behavior): highlight switches on slide, clears
    /// when the finger leaves the rows, and the row under the finger on lift
    /// runs its action.
    @objc private func handleSelectionTracker(_ tracker: UILongPressGestureRecognizer)
    {
        let locationInCard = tracker.location(in: self)

        switch tracker.state
        {
        case .began, .changed:
            setPressedRow(rowAtPoint(locationInCard))
        case .ended:
            let selectedRow = pressedRow
            setPressedRow(nil)
            selectedRow?.performSelection()
        case .cancelled, .failed:
            setPressedRow(nil)
        default:
            break
        }
    }

    private func rowAtPoint(_ pointInCard: CGPoint) -> MenuRowView?
    {
        let pointInStack = rowsStack.convert(pointInCard, from: self)
        return rows.first { $0.frame.contains(pointInStack) }
    }

    private func setPressedRow(_ row: MenuRowView?)
    {
        guard row !== pressedRow else { return }
        pressedRow?.setPressed(false)
        pressedRow = row
        pressedRow?.setPressed(true)
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
