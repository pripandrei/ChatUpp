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
    private var blurEffectViewTopConstraint: NSLayoutConstraint?

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
        
        self.blurEffectView = addBlurEffect(style: .systemThinMaterialDark,
                                            backgroundColor: ColorScheme.inputBarMessageContainerBackgroundColor,
                                            alpha: 0.2)
        
        setupBlurEffectViewTopConstraint()
    }
    
    private func setupBlurEffectViewTopConstraint()
    {
        if let topConstraint = self.blurEffectView.constraints.first(where: { constraint in
            constraint.firstAnchor == self.blurEffectView.topAnchor &&
            constraint.secondAnchor == self.topAnchor
        }) {
            self.blurEffectViewTopConstraint = topConstraint
        }
        
        self.blurEffectViewTopConstraint = blurEffectView.superview?.constraints.first {
            ($0.firstItem as? UIView) == blurEffectView && $0.firstAttribute == .top
        }
    }
    
    func pinBlurTopConstraint(to view: UIView)
    {
        self.blurEffectViewTopConstraint?.isActive = false
        
        let topConstraint = blurEffectView.topAnchor.constraint(equalTo: view.topAnchor)
        topConstraint.isActive = true
        
        self.blurEffectViewTopConstraint = topConstraint
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
