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
import SwiftUI

final class SenderNameLabel: UILabel
{
    private let instrinsicContentSizeWidth: Double = 18
    
    override var intrinsicContentSize: CGSize
    {
        var size = super.intrinsicContentSize
//        size.height -= 20
        size.width += instrinsicContentSizeWidth
        return size
    }
    
    override func drawText(in rect: CGRect)
    {
        let inset: UIEdgeInsets = .init(top: 0, left: instrinsicContentSizeWidth / 2, bottom: 0, right: 0)
        super.drawText(in: rect.inset(by: inset))
    }
}

final class MessageTableViewCell: UITableViewCell
{
    private var messageLayoutConfiguration: MessageLayoutConfiguration!
    
    var handleContentRelayout: (() -> Void)?
    
    private var containerStackViewBottomConstraint: NSLayoutConstraint!
    private var containerStackViewLeadingConstraint: NSLayoutConstraint!
    private var containerStackViewTrailingConstraint: NSLayoutConstraint!

    private var messageComponentsStackView: UIStackView = UIStackView()
    private var messageImageView = UIImageView()
//    private var messageTitleLabel: YYLabel?
    private var timeStamp = YYLabel()
    private var subscribers = Set<AnyCancellable>()
    private var maxMessageWidth: CGFloat = 292.0
    private var replyToMessageStack = ReplyToMessageStackView()
    
    private(set) var reactionBadgeHostingView: UIView?
    private(set) var containerStackView: UIStackView = UIStackView()
//    private(set) var messageContainer = UIView() // remove later
    private(set) var messageLabel = MessageLabel()
    private(set) var seenStatusMark = YYLabel()
    private(set) var editedLabel: UILabel = UILabel()
    private(set) var cellViewModel: MessageCellViewModel!
    
    private lazy var replyMessageLabel: ReplyMessageLabel = {
        let replyMessageLabel = ReplyMessageLabel()
        replyMessageLabel.numberOfLines = 2
        replyMessageLabel.layer.cornerRadius = 4
        replyMessageLabel.clipsToBounds = true
        replyMessageLabel.backgroundColor = ColorManager.replyToMessageBackgroundColor
        replyMessageLabel.rectInset = .init(top: -8, left: -8, bottom: 0, right: -8)
        
        return replyMessageLabel
    }()
    
    private lazy var messageSenderNameLabel: UILabel = {
       let senderNameLabel = UILabel()
        senderNameLabel.numberOfLines = 1
        senderNameLabel.font = UIFont.systemFont(ofSize: 15, weight: .medium)
        senderNameLabel.textColor = messageSenderNameColor
        return senderNameLabel
    }()

    private var messageSenderAvatar: UIImageView = {
        let senderAvatar = UIImageView()
        senderAvatar.clipsToBounds = true
        senderAvatar.translatesAutoresizingMaskIntoConstraints = false
        return senderAvatar
    }()
    
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
        
