//
//  ReactionUIView.swift
//  ChatUpp
//
//  Created by Andrei Pripa on 2/3/26.
//

import UIKit
import SwiftUI

final class ReactionUIView: UIView
{
    private(set) var reactionView: UIView?
    private var message: Message!
    private var viewModel: ReactionViewModel!
    
    init(from message: Message)
    {
        super.init(frame: .zero)
        self.message = message
        setupReaction()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    deinit
    {
        print("removed ReactionUIView")
    }
    
    private func setupReaction()
    {
        let reactionVM = ReactionViewModel(reactions: Array(message.reactions))
        self.viewModel = reactionVM
        let hostView = UIHostingController(rootView: ReactionBadgeView(viewModel: reactionVM))
       
        self.reactionView = hostView.view
        self.reactionView?.backgroundColor = .clear
    }
    
    func removeReaction(from view: ContainerView)
    {
        if let reactionView = self.reactionView
        {
            view.removeArrangedSubview(reactionView)
            UIView.animate(withDuration: 0.6, delay: 0,
                           usingSpringWithDamping: 0.8,
                           initialSpringVelocity: 0)
            {
                view.superview?.layoutIfNeeded()
            }
            self.reactionView = nil
        }
    }
    
    func addReaction(to view: ContainerView, withAnimation animated: Bool = true)
    {
        guard let reactionView = reactionView else {return}
        
        view.addArrangedSubview(reactionView,
//                                padding: .init(top: 7, left: 2, bottom: 0, right: 0),
                                padding: .init(top: 2, left: 2, bottom: 0, right: 0),
                                shouldFillWidth: false)
        
        guard animated else {return}
        
        self.reactionView?.alpha = 0.2
        self.reactionView?.transform = .init(scaleX: 0.1, y: 0.1)
        
        UIView.animate(withDuration: 0.6, delay: 0, usingSpringWithDamping: 0.8, initialSpringVelocity: 0)
        {
            UIView.animate(withDuration: 0.2, delay: 0.3)
            {
                self.reactionView?.transform = .init(scaleX: 1.2, y: 1.2)
                self.reactionView?.alpha = 1.0
                
                UIView.animate(withDuration: 0.2, delay: 0.5) {
                    self.reactionView?.transform = .identity
                }
            }
            view.superview?.layoutIfNeeded()
        }
    }
    
    func updateReactions(on view: ContainerView)
    {
        self.viewModel?.updateMessage(Array(self.message.reactions))
        mainQueue
        {
            self.reactionView?.invalidateIntrinsicContentSize()
            self.reactionView?.layoutIfNeeded()
            UIView.animate(withDuration: 0.3) {
                view.superview?.layoutIfNeeded()
            }
        }
    }
}
