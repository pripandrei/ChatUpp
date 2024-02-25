//
//  CustomCollectionViewCell.swift
//  ChatUpp
//
//  Created by Andrei Pripa on 10/11/23.
//

import UIKit
import ImageIO
import AVFoundation
import DTCoreText

final class ConversationCollectionViewCell: UICollectionViewCell, UIScrollViewDelegate {
    
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
    var messageContainer = DTAttributedTextContentView()
    private var timeStamp = UILabel()
    var cellViewModel: ConversationCellViewModel!
    
    var maxMessageWidth: CGFloat {
        return self.frame.width * 2 / 3
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
//        messageContainer.text = ""
        imageAttachment.image = nil
        layoutIfNeeded()
    }
    
    func configureCell(usingViewModel viewModel: ConversationCellViewModel) {
        defer {
            handleMessageBubbleLayout()
        }
        
        cleanupCellContent()
        
        self.cellViewModel = viewModel
        setupBinding()
        
        timeStamp.text = viewModel.timestamp

        if viewModel.cellMessage.messageBody != "" {
            let attributedString = NSAttributedString(string: viewModel.cellMessage.messageBody, attributes: [
                .font: UIFont(name: "HelveticaNeue", size: 17),
                .foregroundColor: UIColor.white,
                .paragraphStyle: {
                    let paragraphStyle = NSMutableParagraphStyle()
                    paragraphStyle.alignment = .left
                    paragraphStyle.lineBreakMode = .byWordWrapping
                    return paragraphStyle
                }()
            ])
            messageContainer.attributedString = attributedString
            return
        }
        if viewModel.imageData.value != nil  {
            configureImageAttachment(data: viewModel.imageData.value!)
            return
        }
        if viewModel.cellMessage.imagePath != nil && viewModel.imageData.value == nil  {
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
        setupMessageTextView()
        setupTimestamp()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
// MARK: - UI INITIAL STEUP
    
    private func setupMainCellContainer() {
        contentView.addSubview(mainCellContainer)
        mainCellContainer.backgroundColor = .amethyst
        mainCellContainer.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            mainCellContainer.topAnchor.constraint(equalTo: contentView.topAnchor),
            mainCellContainer.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
            mainCellContainer.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            mainCellContainer.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
        ])
    }
    
    private func setupMessageTextView() {
        mainCellContainer.addSubview(messageContainer)

        messageContainer.backgroundColor = .blue
        messageContainer.delegate = self
        messageContainer.contentMode = .redraw
//        messageContainer.layer.cornerRadius = 15
//        messageContainer.clipsToBounds = true
        
        messageContainer.translatesAutoresizingMaskIntoConstraints = false
 
        widthConstraint = messageContainer.widthAnchor.constraint(equalToConstant: 260)
        
        NSLayoutConstraint.activate([
            widthConstraint,
            messageContainer.topAnchor.constraint(equalTo: mainCellContainer.topAnchor),
            messageContainer.bottomAnchor.constraint(equalTo: mainCellContainer.bottomAnchor),
        ])
    }
    
    var widthConstraint: NSLayoutConstraint!
    
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
            messageContainerTrailingConstraint = messageContainer.trailingAnchor.constraint(equalTo: mainCellContainer.trailingAnchor)
            messageContainerLeadingConstraint.isActive = true
            messageContainerTrailingConstraint.isActive = true
            messageContainer.backgroundColor = #colorLiteral(red: 0.7171613574, green: 0.4463854432, blue: 0.351280123, alpha: 1)
        case .left:
            messageContainerLeadingConstraint = messageContainer.leadingAnchor.constraint(equalTo: mainCellContainer.leadingAnchor)
            messageContainerTrailingConstraint = messageContainer.trailingAnchor.constraint(lessThanOrEqualTo: mainCellContainer.trailingAnchor)
            messageContainerLeadingConstraint.isActive = true
            messageContainerTrailingConstraint.isActive = true
            
