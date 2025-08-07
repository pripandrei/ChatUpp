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

final class MessageTableViewCell: UITableViewCell
{
    private var messageLayoutConfiguration: MessageLayoutConfiguration!
    
    var handleContentRelayout: (() -> Void)?
    
    private var messageContainerBottomConstraint: NSLayoutConstraint!
    private var messageContainerLeadingConstraint: NSLayoutConstraint!
    private var messageContainerTrailingConstraint: NSLayoutConstraint!
    private var messageLabelTopConstraints: NSLayoutConstraint!
    
    private var messageSenderNameLabel: UILabel?
    private var messageSenderAvatar: UIImageView?
    
//    private var messageImage: UIImage?
    private var messageComponentsStackView: UIStackView = UIStackView()
    private var messageImageView = UIImageView()
    private var messageTitleLabel: YYLabel?
    private lazy var replyMessageLabel: ReplyMessageLabel = ReplyMessageLabel()
    private var timeStamp = YYLabel()
    private var subscribers = Set<AnyCancellable>()
    
    private(set) var reactionBadgeHostingView: UIView?
    private(set) var messageContainer = UIView()
    private(set) var messageLabel = YYLabel()
    private(set) var seenStatusMark = YYLabel()
    private(set) var editedLabel: UILabel = UILabel()
    private(set) var cellViewModel: MessageCellViewModel!
    
//    private var cellSpacing = 3.0
    private var maxMessageWidth: CGFloat = 292.0

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
        setupMessageContainer()
        setupMessageTextLabel()
        setupMessageComponentsStackView()
        setupTimestamp()
        configureMessageImageView()
        setupEditedLabel()
    }
    
    func configureMessageImageView()
    {
        messageLabel.addSubview(messageImageView)
        messageLabel.sendSubviewToBack(messageImageView)
        
        messageImageView.layer.cornerRadius = 15
        messageImageView.clipsToBounds = true
        messageImageView.translatesAutoresizingMaskIntoConstraints = false
//        profileImageView.contentMode = .redraw
        
        NSLayoutConstraint.activate([
            messageImageView.leadingAnchor.constraint(equalTo: messageLabel.leadingAnchor, constant: 2),
            messageImageView.trailingAnchor.constraint(equalTo: messageLabel.trailingAnchor, constant: -2),
            messageImageView.topAnchor.constraint(equalTo: messageLabel.topAnchor, constant: 2),
//            profileImageView.bottomAnchor.constraint(equalTo: messageLabel.bottomAnchor, constant: -2)
        ])
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
        hostView.view.trailingAnchor.constraint(equalTo: messageContainer.trailingAnchor, constant: -10) :
        hostView.view.leadingAnchor.constraint(equalTo: messageContainer.leadingAnchor, constant: 10)
        
        hostView.view.topAnchor.constraint(equalTo: messageContainer.bottomAnchor, constant: -2).isActive = true
        
        horizontalConstraint.isActive = true
    }
        
    /// - cell configuration
    ///
    
    func configureCell(using viewModel: MessageCellViewModel,
                       layoutConfiguration: MessageLayoutConfiguration)
    {
        guard let message = viewModel.message else { return }
        
        self.cleanupCellContent()
        self.cellViewModel = viewModel
        self.timeStamp.text = viewModel.timestamp
        self.messageLayoutConfiguration = layoutConfiguration
        
        if viewModel.messageAlignment == .left
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
        self.setMessageContainerBottomConstraint()
        self.updateEditedLabel()
        self.updateStackViewAppearance()
        self.setupBinding()
        self.adjustMessageSide()
        
        self.setupMessageData(with: message)
        self.setupReactionView(for: message)
    }
    
    private func setupMessageComponentsStackView()
    {
        self.messageLabel.addSubview(messageComponentsStackView)
        
        messageComponentsStackView.addArrangedSubview(timeStamp)
        messageComponentsStackView.addArrangedSubview(seenStatusMark)
        
        messageComponentsStackView.axis = .horizontal
        messageComponentsStackView.alignment = .center
        messageComponentsStackView.distribution = .equalSpacing
        messageComponentsStackView.spacing = 3
        messageComponentsStackView.clipsToBounds = true
        messageComponentsStackView.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            messageComponentsStackView.trailingAnchor.constraint(equalTo: messageLabel.trailingAnchor, constant: -8),
            messageComponentsStackView.bottomAnchor.constraint(equalTo: messageLabel.bottomAnchor, constant: -5),
//            messageComponentsStackView.heightAnchor.constraint(equalToConstant: 14),
//            messageComponentsStackView.widthAnchor.
            
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
        messageSenderNameLabel?.removeFromSuperview()
        messageSenderNameLabel = nil
//        messageImage = nil
        messageImageView.image = nil
        messageSenderAvatar?.image = nil
        messageSenderAvatar = nil
        seenStatusMark.attributedText = nil
//        editedLabel.text = nil
        messageTitleLabel?.removeFromSuperview()
        messageTitleLabel = nil
        replyMessageLabel.removeFromSuperview()
        reactionBadgeHostingView?.removeFromSuperview()
        reactionBadgeHostingView = nil
        
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
    
    private var messageTopToReplyBottomConstraint: NSLayoutConstraint!
    private var messageTopToContainerTopConstraint: NSLayoutConstraint!
//    private var messageLabelTopToSenderNameConstraint: NSLayoutConstraint!
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
            messageLabel.bottomAnchor.constraint(equalTo: messageContainer.bottomAnchor),
            messageLabel.leadingAnchor.constraint(equalTo: messageContainer.leadingAnchor),
            messageLabel.trailingAnchor.constraint(equalTo: messageContainer.trailingAnchor),
        ])
        
        messageTopToReplyBottomConstraint = messageLabel.topAnchor.constraint(equalTo: replyMessageLabel.bottomAnchor)
        messageTopToContainerTopConstraint = messageLabel.topAnchor.constraint(equalTo: messageContainer.topAnchor)
        