        backgroundColor = .clear
        setupBackgroundSelectionView()
        setupContainerStackView()
        setupMessageLabel()
        setupMessageComponentsStackView()
        setupTimestamp()
        configureMessageImageView()
        setupEditedLabel()
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
                self?.messageSenderAvatar.image = UIImage(data: imageData)
            }).store(in: &subscribers)
        
        cellViewModel.messageImageDataSubject
            .receive(on: DispatchQueue.main)
            .sink(receiveValue: { [weak self] imageData in
                //                if data == self?.cellViewModel.imageData {
//                self?.messageImage = UIImage(data: imageData)
                guard let image = UIImage(data: imageData) else {return}
                self?.configureMessageImage(image)
                //                }
            }).store(in: &subscribers)
        //
        cellViewModel.$message
            .receive(on: DispatchQueue.main)
            .compactMap({ $0 })
            .sink { [weak self] message in
                if message.isInvalidated { return }
                self?.setupMessageData(with: message)
            }.store(in: &subscribers)
        
        cellViewModel.$referencedMessage
            .receive(on: DispatchQueue.main)
            .dropFirst()
            .sink { [weak self] replyMessage in
                if let replyMessage {
                    self?.updateMessageToReply(replyMessage)
                } else {
                    self?.removeMessageToReplyLabel()
                }
            }.store(in: &subscribers)
    }
    
    private func setupMessageData(with message: Message)
    {
        guard let _ = message.imagePath else {
            messageLabel.attributedText = messageTextLabelLinkSetup(from: message.messageBody)
            handleMessageLayout()
            return
        }
        
        if let imageData = cellViewModel.retrieveImageData()
        {
            guard let image = UIImage(data: imageData) else {return}
            self.configureMessageImage(image)
        } else
        {
            cellViewModel.fetchMessageImageData()
        }
    }
    
    func setupReactionView(for message: Message)
    {
        guard !message.reactions.isEmpty else {return}
        
        let reactionVM = ReactionViewModel(message: message)
        let hostView = UIHostingController(rootView: ReactionBadgeView(viewModel: reactionVM))
        
        self.reactionBadgeHostingView = hostView.view
        
        hostView.view.backgroundColor = .clear
        hostView.view.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(hostView.view)
        
        let horizontalConstraint = cellViewModel.messageAlignment == .right ?
        hostView.view.trailingAnchor.constraint(equalTo: containerStackView.trailingAnchor, constant: -10) :
        hostView.view.leadingAnchor.constraint(equalTo: containerStackView.leadingAnchor, constant: 10)
        
        hostView.view.topAnchor.constraint(equalTo: containerStackView.bottomAnchor, constant: -2).isActive = true
        
        horizontalConstraint.isActive = true
    }
        
    /// - cell configuration
    ///
    
    func configureCell(using viewModel: MessageCellViewModel,
                       layoutConfiguration: MessageLayoutConfiguration)
    {
        guard let message = viewModel.message else { return }
        
        cleanupCellContent()
        cellViewModel = viewModel
        timeStamp.text = viewModel.timestamp
        messageLayoutConfiguration = layoutConfiguration
        
//        if viewModel.messageAlignment == .left
//        {
//            if layoutConfiguration.shouldShowSenderName {
//                setupSenderNameLabel()
//            }
//            if layoutConfiguration.shouldShowAvatar {
//                setupSenderAvatar()
//            }
//        }
        setupSenderNameLabel()
        setupSenderAvatar()
        
        setupMessageToReplyView()
        setContainerStackViewBottomConstraint()
        updateEditedLabel()
        updateStackViewAppearance()
        setupBinding()
        adjustMessageSide()

        setupMessageData(with: message)
        setupReactionView(for: message)
            
//        testMessageTextEdit()
    }
    
    private func removeMessageToReplyLabel()
    {
        executeAfter(seconds: 1.0) {
            self.messageLabel.messageUpdateType = .replyRemoved
            UIView.animate(withDuration: 0.3) {
                self.replyToMessageStack.alpha = 0
                self.replyToMessageStack.isHidden = true
                //            self.containerStackView.layoutIfNeeded()
            } completion: { _ in
                self.containerStackView.removeArrangedSubview(self.replyToMessageStack)
                self.replyToMessageStack.removeFromSuperview()
                //            self.messageLabel.layoutIfNeeded()
                self.handleMessageLayout()
                UIView.animate(withDuration: 0.2) {
                    //            self.containerStackView.layoutIfNeeded()
                    //
                    self.contentView.layoutIfNeeded()
                    
                }
            }
            self.handleContentRelayout?()
        }
    }
    
    private func updateMessageToReply(_ message: Message)
    {
        guard let messageSenderName = cellViewModel.referencedMessageSenderName else {return}
        executeAfter(seconds: 4.0, block: { [weak self] in
            guard let self else {return}
            let messageText = message.messageBody.isEmpty ? "Photo" : message.messageBody
            let replyLabelText = self.createReplyMessageAttributedText(
                with: messageSenderName,
                messageText: messageText
            )
            let image = message.imagePath == nil ? nil : self.cellViewModel.retrieveReferencedImageData()
            self.replyToMessageStack.configure(with: replyLabelText, imageData: image)
            
            UIView.animate(withDuration: 0.5) {
                self.contentView.layoutIfNeeded()
            }
        })
    }
    
    private func setupMessageToReplyView()
    {
        guard let senderName = cellViewModel.referencedMessageSenderName,
              let messageText = cellViewModel.referencedMessage?.messageBody else {
            containerStackView.arrangedSubviews
                .compactMap { $0 as? ReplyToMessageStackView }
                .forEach {
                    containerStackView.removeArrangedSubview($0)
                    $0.removeFromSuperview()
                }
            return
        }
        
        let replyLabelText = messageText.isEmpty ? "Photo" : messageText
        let replyText = createReplyMessageAttributedText(
            with: senderName,
            messageText: replyLabelText
        )
        
        let imageData: Data? = cellViewModel.retrieveReferencedImageData()
        
        replyToMessageStack.configure(with: replyText, imageData: imageData)
        
        let index = messageLayoutConfiguration.shouldShowSenderName ? 1 : 0
        
        containerStackView.insertArrangedSubview(replyToMessageStack, at: index)
        replyToMessageStack.widthAnchor.constraint(equalTo: containerStackView.widthAnchor).isActive = true
    }
    
    private func setupStackViewComponentsColor() {
        timeStamp.textColor = getColorForMessageComponents()
        editedLabel.textColor = getColorForMessageComponents()
    }
    
    private func getColorForMessageComponents() -> UIColor
    {
        var color: UIColor = ColorManager.outgoingMessageComponentsTextColor
        
        if let viewModel = cellViewModel
        {
            if viewModel.message?.type == .image {
                color = .white
            } else {
                color = viewModel.messageAlignment == .left ? ColorManager.incomingMessageComponentsTextColor : ColorManager.outgoingMessageComponentsTextColor
            }
        }
        return color
    }
    
    private func messageTextLabelLinkSetup(from text: String) -> NSAttributedString?
    {
        guard let attributedText = makeAttributedString(for: text) else { return nil }

        if let detector = try? NSDataDetector(types: NSTextCheckingResult.CheckingType.link.rawValue) {
            let matches = detector.matches(in: text, options: [], range: NSRange(location: 0, length: text.utf16.count))

            guard !matches.isEmpty else { return attributedText }

            for match in matches {
                guard let _ = Range(match.range, in: text),
                      let url = match.url else { continue }

                let decorator = YYTextDecoration(style: .single,
                                                 width: 1,
                                                 color: ColorManager.messageLinkColor)
                
                attributedText.yy_setTextUnderline(decorator,
                                                   range: match.range)
                attributedText.yy_setTextHighlight(match.range,
                                                   color: ColorManager.messageLinkColor,
                                                   backgroundColor: #colorLiteral(red: 0.6552016139, green: 0.657288909, blue: 0.7513562441, alpha: 1))
                { _, _, _, _ in
                    UIApplication.shared.open(url)
                }
            }
        }
        return attributedText
    }
    
    private func makeAttributedString(for text: String) -> NSMutableAttributedString?
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
        return NSMutableAttributedString(string: text, attributes: attributes)
    }
    
    /// - cleanup
    private func cleanupCellContent()
    {
        messageLabel.attributedText = nil
        timeStamp.text = nil
        messageImageView.image = nil
        messageSenderAvatar.image = nil
        seenStatusMark.attributedText = nil
        reactionBadgeHostingView?.removeFromSuperview()
        reactionBadgeHostingView = nil
        
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
    private func setupContainerStackView()
    {
        contentView.addSubview(containerStackView)
        
        containerStackView.axis = .vertical
        containerStackView.spacing = 4
        containerStackView.layer.cornerRadius = 15
        containerStackView.alignment = .leading
        containerStackView.clipsToBounds = true
        containerStackView.translatesAutoresizingMaskIntoConstraints = false
        
        self.containerStackViewBottomConstraint = containerStackView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor)
        self.containerStackViewBottomConstraint.isActive = true
        containerStackView.topAnchor.constraint(equalTo: contentView.topAnchor).isActive = true
        containerStackView.widthAnchor.constraint(lessThanOrEqualToConstant: maxMessageWidth).isActive = true
        
        containerStackView.widthAnchor.constraint(greaterThanOrEqualToConstant: 80).isActive = true
    }
    
    private func setupMessageLabel()
    {
        containerStackView.addArrangedSubview(messageLabel)
        messageLabel.numberOfLines = 0
        messageLabel.preferredMaxLayoutWidth = maxMessageWidth
        messageLabel.contentMode = .redraw
        messageLabel.layer.cornerRadius = 15
        messageLabel.clipsToBounds = true
    }
    
    private func setupMessageComponentsStackView()
    {
//        self.messageLabel.addSubview(messageComponentsStackView)
        self.containerStackView.addSubview(messageComponentsStackView)
//        self.containerStackView.addSubview(messageComponentsStackView)
        
        messageComponentsStackView.addArrangedSubview(timeStamp)
        messageComponentsStackView.addArrangedSubview(seenStatusMark)
        
        messageComponentsStackView.axis = .horizontal
        messageComponentsStackView.alignment = .center
        messageComponentsStackView.distribution = .equalSpacing
        messageComponentsStackView.spacing = 3
        messageComponentsStackView.clipsToBounds = true
        messageComponentsStackView.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            messageComponentsStackView.trailingAnchor.constraint(equalTo: containerStackView.trailingAnchor, constant: -8),
            messageComponentsStackView.bottomAnchor.constraint(equalTo: containerStackView.bottomAnchor, constant: -5),
//            messageComponentsStackView.heightAnchor.constraint(equalToConstant: 14),
//            messageComponentsStackView.widthAnchor.
            
        ])
    }
    
    func configureMessageImageView()
    {
        messageLabel.addSubview(messageImageView)
        messageLabel.sendSubviewToBack(messageImageView)
        
        messageImageView.layer.cornerRadius = 15
        messageImageView.clipsToBounds = true
        messageImageView.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            messageImageView.leadingAnchor.constraint(equalTo: messageLabel.leadingAnchor, constant: 2),
            messageImageView.trailingAnchor.constraint(equalTo: messageLabel.trailingAnchor, constant: -2),
            messageImageView.topAnchor.constraint(equalTo: messageLabel.topAnchor, constant: 2),
//            profileImageView.bottomAnchor.constraint(equalTo: messageLabel.bottomAnchor, constant: -2)
        ])
    }
    
    private func configureMessageSeenStatus()
    {
        guard let message = cellViewModel.message else {return}
//        if message.type == .text && message.messageBody == "" {return}
        
        let isSeen = message.messageSeen ?? (message.seenBy.count > 1)

        let iconSize = isSeen ? CGSize(width: 16, height: 11) : CGSize(width: 12, height: 13)
        
        let seenIconColor: UIColor = cellViewModel.message?.type == .image ? .white : ColorManager.messageSeenStatusIconColor
        let seenStatusIcon = isSeen ? SeenStatusIcon.double.rawValue : SeenStatusIcon.single.rawValue
        guard let seenStatusIconImage = UIImage(named: seenStatusIcon)?
            .withTintColor(seenIconColor)
            .resize(to: iconSize) else {return}
        
        let imageAttributedString = NSMutableAttributedString.yy_attachmentString(
            withContent: seenStatusIconImage,
            contentMode: .center,
            attachmentSize: seenStatusIconImage.size,
            alignTo: UIFont(name: "Helvetica", size: 14)!,
            alignment: .center)
        
        seenStatusMark.attributedText = imageAttributedString
    }
    
    
    private func updateEditedLabel()
    {
        if cellViewModel.message?.isEdited == true
        {
            editedLabel.text = "edited"
        } else {
            editedLabel.text = nil
        }
    }
    
    private func setupEditedLabel()
    {
        messageComponentsStackView.insertArrangedSubview(editedLabel, at: 0)
        editedLabel.font = UIFont(name: "Helvetica", size: 13)
    }
    
    private func setupTimestamp()
    {
        timeStamp.font = UIFont(name: "HelveticaNeue", size: 13)
    }
    
    private func updateStackViewAppearance()
    {
        let messageType = cellViewModel.message?.type
        if messageType == .image
        {
            messageComponentsStackView.backgroundColor = #colorLiteral(red: 0.121735774, green: 0.1175989285, blue: 0.1221210584, alpha: 1).withAlphaComponent(0.5)
            messageComponentsStackView.isLayoutMarginsRelativeArrangement = true
            messageComponentsStackView.layoutMargins = UIEdgeInsets(top: 3, left: 8, bottom: 3, right: 8)
            messageComponentsStackView.layer.cornerRadius = 12
        } else {
            messageComponentsStackView.backgroundColor = .clear
            messageComponentsStackView.isLayoutMarginsRelativeArrangement = false
            messageComponentsStackView.layoutMargins = .zero
            messageComponentsStackView.layer.cornerRadius = .zero
        }
        
        setupStackViewComponentsColor()
    }
    
    private func adjustMessageSide()
    {
//        if containerStackViewLeadingConstraint != nil { containerStackViewLeadingConstraint.isActive = false }
//        if containerStackViewTrailingConstraint != nil { containerStackViewTrailingConstraint.isActive = false }
        
        containerStackViewLeadingConstraint?.isActive = false
        containerStackViewTrailingConstraint?.isActive = false
        
        let leadingConstant = messageLayoutConfiguration.leadingConstraintConstant
        
        switch cellViewModel.messageAlignment {
        case .right:
            configureMessageSeenStatus()
            
            containerStackViewLeadingConstraint = containerStackView.leadingAnchor.constraint(greaterThanOrEqualTo: contentView.leadingAnchor)
            containerStackViewTrailingConstraint = containerStackView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -10)
            containerStackViewLeadingConstraint.isActive = true
            containerStackViewTrailingConstraint.isActive = true
            containerStackView.backgroundColor = ColorManager.outgoingMessageBackgroundColor
        case .left:
            containerStackViewLeadingConstraint = containerStackView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: leadingConstant)
            containerStackViewTrailingConstraint = containerStackView.trailingAnchor.constraint(lessThanOrEqualTo: contentView.trailingAnchor)
            containerStackViewLeadingConstraint.isActive = true
            containerStackViewTrailingConstraint.isActive = true
            containerStackView.backgroundColor = ColorManager.incomingMessageBackgroundColor
        case .center:
            break
        }
    }
}

