//
//  MessageComponents.swift
//  ChatUpp
//
//  Created by Andrei Pripa on 9/18/25.
//

import UIKit
import YYText
import Combine

enum ComponentsContext {
    case incoming
    case outgoing
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
    }
    
    private func setupEditedLabel()
    {
//        messageComponentsStackView.insertArrangedSubview(editedLabel, at: 0)
        editedLabel.font = UIFont(name: "Helvetica", size: 12)
    }
    
    private func setupTimestamp()
    {
        timeStamp.font = UIFont(name: "HelveticaNeue", size: 12)
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        updateStackViewComponentsAppearance()
    }
    
    private func updateStackViewComponentsAppearance()
    {
        guard let messageType = viewModel?.message.type else {return}

        switch messageType
        {
        case .image, .sticker:
            messageComponentsStackView.backgroundColor = #colorLiteral(red: 0.1982198954, green: 0.2070500851, blue: 0.2227896452, alpha: 1).withAlphaComponent(0.8)
            messageComponentsStackView.isLayoutMarginsRelativeArrangement = true
            messageComponentsStackView.layoutMargins = UIEdgeInsets(top: 2, left: 4, bottom: 2, right: 4)
            messageComponentsStackView.layer.cornerRadius = bounds.height / 2
        case .text, .imageText, .audio :
            messageComponentsStackView.backgroundColor = .clear
            messageComponentsStackView.isLayoutMarginsRelativeArrangement = false
            messageComponentsStackView.layoutMargins = .zero
            messageComponentsStackView.layer.cornerRadius = .zero
        default: break
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
        guard viewModel.componentsContext == .outgoing else {return}
        
        let isSeen = viewModel.isMessageSeen
        let iconSize = isSeen ? CGSize(width: 14, height: 10) : CGSize(width: 10, height: 10)
        
        let seenIconColor: UIColor = getColorForMessageComponents()
        let seenStatusIcon = isSeen ? SeenStatusIcon.double.rawValue : SeenStatusIcon.single.rawValue

        guard let seenStatusIconImage = SeenStatusIconStorage.image(named: seenStatusIcon,
                                                                  size: iconSize,
                                                                  color: seenIconColor)
        else {return}
        
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
        
        if viewModel.message.type == .image || viewModel.message.type == .sticker
        {
            color = .white
        } else {
            color = viewModel.componentsContext == .incoming ? ColorManager.incomingMessageComponentsTextColor : ColorManager.outgoingMessageComponentsTextColor
        }
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
//        updateStackViewComponentsAppearance()
    }
}



