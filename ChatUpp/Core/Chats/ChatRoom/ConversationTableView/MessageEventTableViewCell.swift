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
    
    private let messageEventLabel: YYLabel =
    {
        let messageEventLabel = YYLabel()
        messageEventLabel.preferredMaxLayoutWidth = 250
        messageEventLabel.numberOfLines = 0
        messageEventLabel.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        messageEventLabel.textColor = .white
        messageEventLabel.lineBreakMode = .byWordWrapping
        messageEventLabel.textAlignment = .center
        messageEventLabel.backgroundColor = .blue
        messageEventLabel.layer.cornerRadius = 12
        messageEventLabel.clipsToBounds = true
        messageEventLabel.textContainerInset = .init(top: 4, left: 4, bottom: 4, right: 4)
        messageEventLabel.translatesAutoresizingMaskIntoConstraints = false
        return messageEventLabel
    }()
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupSelf()
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
        
        messageEventLabel.text = "Andrei changed the group name to \"Forgot how much fun this was ct I had this was a good idea for a new game I have a few ide\""
    }
    
    private func setupMessageEventLabelConstraints()
    {
        contentView.addSubview(messageEventLabel)
        messageEventLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 5).isActive = true
        messageEventLabel.bottomAnchor.constraint(equalTo: contentView.bottomAnchor).isActive = true
        
//        messageEventLabel.centerXAnchor.constraint(equalTo: centerXAnchor).isActive = true
//        messageEventLabel.centerYAnchor.constraint(equalTo: centerYAnchor).isActive = true
    }
}
