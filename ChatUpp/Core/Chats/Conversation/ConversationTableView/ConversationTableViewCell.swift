//
//  CustomCollectionViewCell.swift
//  ChatUpp
//
//  Created by Andrei Pripa on 10/11/23.
//

import UIKit
import YYText

final class ConversationTableViewCell: UITableViewCell {
    
    enum BubbleMessageSide {
        case left
        case right
    }
    private enum BubbleMessagePadding {
        case initialSpacing
        case incomingMessageRightSpace
        case outgoingMessageRightSapce
        case bottomSpace
        case imageSpace
    }
    
    private enum SeenStatusIcon: String {
        case single = "icons8-done-64-6"
        case double = "icons8-double-tick-48-3"
    }
    
    private var mainCellContainerMaxWidthConstraint: NSLayoutConstraint!
    private var messageContainerLeadingConstraint: NSLayoutConstraint!
    private var messageContainerTrailingConstraint: NSLayoutConstraint!
    
    var mainCellContainer = UIView()
    var messageBubbleContainer = UIView()
    var messageLabel = YYLabel()
    private var timeStamp = YYLabel()
    var seenStatusMark = YYLabel()
    private var messageImage: UIImage?
    var editedLabel: UILabel?
    var cellViewModel: ConversationCellViewModel!
//    var contextMenuInteraction: MessageContextMenuInteractionHandler!
    
    private var maxMessageWidth: CGFloat {
        return 290.0
    }
    private let cellSpacing = 3.0
    
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
    
  
    
    //MARK: - LIFECYCLE
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)

        // Invert cell upside down
        transform = CGAffineTransform(scaleX: 1, y: -1)
        
        backgroundColor = #colorLiteral(red: 0.1411764771, green: 0.3960784376, blue: 0.5647059083, alpha: 1)
//        setupContentViewConstraints()
        setupBackgroundSelectionView()
        setupMainCellContainer()
        setupReplyMessageContainer()
        setupMessageTextLabel()
        setupSeenStatusMark()
        setupTimestamp()
//        setupEditedLabel()
//        contextMenuInteraction = MessageContextMenuInteractionHandler(message: messageContainer)
    }
    
    // implement for proper cell selection highlight when using UIMenuContextConfiguration on tableView
    private func setupBackgroundSelectionView() {
        let selectedView = UIView()
        selectedView.backgroundColor = UIColor.clear
        selectedBackgroundView = selectedView
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
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
        messageLabel.attributedText = nil
        timeStamp.text = nil
        timeStamp.backgroundColor = .clear
        messageImage = nil
        seenStatusMark.attributedText = nil
        timeStamp.textContainerInset = .zero
//        editedLabel = nil
        editedLabel?.text = nil
        adjustMessagePadding(.initialSpacing)
        
        // Layout with no animation to hide resizing animation of cells on keyboard show/hide
        // or any other table view content offset change
        UIView.performWithoutAnimation {
            self.contentView.layoutIfNeeded()
        }
    }
    
    //MARK: - CELL DATA CONFIGURATION
    func configureCell(usingViewModel viewModel: ConversationCellViewModel, forSide side: BubbleMessageSide) {
        
        cleanupCellContent()
        
        self.cellViewModel = viewModel
        setupEditedLabel()
        timeStamp.text = viewModel.timestamp
        setupBinding()
        adjustMessageSide(side)

        if viewModel.cellMessage.messageBody != "" {
            messageLabel.attributedText = makeAttributedStringForMessage()
            handleMessageBubbleLayout(forSide: side)
            return
        }
        configureImageAttachment(data: viewModel.imageData.value)
    }
    
    func configureMessageSeenStatus() {
        let iconSize = cellViewModel.cellMessage.messageSeen ? CGSize(width: 15, height: 14) : CGSize(width: 16, height: 12)
        let seenStatusIcon = cellViewModel.cellMessage.messageSeen ? SeenStatusIcon.double.rawValue : SeenStatusIcon.single.rawValue
        guard let seenStatusIconImage = UIImage(named: seenStatusIcon)?.resize(to: iconSize) else {return}

        let imageAttributedString = NSMutableAttributedString.yy_attachmentString(withContent: seenStatusIconImage, contentMode: .center, attachmentSize: seenStatusIconImage.size, alignTo: UIFont(name: "Helvetica", size: 4)!, alignment: .center)
      
        seenStatusMark.attributedText = imageAttributedString
    }
    
