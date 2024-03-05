//
//  CustomCollectionViewCell.swift
//  ChatUpp
//
//  Created by Andrei Pripa on 10/11/23.
//

import UIKit
import YYText
//import ImageIO
//import AVFoundation

final class ConversationCollectionViewCell: UICollectionViewCell, UIScrollViewDelegate {
    
    enum MessageSide {
        case left
        case right
    }
    private enum MessagePadding {
        case initialSpacing
        case rightSpace
        case bottomSpace
        case imageSpace
    }
    
    private var mainCellContainerMaxWidthConstraint: NSLayoutConstraint!
    private var messageContainerLeadingConstraint: NSLayoutConstraint!
    private var messageContainerTrailingConstraint: NSLayoutConstraint!
    //    private var widthConstraint: NSLayoutConstraint!
    
    var mainCellContainer = UIView()
    var messageContainer = YYLabel()
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
    
    private func makeAttributedStringForMessage() -> NSAttributedString {
        return NSAttributedString(string: cellViewModel.cellMessage.messageBody, attributes: [
            .font: UIFont(name: "HelveticaNeue", size: 17)!,
            .foregroundColor: UIColor.white,
            .paragraphStyle: {
                let paragraphStyle = NSMutableParagraphStyle()
                paragraphStyle.alignment = .left
                paragraphStyle.lineBreakMode = .byWordWrapping
                return paragraphStyle
            }()
        ])
    }

    private func cleanupCellContent() {
        messageContainer.attributedText = nil
//        imageAttachment.image = nil
        layoutIfNeeded()
    }
    
    func configureCell(usingViewModel viewModel: ConversationCellViewModel) {
//        defer {
//            handleMessageBubbleLayout()
//        }
//        cleanupCellContent()
        
        self.cellViewModel = viewModel
        timeStamp.text = viewModel.timestamp
        
        setupBinding()

        if viewModel.cellMessage.messageBody != "" {
            messageContainer.attributedText = makeAttributedStringForMessage()
            handleMessageBubbleLayout()
            return
        }
        if viewModel.imageData.value != nil {
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
        messageContainer.numberOfLines = 0
        messageContainer.preferredMaxLayoutWidth = maxMessageWidth
        messageContainer.contentMode = .redraw
        messageContainer.layer.cornerRadius = 15
        messageContainer.clipsToBounds = true
        
        adjustMessagePadding(.initialSpacing)
        
        messageContainer.translatesAutoresizingMaskIntoConstraints = false
//        widthConstraint = messageContainer.widthAnchor.constraint(equalToConstant: maxMessageWidth)
        
        NSLayoutConstraint.activate([
//            widthConstraint,
            messageContainer.topAnchor.constraint(equalTo: mainCellContainer.topAnchor),
            messageContainer.bottomAnchor.constraint(equalTo: mainCellContainer.bottomAnchor),
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
        updateMessageTextLayout()
        
        guard let lastLineMessageWidth = getMessageLastLineSize() else {return}
        guard let numberOfMessageLines = messageContainer.textLayout?.lines.count else {return}
        
        let padding: CGFloat = 20
        let lastLineMessageAndTimestampWidth = (lastLineMessageWidth + timeStamp.intrinsicContentSize.width) + padding
        let messageRectWidth = messageContainer.intrinsicContentSize.width
        
        if lastLineMessageAndTimestampWidth > 259 {
            adjustMessagePadding(.bottomSpace)
            return
        }
        if lastLineMessageAndTimestampWidth <= 259 {
            if numberOfMessageLines == 1 {
                adjustMessagePadding(.rightSpace)
            } else if lastLineMessageAndTimestampWidth > messageRectWidth {
                let difference = lastLineMessageAndTimestampWidth - messageRectWidth
                messageContainer.textContainerInset.right += difference + padding / 2
            }
        }
    }
    
    func updateMessageTextLayout() {
//        layoutIfNeeded()
        let textLayout = YYTextLayout(containerSize: CGSize(width: messageContainer.intrinsicContentSize.width, height: messageContainer.intrinsicContentSize.height), text: messageContainer.attributedText!)
        messageContainer.textLayout = textLayout
        adjustMessagePadding(.initialSpacing)
    }
    
    func getMessageLastLineSize() -> CGFloat? {
        if let lastLine = messageContainer.textLayout?.lines.last {
            let range = lastLine.range
            let labelAttributedString = messageContainer.attributedText
            let lastLineString = labelAttributedString?.attributedSubstring(from: range)
            print("last line string: ", lastLineString?.string ,"last line width: " ,lastLine.lineWidth)
            return lastLine.lineWidth
        }
        return nil
    }
    
    private func adjustMessagePadding(_ messagePadding: MessagePadding) {
        switch messagePadding {
        case .initialSpacing: messageContainer.textContainerInset = UIEdgeInsets(top: 6, left: 10, bottom: 6, right: 10)
        case .rightSpace: messageContainer.textContainerInset.right = timeStamp.intrinsicContentSize.width + 15
        case .bottomSpace: messageContainer.textContainerInset.bottom += 14
        case .imageSpace: messageContainer.textContainerInset = UIEdgeInsets(top: 3, left: 4, bottom: 3, right: 4)
        }
        messageContainer.invalidateIntrinsicContentSize()
    }
}

// MARK: - HANDLE IMAGE OF MESSAGE SETUP

extension ConversationCollectionViewCell {
    
    private func configureImageAttachment(data: Data? = Data()) {
        var messageImage = UIImage()
        if let imageData = data, let image = convertDataToImage(imageData) {
            messageImage = image
        }

        if let cellImageSize = cellViewModel.cellMessage.imageSize {
            let cgSize = CGSize(width: cellImageSize.width, height: cellImageSize.height)
            let testSize = cellViewModel.getCellAspectRatio(forImageSize: cgSize)
            messageImage = messageImage.resize(to: CGSize(width: testSize.width, height: testSize.height)).roundedCornerImage(with: 12)
        }
        let imageAttributedString = NSMutableAttributedString.yy_attachmentString(withContent: messageImage, contentMode: .center, attachmentSize: messageImage.size, alignTo: UIFont(name: "HelveticaNeue", size: 18)!, alignment: .center)
        
        messageContainer.attributedText = imageAttributedString
        adjustMessagePadding(.imageSpace)
    }
    
    private func convertDataToImage(_ data: Data) -> UIImage? {
        guard let image = UIImage(data: data) else { return nil }
        return image
    }
}
