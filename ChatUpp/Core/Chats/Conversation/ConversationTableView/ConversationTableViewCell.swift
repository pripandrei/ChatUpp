//
//  CustomCollectionViewCell.swift
//  ChatUpp
//
//  Created by Andrei Pripa on 10/11/23.
//

import UIKit
import YYText
import Combine
import SkeletonView

final class ConversationTableViewCell: UITableViewCell
{
    private var messageContainerLeadingConstraint: NSLayoutConstraint!
    private var messageContainerTrailingConstraint: NSLayoutConstraint!
    private var messageLabelTopConstraints: NSLayoutConstraint!
    
    private var messageImage: UIImage?
    private var replyMessageLabel: ReplyMessageLabel = ReplyMessageLabel()
    private var timeStamp = YYLabel()
    private var subscribers = Set<AnyCancellable>()
    
    private(set) var messageBubbleContainer = UIView()
    private(set) var messageLabel = YYLabel()
    private(set) var seenStatusMark = YYLabel()
    private(set) var editedLabel: UILabel?
    private(set) var cellViewModel: ConversationCellViewModel!
    
    private let cellSpacing = 3.0
    private var messageSide: MessageSide!
    private var maxMessageWidth: CGFloat {
        return 292.0
    }
    
    /// - lifecycle
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        
        // Invert cell upside down
        transform = CGAffineTransform(scaleX: 1, y: -1)
        
        backgroundColor = #colorLiteral(red: 0.1411764771, green: 0.3960784376, blue: 0.5647059083, alpha: 1)
        setupBackgroundSelectionView()
        setupMessageBubbleContainer()
        setupMessageTextLabel()
        setupSeenStatusMark()
        setupTimestamp()
    }
    
    // implement for proper cell selection highlight when using UIMenuContextConfiguration on tableView
    private func setupBackgroundSelectionView()
    {
        let selectedView = UIView()
        selectedView.backgroundColor = UIColor.clear
        selectedBackgroundView = selectedView
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    /// - binding
    ///
    private func setupBinding()
    {
        cellViewModel.$imageData
            .receive(on: DispatchQueue.main)
            .sink(receiveValue: { [weak self] data in
                guard let data = data else {return}
                if data == self?.cellViewModel.imageData {
                    self?.configureImageAttachment(data: data)
                }
            }).store(in: &subscribers)
    }
    
    /// - cell configuration
    ///
    func configureCell(usingViewModel viewModel: ConversationCellViewModel, forSide side: MessageSide)
    {
        self.cleanupCellContent()
        
        self.cellViewModel = viewModel
        self.messageSide = side
        self.timeStamp.text = viewModel.timestamp
        self.setupReplyMessage()
        self.setupEditedLabel()
        self.setupBinding()
        self.adjustMessageSide()
        
        if viewModel.cellMessage?.messageBody != "" {
            self.messageLabel.attributedText = self.makeAttributedStringForMessage()
            self.handleMessageBubbleLayout()
            return
        }
        configureImageAttachment(data: viewModel.imageData)
    }
    
    private func configureMessageSeenStatus()
    {
        guard let message = cellViewModel.cellMessage else {return}
        let iconSize = message.messageSeen ? CGSize(width: 15, height: 14) : CGSize(width: 16, height: 12)
        let seenStatusIcon = message.messageSeen ? SeenStatusIcon.double.rawValue : SeenStatusIcon.single.rawValue
        guard let seenStatusIconImage = UIImage(named: seenStatusIcon)?.resize(to: iconSize) else {return}
        
        let imageAttributedString = NSMutableAttributedString.yy_attachmentString(withContent: seenStatusIconImage, contentMode: .center, attachmentSize: seenStatusIconImage.size, alignTo: UIFont(name: "Helvetica", size: 4)!, alignment: .center)
        
        seenStatusMark.attributedText = imageAttributedString
    }
    
    private func makeAttributedStringForMessage() -> NSAttributedString?
    {
        guard let message = cellViewModel.cellMessage else {return nil}
        
        let attributes: [NSAttributedString.Key : Any] =
        [
            .font: UIFont(name: "Helvetica", size: 17)!,
            .foregroundColor: UIColor.white,
            .paragraphStyle: {
                let paragraphStyle = NSMutableParagraphStyle()
                paragraphStyle.alignment = .left
                paragraphStyle.lineBreakMode = .byWordWrapping
                return paragraphStyle
            }()
        ]
        return NSAttributedString(string: message.messageBody, attributes: attributes)
    }
    
    /// - cleanup
    private func cleanupCellContent()
    {
        messageLabel.attributedText = nil
        timeStamp.text = nil
        timeStamp.backgroundColor = .clear
        messageImage = nil
        seenStatusMark.attributedText = nil
        timeStamp.textContainerInset = .zero
        editedLabel?.text = nil
        replyMessageLabel.removeFromSuperview()
        applyMessagePadding(strategy: .initial)
        
        // Layout with no animation to hide resizing animation of cells on keyboard show/hide
        // or any other table view content offset change
        UIView.performWithoutAnimation {
            self.contentView.layoutIfNeeded()
        }
    }
}
    
