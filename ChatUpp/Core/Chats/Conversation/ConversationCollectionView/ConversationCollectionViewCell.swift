//
//  CustomCollectionViewCell.swift
//  ChatUpp
//
//  Created by Andrei Pripa on 10/11/23.
//

import UIKit

final class ConversationCollectionViewCell: UICollectionViewCell {
    
    var mainCellContainerMaxWidthConstraint: NSLayoutConstraint!
    
    var mainCellContainer = UIView()
    var messageContainer = UITextView(usingTextLayoutManager: false)
    var timeStamp = UILabel()
 
    var mainCellContainerMaxWidth: CGFloat? {
        didSet {
            guard let maxWidth = mainCellContainerMaxWidth else {return }
            mainCellContainerMaxWidthConstraint = messageContainer.widthAnchor.constraint(lessThanOrEqualToConstant: maxWidth - 70)
            mainCellContainerMaxWidthConstraint.isActive = true
        }
    }
    
    enum MessagePadding {
        case initial
        case spaceRight
        case spaceBottom
        
        func adjust(_ message: UITextView) {
            switch self {
            case .initial:  message.textContainerInset = UIEdgeInsets(top: 5, left: 5, bottom: 5, right: 5)
            case .spaceRight: message.textContainerInset.right = 37
            case .spaceBottom:  message.textContainerInset.bottom += 10
            }
            message.invalidateIntrinsicContentSize()
        }
    }
    
    enum MessageSide {
        case left
        case right
    }
    
    func handleMessageBubbleLayout() {
        MessagePadding.initial.adjust(messageContainer)
        
        layoutIfNeeded()
        
        let lastLineString = getStringFromLastLine(usingTextView: messageContainer)
        let lastLineStringWidth = lastLineString.getSize().width
        let lastLineWithTimestempWidth = lastLineStringWidth + timeStamp.bounds.width
        let messageRectWidth = messageContainer.bounds.width

        if lastLineWithTimestempWidth > messageRectWidth {
            if lastLineWithTimestempWidth.rounded(.up) < mainCellContainerMaxWidthConstraint.constant  {
                MessagePadding.spaceRight.adjust(messageContainer)
            } else {
                MessagePadding.spaceBottom.adjust(messageContainer)
            }
        }
    }
    
    func setupMainCellContainer() {
        contentView.addSubview(mainCellContainer)
        
        mainCellContainer.backgroundColor = .magenta
        mainCellContainer.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            mainCellContainer.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            mainCellContainer.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            mainCellContainer.topAnchor.constraint(equalTo: contentView.topAnchor),
            mainCellContainer.bottomAnchor.constraint(equalTo: contentView.bottomAnchor)
        ])
    }
  
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupContentViewConstraints()
        setupMainCellContainer()
        setupMessageTextView()
        setupTimestamp()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func setupTimestamp() {
        mainCellContainer.addSubview(timeStamp)
        
        timeStamp.text = "20:42"
        timeStamp.font = UIFont(name: "HelveticaNeue", size: 15)
        timeStamp.textColor = .white
        timeStamp.backgroundColor = .green
        timeStamp.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            timeStamp.trailingAnchor.constraint(equalTo: messageContainer.trailingAnchor),
            timeStamp.bottomAnchor.constraint(equalTo: messageContainer.bottomAnchor)
        ])
    }
    
    func setupMessageTextView() {
        mainCellContainer.addSubview(messageContainer)
        
        messageContainer.backgroundColor = .cyan
        messageContainer.font = UIFont(name: "HelveticaNeue", size: 17)
        messageContainer.isEditable = false // Make it non-editable
        messageContainer.isScrollEnabled = false // Disable scrolling
        messageContainer.textContainer.maximumNumberOfLines = 0 // Allow multiple lines
//        messageContainer.textContainer.lineFragmentPadding = 15
        messageContainer.textContainerInset = UIEdgeInsets(top: 5, left: 5, bottom: 5, right: 5)
        messageContainer.sizeToFit()
        messageContainer.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
//            messageContainer.leadingAnchor.constraint(equalTo: mainCellContainer.leadingAnchor, constant: 15),
//            messageContainer.trailingAnchor.constraint(lessThanOrEqualTo: mainCellContainer.trailingAnchor),
            messageContainer.topAnchor.constraint(equalTo: mainCellContainer.topAnchor),
            messageContainer.bottomAnchor.constraint(equalTo: mainCellContainer.bottomAnchor)
        ])
    }
    
    var messageContainerLeadingConstraint: NSLayoutConstraint!
    var messageContainerTrailingConstraint: NSLayoutConstraint!
    
    func adjustMessageSide(_ side: MessageSide) {
        if messageContainerLeadingConstraint != nil { messageContainerLeadingConstraint.isActive = false }
        if messageContainerTrailingConstraint != nil { messageContainerTrailingConstraint.isActive = false }

        switch side {
        case .right:
            messageContainerLeadingConstraint = messageContainer.leadingAnchor.constraint(greaterThanOrEqualTo: mainCellContainer.leadingAnchor)
            messageContainerTrailingConstraint = messageContainer.trailingAnchor.constraint(equalTo: mainCellContainer.trailingAnchor, constant: -15)
            messageContainerLeadingConstraint.isActive = true
            messageContainerTrailingConstraint.isActive = true
        case .left:
            messageContainerLeadingConstraint = messageContainer.leadingAnchor.constraint(equalTo: mainCellContainer.leadingAnchor, constant: 15)
            messageContainerTrailingConstraint = messageContainer.trailingAnchor.constraint(lessThanOrEqualTo: mainCellContainer.trailingAnchor)
            messageContainerLeadingConstraint.isActive = true
            messageContainerTrailingConstraint.isActive = true
        }
    }
    
//    var side: MessageSide {
//        didSet {
//            switch side {
//            case .right:
//            case .left:
//            }
//        }
//    }
    
    func setupContentViewConstraints() {
        contentView.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
           contentView.leadingAnchor.constraint(equalTo: leadingAnchor),
           contentView.trailingAnchor.constraint(equalTo: trailingAnchor),
           contentView.topAnchor.constraint(equalTo: topAnchor),
           contentView.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])
    }
}

// MARK: - GET LAST LINE MESSAGE STRING

extension ConversationCollectionViewCell {
    
    func getStringFromLastLine(usingTextView textView: UITextView) -> String {
        let selectedRangee = textView.selectedRange
        let glyphRange = textView.layoutManager.glyphRange(forCharacterRange: selectedRangee, actualCharacterRange: nil)
        
        let glyphIndex = glyphRange.lowerBound == textView.layoutManager.numberOfGlyphs ? glyphRange.lowerBound - 1 : glyphRange.lowerBound
        
        var effectiveGlyphRange = NSRange(location: 0, length: 0)
        
        textView.layoutManager.lineFragmentRect(forGlyphAt: glyphIndex , effectiveRange: &effectiveGlyphRange)
        let effectiveCharRange = textView.layoutManager.characterRange(forGlyphRange: effectiveGlyphRange, actualGlyphRange: nil)
        
        let rangeStart = effectiveCharRange.location
        let rangeLength = effectiveCharRange.length
        
        guard let validRange = Range(NSRange(location: rangeStart, length: rangeLength), in: textView.text!)
        else { print("Invalid range"); return "" }
        
        let substring = textView.text![validRange]
        return String(substring)
    }
}
