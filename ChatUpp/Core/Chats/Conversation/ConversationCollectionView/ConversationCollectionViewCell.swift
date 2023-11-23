//
//  CustomCollectionViewCell.swift
//  ChatUpp
//
//  Created by Andrei Pripa on 10/11/23.
//

import UIKit
import ImageIO

final class ConversationCollectionViewCell: UICollectionViewCell {
    
    enum MessageSide {
        case left
        case right
    }
    
    private enum MessagePadding {
        case initial
        case spaceRight
        case spaceBottom
    }
    
    private var mainCellContainerMaxWidthConstraint: NSLayoutConstraint!
    private var messageContainerLeadingConstraint: NSLayoutConstraint!
    private var messageContainerTrailingConstraint: NSLayoutConstraint!
    
    private var mainCellContainer = UIView()
    var messageContainer = UITextView(usingTextLayoutManager: false)
    private var timeStamp = UILabel()
    var cellViewModel: ConversationCellViewModel!
 
    var mainCellContainerMaxWidth :CGFloat? {
        didSet {
            guard let maxWidth = mainCellContainerMaxWidth else { return }
            mainCellContainerMaxWidthConstraint = messageContainer.widthAnchor.constraint(lessThanOrEqualToConstant: maxWidth - 70)
            mainCellContainerMaxWidthConstraint.isActive = true
        }
    }
    
    func configureCell(usingViewModel viewModel: ConversationCellViewModel) {
        self.cellViewModel = viewModel
        setupBinding()
        
        if viewModel.messageText == "" {
            createImageAttachment()
        } else {
            messageContainer.text = viewModel.messageText
        }
        
        if viewModel.imageData.value == nil && viewModel.imagePath != nil {
            viewModel.fetchImageData()
        }
    }
    
    private func convertDataToImage(_ data: Data) -> UIImage? {
        guard let image = UIImage(data: data) else { return nil }
        return image
    }
    
    private func createImageAttachment(withImage image: UIImage) {
        let imageAttachment = NSTextAttachment(image: image)
//        imageAttachment.bounds = CGRect(origin: CGPoint.zero, size: CGSize(width: 150, height: 200))
        let attributedString = NSAttributedString(attachment: imageAttachment)
//        messageContainer.attributedText = attributedString
        messageContainer.textStorage.insert(attributedString, at: 0)
    }
    
    private var imageAttachment: NSTextAttachment?

    private func createImageAttachment() {
        imageAttachment = NSTextAttachment()
        imageAttachment?.image = UIImage()
        
        if let size = cellViewModel.imageSize {
            imageAttachment?.bounds.size = CGSize(width: size.width, height: size.height)
        }
        let attributedString = NSAttributedString(attachment: imageAttachment!)

        messageContainer.textStorage.insert(attributedString, at: 0)
    }
       
    func setupBinding() {
        cellViewModel.imageData.bind { [weak self] data in
            DispatchQueue.main.async {
                self?.updateImageAttachment(data: data)
            }
        }
    }
    
    func updateImageAttachment(data: Data?) {
        guard let imageData = data else { return }
        guard let image = convertDataToImage(imageData) else { return }
        
        if let attachment = imageAttachment {
            attachment.image = image
            let attributedString = NSAttributedString(attachment: attachment)
            messageContainer.attributedText = attributedString
        }
    }

    
    //MARK: - LIFECYCLE
  
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
    
// MARK: - UI INITIAL STEUP
    
    private func setupMainCellContainer() {
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
    
    private func setupMessageTextView() {
        mainCellContainer.addSubview(messageContainer)
        
        messageContainer.textColor = .white
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
            messageContainer.topAnchor.constraint(equalTo: mainCellContainer.topAnchor),
            messageContainer.bottomAnchor.constraint(equalTo: mainCellContainer.bottomAnchor)
        ])
    }
    
    private func setupTimestamp() {
        mainCellContainer.addSubview(timeStamp)
        
        timeStamp.text = "20:42"
        timeStamp.font = UIFont(name: "HelveticaNeue", size: 12)
        timeStamp.textColor = #colorLiteral(red: 0.74693048, green: 0.7898075581, blue: 1, alpha: 1)
        timeStamp.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            timeStamp.trailingAnchor.constraint(equalTo: messageContainer.trailingAnchor, constant: -8),
            timeStamp.bottomAnchor.constraint(equalTo: messageContainer.bottomAnchor, constant: -5)
        ])
    }
    
    private func setupContentViewConstraints() {
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
            messageContainer.backgroundColor = #colorLiteral(red: 0.7171613574, green: 0.4463854432, blue: 0.351280123, alpha: 1)
        case .left:
            messageContainerLeadingConstraint = messageContainer.leadingAnchor.constraint(equalTo: mainCellContainer.leadingAnchor, constant: 10)
            messageContainerTrailingConstraint = messageContainer.trailingAnchor.constraint(lessThanOrEqualTo: mainCellContainer.trailingAnchor)
            messageContainerLeadingConstraint.isActive = true
            messageContainerTrailingConstraint.isActive = true
            
            messageContainer.backgroundColor = #colorLiteral(red: 0, green: 0.6150025129, blue: 0.6871898174, alpha: 1)
        }
    }
    
    // MARK: - MESSAGE BUBBLE LAYOUT HANDLER
    
    func handleMessageBubbleLayout() {
        adjustMessagePadding(.initial)
        
        layoutIfNeeded()
        
        let padding :CGFloat = 12
        let lastLineString = getStringFromLastLine(usingTextView: messageContainer)
        let lastLineStringWidth = lastLineString.getSize().width
        let lastLineWithTimestempWidth = (lastLineStringWidth + timeStamp.bounds.width) + padding
        let messageRectWidth = messageContainer.bounds.width

        if lastLineWithTimestempWidth > messageRectWidth {
            if lastLineWithTimestempWidth.rounded(.up) < mainCellContainerMaxWidthConstraint.constant  {
                adjustMessagePadding(.spaceRight)
            } else {
                adjustMessagePadding(.spaceBottom)
            }
        }
    }
    
    private func adjustMessagePadding(_ messagePadding: MessagePadding) {
        switch messagePadding {
        case .initial: messageContainer.textContainerInset = UIEdgeInsets(top: 6, left: 6, bottom: 6, right: 6)
        case .spaceRight: messageContainer.textContainerInset.right = 41
        case .spaceBottom: messageContainer.textContainerInset.bottom += 15
        }
        messageContainer.invalidateIntrinsicContentSize()
    }
}

// MARK: - GET LAST LINE MESSAGE STRING

extension ConversationCollectionViewCell {
    
    private func getStringFromLastLine(usingTextView textView: UITextView) -> String {
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
