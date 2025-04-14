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

final class MessageTableViewCell: UITableViewCell
{
    private var messageLayoutConfiguration: MessageLayoutConfiguration!
    
    private var messageContainerLeadingConstraint: NSLayoutConstraint!
    private var messageContainerTrailingConstraint: NSLayoutConstraint!
    private var messageLabelTopConstraints: NSLayoutConstraint!
    
    private var messageSenderNameLabel: UILabel?
    private var messageSenderAvatar: UIImageView?
    
    private var messageImage: UIImage?
    private var messageTitleLabel: YYLabel?
    private var replyMessageLabel: ReplyMessageLabel = ReplyMessageLabel()
    private var timeStamp = YYLabel()
    private var subscribers = Set<AnyCancellable>()
    
    private(set) var messageBubbleContainer = UIView()
    private(set) var messageLabel = YYLabel()
    private(set) var seenStatusMark = YYLabel()
    private(set) var editedLabel: UILabel?
    private(set) var cellViewModel: MessageCellViewModel!
    
    private let cellSpacing = 3.0
    private var maxMessageWidth: CGFloat {
        return 292.0
    }

    private var messageSenderNameColor: UIColor
    {
        let senderID = cellViewModel.message?.senderId
        return ColorManager.color(for: senderID ?? "12345")
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
        cellViewModel.senderImageDataSubject
            .receive(on: DispatchQueue.main)
            .sink(receiveValue: { [weak self] imageData in
                self?.messageSenderAvatar?.image = UIImage(data: imageData)
            }).store(in: &subscribers)
        
        cellViewModel.messageImageDataSubject
            .receive(on: DispatchQueue.main)
            .sink(receiveValue: { [weak self] imageData in
                //                if data == self?.cellViewModel.imageData {
                self?.messageImage = UIImage(data: imageData)
                self?.configureImageAttachment(data: imageData)
                //                }
            }).store(in: &subscribers)
        //
        cellViewModel.$message
            .receive(on: DispatchQueue.main)
            .compactMap({ $0 })
            .sink { [weak self] message in
                self?.setupCellData(with: message)
            }.store(in: &subscribers)
    }
    
    private func setupCellData(with message: Message)
    {
        if message.messageBody != "" {
            messageLabel.attributedText = makeAttributedString(for: message)
            handleMessageBubbleLayout()
            return
        }
        
        guard let _ = message.imagePath else {return}
        
        if let imageData = cellViewModel.retrieveImageData()
        {
            messageImage = UIImage(data: imageData)
            self.configureImageAttachment()
        } else
        {
            cellViewModel.fetchMessageImageData()
        }
    }
        
    /// - cell configuration
    ///
    
    private func setupTitleLabel()
    {
        guard let message = cellViewModel.message else {return}
        
        messageTitleLabel = YYLabel()
        
        messageTitleLabel?.numberOfLines = 0
        messageTitleLabel?.preferredMaxLayoutWidth = 260
        messageTitleLabel?.layer.cornerRadius = 12
        messageTitleLabel?.translatesAutoresizingMaskIntoConstraints = false
        messageTitleLabel?.attributedText = makeAttributedString(for: message)
        
        setupTitleLabelConstraints()
    }
    
    private func setupTitleLabelConstraints()
    {
        guard let messageTitleLabel = messageTitleLabel else {return}
        
        NSLayoutConstraint.activate([
            messageTitleLabel.topAnchor.constraint(equalTo: messageBubbleContainer.topAnchor),
            messageTitleLabel.bottomAnchor.constraint(equalTo: messageBubbleContainer.bottomAnchor),
            messageTitleLabel.leadingAnchor.constraint(equalTo: messageBubbleContainer.leadingAnchor),
            messageTitleLabel.trailingAnchor.constraint(equalTo: messageBubbleContainer.trailingAnchor),
        ])
    }
    
    func configureCell(using viewModel: MessageCellViewModel,
                       layoutConfiguration: MessageLayoutConfiguration)
    {
        self.cleanupCellContent()
        
        self.cellViewModel = viewModel
        self.timeStamp.text = viewModel.timestamp
        self.messageLayoutConfiguration = layoutConfiguration
        
        if cellViewModel.messageAlignment == .left
        {
            if layoutConfiguration.shouldShowSenderName {
                self.setupSenderNameLabel()
            }
            if layoutConfiguration.shouldShowAvatar {
                self.setupSenderAvatar()
            }
        }
        
        self.setupReplyMessage()
        self.setMessageLabelTopConstraints()
        self.setupEditedLabel()
        self.setupBinding()
        self.adjustMessageSide()
        
        if let message = viewModel.message {
            self.setupCellData(with: message)
        }
    }
    
