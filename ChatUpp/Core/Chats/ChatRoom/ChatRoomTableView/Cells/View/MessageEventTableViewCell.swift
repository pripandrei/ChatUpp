//
//  Conversation23.swift
//  ChatUpp
//
//  Created by Andrei Pripa on 4/2/25.
//

import UIKit
import Foundation
import YYText
import SwiftUI

final class MessageEventCell: UITableViewCell
{
    private(set) var cellViewModel: MessageCellViewModel!
    private(set) var reactionBadgeHostingView: UIView?
    private var contentContainerViewBottomConstraint: NSLayoutConstraint!
    
    let messageLabel: UILabel =
    {
        let messageEventLabel = UILabel()
        messageEventLabel.preferredMaxLayoutWidth = 290
        messageEventLabel.numberOfLines = 0
        messageEventLabel.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        messageEventLabel.textColor = .white
        messageEventLabel.lineBreakMode = .byWordWrapping
        messageEventLabel.textAlignment = .center
        messageEventLabel.translatesAutoresizingMaskIntoConstraints = false
        return messageEventLabel
    }()
    
    let contentContainer: UIView! =
    {
        let container = UIView()
        container.backgroundColor = ColorManager.messageEventBackgroundColor
        container.layer.cornerRadius = 10
        container.clipsToBounds = true
        container.translatesAutoresizingMaskIntoConstraints = false

        return container
    }()
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupSelf()
        setupBackgroundSelectionView()
        setupMessageEventContainerConstraints()
        setupMessageEventLabelConstraints()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupBackgroundSelectionView()
    {
        let selectedView = UIView()
        selectedView.backgroundColor = UIColor.clear
        selectedBackgroundView = selectedView
    }
    
    private func setupSelf() {
        transform = CGAffineTransform(scaleX: 1, y: -1)
        backgroundColor = .clear
        contentView.backgroundColor = .clear
    }
    
    func configureCell(with viewModel: MessageCellViewModel)
    {
        self.cellViewModel = viewModel
        
        let username = viewModel.messageSender?.name
        let textMessage = viewModel.message?.messageBody
        
        messageLabel.attributedText = makeAttributedMessage(username: username,
                                                                 text: textMessage)
        setupReactionView(for: viewModel.message!)
        setContentContainerViewBottomConstraint()
    }
    
    private func setContentContainerViewBottomConstraint()
    {
        let isReactionsEmpty = cellViewModel.message?.reactions.isEmpty
        self.contentContainerViewBottomConstraint.constant = isReactionsEmpty ?? true ? -7 : -27
    }
    
    func setupReactionView(for message: Message)
    {
        guard !message.reactions.isEmpty else {return}
        
        let reactionVM = ReactionViewModel(message: message)
        let hostView = UIHostingController(rootView: ReactionBadgeView(viewModel: reactionVM))
        
        self.reactionBadgeHostingView = hostView.view
        
        hostView.view.backgroundColor = .clear
        hostView.view.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(hostView.view)
        
        hostView.view.centerXAnchor.constraint(equalTo: contentContainer.centerXAnchor).isActive = true
        
        hostView.view.topAnchor.constraint(equalTo: contentContainer.bottomAnchor, constant: -2).isActive = true
    }
    
    private func makeAttributedMessage(username: String?, text: String?) -> NSAttributedString
    {
        let attributedText = NSMutableAttributedString()
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.alignment = .center

        attributedText.append(NSAttributedString(
            string: "\(username ?? "") ",
            attributes: [
                .font: UIFont.systemFont(ofSize: 13.5, weight: .bold),
                .foregroundColor: UIColor.white,
            ]
        ))

        attributedText.append(NSAttributedString(
            string: "\(text ?? "")",
            attributes: [
                .font: UIFont.systemFont(ofSize: 13.5, weight: .medium),
                .foregroundColor: UIColor.white,
                .paragraphStyle: paragraphStyle
                
            ]
        ))
        
        return attributedText
    }

    private func setupMessageEventContainerConstraints()
    {
        contentView.addSubview(contentContainer)
        contentContainer.topAnchor.constraint(equalTo: contentView.topAnchor).isActive = true
        contentContainer.bottomAnchor.constraint(equalTo: contentView.bottomAnchor).isActive = true
        contentContainer.centerXAnchor.constraint(equalTo: contentView.centerXAnchor).isActive = true
    }
    
    private func setupMessageEventLabelConstraints()
    {
        contentContainer.addSubview(messageLabel)
        
        messageLabel.topAnchor.constraint(equalTo: contentContainer.topAnchor, constant: 3).isActive = true
        messageLabel.bottomAnchor.constraint(equalTo: contentContainer.bottomAnchor, constant: -3).isActive = true
        messageLabel.leadingAnchor.constraint(equalTo: contentContainer.leadingAnchor, constant: 7).isActive = true
        messageLabel.trailingAnchor.constraint(equalTo: contentContainer.trailingAnchor, constant: -7).isActive = true
        
        contentContainerViewBottomConstraint = contentContainer.bottomAnchor.constraint(equalTo: contentView.bottomAnchor)
//        contentContainerViewBottomConstraint.priority = UILayoutPriority(rawValue: 999)
        contentContainerViewBottomConstraint.isActive = true
    }
}

extension MessageEventCell: TargetPreviewable {}
extension MessageEventCell: MessageCellSeenable {}








// MARK: - Context Menu Types

/// Represents available actions for message context menus
enum MessageContextAction {
    case reply(Message, String, String?)  // message, text, senderName
    case copy(String)                     // text to copy
    case edit(Message, String)            // message, current text
    case delete(Message)                  // message to delete
}

/// Protocol for objects that can handle message context actions
protocol MessageContextActionHandler: AnyObject {
    func handle(_ action: MessageContextAction)
}

/// Configuration for building context menus
struct MessageContextMenuConfiguration {
    let message: Message
    let displayText: String
    let isOwner: Bool
    let senderName: String?
    
    init(message: Message, displayText: String, isOwner: Bool, senderName: String? = nil) {
        self.message = message
        self.displayText = displayText
        self.isOwner = isOwner
        self.senderName = senderName
    }
}