// MARK: - message layout

extension MessageTableViewCell
{
    private func handleMessageLayout()
    {
        createMessageTextLayout()
        let padding = getMessagePaddingStrategy()
        applyMessagePadding(strategy: padding)
    }
    
    private func createMessageTextLayout()
    {
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
        return editedLabel.intrinsicContentSize.width
    }
}

// MARK: - HANDLE IMAGE OF MESSAGE SETUP
extension MessageTableViewCell
{
    private func configureMessageImage(_ image: UIImage)
    {
        let newSize = cellViewModel.getCellAspectRatio(forImageSize: image.size)
        
        resizeImage(image, toSize: newSize)
        let imageAttachementAttributed = getAttributedImageAttachment(size: newSize)
        
        if let messageText = cellViewModel.message?.messageBody, !messageText.isEmpty
        {
            let newLine = "\n"
            let text = "\(newLine)\(messageText))"
            let combinedAttributedString = NSMutableAttributedString()
            combinedAttributedString.append(imageAttachementAttributed)
            guard let messageTextAttribute = messageTextLabelLinkSetup(from: text) else {return}
            combinedAttributedString.append(messageTextAttribute)
            self.messageLabel.attributedText = combinedAttributedString
            handleMessageLayout()
        } else {
            self.messageLabel.attributedText = imageAttachementAttributed
            applyMessagePadding(strategy: .image)
        }
    }

