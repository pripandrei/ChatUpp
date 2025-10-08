//
//  InputBarContainer.swift
//  ChatUpp
//
//  Created by Andrei Pripa on 1/18/25.
//

import UIKit

final class InputBarContainer: UIView {

    // MARK: - Properties
    private var blurEffectView: UIVisualEffectView!

    // MARK: - Init
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupView()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Setup
    private func setupView()
    {
        bounds.size.height                        = 80
        translatesAutoresizingMaskIntoConstraints = false
        backgroundColor = .clear  // Let blur show through
        createBackgroundBlurEffect()
    }

    private func createBackgroundBlurEffect()
    {
        let blurEffect = UIBlurEffect(style: .systemMaterialDark)
        blurEffectView = UIVisualEffectView(effect: blurEffect)
        blurEffectView.translatesAutoresizingMaskIntoConstraints = false
        blurEffectView.backgroundColor = #colorLiteral(red: 0.3078631759, green: 0.1839652359, blue: 0.3157553673, alpha: 1).withAlphaComponent(0.6)
        insertSubview(blurEffectView, at: 0)

        NSLayoutConstraint.activate([
            blurEffectView.topAnchor.constraint(equalTo: topAnchor),
            blurEffectView.leadingAnchor.constraint(equalTo: leadingAnchor),
            blurEffectView.trailingAnchor.constraint(equalTo: trailingAnchor),
            blurEffectView.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])
    }
}

// MARK: - Hit Testing Override
extension InputBarContainer
{
    /// Allows touches on subviews that are visually outside this view’s frame
    ///
    override func point(inside point: CGPoint, with event: UIEvent?) -> Bool {
        if super.point(inside: point, with: event) { return true }

        for subview in subviews {
            let convertedPoint = subview.convert(point, from: self)
            if subview.point(inside: convertedPoint, with: event) {
                return true
            }
        }
        return false
    }
}
