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
        containerStackView.spacing = spacing
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
    
    func removeArrangedSubview(_ view: UIView)
    {
        if let wrapper = containerStackView.arrangedSubviews.first(where: { $0.subviews.contains(view) }) {
            containerStackView.removeArrangedSubview(wrapper)
            wrapper.removeFromSuperview()
            viewPaddings.removeValue(forKey: view)
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