    private func resizeImage(_ image: UIImage, toSize size: CGSize)
    {
        guard let imagePath = cellViewModel.resizedMessageImagePath else {return}
        
        if let image = CacheManager.shared.getCachedImage(forKey: imagePath)
        {
            self.messageImageView.image = image
            return
        }
        
        DispatchQueue.global().async
        {
            guard let image = image.resize(to: size) else {return}
            
            CacheManager.shared.cacheImage(image: image, key: imagePath)
            
            DispatchQueue.main.async {
                self.messageImageView.image = image
            }
        }
    }
    
    private func getAttributedImageAttachment(size: CGSize) -> NSMutableAttributedString
    {
        let imageAttributedString = NSMutableAttributedString.yy_attachmentString(
            withContent: nil,
            contentMode: .center,
            attachmentSize: size,
            alignTo: UIFont(name: "Helvetica", size: 17)!,
            alignment: .center)
        
        return imageAttributedString
//        messageLabel.attributedText = combined
    }
    
    private func makeAttributedString2(for text: String) -> NSMutableAttributedString?
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
        return NSMutableAttributedString(string: text, attributes: attributes)
    }

    private func convertDataToImage(_ data: Data) -> UIImage? {
        guard let image = UIImage(data: data) else { return nil }
        return image
    }
}