    private func configureMessageSeenStatus()
    {
        guard let message = cellViewModel.message else {return}
        
        let isSeen = message.messageSeen ?? (message.seenBy.count > 1)

        let iconSize = isSeen ? CGSize(width: 15, height: 14) : CGSize(width: 16, height: 12)
        let seenStatusIcon = isSeen ? SeenStatusIcon.double.rawValue : SeenStatusIcon.single.rawValue
        guard let seenStatusIconImage = UIImage(named: seenStatusIcon)?.resize(to: iconSize) else {return}
        
        let imageAttributedString = NSMutableAttributedString.yy_attachmentString(withContent: seenStatusIconImage, contentMode: .center, attachmentSize: seenStatusIconImage.size, alignTo: UIFont(name: "Helvetica", size: 4)!, alignment: .center)
        
        seenStatusMark.attributedText = imageAttributedString
    }
    
    private func makeAttributedString(for message: Message) -> NSAttributedString?
    {
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
        timeStamp.textContainerInset = .zero
        messageSenderNameLabel?.removeFromSuperview()
        messageSenderNameLabel = nil
        messageImage = nil
        messageSenderAvatar?.image = nil
        messageSenderAvatar = nil
        seenStatusMark.attributedText = nil
        editedLabel?.text = nil
        messageTitleLabel?.removeFromSuperview()
        messageTitleLabel = nil
        replyMessageLabel.removeFromSuperview()
        
//        messageLabel.removeFromSuperview()
        
        applyMessagePadding(strategy: .initial)
        
        subscribers.forEach { subscriber in
            subscriber.cancel()
        }
        subscribers.removeAll()
        
        // Layout with no animation to hide resizing animation of cells on keyboard show/hide
        // or any other table view content offset change
        UIView.performWithoutAnimation {
            self.contentView.layoutIfNeeded()
        }
    }
}
    
// MARK: - UI INITIAL STEUP

extension MessageTableViewCell
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
        guard cellViewModel.message?.isEdited == true else {return}
        
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
        
        let leadingConstant = messageLayoutConfiguration.leadingConstraintConstant
        
        switch cellViewModel.messageAlignment {
        case .right:
            configureMessageSeenStatus()
            
            messageContainerLeadingConstraint = messageBubbleContainer.leadingAnchor.constraint(greaterThanOrEqualTo: contentView.leadingAnchor)
            messageContainerTrailingConstraint = messageBubbleContainer.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -10)
            messageContainerLeadingConstraint.isActive = true
            messageContainerTrailingConstraint.isActive = true
            messageBubbleContainer.backgroundColor = #colorLiteral(red: 0.7171613574, green: 0.4463854432, blue: 0.351280123, alpha: 1)
        case .left:
            messageContainerLeadingConstraint = messageBubbleContainer.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: leadingConstant)
            messageContainerTrailingConstraint = messageBubbleContainer.trailingAnchor.constraint(lessThanOrEqualTo: contentView.trailingAnchor)
            messageContainerLeadingConstraint.isActive = true
            messageContainerTrailingConstraint.isActive = true
            messageBubbleContainer.backgroundColor = #colorLiteral(red: 0, green: 0.6150025129, blue: 0.6871898174, alpha: 1)
        case .center:
            break
        }
    }
}

// MARK: - message bubble layout

extension MessageTableViewCell
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
        let sideWidth = cellViewModel.messageAlignment == .right ? seenStatusMark.intrinsicContentSize.width : 0.0
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
extension MessageTableViewCell
{
    private func configureImageAttachment(data: Data? = nil) {
//        setMessageImage(imageData: data)
        setMessageImageSize()
        setMessageLabelAttributedTextImage()
        setupTimestampBackgroundForImage()
        applyMessagePadding(strategy: .image)
    }

//    private func setMessageImage(imageData: Data?)
//    {
////        guard let imageData = cellViewModel.retrieveImageData() else {
////            cellViewModel.fetchImageData()
////            return
////        }
////        
////        messageImage?.image = UIImage(data: imageData)
//        
//        if let imageData = imageData, let image = convertDataToImage(imageData) {
//            messageImage?.image = image
//        } else {
//            messageImage?.image = UIImage()
//            cellViewModel.fetchImageData()
//        }
//    }