// MARK: - UI INITIAL STEUP

extension ConversationTableViewCell
{
    private func setupMessageTextLabel()
    {
        messageLabel.numberOfLines = 0
        messageLabel.preferredMaxLayoutWidth = maxMessageWidth
        messageLabel.contentMode = .redraw
        messageLabel.layer.cornerRadius = 15
        messageLabel.clipsToBounds = true
        messageLabel.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
//            messageLabel.topAnchor.constraint(equalTo: replyMessageLabel.bottomAnchor),
            messageLabel.bottomAnchor.constraint(equalTo: messageBubbleContainer.bottomAnchor),
            messageLabel.leadingAnchor.constraint(equalTo: messageBubbleContainer.leadingAnchor),
            messageLabel.trailingAnchor.constraint(equalTo: messageBubbleContainer.trailingAnchor),
        ])
    }
    
    private func setupMessageBubbleContainer()
    {
        contentView.addSubview(messageBubbleContainer)
        
        messageBubbleContainer.addSubview(messageLabel)
        messageBubbleContainer.layer.cornerRadius = 15
        messageBubbleContainer.translatesAutoresizingMaskIntoConstraints = false
        messageBubbleContainer.topAnchor.constraint(equalTo: contentView.topAnchor).isActive = true
        messageBubbleContainer.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -cellSpacing).isActive = true
        messageBubbleContainer.widthAnchor.constraint(lessThanOrEqualToConstant: maxMessageWidth).isActive = true
    }
    
    private func setupEditedLabel()
    {
        guard cellViewModel.cellMessage?.isEdited == true else {return}
        
        editedLabel = UILabel()
        messageLabel.addSubviews(editedLabel!)
        
        editedLabel!.font = UIFont(name: "TimesNewRomanPSMT", size: 13)
        editedLabel!.text = "edited"
        editedLabel!.textColor = #colorLiteral(red: 0.74693048, green: 0.7898075581, blue: 1, alpha: 1)
        editedLabel!.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            editedLabel!.trailingAnchor.constraint(equalTo: timeStamp.leadingAnchor, constant: -2),
            editedLabel!.bottomAnchor.constraint(equalTo: messageLabel.bottomAnchor, constant: -5)
        ])
    }
    
    private func setupSeenStatusMark()
    {
        messageLabel.addSubview(seenStatusMark)
        
        seenStatusMark.font = UIFont(name: "Helvetica", size: 4)
        seenStatusMark.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            seenStatusMark.trailingAnchor.constraint(equalTo: messageLabel.trailingAnchor, constant: -8),
            seenStatusMark.bottomAnchor.constraint(equalTo: messageLabel.bottomAnchor, constant: -5)
        ])
    }
    
    private func setupTimestamp()
    {
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
    
    private func setupTimestampBackgroundForImage()
    {
        timeStamp.backgroundColor = .darkGray.withAlphaComponent(0.6)
        timeStamp.textContainerInset = UIEdgeInsets(top: 2, left: 6, bottom: 2, right: 6)
    }
    
    private func adjustMessageSide() {
        if messageContainerLeadingConstraint != nil { messageContainerLeadingConstraint.isActive = false }
        if messageContainerTrailingConstraint != nil { messageContainerTrailingConstraint.isActive = false }

        switch messageSide {
        case .right:
            configureMessageSeenStatus()
            
            messageContainerLeadingConstraint = messageBubbleContainer.leadingAnchor.constraint(greaterThanOrEqualTo: contentView.leadingAnchor)
            messageContainerTrailingConstraint = messageBubbleContainer.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -10)
            messageContainerLeadingConstraint.isActive = true
            messageContainerTrailingConstraint.isActive = true
            messageBubbleContainer.backgroundColor = #colorLiteral(red: 0.7171613574, green: 0.4463854432, blue: 0.351280123, alpha: 1)
        case .left:
            messageContainerLeadingConstraint = messageBubbleContainer.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 10)
            messageContainerTrailingConstraint = messageBubbleContainer.trailingAnchor.constraint(lessThanOrEqualTo: contentView.trailingAnchor)
            messageContainerLeadingConstraint.isActive = true
            messageContainerTrailingConstraint.isActive = true
            messageBubbleContainer.backgroundColor = #colorLiteral(red: 0, green: 0.6150025129, blue: 0.6871898174, alpha: 1)
        case .none:
            break
        }
    }
}