//MARK: - Reply message setup
extension MessageTableViewCell
{
    private func createReplyMessageAttributedText(
        with senderName: String,
        messageText: String
    ) -> NSMutableAttributedString
    {
        let boldAttributeForName: [NSAttributedString.Key: Any] = [
            .font: UIFont.boldSystemFont(ofSize: 13),
            .foregroundColor: UIColor.white
        ]
        let boldAttributeForText: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 13),
            .foregroundColor: UIColor.white
        ]
        let attributedText = NSMutableAttributedString(string: senderName, attributes: boldAttributeForName)
        let replyMessageAttributedText = NSAttributedString(string: " \n\(messageText)", attributes: boldAttributeForText)
        attributedText.append(replyMessageAttributedText)
        
        return attributedText
    }
}

//MARK: - message layout for group

extension MessageTableViewCell
{
    private func setupSenderNameLabel()
    {
        /// check if chat is group (seen by is not empty in group)
        guard cellViewModel.message?.seenBy.isEmpty == false else {return}
        
        guard messageLayoutConfiguration.shouldShowSenderName else
        {
            containerStackView.removeArrangedSubview(messageSenderNameLabel)
            messageSenderNameLabel.removeFromSuperview()
            return
        }
    
        if !containerStackView.arrangedSubviews.contains(messageSenderNameLabel)
        {
            containerStackView.insertArrangedSubview(messageSenderNameLabel, at: 0)
        }
        
        messageSenderNameLabel.text = cellViewModel.messageSender?.name
    }
    
