//
//  CustomCollectionViewCell.swift
//  ChatUpp
//
//  Created by Andrei Pripa on 10/11/23.
//

import UIKit
import ImageIO
import AVFoundation
final class ConversationCollectionViewCell: UICollectionViewCell {
    
    enum MessageSide {
        case left
        case right
    }
    private enum MessagePadding {
        case initial
        case rightSpace
        case bottomSpace
        case imageSpace
    }
    
    private var mainCellContainerMaxWidthConstraint: NSLayoutConstraint!
    private var messageContainerLeadingConstraint: NSLayoutConstraint!
    private var messageContainerTrailingConstraint: NSLayoutConstraint!
    
    private var imageAttachment = NSTextAttachment()
     var mainCellContainer = UIView()
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
    
    private func setupBinding() {
        cellViewModel.imageData.bind { [weak self] data in
            if data == self?.cellViewModel.imageData.value {
                DispatchQueue.main.async {
                    self?.configureImageAttachment(data: data)
                }
            }
        }
    }

    private func cleanupCellContent() {
        messageContainer.text = ""
        imageAttachment.image = nil
        layoutIfNeeded()
    }
    
    func configureCell(usingViewModel viewModel: ConversationCellViewModel) {
//        print(imageAttachment.image)
        print(imageAttachment.bounds.size)
        defer {
            handleMessageBubbleLayout()
        }
        
        cleanupCellContent()
        
        self.cellViewModel = viewModel
        setupBinding()
        
        timeStamp.text = viewModel.timestamp

        if viewModel.messageText != "" {
            messageContainer.text = viewModel.messageText
            return
        }
        if viewModel.imageData.value != nil  {
            configureImageAttachment(data: viewModel.imageData.value!)
            return
        }
        if viewModel.imagePath != nil && viewModel.imageData.value == nil  {
            configureImageAttachment()
            viewModel.fetchImageData()
            return
        }
    }
    
    //MARK: - LIFECYCLE
  
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        setupContentViewConstraints()
        setupMainCellContainer()
//        mainCellContainer.backgroundColor = .alizarin
        setupMessageTextView()
        setupTimestamp()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
// MARK: - UI INITIAL STEUP
    
    private func setupMainCellContainer() {
        contentView.addSubview(mainCellContainer)

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
        
        messageContainer.backgroundColor = .blue
        
        
        messageContainer.textColor = .white
        messageContainer.font = UIFont(name: "HelveticaNeue", size: 17)
        messageContainer.isEditable = false
        messageContainer.isScrollEnabled = false
        messageContainer.isSelectable = false
        messageContainer.textContainer.maximumNumberOfLines = 0 // Allow multiple lines
//        messageContainer.textContainer.lineFragmentPadding = 1.5
//        messageContainer.textContainerInset = UIEdgeInsets(top: 5, left: 5, bottom: 5, right: 5)
//        messageContainer.sizeToFit()
        messageContainer.contentMode = .scaleToFill
        messageContainer.translatesAutoresizingMaskIntoConstraints = false
        messageContainer.layer.cornerRadius = 15
        messageContainer.clipsToBounds = true
        
        NSLayoutConstraint.activate([
//            messageContainer.widthAnchor.constraint(equalToConstant: 300),

            messageContainer.topAnchor.constraint(equalTo: mainCellContainer.topAnchor),
            messageContainer.bottomAnchor.constraint(equalTo: mainCellContainer.bottomAnchor)
        ])
    }
    
    private func setupTimestamp() {
        mainCellContainer.addSubview(timeStamp)
        
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
//            contentView.heightAnchor.constraint(equalToConstant: 250),
//            contentView.widthAnchor.constraint(equalToConstant: 200),
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
                adjustMessagePadding(.rightSpace)
            } else {
                adjustMessagePadding(.bottomSpace)
            }
        }
        
    }
    
    private func adjustMessagePadding(_ messagePadding: MessagePadding) {
        switch messagePadding {
        case .initial: messageContainer.textContainerInset = UIEdgeInsets(top: 6, left: 6, bottom: 6, right: 6)
        case .rightSpace: messageContainer.textContainerInset.right = 41
        case .bottomSpace: messageContainer.textContainerInset.bottom += 15
        case .imageSpace: messageContainer.textContainerInset = UIEdgeInsets(top: 4, left: 5, bottom: 4, right: 5)
        }
        messageContainer.invalidateIntrinsicContentSize()
    }
}

// MARK: - HANDLE IMAGE TO MESSAGE ATTACHEMENT

extension ConversationCollectionViewCell {
    
    private func configureImageAttachment(data: Data? = Data()) {
        if let imageData = data,
           let image = convertDataToImage(imageData) {
            imageAttachment.image = image
        } else {
            imageAttachment.image = UIImage()
        }
        if let cellImageSize = cellViewModel.imageSize {
            let cgSize = CGSize(width: cellImageSize.width, height: cellImageSize.height)
            imageAttachment.bounds.size = cellViewModel.getCellAspectRatio(forImageSize: cgSize)
            
        }
        let attributedString = NSAttributedString(attachment: imageAttachment)
        
        // 0 padding for image
        imageAttachment.lineLayoutPadding = -6
        
        messageContainer.textStorage.insert(attributedString, at: 0)
    }
    
    private func convertDataToImage(_ data: Data) -> UIImage? {
        guard let image = UIImage(data: data) else { return nil }
        return image
    }
}

// MARK: - GET LAST LINE MESSAGE STRING
extension ConversationCollectionViewCell {
    
    private func getStringFromLastLine(usingTextView textView: UITextView) -> String {
        guard textView.text != "" else { return "" }
        
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
