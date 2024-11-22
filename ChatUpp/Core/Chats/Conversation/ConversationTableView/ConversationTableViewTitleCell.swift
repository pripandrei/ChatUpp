//
//  ConversationTableViewTitleCell.swift
//  ChatUpp
//
//  Created by Andrei Pripa on 11/22/24.
//

import UIKit

//MARK: - cell to displaying unseen messages title
final class ConversationTableViewTitleCell: UITableViewCell
{
    private var cellPadding: CGFloat = 8.0
    private var unseenMessagePadding: CGFloat = 5.0
    
    private var containerView: UIView = {
        let containerView = UIView()
        containerView.translatesAutoresizingMaskIntoConstraints = false
        return containerView
    }()
    
    private var unreadMessagesLabel: UILabel = {
        let unreadMessagesLabel = UILabel()
        unreadMessagesLabel.font = UIFont.systemFont(ofSize: 14, weight: .semibold)
        unreadMessagesLabel.textColor = .white
        unreadMessagesLabel.text = "Unread Messages"
        unreadMessagesLabel.translatesAutoresizingMaskIntoConstraints = false
        
        return unreadMessagesLabel
    }()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {

        super.init(style: style, reuseIdentifier: reuseIdentifier)
        
        setupSelf()
        setupContainerViewConstraint()
        setUnreadMessagesLabel()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupSelf() {
        transform = CGAffineTransform(scaleX: 1, y: -1)
        backgroundColor = .clear
        isUserInteractionEnabled = false
    }
    
    private func setupContainerViewConstraint()
    {
        contentView.addSubview(containerView)
        containerView.backgroundColor = #colorLiteral(red: 0.3664873742, green: 0.3167806026, blue: 0.5121211105, alpha: 1)
        
        containerView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -cellPadding).isActive = true
        containerView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: cellPadding - 3).isActive = true
        containerView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor).isActive = true
        containerView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor).isActive = true
    }
    
    private func setUnreadMessagesLabel()
    {
        containerView.addSubview(unreadMessagesLabel)
        
        unreadMessagesLabel.centerXAnchor.constraint(equalTo: containerView.centerXAnchor).isActive = true
        unreadMessagesLabel.topAnchor.constraint(equalTo: containerView.topAnchor, constant: unseenMessagePadding).isActive = true
        unreadMessagesLabel.bottomAnchor.constraint(equalTo: containerView.bottomAnchor, constant: -unseenMessagePadding).isActive = true
    }
}
