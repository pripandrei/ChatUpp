//
//  ContainerView.swift
//  ChatUpp
//
//  Created by Andrei Pripa on 8/14/25.
//

import UIKit

class ContainerView: UIView {

    var spacing: CGFloat = .zero
    private var arrangedViews: [(view: UIView, padding: UIEdgeInsets)] = []
    private var arrangedConstraints: [NSLayoutConstraint] = []

//    init()
//    {
//        super.init(frame: .zero)
//        translatesAutoresizingMaskIntoConstraints = false
//    }
    
    init(spacing: CGFloat = 0, margin: UIEdgeInsets = .zero)
    {
        super.init(frame: .zero)
        self.spacing = spacing
        self.margins = margin
        translatesAutoresizingMaskIntoConstraints = false
    }
    
//    convenience init(spacing: CGFloat = 0, margin: UIEdgeInsets = .zero)
//    {
//        self.init()
//        self.spacing = spacing
//        self.margins = margin
//    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    var margins: UIEdgeInsets = .zero {
        didSet { updateConstraintsForArrangedViews() }
    }

    // MARK: - Add View
    func addArrangedSubview(_ view: UIView, padding: UIEdgeInsets = .zero, at index: Int? = nil)
    {
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
    func removeArrangedSubview(_ view: UIView)
    {
        if let index = arrangedViews.firstIndex(where: { $0.view == view }) {
            arrangedViews.remove(at: index)
            view.removeFromSuperview()
            updateConstraintsForArrangedViews()
            print("reply is removed")
        }
    }
    
    // MARK: - Update Padding
    func updatePadding(for view: UIView, padding: UIEdgeInsets) {
        if let index = arrangedViews.firstIndex(where: { $0.view == view }) {
            arrangedViews[index].padding = padding
            updateConstraintsForArrangedViews()
        }
    }
    
    //    // MARK: - Layout
    private func updateConstraintsForArrangedViews()
    {
        /// Remove only constraints created for arranged views
        /// (dont touch constraints of view that were added via addSubview)
        NSLayoutConstraint.deactivate(arrangedConstraints)
        arrangedConstraints.removeAll()
        
        var previousView: (view: UIView, padding: UIEdgeInsets)?

        for (index, pair) in arrangedViews.enumerated() {
            let view = pair.view
            let padding = pair.padding
            
            // Horizontal constraints (left/right)
            arrangedConstraints.append(contentsOf: [
                view.leadingAnchor.constraint(equalTo: leadingAnchor, constant: margins.left + padding.left),
                view.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -(margins.right + padding.right))
            ])
            
            // Vertical constraints
            if let prev = previousView {
                // ✅ include BOTH previous bottom padding + current top padding
                let verticalGap = spacing + prev.padding.bottom + padding.top
                let top = view.topAnchor.constraint(equalTo: prev.view.bottomAnchor, constant: verticalGap)
                arrangedConstraints.append(top)
            } else {
                // First view
                let top = view.topAnchor.constraint(equalTo: topAnchor, constant: margins.top + padding.top)
                arrangedConstraints.append(top)
            }
            
            // If this is the last view, pin its bottom as well
            if index == arrangedViews.count - 1 {
                let bottom = view.bottomAnchor.constraint(equalTo: bottomAnchor,
                                                          constant: -(margins.bottom + padding.bottom))
                arrangedConstraints.append(bottom)
            }
            
            previousView = pair
        }
        
        NSLayoutConstraint.activate(arrangedConstraints)
    }

//    // MARK: - Layout
//    private func updateConstraintsForArrangedViews()
//    {
//        /// Remove only constraints created for arranged views
//        /// (dont touch constraints of view that were added via addSubview)
//        NSLayoutConstraint.deactivate(arrangedConstraints)
//        arrangedConstraints.removeAll()
//        
//        var previousView: UIView?
//        
//        for (view, localPadding) in arrangedViews
//        {
//            let totalPadding = UIEdgeInsets(
//                top: margins.top + localPadding.top,
//                left: margins.left + localPadding.left,
//                bottom: margins.bottom + localPadding.bottom,
//                right: margins.right + localPadding.right
//            )
//            
//            let leading = view.leadingAnchor.constraint(equalTo: leadingAnchor, constant: totalPadding.left)
//            let trailing = view.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -totalPadding.right)
//            arrangedConstraints.append(contentsOf: [leading, trailing])
//            
//            if let prev = previousView {
//                let top = view.topAnchor.constraint(equalTo: prev.bottomAnchor, constant: spacing)
//                arrangedConstraints.append(top)
//            } else {
//                let top = view.topAnchor.constraint(equalTo: topAnchor, constant: totalPadding.top)
//                arrangedConstraints.append(top)
//            }
//            
//            previousView = view
//        }
//        
//        if let last = previousView, let lastPadding = arrangedViews.last?.padding {
//            let totalBottomPadding = margins.bottom + lastPadding.bottom
//            let bottom = last.bottomAnchor.constraint(lessThanOrEqualTo: bottomAnchor, constant: -totalBottomPadding)
//            arrangedConstraints.append(bottom)
//        }
//        
//        NSLayoutConstraint.activate(arrangedConstraints)
//    }
}