// MARK: - UI INITIAL STEUP
    
    private func setupEditedLabel() {
        if cellViewModel.cellMessage.isEdited {
            editedLabel = UILabel()
            guard let editedLabel = editedLabel else {return}
            
            messageLabel.addSubviews(editedLabel)
            
            editedLabel.font = UIFont(name: "TimesNewRomanPSMT", size: 13)
            editedLabel.text = "edited"
    //        editedLabel.layer.cornerRadius = 7
    //        editedLabel.clipsToBounds = true
            editedLabel.textColor = #colorLiteral(red: 0.74693048, green: 0.7898075581, blue: 1, alpha: 1)
    //        editedLabel.isHidden = true
            
            editedLabel.translatesAutoresizingMaskIntoConstraints = false
            
            NSLayoutConstraint.activate([
                editedLabel.trailingAnchor.constraint(equalTo: timeStamp.leadingAnchor, constant: -2),
                editedLabel.bottomAnchor.constraint(equalTo: messageLabel.bottomAnchor, constant: -5)
            ])
        }
    }
    
    private func setupSeenStatusMark() {
        messageLabel.addSubview(seenStatusMark)
        
        seenStatusMark.font = UIFont(name: "Helvetica", size: 4)
        seenStatusMark.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            seenStatusMark.trailingAnchor.constraint(equalTo: messageLabel.trailingAnchor, constant: -8),
            seenStatusMark.bottomAnchor.constraint(equalTo: messageLabel.bottomAnchor, constant: -5)
        ])
    }
    
    private func setupTimestamp() {
        messageLabel.addSubview(timeStamp)
        
        timeStamp.font = UIFont(name: "TimesNewRomanPSMT", size: 13)
        timeStamp.layer.cornerRadius = 7
        timeStamp.clipsToBounds = true
        timeStamp.textColor = #colorLiteral(red: 0.74693048, green: 0.7898075581, blue: 1, alpha: 1)
        timeStamp.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            timeStamp.trailingAnchor.constraint(equalTo: seenStatusMark.leadingAnchor, constant: -2),
            timeStamp.bottomAnchor.constraint(equalTo: messageLabel.bottomAnchor, constant: -5)
        ])
    }
    
    private func setupTimestampBackgroundForImage() {
        timeStamp.backgroundColor = .darkGray.withAlphaComponent(0.6)
        timeStamp.textContainerInset = UIEdgeInsets(top: 2, left: 6, bottom: 2, right: 6)
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
        messageBubbleContainer.addSubview(messageLabel)

        //TODO: - review implementing a main container for message,timestamp,seenstatus
        
        messageLabel.backgroundColor = .blue
        messageLabel.numberOfLines = 0
        messageLabel.preferredMaxLayoutWidth = maxMessageWidth
        messageLabel.contentMode = .redraw
        messageLabel.layer.cornerRadius = 15
        messageLabel.clipsToBounds = true
        
        messageLabel.translatesAutoresizingMaskIntoConstraints = false
//        widthConstraint = messageContainer.widthAnchor.constraint(equalToConstant: maxMessageWidth)

        NSLayoutConstraint.activate([
//            widthConstraint,
            messageLabel.topAnchor.constraint(equalTo: messageBubbleContainer.topAnchor),
            messageLabel.bottomAnchor.constraint(equalTo: messageBubbleContainer.bottomAnchor, constant: -cellSpacing),
            messageLabel.leadingAnchor.constraint(equalTo: messageBubbleContainer.leadingAnchor),
            messageLabel.trailingAnchor.constraint(equalTo: messageBubbleContainer.trailingAnchor),
//            messageContainer.widthAnchor.constraint(lessThanOrEqualToConstant: maxMessageWidth)
        ])
    }
    
