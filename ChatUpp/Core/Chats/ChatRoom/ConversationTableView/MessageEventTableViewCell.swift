//
//  Conversation23.swift
//  ChatUpp
//
//  Created by Andrei Pripa on 4/2/25.
//

import UIKit
import Foundation
import YYText

final class MessageEventCell: UITableViewCell
{
    private var cellViewModel: MessageCellViewModel!
    
    private let messageEventLabel: UILabel =
    {
        let messageEventLabel = UILabel()
        messageEventLabel.preferredMaxLayoutWidth = 250
        messageEventLabel.numberOfLines = 0
        messageEventLabel.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        messageEventLabel.textColor = .white
        messageEventLabel.lineBreakMode = .byWordWrapping
        messageEventLabel.textAlignment = .center
//        messageEventLabel.backgroundColor = .blue
//        messageEventLabel.layer.cornerRadius = 12
//        messageEventLabel.clipsToBounds = true
//        messageEventLabel.textContainerInset = .init(top: 10, left: 5, bottom: 10, right: 5)
        messageEventLabel.translatesAutoresizingMaskIntoConstraints = false
        return messageEventLabel
    }()
    
    private let messageEventContainer: UIView =
    {
        let container = UIView()
        container.backgroundColor = #colorLiteral(red: 0.2971534729, green: 0.3519872129, blue: 0.7117250562, alpha: 1)
        container.layer.cornerRadius = 12
        container.clipsToBounds = true
        container.translatesAutoresizingMaskIntoConstraints = false

        return container
    }()
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupSelf()
        setupMessageEventContainerConstraints()
        setupMessageEventLabelConstraints()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupSelf() {
        transform = CGAffineTransform(scaleX: 1, y: -1)
        backgroundColor = .clear
//        isUserInteractionEnabled = false
    }
    
    func configureCell(with viewModel: MessageCellViewModel)
    {
        self.cellViewModel = viewModel
        
        messageEventLabel.text = "Andrei has changed group name to \"has not been implemented has not been implemented has not been implemented\""
    }
    
    private func setupMessageEventContainerConstraints()
    {
        contentView.addSubview(messageEventContainer)
        messageEventContainer.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 5).isActive = true
        messageEventContainer.bottomAnchor.constraint(equalTo: contentView.bottomAnchor).isActive = true
        messageEventContainer.centerXAnchor.constraint(equalTo: contentView.centerXAnchor).isActive = true
    }
    
    private func setupMessageEventLabelConstraints()
    {
        messageEventContainer.addSubview(messageEventLabel)
        
        messageEventLabel.topAnchor.constraint(equalTo: messageEventContainer.topAnchor, constant: 5).isActive = true
        messageEventLabel.bottomAnchor.constraint(equalTo: messageEventContainer.bottomAnchor, constant: -5).isActive = true
        messageEventLabel.leadingAnchor.constraint(equalTo: messageEventContainer.leadingAnchor, constant: 10).isActive = true
        messageEventLabel.trailingAnchor.constraint(equalTo: messageEventContainer.trailingAnchor, constant: -10).isActive = true
//        messageEventLabel.centerXAnchor.constraint(equalTo: messageEventContainer.centerXAnchor).isActive = true
        
//        messageEventLabel.centerXAnchor.constraint(equalTo: centerXAnchor).isActive = true
//        messageEventLabel.centerYAnchor.constraint(equalTo: centerYAnchor).isActive = true
    }
}