//        messageLabelTopToSenderNameConstraint = messageLabel.topAnchor.constraint(equalTo: messageSenderNameLabel!.bottomAnchor, constant: -5)
        
    }
    
    private func setupMessageContainer()
    {
        contentView.addSubview(messageContainer)
        
        messageContainer.addSubview(messageLabel)
        messageContainer.layer.cornerRadius = 15
        messageContainer.layer.opacity = 1
        messageContainer.translatesAutoresizingMaskIntoConstraints = false
        
        self.messageContainerBottomConstraint = messageContainer.bottomAnchor.constraint(equalTo: contentView.bottomAnchor)
        self.messageContainerBottomConstraint.isActive = true
        messageContainer.topAnchor.constraint(equalTo: contentView.topAnchor).isActive = true
        messageContainer.widthAnchor.constraint(lessThanOrEqualToConstant: maxMessageWidth).isActive = true
        
        messageContainer.widthAnchor.constraint(greaterThanOrEqualToConstant: 80).isActive = true
        
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
        if messageContainerLeadingConstraint != nil { messageContainerLeadingConstraint.isActive = false }
        if messageContainerTrailingConstraint != nil { messageContainerTrailingConstraint.isActive = false }
        
        let leadingConstant = messageLayoutConfiguration.leadingConstraintConstant
        
        switch cellViewModel.messageAlignment {
        case .right:
            configureMessageSeenStatus()
            
            messageContainerLeadingConstraint = messageContainer.leadingAnchor.constraint(greaterThanOrEqualTo: contentView.leadingAnchor)
            messageContainerTrailingConstraint = messageContainer.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -10)
            messageContainerLeadingConstraint.isActive = true
            messageContainerTrailingConstraint.isActive = true
            messageContainer.backgroundColor = ColorManager.outgoingMessageBackgroundColor
        case .left:
            messageContainerLeadingConstraint = messageContainer.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: leadingConstant)
            messageContainerTrailingConstraint = messageContainer.trailingAnchor.constraint(lessThanOrEqualTo: contentView.trailingAnchor)
            messageContainerLeadingConstraint.isActive = true
            messageContainerTrailingConstraint.isActive = true
            messageContainer.backgroundColor = ColorManager.incomingMessageBackgroundColor
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
        
        replyMessageLabel.attributedText = createReplyMessageAttributedText(
            with: messageSenderName,
            messageText: messageText
        )
        
