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

final class ConversationCollectionViewCell: UITableViewCell, UIScrollViewDelegate {
    
    enum BubbleMessageSide {
        case left
        case right
    }
    private enum BubbleMessagePadding {
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
    private var timeStamp = YYLabel()
    var cellViewModel: ConversationCellViewModel!
    private var messageImage: UIImage?
    
    var maxMessageWidth: CGFloat {
        return 290.0
    }
    private let cellSpacing = 5.0
    
    private func makeAttributedStringForMessage() -> NSAttributedString {
        return NSAttributedString(string: cellViewModel.cellMessage.messageBody, attributes: [
            .font: UIFont(name: "Helvetica", size: 17)!,
            .foregroundColor: UIColor.white,
            .paragraphStyle: {
                let paragraphStyle = NSMutableParagraphStyle()
                paragraphStyle.alignment = .left
                paragraphStyle.lineBreakMode = .byWordWrapping
                return paragraphStyle
            }()
        ])
    }

    //MARK: - BINDER
    private func setupBinding() {
        cellViewModel.imageData.bind { [weak self] data in
            if data == self?.cellViewModel.imageData.value {
                DispatchQueue.main.async {
                    self?.configureImageAttachment(data: data)
                }
            }
        }
    }

    //MARK: - CELL PREPARE CLEANUP
    private func cleanupCellContent() {
        messageContainer.attributedText = nil
        timeStamp.text = nil
        timeStamp.backgroundColor = .clear
        messageImage = nil
        sennStatusMark.attributedText = nil
        timeStamp.textContainerInset = .zero
        adjustMessagePadding(.initialSpacing)
        contentView.layoutIfNeeded()
    }
    
    //MARK: - CELL DATA CONFIGURATION
    func configureCell(usingViewModel viewModel: ConversationCellViewModel) {
        cleanupCellContent()
        
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
    
    func configureMessageSeenStatus() {
        let iconSize = cellViewModel.cellMessage.messageSeen ? CGSize(width: 16, height: 15) : CGSize(width: 18, height: 14)
        let seenStatusIcon = cellViewModel.cellMessage.messageSeen ? SeenStatusIcon.double.rawValue : SeenStatusIcon.single.rawValue
        guard let seenStatusIconImage = UIImage(named: seenStatusIcon)?.resize(to: iconSize) else {return}

        let imageAttributedString = NSMutableAttributedString.yy_attachmentString(withContent: seenStatusIconImage, contentMode: .center, attachmentSize: seenStatusIconImage.size, alignTo: UIFont(name: "Helvetica", size: 4)!, alignment: .center)
      
        sennStatusMark.attributedText = imageAttributedString
    }
    
    //MARK: - LIFECYCLE
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        
        
//        transform = CGAffineTransform(scaleX: 1, y: -1)
        backgroundColor = #colorLiteral(red: 0.1411764771, green: 0.3960784376, blue: 0.5647059083, alpha: 1)
        setupContentViewConstraints()
        setupMainCellContainer()
        setupMessageTextLabel()
        setupTimestamp()
        setupSeenStatusMark()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
// MARK: - UI INITIAL STEUP
    
    enum SeenStatusIcon: String {
        case single = "icons8-done-64-6"
        case double = "icons8-double-tick-48-3"
    }
    
    var sennStatusMark = YYLabel()
    
    private func setupSeenStatusMark() {
        mainCellContainer.addSubview(sennStatusMark)
        
        sennStatusMark.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            sennStatusMark.trailingAnchor.constraint(equalTo: messageContainer.trailingAnchor, constant: -5),
            sennStatusMark.bottomAnchor.constraint(equalTo: messageContainer.bottomAnchor, constant: -5)
        ])
        
    }
    
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
    
    private func setupMessageTextLabel() {
        mainCellContainer.addSubview(messageContainer)

        messageContainer.backgroundColor = .blue
        messageContainer.numberOfLines = 0
        messageContainer.preferredMaxLayoutWidth = maxMessageWidth
        messageContainer.contentMode = .redraw
        messageContainer.layer.cornerRadius = 15
        messageContainer.clipsToBounds = true
        
        messageContainer.translatesAutoresizingMaskIntoConstraints = false
//        widthConstraint = messageContainer.widthAnchor.constraint(equalToConstant: maxMessageWidth)

        NSLayoutConstraint.activate([
//            widthConstraint,
            messageContainer.topAnchor.constraint(equalTo: mainCellContainer.topAnchor, constant: cellSpacing),
            messageContainer.bottomAnchor.constraint(equalTo: mainCellContainer.bottomAnchor),
//            messageContainer.widthAnchor.constraint(lessThanOrEqualToConstant: maxMessageWidth)
        ])
    }
    