            messageContainer.backgroundColor = #colorLiteral(red: 0, green: 0.6150025129, blue: 0.6871898174, alpha: 1)
        }
    }
    
    // MARK: - MESSAGE BUBBLE LAYOUT HANDLER
    
    func handleMessageBubbleLayout() {
        adjustMessagePadding(.initial)
        
        if messageContainer.attributedString == nil {
            messageContainer.attributedString = NSAttributedString(string: "")
        }
        let boundingRect: CGRect = messageContainer.attributedString.boundingRect(with: .init(width: 260.0, height: .greatestFiniteMagnitude), options: .usesLineFragmentOrigin, context: nil)
        widthConstraint.constant = ceil(boundingRect.width + 18)

        layoutIfNeeded()
        
        let padding :CGFloat = 18
        
        guard let lastLineString = getLastLineFromMessageAttributedString()?.string else {return}

        let lastLineStringWidth = lastLineString.getSize().width
        let lastLineWithTimestempWidth = (lastLineStringWidth + timeStamp.bounds.width) + padding
        let messageRectWidth = messageContainer.intrinsicContentSize().width

        if lastLineWithTimestempWidth > messageRectWidth {
            if lastLineWithTimestempWidth.rounded(.up) < maxMessageWidth  {
                adjustMessagePadding(.rightSpace)
                widthConstraint.constant += timeStamp.frame.width + 5
                layoutIfNeeded()
            } else {
                adjustMessagePadding(.bottomSpace)
            }
        }
    }
    
    private func getLastLineFromMessageAttributedString() -> NSAttributedString? {
        if let lines = messageContainer.layoutFrame.lines as? [DTCoreTextLayoutLine], let lastLine = lines.last {
            let string = lastLine.stringRange()
            let attributedString = messageContainer.attributedString
            return attributedString?.attributedSubstring(from: string)
        }
        return nil
    }
    
    private func adjustMessagePadding(_ messagePadding: MessagePadding) {
        switch messagePadding {
        case .initial: messageContainer.edgeInsets = UIEdgeInsets(top: 6, left: 6, bottom: 6, right: 6)
        case .rightSpace: messageContainer.edgeInsets.right = timeStamp.intrinsicContentSize.width
        case .bottomSpace: messageContainer.edgeInsets.bottom += 15
        case .imageSpace: messageContainer.edgeInsets = UIEdgeInsets(top: 4, left: 5, bottom: 4, right: 5)
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
        if let cellImageSize = cellViewModel.cellMessage.imageSize {
            let cgSize = CGSize(width: cellImageSize.width, height: cellImageSize.height)
            imageAttachment.bounds.size = cellViewModel.getCellAspectRatio(forImageSize: cgSize)
            
        }
        let attributedString = NSAttributedString(attachment: imageAttachment)
        
        // 0 padding for image
        imageAttachment.lineLayoutPadding = -6
        
//        messageContainer.textStorage.insert(attributedString, at: 0)
    }
    
    private func convertDataToImage(_ data: Data) -> UIImage? {
        guard let image = UIImage(data: data) else { return nil }
        return image
    }
}

// MARK: - GET LAST LINE MESSAGE STRING
//extension ConversationCollectionViewCell {
//
//    private func getStringFromLastLine(usingTextView textView: UITextView) -> String {
//        guard textView.text != "" else { return "" }
//
//        let selectedRangee = textView.selectedRange
//        let glyphRange = textView.layoutManager.glyphRange(forCharacterRange: selectedRangee, actualCharacterRange: nil)
//
//        let glyphIndex = glyphRange.lowerBound == textView.layoutManager.numberOfGlyphs ? glyphRange.lowerBound - 1 : glyphRange.lowerBound
//
//        var effectiveGlyphRange = NSRange(location: 0, length: 0)
//
//        textView.layoutManager.lineFragmentRect(forGlyphAt: glyphIndex , effectiveRange: &effectiveGlyphRange)
//        let effectiveCharRange = textView.layoutManager.characterRange(forGlyphRange: effectiveGlyphRange, actualGlyphRange: nil)
//
//        let rangeStart = effectiveCharRange.location
//        let rangeLength = effectiveCharRange.length
//
//        guard let validRange = Range(NSRange(location: rangeStart, length: rangeLength), in: textView.text!)
//        else { print("Invalid range"); return "" }
//
//        let substring = textView.text![validRange]
//        return String(substring)
//        return ""
//    }
//}

//extension UITextView {
//    func lastLine() -> String {
//        guard let text = text as NSString? else {
//            return "nil"
//        }
//
//        // Calculate the range for the last line
//        let lastGlyphIndex = layoutManager.glyphIndexForCharacter(at: text.length - 1)
//        let lastLineRange = layoutManager.lineFragmentRect(forGlyphAt: lastGlyphIndex, effectiveRange: nil)
//        let lastLineRect = layoutManager.boundingRect(forGlyphRange: NSRange(location: lastGlyphIndex, length: 1), in: textContainer)
//
//        // Check if the last line is visible in the text view
//        if lastLineRect.maxY < contentOffset.y || lastLineRect.minY > contentOffset.y + bounds.height {
//            // Last line is not currently visible
//            return "nil"
//        }
//
//        // Extract the last line string
//        let lastLineStartIndex = layoutManager.characterIndexForGlyph(at: lastGlyphIndex)
//        let lastLine = text.substring(from: lastLineStartIndex)
//        return lastLine
//    }
//}


extension ConversationCollectionViewCell: DTAttributedTextContentViewDelegate {
    
//    func attributedTextContentView(_ attributedTextContentView: DTAttributedTextContentView!, willDraw layoutFrame: DTCoreTextLayoutFrame!, in context: CGContext!) {
////        print("")
////        handleMessageBubbleLayout()
//    }
//
//    func attributedTextContentView(_ attributedTextContentView: DTAttributedTextContentView!, didDraw layoutFrame: DTCoreTextLayoutFrame!, in context: CGContext!) {
//        //        let asd = layoutFrame.linesContained(in: messageContainer.bounds)
//        //        print(layoutFrame.linesContained(in: messageContainer.bounds))
//        //        print(layoutFrame.lines.last)
//        //        print(messageContainer.lastLine())
//                layoutFrame.numberOfLines = 0
//
//
//        if let lines = layoutFrame.lines as? [DTCoreTextLayoutLine], let lastLine = lines.last {
//            let string = lastLine.stringRange()
//            let attributedString = attributedTextContentView.attributedString
//            let plainText = attributedString?.attributedSubstring(from: string)
//        }
////        handleMessageBubbleLayout()
//    }
}