//        executeAfter(seconds: 4.0, block: {
//            self.replyMessageLabel.attributedText = self.createReplyMessageAttributedText(
//                with: messageSenderName,
//                messageText: "This is a test message right now right heere where we are"
//            )
//            UIView.animate(withDuration: 0.5) {
////                self.messageLabel.attributedText = self.messageTextLabelLinkSetup(from: self.cellViewModel.message!.messageBody)
////                self.messageContainer.layoutIfNeeded()
////                self.messageLabel.layoutIfNeeded()
////                self.replyMessageLabel.layoutIfNeeded()
//                self.contentView.layoutIfNeeded()
//            }
//        })
//        
        messageContainer.addSubview(replyMessageLabel)
      
        replyMessageLabel.numberOfLines = 2
        replyMessageLabel.layer.cornerRadius = 4
        replyMessageLabel.clipsToBounds = true
        replyMessageLabel.backgroundColor = ColorManager.replyToMessageBackgroundColor
        replyMessageLabel.translatesAutoresizingMaskIntoConstraints = false
        
        let topAnchor = messageSenderNameLabel == nil ?
        messageContainer.topAnchor : messageSenderNameLabel!.bottomAnchor
        
        replyMessageLabel.topAnchor.constraint(equalTo: topAnchor, constant: 10).isActive = true
        replyMessageLabel.trailingAnchor.constraint(equalTo: messageContainer.trailingAnchor, constant: -10).isActive = true
        replyMessageLabel.leadingAnchor.constraint(equalTo: messageContainer.leadingAnchor, constant: 10).isActive = true
//        messageLabelTopConstraints = messageLabel.topAnchor.constraint(equalTo: replyMessageLabel.bottomAnchor)
//        messageLabelTopConstraints.isActive = true
//        replyMessageHeightConstraint = replyMessageLabel.heightAnchor.constraint(greaterThanOrEqualToConstant: 0)
//        replyMessageHeightConstraint.isActive = true
        
        // Create alternative top constraint for messageLabel (to container top)
//        messageLabelTopToContainerConstraint = messageLabel.topAnchor.constraint(equalTo: messageContainer.topAnchor)
        
        executeAfter(seconds: 2.0, block: {
            self.collapseReplyMessage()
        })
        
    }
    
    private func collapseReplyMessage() {
        // Fade out reply message and collapse height simultaneously
//        UIView.animate(withDuration: 0.25, animations: {
//            self.replyMessageLabel.alpha = 0
////            self.replyMessageHeightConstraint.constant = 0
//        }) { _ in
            self.messageTopToReplyBottomConstraint.isActive = false
            self.messageTopToContainerTopConstraint.isActive = true
//            self.messageLabelTopConstraints.isActive = false
//            //                    self.messageLabelTopToContainerConstraint.isActive = true
//            self.messageLabelTopConstraints = self.messageLabel.topAnchor.constraint(equalTo: self.messageContainer.topAnchor)
//            self.messageLabelTopConstraints.isActive = true
            UIView.animate(withDuration: 0.3) {
//                    self.replyMessageLabel.isHidden = true
                    
                    // Trigger table view height update with immediate layout
                    
                    // Small delay to ensure smooth transition
                    self.layoutIfNeeded()
//                    UIView.animate(withDuration: 0.1) {
//                    }
                }
            self.handleContentRelayout?()
//            UIView.animate(withDuration: 0.25, delay: 3.0, animations: {
//                // Only switch the top constraint after reply is collapsed
//                self.messageLabelTopConstraints.isActive = false
//                self.messageLabelTopToContainerConstraint.isActive = true
//                self.replyMessageLabel.isHidden = true
//                
//                // Trigger table view height update with immediate layout
//                self.handleContentRelayout?()
//                
//                // Small delay to ensure smooth transition
//                UIView.animate(withDuration: 0.1) {
//                    self.layoutIfNeeded()
//                }
//            })
//        }
    }
    
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
            self.fillColor(with: .white, width: 5)
        }
        
        private func fillColor(with color: UIColor, width: CGFloat)
        {
            let topRect = CGRect(
                x: 0,
                y: 0,
                width : width,
                height: self.bounds.height
            )
            color.setFill()
            UIRectFill(topRect)
        }
    }
}