    private func setupSenderAvatar()
    {
        /// check if chat is group (seen by is not empty in group)
        guard cellViewModel.message?.seenBy.isEmpty == false else {return}
        
        guard messageLayoutConfiguration.shouldShowAvatar else
        {
            messageSenderAvatar.removeFromSuperview()
            return
        }
    
        if !contentView.contains(messageSenderAvatar)
        {
            contentView.addSubview(messageSenderAvatar)
            setupSenderAvatarConstraints()
        }
        
        messageSenderAvatar.layer.cornerRadius = (messageLayoutConfiguration.avatarSize?.width ?? 35) / 2
        
        if let imageData = cellViewModel.retrieveSenderAvatarData(ofSize: "small") {
            messageSenderAvatar.image = UIImage(data: imageData)
        }
    }
    
    private func setupSenderAvatarConstraints()
    {
        guard let avatarSize = messageLayoutConfiguration.avatarSize else {return}
        
        messageSenderAvatar.trailingAnchor.constraint(equalTo: containerStackView.leadingAnchor, constant: -8).isActive = true
        messageSenderAvatar.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -3).isActive = true
        messageSenderAvatar.widthAnchor.constraint(equalToConstant: avatarSize.width).isActive = true
        messageSenderAvatar.heightAnchor.constraint(equalToConstant: avatarSize.height).isActive = true
    }
    
    private func setContainerStackViewBottomConstraint()
    {
        let isReactionsEmpty = cellViewModel.message?.reactions.isEmpty
        self.containerStackViewBottomConstraint.constant = isReactionsEmpty ?? true ? -3 : -25
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
//    case single = "icons8-done-64-6"
    case single = "test-cropped-single-checkmark-2"
//    case double = "icons8-double-tick-48-3"
    case double = "test-cropped-double-checkmark"
}

extension MessageTableViewCell: TargetPreviewable
{
    func getTargetViewForPreview() -> UIView
    {
        return containerStackView
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

// MARK: Message edit animation
extension MessageTableViewCell
{
    private func testMessageTextEdit()
    {
        if messageLabel.attributedText?.string == "Pedro pascal Hi there Pedro pascal Hi there Pedro pascal Hi there Pedro pascal Hi there Pedro pascal with on this"
        {
            executeAfter(seconds: 3.0, block: {
                self.messageLabel.messageUpdateType = .edited
                self.messageLabel.attributedText = self.messageTextLabelLinkSetup(from: "Pedro pascal")

                self.handleMessageLayout()

                UIView.animate(withDuration: 0.3) {
                    self.contentView.layoutIfNeeded()
                }
                self.handleContentRelayout?()
            })
        }
    }
}

extension MessageTableViewCell: MessageCellDragable
{
    var messageText: String?
    {
        if let text = messageLabel.attributedText?.string {
            let cleaned = text.replacingOccurrences(
                of: #"^[ \n￼]+"#,
                with: "",
                options: .regularExpression
            )
            return cleaned.isEmpty ? nil : cleaned
        }
        return nil
    }
    
    var messageImage: UIImage?
    {
        return messageImageView.image
    }
}
