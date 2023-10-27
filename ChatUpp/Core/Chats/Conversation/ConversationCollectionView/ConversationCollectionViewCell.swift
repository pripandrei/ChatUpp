//
//  CustomCollectionViewCell.swift
//  ChatUpp
//
//  Created by Andrei Pripa on 10/11/23.
//

import UIKit

final class ConversationCollectionViewCell: UICollectionViewCell {
    
    enum MessageSide {
        case left
        case right
    }
    
    var mainCellContainerMaxWidthConstraint: NSLayoutConstraint!
    var messageContainerLeadingConstraint: NSLayoutConstraint!
    var messageContainerTrailingConstraint: NSLayoutConstraint!
    
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
        
//        func adjust(_ message: UITextView) {
//            switch self {
//            case .initial: message.textContainerInset = UIEdgeInsets(top: 6, left: 6, bottom: 6, right: 6)
//            case .spaceRight: message.textContainerInset.right = 41
//            case .spaceBottom: message.textContainerInset.bottom += 15
//            }
//            message.invalidateIntrinsicContentSize()
//        }
    }
    
    private func adjustMessagePadding(_ messagePadding: MessagePadding) {
        switch messagePadding {
        case .initial: messageContainer.textContainerInset = UIEdgeInsets(top: 6, left: 6, bottom: 6, right: 6)
        case .spaceRight: messageContainer.textContainerInset.right = 41
        case .spaceBottom: messageContainer.textContainerInset.bottom += 15
        }
        messageContainer.invalidateIntrinsicContentSize()
    }
    
    func setupMainCellContainer() {
        contentView.addSubview(mainCellContainer)
        
//        mainCellContainer.backgroundColor = .magenta
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
        timeStamp.font = UIFont(name: "HelveticaNeue", size: 12)
        timeStamp.textColor = #colorLiteral(red: 0.74693048, green: 0.7898075581, blue: 1, alpha: 1)
//        timeStamp.backgroundColor = .green
        timeStamp.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            timeStamp.trailingAnchor.constraint(equalTo: messageContainer.trailingAnchor, constant: -8),
            timeStamp.bottomAnchor.constraint(equalTo: messageContainer.bottomAnchor, constant: -5)
        ])
    }
    
    func setupMessageTextView() {
        mainCellContainer.addSubview(messageContainer)
        
//        messageContainer.backgroundColor = #colorLiteral(red: 0.5966709256, green: 0.3349125683, blue: 0.6765266657, alpha: 1)
        messageContainer.textColor = #colorLiteral(red: 1, green: 1, blue: 1, alpha: 1)
        messageContainer.font = UIFont(name: "HelveticaNeue", size: 17)
        messageContainer.isEditable = false // Make it non-editable
        messageContainer.isScrollEnabled = false // Disable scrolling
        messageContainer.textContainer.maximumNumberOfLines = 0 // Allow multiple lines
//        messageContainer.textContainer.lineFragmentPadding = 15
        messageContainer.textContainerInset = UIEdgeInsets(top: 5, left: 5, bottom: 5, right: 5)
        messageContainer.sizeToFit()
        messageContainer.translatesAutoresizingMaskIntoConstraints = false
        messageContainer.layer.cornerRadius = 15
        messageContainer.clipsToBounds = true
        
        NSLayoutConstraint.activate([
//            messageContainer.leadingAnchor.constraint(equalTo: mainCellContainer.leadingAnchor, constant: 15),
//            messageContainer.trailingAnchor.constraint(lessThanOrEqualTo: mainCellContainer.trailingAnchor),
            messageContainer.topAnchor.constraint(equalTo: mainCellContainer.topAnchor),
            messageContainer.bottomAnchor.constraint(equalTo: mainCellContainer.bottomAnchor)
        ])
    }
    
    func setupContentViewConstraints() {
        contentView.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
           contentView.leadingAnchor.constraint(equalTo: leadingAnchor),
           contentView.trailingAnchor.constraint(equalTo: trailingAnchor),
           contentView.topAnchor.constraint(equalTo: topAnchor),
           contentView.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])
    }
    
    func adjustMessageSide(_ side: MessageSide) {
        if messageContainerLeadingConstraint != nil { messageContainerLeadingConstraint.isActive = false }
        if messageContainerTrailingConstraint != nil { messageContainerTrailingConstraint.isActive = false }

        switch side {
        case .right:
            messageContainerLeadingConstraint = messageContainer.leadingAnchor.constraint(greaterThanOrEqualTo: mainCellContainer.leadingAnchor)
            messageContainerTrailingConstraint = messageContainer.trailingAnchor.constraint(equalTo: mainCellContainer.trailingAnchor, constant: -10)
            messageContainerLeadingConstraint.isActive = true
            messageContainerTrailingConstraint.isActive = true
//            messageContainer.backgroundColor = #colorLiteral(red: 0.3709801435, green: 0.3060381413, blue: 0.6801858544, alpha: 1)
            messageContainer.backgroundColor = #colorLiteral(red: 0.7171613574, green: 0.4463854432, blue: 0.351280123, alpha: 1)
        case .left:
            messageContainerLeadingConstraint = messageContainer.leadingAnchor.constraint(equalTo: mainCellContainer.leadingAnchor, constant: 10)
            messageContainerTrailingConstraint = messageContainer.trailingAnchor.constraint(lessThanOrEqualTo: mainCellContainer.trailingAnchor)
            messageContainerLeadingConstraint.isActive = true
            messageContainerTrailingConstraint.isActive = true
            
//            messageContainer.backgroundColor = #colorLiteral(red: 0.6038621068, green: 0.3715925217, blue: 0.5945875049, alpha: 1)
//            messageContainer.backgroundColor = #colorLiteral(red: 0.6996396184, green: 0.3022745848, blue: 0.5303084254, alpha: 1)
            messageContainer.backgroundColor = #colorLiteral(red: 0, green: 0.6150025129, blue: 0.6871898174, alpha: 1)
        }
    }
    
    func handleMessageBubbleLayout() {
//        MessagePadding.initial.adjust(messageContainer)
        adjustMessagePadding(.initial)
        
        layoutIfNeeded()
        
        let padding :CGFloat = 12
        let lastLineString = getStringFromLastLine(usingTextView: messageContainer)
        let lastLineStringWidth = lastLineString.getSize().width
        let lastLineWithTimestempWidth = (lastLineStringWidth + timeStamp.bounds.width) + padding
        let messageRectWidth = messageContainer.bounds.width

        if lastLineWithTimestempWidth > messageRectWidth {
            if lastLineWithTimestempWidth.rounded(.up) < mainCellContainerMaxWidthConstraint.constant  {
//                MessagePadding.spaceRight.adjust(messageContainer)
                adjustMessagePadding(.spaceRight)
            } else {
//                MessagePadding.spaceBottom.adjust(messageContainer)
                adjustMessagePadding(.spaceBottom)
            }
        }
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
