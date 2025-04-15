//
//  ReactionView.swift
//  ChatUpp
//
//  Created by Andrei Pripa on 4/15/25.
//

import UIKit

enum ReactionType {
    case like
    case love
    case angry
    case sad
}

class ReactionView: UIView
{
    private let stackView = UIStackView()
    var onReaction: ((ReactionType) -> Void)?
    
    private let reactions: [(title: String, type: ReactionType)] = [
        ("👍", .like),
        ("❤️", .love),
        ("😡", .angry),
        ("😢", .sad)
    ]
    
    // MARK: - Init
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupView()
        setupReactions()
        doAnimation()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupView()
        setupReactions()
        doAnimation()
    }
    
    // MARK: - Setup
    
    private func setupView() {
        backgroundColor = UIColor.systemGray6
        layer.cornerRadius = 10
        clipsToBounds = true
        
        stackView.axis = .horizontal
        stackView.alignment = .center
        stackView.distribution = .fillEqually
        stackView.spacing = 12
        stackView.translatesAutoresizingMaskIntoConstraints = false
        
        addSubview(stackView)
        
        NSLayoutConstraint.activate([
            stackView.topAnchor.constraint(equalTo: topAnchor, constant: 8),
            stackView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -8),
            stackView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 12),
            stackView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -12)
        ])
    }
    
    private func setupReactions()
    {
        for (emoji, type) in reactions
        {
            let button = UIButton(type: .system)
            button.setTitle(emoji, for: .normal)
            button.titleLabel?.font = UIFont.systemFont(ofSize: 28)
            button.addTarget(self, action: #selector(reactionTapped(_:)), for: .touchUpInside)
            button.tag = reactions.firstIndex(where: { $0.type == type }) ?? 0
            stackView.addArrangedSubview(button)
        }
    }
    
    // MARK: - Animation
    
    func doAnimation() {
        let offset = CGPoint(x: UIScreen.main.bounds.width, y: 0)
        transform = CGAffineTransform(translationX: offset.x, y: offset.y)
        alpha = 0
        UIView.animate(withDuration: 0.6,
                       delay: 0,
                       usingSpringWithDamping: 0.7,
                       initialSpringVelocity: 0.8,
                       options: .curveEaseOut,
                       animations: {
            self.transform = .identity
            self.alpha = 1
        }, completion: { [weak self] _ in
            self?.stackView.arrangedSubviews.forEach { view in
                UIView.animate(withDuration: 0.5,
                               delay: 0,
                               options: .curveEaseIn,
                               animations: {
                    view.transform = CGAffineTransform.identity.scaledBy(x: 1.5, y: 1.5)
                }, completion: { _ in
                    UIView.animate(withDuration: 0.5) {
                        view.transform = .identity
                    }
                })
            }
        })
    }
    
    // MARK: - Actions
    
    @objc private func reactionTapped(_ sender: UIButton) {
        let type = reactions[sender.tag].type
        onReaction?(type)
    }
}
