//
//  MessageComponents.swift
//  ChatUpp
//
//  Created by Andrei Pripa on 9/18/25.
//

import UIKit
import YYText

enum ComponentsContext {
    case incoming
    case outgoing
}

final class MessageComponentsViewModel
{
    let message: Message
    var componentsContext: ComponentsContext
    
    init(message: Message,
         context: ComponentsContext)
    {
        self.message = message
        self.componentsContext = context
    }
    
    var timestamp: String? {
        let hoursAndMinutes = message.timestamp.formatToHoursAndMinutes()
        return hoursAndMinutes
    }
    
    var isMessageSeen: Bool
    {
        return message.messageSeen ?? (message.seenBy.count > 1)
    }
    
}


final class MessageComponentsView: UIView
{
    private var viewModel: MessageComponentsViewModel!
    private(set) var messageComponentsStackView: UIStackView = UIStackView()
    private var seenStatusMark = YYLabel()
    private var editedLabel: UILabel = UILabel()
    private var timeStamp = YYLabel()
    
    init() {
        super.init(frame: .zero)
        setupMessageComponentsStackView()
        setupTimestamp()
        setupEditedLabel()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupMessageComponentsStackView()
    {
        addSubview(messageComponentsStackView)
        
        messageComponentsStackView.addArrangedSubview(editedLabel)
        messageComponentsStackView.addArrangedSubview(timeStamp)
        messageComponentsStackView.addArrangedSubview(seenStatusMark)
        
        messageComponentsStackView.axis = .horizontal
        messageComponentsStackView.alignment = .center
        messageComponentsStackView.distribution = .equalSpacing
        messageComponentsStackView.spacing = 3
        messageComponentsStackView.clipsToBounds = true
        messageComponentsStackView.translatesAutoresizingMaskIntoConstraints = false
        
        
        NSLayoutConstraint.activate([
            messageComponentsStackView.trailingAnchor.constraint(equalTo: trailingAnchor),
            messageComponentsStackView.bottomAnchor.constraint(equalTo: bottomAnchor),
            messageComponentsStackView.topAnchor.constraint(equalTo: topAnchor),
            messageComponentsStackView.leadingAnchor.constraint(equalTo: leadingAnchor),
        ])
        
//        NSLayoutConstraint.activate([
//            messageComponentsStackView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -8),
//            messageComponentsStackView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -5),
//        ])
    }
    
    private func setupEditedLabel()
    {
//        messageComponentsStackView.insertArrangedSubview(editedLabel, at: 0)
        editedLabel.font = UIFont(name: "Helvetica", size: 13)
    }
    
    private func setupTimestamp()
    {
        timeStamp.font = UIFont(name: "HelveticaNeue", size: 13)
    }
    
    private func updateStackViewComponentsAppearance()
    {
        let messageType = viewModel.message.type
        if messageType == .image
        {
            messageComponentsStackView.backgroundColor = #colorLiteral(red: 0.121735774, green: 0.1175989285, blue: 0.1221210584, alpha: 1).withAlphaComponent(0.5)
            messageComponentsStackView.isLayoutMarginsRelativeArrangement = true
            messageComponentsStackView.layoutMargins = UIEdgeInsets(top: 3, left: 8, bottom: 3, right: 8)
            messageComponentsStackView.layer.cornerRadius = 12
        } else {
            messageComponentsStackView.backgroundColor = .clear
            messageComponentsStackView.isLayoutMarginsRelativeArrangement = false
            messageComponentsStackView.layoutMargins = .zero
            messageComponentsStackView.layer.cornerRadius = .zero
        }
        
        updateStackViewComponentsColor()
    }
    
    private func updateStackViewComponentsColor()
    {
        timeStamp.textColor = getColorForMessageComponents()
        editedLabel.textColor = getColorForMessageComponents()
    }
    
    func updateEditedLabel()
    {
        if viewModel.message.isEdited == true
        {
            editedLabel.text = "edited"
        }
    }
    
    func configureMessageSeenStatus()
    {
        guard
//            let message = viewModel.message,
            viewModel.componentsContext == .outgoing else {return}
//        if message.type == .text && message.messageBody == "" {return}
        
//        let isSeen = message.messageSeen ?? (message.seenBy.count > 1)
        let isSeen = viewModel.isMessageSeen
        let iconSize = isSeen ? CGSize(width: 16, height: 11) : CGSize(width: 12, height: 13)
        
        let seenIconColor: UIColor = viewModel.message.type == .image ? .white : ColorManager.messageSeenStatusIconColor
        let seenStatusIcon = isSeen ? SeenStatusIcon.double.rawValue : SeenStatusIcon.single.rawValue
        guard let seenStatusIconImage = UIImage(named: seenStatusIcon)?
            .withTintColor(seenIconColor)
            .resize(to: iconSize) else {return}
        
        let imageAttributedString = NSMutableAttributedString.yy_attachmentString(
            withContent: seenStatusIconImage,
            contentMode: .center,
            attachmentSize: seenStatusIconImage.size,
            alignTo: UIFont(name: "Helvetica", size: 14)!,
            alignment: .center)
        
        seenStatusMark.attributedText = imageAttributedString
    }
    
    private func getColorForMessageComponents() -> UIColor
    {
        var color: UIColor = ColorManager.outgoingMessageComponentsTextColor
        
//        if let viewModel = viewModel
//        {
        if viewModel.message.type == .image
        {
            color = .white
        } else {
            color = viewModel.componentsContext == .incoming ? ColorManager.incomingMessageComponentsTextColor : ColorManager.outgoingMessageComponentsTextColor
        }
        //        }
        return color
    }
}

//MARK: - Computed properties
extension MessageComponentsView
{
    var componentsWidth: CGFloat
    {
        let sideWidth = viewModel.componentsContext == .outgoing ? seenStatusMark.intrinsicContentSize.width : 0.0
        return timeStamp.intrinsicContentSize.width + sideWidth + editedMessageWidth + 4.0
    }
    
    private var editedMessageWidth: CGFloat {
        return editedLabel.intrinsicContentSize.width
    }
}

//MARK: cleanup

extension MessageComponentsView
{
    func cleanupContent()
    {
        timeStamp.text = nil
        seenStatusMark.attributedText = nil
        editedLabel.text = nil
    }
}

//MARK: - configuration
extension MessageComponentsView
{
    func configure(viewModel: MessageComponentsViewModel)
    {
        self.viewModel = viewModel
        timeStamp.text = viewModel.timestamp
        updateEditedLabel()
        configureMessageSeenStatus()
        updateStackViewComponentsAppearance()
    }
}