//    private func setupContentViewConstraints() {
//        contentView.translatesAutoresizingMaskIntoConstraints = false
//        
//        NSLayoutConstraint.activate([
//           contentView.leadingAnchor.constraint(equalTo: leadingAnchor),
//           contentView.trailingAnchor.constraint(equalTo: trailingAnchor),
//           contentView.topAnchor.constraint(equalTo: topAnchor),
//           contentView.bottomAnchor.constraint(equalTo: bottomAnchor)
//        ])
//    }
}

// MARK: - MESSAGE BUBBLE LAYOUT HANDLER
extension ConversationTableViewCell
{
    func handleMessageBubbleLayout(forSide side: BubbleMessageSide) {
        createMessageTextLayout()
    
        guard let lastLineMessageWidth = getMessageLastLineSize() else {return}
        guard let numberOfMessageLines = messageLabel.textLayout?.lines.count else {return}
        
        let padding: CGFloat = 20.0
        let timestampWidth: CGFloat = timeStamp.intrinsicContentSize.width
        let seenStatusMarkWidth: CGFloat = 24.0
        
        let widthForSide = side == .right ? seenStatusMarkWidth : 0
        
        let lastLineMessageAndTimestampWidth = (lastLineMessageWidth + timestampWidth + widthForSide) + padding + editedMessageWidth()
        let messageRectWidth = messageLabel.intrinsicContentSize.width
        
        if lastLineMessageAndTimestampWidth > maxMessageWidth  {
            adjustMessagePadding(.bottomSpace)
            return
        }
        if lastLineMessageAndTimestampWidth <= maxMessageWidth {
            if numberOfMessageLines == 1 {
                side == .right ? adjustMessagePadding(.incomingMessageRightSpace) : adjustMessagePadding(.outgoingMessageRightSapce)
            } else if lastLineMessageAndTimestampWidth > messageRectWidth {
                let difference = lastLineMessageAndTimestampWidth - messageRectWidth
                messageLabel.textContainerInset.right = difference + padding / 2
            }
        }
    }
    
    func createMessageTextLayout() {
        let textLayout = YYTextLayout(containerSize: CGSize(width: messageLabel.intrinsicContentSize.width, height: messageLabel.intrinsicContentSize.height), text: messageLabel.attributedText!)
        messageLabel.textLayout = textLayout
        adjustMessagePadding(.initialSpacing)
    }
    
    func getMessageLastLineSize() -> CGFloat? {
        if let lastLine = messageLabel.textLayout?.lines.last {
            return lastLine.lineWidth
        }
        return nil
    }
    