    private func setupTimestamp() {
        mainCellContainer.addSubview(timeStamp)
        
        timeStamp.font = UIFont(name: "TimesNewRomanPSMT", size: 12)
        timeStamp.layer.cornerRadius = 7
        timeStamp.clipsToBounds = true
        timeStamp.textColor = #colorLiteral(red: 0.74693048, green: 0.7898075581, blue: 1, alpha: 1)
        timeStamp.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            timeStamp.trailingAnchor.constraint(equalTo: messageContainer.trailingAnchor, constant: -8),
            timeStamp.bottomAnchor.constraint(equalTo: messageContainer.bottomAnchor, constant: -5)
        ])
    }
    
    private func setupTimestampBackgroundForImage() {
        timeStamp.backgroundColor = .darkGray.withAlphaComponent(0.6)
        timeStamp.textContainerInset = UIEdgeInsets(top: 2, left: 6, bottom: 2, right: 6)
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
}

// MARK: - MESSAGE BUBBLE LAYOUT HANDLER
extension ConversationCollectionViewCell
{
    func handleMessageBubbleLayout() {
        createMessageTextLayout()
    
        guard let lastLineMessageWidth = getMessageLastLineSize() else {return}
        guard let numberOfMessageLines = messageContainer.textLayout?.lines.count else {return}
        
        let padding: CGFloat = 20.0
        let lastLineMessageAndTimestampWidth = (lastLineMessageWidth + timeStamp.intrinsicContentSize.width) + padding
        let messageRectWidth = messageContainer.intrinsicContentSize.width
        
        if lastLineMessageAndTimestampWidth > maxMessageWidth  {
            adjustMessagePadding(.bottomSpace)
            return
        }
        if lastLineMessageAndTimestampWidth <= maxMessageWidth {
            if numberOfMessageLines == 1 {
                adjustMessagePadding(.rightSpace)
            } else if lastLineMessageAndTimestampWidth > messageRectWidth {
                let difference = lastLineMessageAndTimestampWidth - messageRectWidth
                messageContainer.textContainerInset.right = difference + padding / 2
            }
        }
    }
    
    func createMessageTextLayout() {
        let textLayout = YYTextLayout(containerSize: CGSize(width: messageContainer.intrinsicContentSize.width, height: messageContainer.intrinsicContentSize.height), text: messageContainer.attributedText!)
        messageContainer.textLayout = textLayout
        adjustMessagePadding(.initialSpacing)
    }
    
    func getMessageLastLineSize() -> CGFloat? {
        if let lastLine = messageContainer.textLayout?.lines.last {
//            print(lastLine.bounds)
//            print("String: ",messageContainer.textLayout?.text.string)
//            print("number of lines: ",messageContainer.textLayout?.lines.count)
//            let range = lastLine.range
//            let labelAttributedString = messageContainer.attributedText
//            let lastLineString = labelAttributedString?.attributedSubstring(from: range)
            return lastLine.lineWidth
        }
        return nil
    }
    
    // MARK: - MESSAGE BUBBLE CONSTRAINTS
    func adjustMessageSide(_ side: BubbleMessageSide) {
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
    // MARK: - MESSAGE BUBBLE PADDING
    private func adjustMessagePadding(_ messagePadding: BubbleMessagePadding) {
        switch messagePadding {
        case .initialSpacing: messageContainer.textContainerInset = UIEdgeInsets(top: 6, left: 10, bottom: 6, right: 10)
        case .rightSpace: messageContainer.textContainerInset = UIEdgeInsets(top: 6, left: 10, bottom: 6, right: timeStamp.intrinsicContentSize.width + 10)
        case .bottomSpace: messageContainer.textContainerInset = UIEdgeInsets(top: 6, left: 10, bottom: 20, right: 10)
        case .imageSpace: messageContainer.textContainerInset = UIEdgeInsets(top: 3, left: 4, bottom: 3, right: 4)
        }
        messageContainer.invalidateIntrinsicContentSize()
    }
}

// MARK: - HANDLE IMAGE OF MESSAGE SETUP
extension ConversationCollectionViewCell {
    
    private func configureImageAttachment(data: Data? = Data()) {
        if let imageData = data, let image = convertDataToImage(imageData) {
            messageImage = image
        } else {
            messageImage = UIImage()
        }
        if let cellImageSize = cellViewModel.cellMessage.imageSize {
            let cgSize = CGSize(width: cellImageSize.width, height: cellImageSize.height)
            let testSize = cellViewModel.getCellAspectRatio(forImageSize: cgSize)
            messageImage = messageImage?.resize(to: CGSize(width: testSize.width, height: testSize.height)).roundedCornerImage(with: 12)
        }
        let imageAttributedString = NSMutableAttributedString.yy_attachmentString(withContent: messageImage, contentMode: .center, attachmentSize: messageImage!.size, alignTo: UIFont(name: "Helvetica", size: 17)!, alignment: .center)
        
        messageContainer.attributedText = imageAttributedString
        setupTimestampBackgroundForImage()
        adjustMessagePadding(.imageSpace)
    }
    
    private func convertDataToImage(_ data: Data) -> UIImage? {
        guard let image = UIImage(data: data) else { return nil }
        return image
    }
}