    private func setMessageImageSize() {
        if let cellImageSize = cellViewModel.message?.imageSize {
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
extension MessageTableViewCell
{
    private func setupReplyMessage()
    {
        guard let messageSenderName = cellViewModel.referencedMessageSenderName,
              let messageText = cellViewModel.referencedMessage?.messageBody else
        {
//            messageLabelTopConstraints = messageLabel.topAnchor.constraint(equalTo: messageBubbleContainer.topAnchor)
//            messageLabelTopConstraints.isActive = true
            return
        }
        
//        if messageLabelTopConstraints != nil { messageLabelTopConstraints.isActive = false }
        
        replyMessageLabel.attributedText = createReplyMessageAttributedText(with: messageSenderName, messageText: messageText)
        replyMessageLabel.numberOfLines = 2
        replyMessageLabel.layer.cornerRadius = 4
        replyMessageLabel.clipsToBounds = true
        replyMessageLabel.backgroundColor = .peterRiver
        replyMessageLabel.translatesAutoresizingMaskIntoConstraints = false
        messageBubbleContainer.addSubview(replyMessageLabel)
        
        let topAnchor = messageSenderNameLabel == nil ? messageBubbleContainer.topAnchor : messageSenderNameLabel!.bottomAnchor
        
        replyMessageLabel.topAnchor.constraint(equalTo: topAnchor, constant: 10).isActive = true
        replyMessageLabel.trailingAnchor.constraint(equalTo: messageBubbleContainer.trailingAnchor, constant: -10).isActive = true
        replyMessageLabel.leadingAnchor.constraint(equalTo: messageBubbleContainer.leadingAnchor, constant: 10).isActive = true
//        messageLabelTopConstraints = messageLabel.topAnchor.constraint(equalTo: replyMessageLabel.bottomAnchor)
//        messageLabelTopConstraints.isActive = true
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
}

//MARK: - Reply message label
extension MessageTableViewCell
{
    /// Customized reply message to simplify left side indentation color fill and text inset
    /// 
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

//MARK: - message layout for group

extension MessageTableViewCell
{
    private func setupSenderNameLabel()
    {
        if messageSenderNameLabel == nil {
            messageSenderNameLabel = UILabel()
            messageBubbleContainer.addSubview(messageSenderNameLabel!)
        }
        
        messageSenderNameLabel?.text = cellViewModel.messageSender?.name
        messageSenderNameLabel?.font = UIFont.systemFont(ofSize: 15, weight: .bold)
        messageSenderNameLabel?.textColor = messageSenderNameColor
        messageSenderNameLabel?.numberOfLines = 1
        messageSenderNameLabel?.translatesAutoresizingMaskIntoConstraints = false
        setupSenderNameLabelConstraints()
    }
     
    private func setupSenderNameLabelConstraints()
    {
        guard let messageSenderNameLabel = messageSenderNameLabel else { return }
        
        messageSenderNameLabel.topAnchor.constraint(equalTo: messageBubbleContainer.topAnchor, constant: 5).isActive = true
        messageSenderNameLabel.leadingAnchor.constraint(equalTo: messageBubbleContainer.leadingAnchor, constant: 10).isActive = true
        messageSenderNameLabel.widthAnchor.constraint(lessThanOrEqualTo: messageBubbleContainer.widthAnchor, multiplier: 0.80).isActive = true
    }
    
    private func setupSenderAvatar()
    {
        if messageSenderAvatar == nil {
            messageSenderAvatar = UIImageView()
            messageBubbleContainer.addSubview(messageSenderAvatar!)
        }
        messageSenderAvatar?.layer.cornerRadius = (messageLayoutConfiguration.avatarSize?.width ?? 40) / 2
        messageSenderAvatar?.clipsToBounds = true
        messageSenderAvatar?.translatesAutoresizingMaskIntoConstraints = false
        setupSenderAvatarConstraints()
        
        if let imageData = cellViewModel.retrieveSenderAvatarData(ofSize: "medium") {
            messageSenderAvatar?.image = UIImage(data: imageData)
            return
        }
        
        cellViewModel.fetchSenderAvatartImageData() //fetch medium size image
        
        if let imageData = cellViewModel.retrieveSenderAvatarData(ofSize: "small") {
            messageSenderAvatar?.image = UIImage(data: imageData)
        }
    }
    
    private func setupSenderAvatarConstraints()
    {
        guard let messageSenderAvatar = messageSenderAvatar,
              let avatarSize = messageLayoutConfiguration.avatarSize else {return}

        messageSenderAvatar.trailingAnchor.constraint(equalTo: messageBubbleContainer.leadingAnchor, constant: -8).isActive = true
        messageSenderAvatar.widthAnchor.constraint(equalToConstant: avatarSize.width).isActive = true
        messageSenderAvatar.heightAnchor.constraint(equalToConstant: avatarSize.height).isActive = true
        messageSenderAvatar.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -3).isActive = true
    }
    
    private func setMessageLabelTopConstraints()
    {
        if messageLabelTopConstraints != nil { messageLabelTopConstraints.isActive = false ; messageLabelTopConstraints = nil }
        
        if cellViewModel.isReplayToMessage
        {
            messageLabelTopConstraints = messageLabel.topAnchor.constraint(equalTo: replyMessageLabel.bottomAnchor)
        }
        else if messageSenderNameLabel != nil
        {
            messageLabelTopConstraints = messageLabel.topAnchor.constraint(equalTo: messageSenderNameLabel!.bottomAnchor, constant: -5)
            messageBubbleContainer.widthAnchor.constraint(greaterThanOrEqualToConstant: 80).isActive = true
        }
        else if messageLabelTopConstraints == nil {
            messageLabelTopConstraints = messageLabel.topAnchor.constraint(equalTo: messageBubbleContainer.topAnchor)
        }
        messageLabelTopConstraints.isActive = true
    }
}

//MARK: - conversation cell enums
extension MessageTableViewCell
{
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

enum SeenStatusIcon: String {
    case single = "icons8-done-64-6"
    case double = "icons8-double-tick-48-3"
}








//protocol MessageLayoutConfiguration
//{
//    var shouldShowSenderName: Bool { get }
//    var shouldShowAvatar: Bool { get set }
//    var avatarSize: CGSize? { get }
//    var leadingConstraintConstant: CGFloat { get }
//}
//
//struct PrivateChatMessageLayout: MessageLayoutConfiguration
//{
//    let leadingConstraintConstant: CGFloat = 10
//    let shouldShowSenderName: Bool = false
//    var shouldShowAvatar: Bool = false
//    let avatarSize: CGSize? = nil
//}
//
//struct GroupChatMessageLayout: MessageLayoutConfiguration
//{
//    let leadingConstraintConstant: CGFloat = 52
//    let shouldShowSenderName: Bool = true
//    var shouldShowAvatar: Bool = false
//    let avatarSize: CGSize? = CGSize(width: 40, height: 40)
//}

struct MessageLayoutConfiguration {
    let shouldShowSenderName: Bool
    let shouldShowAvatar: Bool
    let avatarSize: CGSize?
    let leadingConstraintConstant: CGFloat
}

extension MessageLayoutConfiguration
{
    func withUpdatedAvatar(_ shouldShow: Bool) -> MessageLayoutConfiguration
    {
        return MessageLayoutConfiguration(shouldShowSenderName: shouldShowSenderName,
                                          shouldShowAvatar: shouldShow,
                                          avatarSize: avatarSize,
                                          leadingConstraintConstant: leadingConstraintConstant)
    }
}

//enum MessageLayoutConfigurationFactory
//{
//    static func makeConfiguration(for chatType: ChatType) -> MessageLayoutConfiguration
//    {
//        switch chatType {
//        case ._private:
//            return PrivateChatMessageLayout()
//        case ._group:
//            return GroupChatMessageLayout()
//        }
//    }
//}

enum ChatType
{
    case _private
    case _group
    
    var messageLayoutConfiguration: MessageLayoutConfiguration
    {
        switch self {
        case ._private:
            return MessageLayoutConfiguration(shouldShowSenderName: false,
                                              shouldShowAvatar: false,
                                              avatarSize: nil,
                                              leadingConstraintConstant: 10)
        case ._group:
            return MessageLayoutConfiguration(shouldShowSenderName: true,
                                              shouldShowAvatar: false, // Adjusted dynamically
                                              avatarSize: CGSize(width: 40, height: 40),
                                              leadingConstraintConstant: 52)
        }
    }
}

extension MessageTableViewCell: TargetPreviewable
{
    func getTargetViewForPreview() -> UIView
    {
        return messageBubbleContainer
    }
    
    func getTargetedPreviewColor() -> UIColor
    {
        switch cellViewModel.messageAlignment {
        case .left: return #colorLiteral(red: 0, green: 0.6150025129, blue: 0.6871898174, alpha: 1)
        case .right: return #colorLiteral(red: 0.7171613574, green: 0.4463854432, blue: 0.351280123, alpha: 1)
        default: return .clear
        }
    }
}