    // MARK: - MESSAGE BUBBLE CONSTRAINTS
    func adjustMessageSide(_ side: BubbleMessageSide) {
        if messageContainerLeadingConstraint != nil { messageContainerLeadingConstraint.isActive = false }
        if messageContainerTrailingConstraint != nil { messageContainerTrailingConstraint.isActive = false }
        if side == .left {
            print("Side: ",side)
        }
        switch side {
        case .right:
            configureMessageSeenStatus()
            
            messageContainerLeadingConstraint = messageBubbleContainer.leadingAnchor.constraint(greaterThanOrEqualTo: mainCellContainer.leadingAnchor)
            messageContainerTrailingConstraint = messageBubbleContainer.trailingAnchor.constraint(equalTo: mainCellContainer.trailingAnchor, constant: -10)
            messageContainerLeadingConstraint.isActive = true
            messageContainerTrailingConstraint.isActive = true
            messageLabel.backgroundColor = #colorLiteral(red: 0.7171613574, green: 0.4463854432, blue: 0.351280123, alpha: 1)
        case .left:
            messageContainerLeadingConstraint = messageBubbleContainer.leadingAnchor.constraint(equalTo: mainCellContainer.leadingAnchor, constant: 10)
            messageContainerTrailingConstraint = messageBubbleContainer.trailingAnchor.constraint(lessThanOrEqualTo: mainCellContainer.trailingAnchor)
            messageContainerLeadingConstraint.isActive = true
            messageContainerTrailingConstraint.isActive = true
            messageLabel.backgroundColor = #colorLiteral(red: 0, green: 0.6150025129, blue: 0.6871898174, alpha: 1)
        }
    }
    // MARK: - MESSAGE BUBBLE PADDING
    private func adjustMessagePadding(_ messagePadding: BubbleMessagePadding) {
        switch messagePadding {
        case .initialSpacing: messageLabel.textContainerInset = UIEdgeInsets(top: 6, left: 10, bottom: 6, right: 10)
        case .incomingMessageRightSpace: messageLabel.textContainerInset = UIEdgeInsets(top: 6, left: 10, bottom: 6, right: timeStamp.intrinsicContentSize.width + seenStatusMark.intrinsicContentSize.width + 15 + editedMessageWidth())
        case .outgoingMessageRightSapce: messageLabel.textContainerInset = UIEdgeInsets(top: 6, left: 10, bottom: 6, right: timeStamp.intrinsicContentSize.width + 15 + editedMessageWidth())
        case .bottomSpace: messageLabel.textContainerInset = UIEdgeInsets(top: 6, left: 10, bottom: 20, right: 10)
        case .imageSpace: messageLabel.textContainerInset = UIEdgeInsets(top: 2, left: 2, bottom: 2, right: 2)
        }
        messageLabel.invalidateIntrinsicContentSize()
    }
    
    private func editedMessageWidth() -> Double {
        guard let editedLabel = editedLabel else {return 0}
        return editedLabel.intrinsicContentSize.width
    }
}

// MARK: - HANDLE IMAGE OF MESSAGE SETUP
extension ConversationTableViewCell {
    
    private func configureImageAttachment(data: Data?) {
        if let imageData = data, let image = convertDataToImage(imageData) {
            messageImage = image
        } else {
            messageImage = UIImage()
            cellViewModel.fetchImageData()
        }
        if let cellImageSize = cellViewModel.cellMessage.imageSize {
            let cgSize = CGSize(width: cellImageSize.width, height: cellImageSize.height)
            let testSize = cellViewModel.getCellAspectRatio(forImageSize: cgSize)
            messageImage = messageImage?.resize(to: CGSize(width: testSize.width, height: testSize.height)).roundedCornerImage(with: 12)
        }
        let imageAttributedString = NSMutableAttributedString.yy_attachmentString(withContent: messageImage, contentMode: .center, attachmentSize: messageImage!.size, alignTo: UIFont(name: "Helvetica", size: 17)!, alignment: .center)
        
        messageLabel.attributedText = imageAttributedString
        setupTimestampBackgroundForImage()
        adjustMessagePadding(.imageSpace)
    }
    
    private func convertDataToImage(_ data: Data) -> UIImage? {
        guard let image = UIImage(data: data) else { return nil }
        return image
    }
}


extension ConversationTableViewCell {
    
    func setupReplyMessageContainer() {
        mainCellContainer.addSubview(messageBubbleContainer)
        
        messageBubbleContainer.backgroundColor = .brown
        messageBubbleContainer.translatesAutoresizingMaskIntoConstraints = false
        
        messageBubbleContainer.topAnchor.constraint(equalTo: mainCellContainer.topAnchor).isActive = true
        messageBubbleContainer.bottomAnchor.constraint(equalTo: mainCellContainer.bottomAnchor).isActive = true
//        replayMessageContainer.widthAnchor.constraint(lessThanOrEqualToConstant: maxMessageWidth).isActive = true
    }
}
