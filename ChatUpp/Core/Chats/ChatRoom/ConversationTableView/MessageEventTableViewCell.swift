//
//  Conversation23.swift
//  ChatUpp
//
//  Created by Andrei Pripa on 4/2/25.
//

import UIKit
import Foundation
import YYText

protocol MessageCellPreviewable
{
    var cellViewModel: MessageCellViewModel! { get }
}

final class MessageEventCell: UITableViewCell
{
    private(set) var cellViewModel: MessageCellViewModel!
    
    let messageLabel: YYLabel =
    {
        let messageEventLabel = YYLabel()
        messageEventLabel.preferredMaxLayoutWidth = 250
        messageEventLabel.numberOfLines = 0
        messageEventLabel.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        messageEventLabel.textColor = .white
        messageEventLabel.lineBreakMode = .byWordWrapping
        messageEventLabel.textAlignment = .center
        messageEventLabel.translatesAutoresizingMaskIntoConstraints = false
        return messageEventLabel
    }()
    
    let messageEventContainer: UIView =
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
    }
    
    private func makeAttributedMessage(username: String?, text: String?) -> NSAttributedString
    {
        let attributedText = NSMutableAttributedString()

        attributedText.append(NSAttributedString(
            string: "\(username ?? "") ",
            attributes: [
                .font: UIFont.systemFont(ofSize: 14, weight: .bold),
                .foregroundColor: UIColor.white
            ]
        ))

        attributedText.append(NSAttributedString(
            string: "\(text ?? "")",
            attributes: [
                .font: UIFont.systemFont(ofSize: 14, weight: .medium),
                .foregroundColor: UIColor.white
            ]
        ))

        return attributedText
    }

    private func setupMessageEventContainerConstraints()
    {
        contentView.addSubview(messageEventContainer)
        messageEventContainer.topAnchor.constraint(equalTo: contentView.topAnchor).isActive = true
        messageEventContainer.bottomAnchor.constraint(equalTo: contentView.bottomAnchor,  constant: -5).isActive = true
        messageEventContainer.centerXAnchor.constraint(equalTo: contentView.centerXAnchor).isActive = true
    }
    
    private func setupMessageEventLabelConstraints()
    {
        messageEventContainer.addSubview(messageLabel)
        
        messageLabel.topAnchor.constraint(equalTo: messageEventContainer.topAnchor, constant: 2).isActive = true
        messageLabel.bottomAnchor.constraint(equalTo: messageEventContainer.bottomAnchor, constant: -2).isActive = true
        messageLabel.leadingAnchor.constraint(equalTo: messageEventContainer.leadingAnchor, constant: 8).isActive = true
        messageLabel.trailingAnchor.constraint(equalTo: messageEventContainer.trailingAnchor, constant: -8).isActive = true
    }
}

extension MessageEventCell: MessageCellPreviewable {}
















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

extension MessageEventCell : TargetPreviewable
{
    func getTargetViewForPreview() -> UIView
    {
        return messageEventContainer
    }
    
    func getTargetedPreviewColor() -> UIColor
    {
        return #colorLiteral(red: 0.2971534729, green: 0.3519872129, blue: 0.7117250562, alpha: 1)
    }
}
