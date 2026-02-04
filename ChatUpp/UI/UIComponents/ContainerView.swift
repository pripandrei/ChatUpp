//
//  ContainerView.swift
//  ChatUpp
//
//  Created by Andrei Pripa on 8/14/25.
//

import UIKit


class ContainerView: UIView {
    
    // MARK: - Properties
    var spacing: CGFloat = 0 {
        didSet { containerStackView.spacing = spacing }
    }
    
    var margins: UIEdgeInsets = .zero {
        didSet {
            NSLayoutConstraint.deactivate(marginConstraints)
            updateMargins()
        }
    }
    
    private(set) var containerStackView: UIStackView = {
        let stack = UIStackView()
        stack.axis = .vertical
        stack.alignment = .fill
        stack.distribution = .fill
        stack.translatesAutoresizingMaskIntoConstraints = false
        return stack
    }()
    
    private var viewPaddings: [UIView: UIEdgeInsets] = [:]
    private var marginConstraints: [NSLayoutConstraint] = []
    
    // MARK: - Init
    init(spacing: CGFloat = 0, margin: UIEdgeInsets = .zero) {
        super.init(frame: .zero)
        self.spacing = spacing
        self.margins = margin
        self.translatesAutoresizingMaskIntoConstraints = false
        setupStackView()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Setup
    private func setupStackView() {
        addSubview(containerStackView)
        updateMargins()
    }
    
    private func updateMargins() {
        marginConstraints = [
            containerStackView.topAnchor.constraint(equalTo: topAnchor, constant: margins.top),
            containerStackView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: margins.left),
            containerStackView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -margins.right),
            containerStackView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -margins.bottom)
        ]
        NSLayoutConstraint.activate(marginConstraints)
    }
    
    // MARK: - Public Methods
    func addArrangedSubview(_ view: UIView,
                            padding: UIEdgeInsets = .zero,
                            shouldFillWidth: Bool = true,
                            at index: Int? = nil)
    {
        let wrapper = createWrapper(for: view,
                                    padding: padding,
                                    shouldFillWidth: shouldFillWidth)
        
        if let index = index, index >= 0, index < containerStackView.arrangedSubviews.count {
            containerStackView.insertArrangedSubview(wrapper, at: index)
        } else {
            containerStackView.addArrangedSubview(wrapper)
        }
    }
    
    func removeArrangedSubview(_ view: UIView) {
        if let wrapper = containerStackView.arrangedSubviews.first(where: { $0.subviews.contains(view) }) {
            containerStackView.removeArrangedSubview(wrapper)
            wrapper.removeFromSuperview()
            viewPaddings.removeValue(forKey: view)
            print("view is removed")
        }
    }
    
    func updatePadding(for view: UIView, padding: UIEdgeInsets)
    {
        if let wrapper = containerStackView.arrangedSubviews.first(where: { $0.subviews.contains(view) }) {
            viewPaddings[view] = padding
            
            NSLayoutConstraint.deactivate(wrapper.constraints)
            
            // Check if this view should fill width based on its content hugging priority
            let shouldFillWidth = view.contentHuggingPriority(for: .horizontal).rawValue < UILayoutPriority.required.rawValue
            
            if shouldFillWidth {
                NSLayoutConstraint.activate([
                    view.topAnchor.constraint(equalTo: wrapper.topAnchor, constant: padding.top),
                    view.leadingAnchor.constraint(equalTo: wrapper.leadingAnchor, constant: padding.left),
                    view.trailingAnchor.constraint(equalTo: wrapper.trailingAnchor, constant: -padding.right),
                    view.bottomAnchor.constraint(equalTo: wrapper.bottomAnchor, constant: -padding.bottom)
                ])
            } else {
                NSLayoutConstraint.activate([
                    view.topAnchor.constraint(equalTo: wrapper.topAnchor, constant: padding.top),
                    view.leadingAnchor.constraint(equalTo: wrapper.leadingAnchor, constant: padding.left),
                    view.bottomAnchor.constraint(equalTo: wrapper.bottomAnchor, constant: -padding.bottom),
                    view.trailingAnchor.constraint(lessThanOrEqualTo: wrapper.trailingAnchor, constant: -padding.right)
                ])
            }
        }
    }
    
    // MARK: - Helper
    private func createWrapper(for view: UIView,
                               padding: UIEdgeInsets,
                               shouldFillWidth: Bool) -> UIView
    {
        let wrapper = UIView()
        wrapper.translatesAutoresizingMaskIntoConstraints = false
        view.translatesAutoresizingMaskIntoConstraints = false
        
        wrapper.addSubview(view)
        viewPaddings[view] = padding
        
        if shouldFillWidth {
            // View should stretch to fill available width
            NSLayoutConstraint.activate([
                view.topAnchor.constraint(equalTo: wrapper.topAnchor, constant: padding.top),
                view.leadingAnchor.constraint(equalTo: wrapper.leadingAnchor, constant: padding.left),
                view.trailingAnchor.constraint(equalTo: wrapper.trailingAnchor, constant: -padding.right),
                view.bottomAnchor.constraint(equalTo: wrapper.bottomAnchor, constant: -padding.bottom)
            ])
            
            // Allow view to stretch
            view.setContentHuggingPriority(.defaultLow, for: .horizontal)
        } else {
            // View should hug its content and align to leading
            NSLayoutConstraint.activate([
                view.topAnchor.constraint(equalTo: wrapper.topAnchor, constant: padding.top),
                view.leadingAnchor.constraint(equalTo: wrapper.leadingAnchor, constant: padding.left),
                view.bottomAnchor.constraint(equalTo: wrapper.bottomAnchor, constant: -padding.bottom),
                view.trailingAnchor.constraint(lessThanOrEqualTo: wrapper.trailingAnchor, constant: -padding.right)
            ])
            
            // Prevent view from stretching
            view.setContentHuggingPriority(.required, for: .horizontal)
        }
        
        return wrapper
    }
}
//
//class ContainerView: UIView {
//    var spacing: CGFloat = .zero
//    private var arrangedViews: [(view: UIView, padding: UIEdgeInsets)] = []
//    private var arrangedConstraints: [NSLayoutConstraint] = []
//    private var heightConstraints: [UIView: NSLayoutConstraint] = [:] // **NEW**
//    
//    // ... rest of your init code ...
//    
//    init(spacing: CGFloat = 0, margin: UIEdgeInsets = .zero)
//    {
//        super.init(frame: .zero)
//        self.spacing = spacing
//        self.margins = margin
//        translatesAutoresizingMaskIntoConstraints = false
//    }
//    
//    required init?(coder: NSCoder) {
//        fatalError("init(coder:) has not been implemented")
//    }
//    
//    var margins: UIEdgeInsets = .zero {
//        didSet { updateConstraintsForArrangedViews() }
//    }
//    
//    func updatePadding(for view: UIView, padding: UIEdgeInsets) {
//        if let index = arrangedViews.firstIndex(where: { $0.view == view }) {
//            arrangedViews[index].padding = padding
//            updateConstraintsForArrangedViews()
//        }
//    }
//    
//    func addArrangedSubview(_ view: UIView, padding: UIEdgeInsets = .zero, at index: Int? = nil) {
//        view.translatesAutoresizingMaskIntoConstraints = false
//        addSubview(view)
//        
//        // **Create and store height constraint BEFORE adding to array**
//        let height = view.intrinsicContentSize.height > 0 ? view.intrinsicContentSize.height : 44
//        let heightConstraint = view.heightAnchor.constraint(equalToConstant: height)
//        heightConstraint.priority = .init(999)
//        heightConstraint.isActive = true
//        heightConstraints[view] = heightConstraint
//        
//        if let index = index, index >= 0, index <= arrangedViews.count {
//            arrangedViews.insert((view, padding), at: index)
//        } else {
//            arrangedViews.append((view, padding))
//        }
//        updateConstraintsForArrangedViews()
//    }
//    
//    func removeArrangedSubview(_ view: UIView) {
//        if let index = arrangedViews.firstIndex(where: { $0.view == view }) {
//            arrangedViews.remove(at: index)
//            heightConstraints[view]?.isActive = false
//            heightConstraints.removeValue(forKey: view)
//            view.removeFromSuperview()
//            updateConstraintsForArrangedViews()
//            print("reply is removed")
//        }
//    }
//    
//    private func updateConstraintsForArrangedViews() {
//        // **Update stored height constraints with current sizes**
//        for pair in arrangedViews {
//            if let heightConstraint = heightConstraints[pair.view] {
//                let newHeight = pair.view.intrinsicContentSize.height > 0
//                    ? pair.view.intrinsicContentSize.height
//                    : pair.view.frame.height
//                
//                if newHeight > 0 {
//                    heightConstraint.constant = newHeight
//                }
//            }
//        }
//        
//        NSLayoutConstraint.deactivate(arrangedConstraints)
//        arrangedConstraints.removeAll()
//        
//        var previousView: (view: UIView, padding: UIEdgeInsets)?
//        
//        for (index, pair) in arrangedViews.enumerated() {
//            let view = pair.view
//            let padding = pair.padding
//            
//            // Horizontal constraints
//            arrangedConstraints.append(contentsOf: [
//                view.leadingAnchor.constraint(equalTo: leadingAnchor, constant: margins.left + padding.left),
//                view.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -(margins.right + padding.right))
//            ])
//            
//            // Vertical constraints
//            if let prev = previousView {
//                let verticalGap = spacing + prev.padding.bottom + padding.top
//                arrangedConstraints.append(
//                    view.topAnchor.constraint(equalTo: prev.view.bottomAnchor, constant: verticalGap)
//                )
//            } else {
//                arrangedConstraints.append(
//                    view.topAnchor.constraint(equalTo: topAnchor, constant: margins.top + padding.top)
//                )
//            }
//            
//            if index == arrangedViews.count - 1 {
//                let bottom = view.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -(margins.bottom + padding.bottom))
//                bottom.priority = .init(999) // **Lower priority to avoid conflicts**
//                arrangedConstraints.append(bottom)
//            }
//            
//            previousView = pair
//        }
//        
//        NSLayoutConstraint.activate(arrangedConstraints)
//    }
//}

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
//}