// MARK: - message bubble layout

extension ConversationTableViewCell
{
    private func handleMessageBubbleLayout()
    {
        createMessageTextLayout()
        let padding = getMessagePaddingStrategy()
        applyMessagePadding(strategy: padding)
    }
    
    private func createMessageTextLayout() {
        let textLayout = YYTextLayout(containerSize: CGSize(width: messageLabel.intrinsicContentSize.width, height: messageLabel.intrinsicContentSize.height), text: messageLabel.attributedText!)
        messageLabel.textLayout = textLayout
        applyMessagePadding(strategy: .initial)
    }
    
    /// padding strategy
    ///
    private func getMessagePaddingStrategy() -> TextPaddingStrategy
    {
        let padding = (TextPaddingStrategy.initial.padding.left * 2) + 3.0
        let expectedLineWidth = self.messageLastLineTextWidth + self.messageComponentsWidth
        
        guard expectedLineWidth < (maxMessageWidth - padding) else {
            return .bottom
        }
        
        if expectedLineWidth > self.messageTextBoundingWidth
        {
            let difference = expectedLineWidth - self.messageTextBoundingWidth
            return .trailling(space: difference)
        }
        return .initial
    }
    
    private func applyMessagePadding(strategy paddingStrategy: TextPaddingStrategy)
    {
        messageLabel.textContainerInset = paddingStrategy.padding
        messageLabel.invalidateIntrinsicContentSize()
    }
    
    /// computed properties
    private var messageComponentsWidth: CGFloat
    {
        let sideWidth = messageSide == .right ? seenStatusMark.intrinsicContentSize.width : 0.0
        return timeStamp.intrinsicContentSize.width + sideWidth + editedMessageWidth + 4.0
    }

    private var messageLastLineTextWidth: CGFloat {
        messageLabel.textLayout?.lines.last?.width ?? 0.0
    }

    private var messageTextBoundingWidth: CGFloat {
        return messageLabel.textLayout?.textBoundingRect.width ?? 0.0
    }
    
    private var editedMessageWidth: CGFloat {
        return editedLabel?.intrinsicContentSize.width ?? 0.0
    }
}

// MARK: - HANDLE IMAGE OF MESSAGE SETUP
extension ConversationTableViewCell
{
    private func configureImageAttachment(data: Data?) {
        setMessageImage(imageData: data)
        setMessageImageSize()
        setMessageLabelAttributedTextImage()
        setupTimestampBackgroundForImage()
        applyMessagePadding(strategy: .image)
    }

    private func setMessageImage(imageData: Data?) {
        if let imageData = imageData, let image = convertDataToImage(imageData) {
            messageImage = image
        } else {
            messageImage = UIImage()
            cellViewModel.fetchImageData()
        }
    }

    private func setMessageImageSize() {
        if let cellImageSize = cellViewModel.cellMessage?.imageSize {
            let cgSize = CGSize(width: cellImageSize.width, height: cellImageSize.height)
            let testSize = cellViewModel.getCellAspectRatio(forImageSize: cgSize)
            messageImage = messageImage?.resize(to: CGSize(width: testSize.width, height: testSize.height)).roundedCornerImage(with: 12)
        }
    }

    private func setMessageLabelAttributedTextImage() {
        let imageAttributedString = NSMutableAttributedString.yy_attachmentString(withContent: messageImage, contentMode: .center, attachmentSize: messageImage!.size, alignTo: UIFont(name: "Helvetica", size: 17)!, alignment: .center)

        messageLabel.attributedText = imageAttributedString
    }

    private func convertDataToImage(_ data: Data) -> UIImage? {
        guard let image = UIImage(data: data) else { return nil }
        return image
    }
}