//MARK: - message layout for group

extension MessageTableViewCell
{
    private func setupSenderNameLabel()
    {
        if messageSenderNameLabel == nil {
            messageSenderNameLabel = UILabel()
            messageContainer.addSubview(messageSenderNameLabel!)
        }
        
        messageSenderNameLabel?.text = cellViewModel.messageSender?.name
        messageSenderNameLabel?.font = UIFont.systemFont(ofSize: 15, weight: .medium)
        messageSenderNameLabel?.textColor = messageSenderNameColor
        messageSenderNameLabel?.numberOfLines = 1
        messageSenderNameLabel?.translatesAutoresizingMaskIntoConstraints = false
        setupSenderNameLabelConstraints()
    }
     
    private func setupSenderNameLabelConstraints()
    {
        guard let messageSenderNameLabel = messageSenderNameLabel else { return }
        
        messageSenderNameLabel.topAnchor.constraint(equalTo: messageContainer.topAnchor, constant: 5).isActive = true
        messageSenderNameLabel.leadingAnchor.constraint(equalTo: messageContainer.leadingAnchor, constant: 10).isActive = true
        messageSenderNameLabel.widthAnchor.constraint(lessThanOrEqualTo: messageContainer.widthAnchor, multiplier: 0.80).isActive = true
    }
    
    private func setupSenderAvatar()
    {
        if messageSenderAvatar == nil {
            messageSenderAvatar = UIImageView()
            messageContainer.addSubview(messageSenderAvatar!)
        }
        messageSenderAvatar?.layer.cornerRadius = (messageLayoutConfiguration.avatarSize?.width ?? 35) / 2
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

        messageSenderAvatar.trailingAnchor.constraint(equalTo: messageContainer.leadingAnchor, constant: -8).isActive = true
        messageSenderAvatar.widthAnchor.constraint(equalToConstant: avatarSize.width).isActive = true
        messageSenderAvatar.heightAnchor.constraint(equalToConstant: avatarSize.height).isActive = true
        messageSenderAvatar.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -3).isActive = true
    }
    
    private func setMessageLabelTopConstraints()
    {
//        if messageLabelTopConstraints != nil {
//            messageLabelTopConstraints.isActive = false
//            messageLabelTopConstraints = nil
//        }
        
        if cellViewModel.isReplayToMessage
        {
            messageTopToReplyBottomConstraint.isActive = true
            messageTopToContainerTopConstraint.isActive = false
//            messageLabelTopConstraints = messageLabel.topAnchor.constraint(equalTo: replyMessageLabel.bottomAnchor)
        }
        else if messageSenderNameLabel != nil
        {
            messageLabelTopConstraints = messageLabel.topAnchor.constraint(equalTo: messageSenderNameLabel!.bottomAnchor, constant: -5)
//            messageContainer.widthAnchor.constraint(greaterThanOrEqualToConstant: 80).isActive = true
        }
//        else if messageLabelTopConstraints == nil {
        else  {
//            messageLabelTopConstraints = messageLabel.topAnchor.constraint(equalTo: messageContainer.topAnchor)
            messageTopToContainerTopConstraint.isActive = true
            messageTopToReplyBottomConstraint.isActive = false
        }
//        messageLabelTopConstraints.isActive = true
    }
    
    private func setMessageContainerBottomConstraint()
    {
        let isReactionsEmpty = cellViewModel.message?.reactions.isEmpty
        self.messageContainerBottomConstraint.constant = isReactionsEmpty ?? true ? -3 : -25
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
    
    func withUpdatedSenderName(_ shouldShow: Bool) -> MessageLayoutConfiguration
    {
        return MessageLayoutConfiguration(shouldShowSenderName: shouldShow,
                                          shouldShowAvatar: shouldShowAvatar,
                                          avatarSize: avatarSize,
                                          leadingConstraintConstant: leadingConstraintConstant)
    }
    
}

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
                                              avatarSize: CGSize(width: 35, height: 35),
                                              leadingConstraintConstant: 52)
        }
    }
}

extension MessageTableViewCell: TargetPreviewable
{
    func getTargetViewForPreview() -> UIView
    {
        return messageContainer
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
