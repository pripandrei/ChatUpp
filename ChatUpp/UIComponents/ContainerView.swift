//
//  ContainerView.swift
//  ChatUpp
//
//  Created by Andrei Pripa on 8/14/25.
//

import UIKit

class ContainerView: UIView {

    private var spacing: CGFloat
    private var arrangedViews: [(view: UIView, padding: UIEdgeInsets)] = []
    private var arrangedConstraints: [NSLayoutConstraint] = []

    init(spacing: CGFloat = 3) {
        self.spacing = spacing
        super.init(frame: .zero)
        translatesAutoresizingMaskIntoConstraints = false
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Add View
    func addArrangedSubview(_ view: UIView, padding: UIEdgeInsets = .zero, at index: Int? = nil) {
        view.translatesAutoresizingMaskIntoConstraints = false
        addSubview(view)

        if let index = index, index >= 0, index <= arrangedViews.count {
            arrangedViews.insert((view, padding), at: index)
        } else {
            arrangedViews.append((view, padding))
        }

        updateConstraintsForArrangedViews()
    }

    // MARK: - Remove View
    func removeArrangedSubview(_ view: UIView) {
        if let index = arrangedViews.firstIndex(where: { $0.view == view }) {
            arrangedViews.remove(at: index)
            view.removeFromSuperview()
            updateConstraintsForArrangedViews()
        }
    }

    // MARK: - Update Padding
    func updatePadding(for view: UIView, padding: UIEdgeInsets) {
        if let index = arrangedViews.firstIndex(where: { $0.view == view }) {
            arrangedViews[index].padding = padding
            updateConstraintsForArrangedViews()
        }
    }

    // MARK: - Layout
    private func updateConstraintsForArrangedViews() {
        // Remove only constraints created for arranged views
        NSLayoutConstraint.deactivate(arrangedConstraints)
        arrangedConstraints.removeAll()

        var previousView: UIView?

        for (view, padding) in arrangedViews {
            let leading = view.leadingAnchor.constraint(equalTo: leadingAnchor, constant: padding.left)
            let trailing = view.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -padding.right)

            arrangedConstraints.append(contentsOf: [leading, trailing])

            if let prev = previousView {
                let top = view.topAnchor.constraint(equalTo: prev.bottomAnchor, constant: spacing + padding.top)
                arrangedConstraints.append(top)
            } else {
                let top = view.topAnchor.constraint(equalTo: topAnchor, constant: padding.top)
                arrangedConstraints.append(top)
            }

            previousView = view
        }

        // Last view bottom constraint
        if let last = previousView, let lastPadding = arrangedViews.last?.padding {
            let bottom = last.bottomAnchor.constraint(lessThanOrEqualTo: bottomAnchor, constant: -lastPadding.bottom)
            arrangedConstraints.append(bottom)
        }

        NSLayoutConstraint.activate(arrangedConstraints)
    }
}