//MARK: - Reply message setup
extension ConversationTableViewCell
{
    private func setupReplyMessage() {
        if messageLabelTopConstraints != nil { messageLabelTopConstraints.isActive = false }
        
        guard let messageSenderName = cellViewModel.senderNameOfMessageToBeReplied, let messageText = cellViewModel.textOfMessageToBeReplied  else {
            messageLabelTopConstraints = messageLabel.topAnchor.constraint(equalTo: messageBubbleContainer.topAnchor)
            messageLabelTopConstraints.isActive = true
            return
        }
        
        replyMessageLabel.attributedText = createReplyMessageAttributedText(with: messageSenderName, messageText: messageText)
        replyMessageLabel.numberOfLines = 2
        replyMessageLabel.layer.cornerRadius = 4
        replyMessageLabel.clipsToBounds = true
        replyMessageLabel.backgroundColor = .peterRiver
        replyMessageLabel.translatesAutoresizingMaskIntoConstraints = false
        messageBubbleContainer.addSubview(replyMessageLabel)
        
        replyMessageLabel.topAnchor.constraint(equalTo: messageBubbleContainer.topAnchor, constant: 10).isActive = true
        replyMessageLabel.trailingAnchor.constraint(equalTo: messageBubbleContainer.trailingAnchor, constant: -10).isActive = true
        replyMessageLabel.leadingAnchor.constraint(equalTo: messageBubbleContainer.leadingAnchor, constant: 10).isActive = true
        messageLabelTopConstraints = messageLabel.topAnchor.constraint(equalTo: replyMessageLabel.bottomAnchor)
        messageLabelTopConstraints.isActive = true
    }
    
    private func createReplyMessageAttributedText(with senderName: String, messageText: String) -> NSMutableAttributedString
    {
        let boldAttributeForName = [NSAttributedString.Key.font: UIFont.boldSystemFont(ofSize: 13)]
        let boldAttributeForText = [NSAttributedString.Key.font: UIFont.systemFont(ofSize: 13)]
        let attributedText = NSMutableAttributedString(string: senderName, attributes: boldAttributeForName)
        let replyMessageAttributedText = NSAttributedString(string: " \n\(messageText)", attributes: boldAttributeForText)
        attributedText.append(replyMessageAttributedText)
        
        return attributedText
    }
    
    /// Customized reply message to simplify left side indentation color fill and text inset
    class ReplyMessageLabel: UILabel
    {
        private let textInset = UIEdgeInsets(top: 5, left: 10, bottom: 5, right: 8)
        
        override var intrinsicContentSize: CGSize {
            get {
                var contentSize = super.intrinsicContentSize
                contentSize.height += textInset.top + textInset.bottom
                contentSize.width += textInset.left + textInset.right
                return contentSize
            }
        }
        
        override func drawText(in rect: CGRect) {
            super.drawText(in: rect.inset(by: textInset))
        }

        override func draw(_ rect: CGRect) {
            super.draw(rect)
            self.fillColor(with: .cyan, width: 5)
        }
        
        private func fillColor(with color: UIColor, width: CGFloat)
        {
            let topRect = CGRect(x:0, y:0, width : width, height: self.bounds.height);
            color.setFill()
            UIRectFill(topRect)
        }
    }
}

//MARK: - Skeleton cell
class SkeletonViewCell: UITableViewCell
{
    let customSkeletonView: UIView = {
        let skeletonView = UIView()
        skeletonView.translatesAutoresizingMaskIntoConstraints = false
        skeletonView.isSkeletonable = true
        skeletonView.skeletonCornerRadius = 15
        return skeletonView
    }()
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)

        backgroundColor = #colorLiteral(red: 0.1411764771, green: 0.3960784376, blue: 0.5647059083, alpha: 1)
        setupCustomSkeletonView()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupCustomSkeletonView() 
    {
        self.isSkeletonable = true
        contentView.isSkeletonable = true
        contentView.addSubview(customSkeletonView)
        
        NSLayoutConstraint.activate([
            customSkeletonView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 5),
            customSkeletonView.widthAnchor.constraint(equalToConstant: CGFloat((120...270).randomElement()!)),
            customSkeletonView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            customSkeletonView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -5)
        ])
    }
}

//MARK: - conversation cell enums
extension ConversationTableViewCell
{
    enum MessageSide {
        case left
        case right
    }
    
    private enum SeenStatusIcon: String {
        case single = "icons8-done-64-6"
        case double = "icons8-double-tick-48-3"
    }
    
    enum TextPaddingStrategy
    {
        case initial
        case bottom
        case trailling(space: CGFloat)
        case image
        
        var padding: UIEdgeInsets
        {
            switch self {
            case .image: return UIEdgeInsets(top: 2, left: 2, bottom: 2, right: 2)
            case .bottom: return UIEdgeInsets(top: 6, left: 10, bottom: 20, right: 10)
            case .initial: return UIEdgeInsets(top: 6, left: 10, bottom: 6, right: 10)
            case .trailling (let space): return UIEdgeInsets(top: 6, left: 10, bottom: 6, right: space + 10 + 3.0)
            }
        }
    }
}



