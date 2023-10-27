//
//  CustomCollectionViewCell.swift
//  ChatUpp
//
//  Created by Andrei Pripa on 10/11/23.
//

import UIKit

final class ConversationCollectionViewCell: UICollectionViewCell {
    
    var cellContainerMaxWidthConstraint: NSLayoutConstraint!
    
    var topView = UIView()
    var messageContainer = UITextView(usingTextLayoutManager: false)
    var timeStamp = UILabel()
    
    let label = UILabel()
    
    var customViewMaxWidth: CGFloat? {
        didSet {
            guard let maxWidth = customViewMaxWidth else {return }
            cellContainerMaxWidthConstraint = topView.widthAnchor.constraint(lessThanOrEqualToConstant: maxWidth - 70)
            cellContainerMaxWidthConstraint.isActive = true
        }
    }
    
    func handleMessageBubbleLayout() {
//        let sizeContainter = containerView.sizeThatFits(CGSize(width: customViewMaxWidth ?? 0, height: .greatestFiniteMagnitude))
        messageContainer.textContainerInset = UIEdgeInsets(top: 5, left: 5, bottom: 5, right: 5)
        messageContainer.invalidateIntrinsicContentSize()
        layoutIfNeeded()

        let lastLineString = getStringFromLastLine(usingTextView: messageContainer)
        let lastLineStringWidth = lastLineString.getSize().width
        let lastLineWithTimestempWidth = lastLineStringWidth + timeStamp.bounds.width
        let messageRectWidth = messageContainer.bounds.width

        if lastLineWithTimestempWidth > messageRectWidth {
            if lastLineWithTimestempWidth.rounded(.up) < cellContainerMaxWidthConstraint.constant  {
                messageContainer.textContainerInset.right = timeStamp.bounds.width
            } else {
                messageContainer.textContainerInset.bottom += 10
            }
        }
        messageContainer.invalidateIntrinsicContentSize()
    }
    
    func setupTopView() {
        contentView.addSubview(topView)
        
        topView.backgroundColor = .magenta
        topView.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            topView.leadingAnchor.constraint(greaterThanOrEqualTo: contentView.leadingAnchor),
            topView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -15),
            topView.topAnchor.constraint(equalTo: contentView.topAnchor),
            topView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor)
        ])
    }
  
    override init(frame: CGRect) {
        super.init(frame: frame)
        intialConstraints()
        setupTopView()
        setCotainer()
        setupTimestamp()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func setupTimestamp() {
        topView.addSubview(timeStamp)
        
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
    
    func setCotainer() {
        topView.addSubview(messageContainer)
        
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
            messageContainer.leadingAnchor.constraint(greaterThanOrEqualTo: topView.leadingAnchor),
            messageContainer.trailingAnchor.constraint(equalTo: topView.trailingAnchor),
            messageContainer.topAnchor.constraint(equalTo: topView.topAnchor),
            messageContainer.bottomAnchor.constraint(equalTo: topView.bottomAnchor)
        ])
    }
    
    func intialConstraints() {
        contentView.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
           contentView.leadingAnchor.constraint(equalTo: leadingAnchor),
           contentView.trailingAnchor.constraint(equalTo: trailingAnchor),
           contentView.topAnchor.constraint(equalTo: topAnchor),
           contentView.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])
    }
}

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
        
        guard let validRange = Range(NSRange(location: rangeStart, length: rangeLength), in: textView.text!) else { print("Invalid range"); return "" }
        
        let substring = textView.text![validRange]
        print(substring)
        return String(substring)
    }
}

final class PaddingLabel: UILabel {
    
    var padding = UIEdgeInsets(top: 10, left: 10, bottom: 10, right: 10) {didSet { invalidateIntrinsicContentSize() }}
    
    override var intrinsicContentSize: CGSize {
        var contentSize = super.intrinsicContentSize
        contentSize.width += padding.left + padding.right
        contentSize.height += padding.top + padding.bottom
        return contentSize
    }
    
    override func drawText(in rect: CGRect) {
        let paddedRect = rect.inset(by: padding)
        super.drawText(in: paddedRect)
    }
    
    override func textRect(forBounds bounds:CGRect,
                           limitedToNumberOfLines n:Int) -> CGRect
    {
        let bounds = bounds.inset(by: padding)
        let textRect = super.textRect(forBounds: bounds, limitedToNumberOfLines: 0)
        return textRect
    }
}

