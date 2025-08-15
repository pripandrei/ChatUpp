//
//  Untitled.swift
//  ChatUpp
//
//  Created by Andrei Pripa on 8/14/25.
//

import Foundation
import UIKit
import YYText
import Combine

final class MessageContainerView: ContainerView
{
    private var messageComponentsStackView: UIStackView = UIStackView()
    var seenStatusMark = YYLabel()
    var editedLabel: UILabel = UILabel()
    var timeStamp = YYLabel()
    var messageLabel = MessageLabel()
    var messageImageView = UIImageView()
    var replyToMessageStack = ReplyToMessageStackView()
    
    var viewModel: MessageCellViewModel!
    private var messageLayoutConfiguration: MessageLayoutConfiguration!
    
    var handleContentRelayout: (() -> Void)?
    
    var maxMessageWidth: CGFloat = 292.0
    
    private var subscribers = Set<AnyCancellable>()

//    private lazy var replyMessageLabel: ReplyMessageLabel = {
//        let replyMessageLabel = ReplyMessageLabel()
//        replyMessageLabel.numberOfLines = 2
//        replyMessageLabel.layer.cornerRadius = 4
//        replyMessageLabel.clipsToBounds = true
//        replyMessageLabel.backgroundColor = ColorManager.replyToMessageBackgroundColor
//        replyMessageLabel.rectInset = .init(top: -8, left: -8, bottom: 0, right: -8)
//        
//        return replyMessageLabel
//    }()
//    
    private lazy var messageSenderNameLabel: UILabel = {
       let senderNameLabel = UILabel()
        senderNameLabel.numberOfLines = 1
        senderNameLabel.font = UIFont.systemFont(ofSize: 15, weight: .medium)
        senderNameLabel.textColor = messageSenderNameColor
        return senderNameLabel
    }()
    
    private var messageSenderNameColor: UIColor
    {
        let senderID = viewModel.message?.senderId
        return ColorManager.color(for: senderID ?? "12345")
    }
    
    override init(spacing: CGFloat = 0)
    {
        super.init(spacing: spacing)
        setupMessageLabel()
        setupMessageComponentsStackView()
        setupTimestamp()
        setupEditedLabel()
        configureMessageImageView()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

//MARK: - message container configuration
extension MessageContainerView
{
    private func setupBindings()
    {
        viewModel.$referencedMessage
            .receive(on: DispatchQueue.main)
            .dropFirst()
            .sink { [weak self] replyMessage in
                if let replyMessage {
                    self?.updateMessageToReply(replyMessage)
                } else {
                    self?.removeMessageToReplyLabel()
                }
            }.store(in: &subscribers)
        
        viewModel.messageImageDataSubject
            .receive(on: DispatchQueue.main)
            .sink(receiveValue: { [weak self] imageData in
                //                if data == self?.cellViewModel.imageData {
//                self?.messageImage = UIImage(data: imageData)
                guard let image = UIImage(data: imageData) else {return}
                self?.configureMessageImage(image)
                //                }
            }).store(in: &subscribers)
    }
}

//MARK: - message container configuration
extension MessageContainerView
{
    func configure(with viewModel: MessageCellViewModel,
                   layoutConfiguration: MessageLayoutConfiguration)
    {
        cleanupContent()
        
        self.viewModel = viewModel
        self.messageLayoutConfiguration = layoutConfiguration
        
        timeStamp.text = viewModel.timestamp
        
        setupSenderNameLabel()
        setupMessageToReplyView()
        updateEditedLabel()
        updateStackViewComponentsAppearance()
        
        setupBindings()
    }
    
    func showTextMessage(_ text: String) {
        messageLabel.attributedText = messageTextLabelLinkSetup(from: text)
        handleMessageLayout()
    }

    func showImageMessage(_ image: UIImage, text: String?) {
        configureMessageImage(image)
    }
}


//MARK: Setup Message container components (timestamp + edited + seen mark)
extension MessageContainerView
{
    private func setupMessageComponentsStackView()
    {
//        self.messageLabel.addSubview(messageComponentsStackView)
        addSubview(messageComponentsStackView)
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
            messageComponentsStackView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -8),
            messageComponentsStackView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -5),
//            messageComponentsStackView.heightAnchor.constraint(equalToConstant: 14),
//            messageComponentsStackView.widthAnchor.
            
        ])
    }
    
    private func setupMessageLabel()
    {
        addArrangedSubview(messageLabel)
        messageLabel.numberOfLines = 0
        messageLabel.preferredMaxLayoutWidth = maxMessageWidth
        messageLabel.contentMode = .redraw
        messageLabel.layer.cornerRadius = 15
        messageLabel.clipsToBounds = true
    }
    
    private func setupEditedLabel()
    {
        messageComponentsStackView.insertArrangedSubview(editedLabel, at: 0)
        editedLabel.font = UIFont(name: "Helvetica", size: 13)
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
    
    private func setupTimestamp()
    {
        timeStamp.font = UIFont(name: "HelveticaNeue", size: 13)
    }
    
    private func setupSenderNameLabel()
    {
        /// check if chat is group (seen by is not empty in group)
//        guard cellViewModel.message?.seenBy.isEmpty == false else {return}
        
        guard messageLayoutConfiguration.shouldShowSenderName else
        {
//            if let senderName = subviews.compactMap({ $0 as? ReplyToMessageStackView }).first {
//                removeArrangedSubview(replyView)
//            }
            removeArrangedSubview(messageSenderNameLabel)
//            messageSenderNameLabel.removeFromSuperview()
            return
        }
    
        if !contains(messageSenderNameLabel)
        {
//            containerStackView.insertArrangedSubview(messageSenderNameLabel, at: 0)
            addArrangedSubview(messageSenderNameLabel, at: 0)
        }
        
        messageSenderNameLabel.text = viewModel.messageSender?.name
    }
    
    private func getColorForMessageComponents() -> UIColor
    {
        var color: UIColor = ColorManager.outgoingMessageComponentsTextColor
        
        if let viewModel = viewModel
        {
            if viewModel.message?.type == .image {
                color = .white
            } else {
                color = viewModel.messageAlignment == .left ? ColorManager.incomingMessageComponentsTextColor : ColorManager.outgoingMessageComponentsTextColor
            }
        }
        return color
    }
}

//MARK: - Update message components

extension MessageContainerView
{
    private func updateStackViewComponentsAppearance()
    {
        let messageType = viewModel.message?.type
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
        
        updateStackViewComponentsColor()
    }
    
    private func updateStackViewComponentsColor() {
        timeStamp.textColor = getColorForMessageComponents()
        editedLabel.textColor = getColorForMessageComponents()
    }
    
    private func updateEditedLabel()
    {
        if viewModel.message?.isEdited == true
        {
            editedLabel.text = "edited"
        }
//        else {
//            editedLabel.text = nil
//        }
    }
    
    func configureMessageSeenStatus()
    {
        guard let message = viewModel.message else {return}
//        if message.type == .text && message.messageBody == "" {return}
        
        let isSeen = message.messageSeen ?? (message.seenBy.count > 1)

        let iconSize = isSeen ? CGSize(width: 16, height: 11) : CGSize(width: 12, height: 13)
        
        let seenIconColor: UIColor = viewModel.message?.type == .image ? .white : ColorManager.messageSeenStatusIconColor
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
}

//MARK: Reply view update
extension MessageContainerView
{
    private func setupMessageToReplyView()
    {
        guard let senderName = viewModel.referencedMessageSenderName,
              let messageText = viewModel.referencedMessage?.messageBody else {
            removeArrangedSubview(replyToMessageStack)
            return
        }
        
        let replyLabelText = messageText.isEmpty ? "Photo" : messageText
        let replyText = replyToMessageStack.createReplyMessageAttributedText(
            with: senderName,
            messageText: replyLabelText
        )
        
        let imageData: Data? = viewModel.retrieveReferencedImageData()
        
        replyToMessageStack.configure(with: replyText, imageData: imageData)
        
        let index = messageLayoutConfiguration.shouldShowSenderName ? 1 : 0
        
//        containerStackView.insertArrangedSubview(replyToMessageStack, at: index)
        addArrangedSubview(replyToMessageStack, at: index)
//        replyToMessageStack.widthAnchor.constraint(equalTo: containerStackView.widthAnchor).isActive = true
    }
    
//    private func removeMessageToReplyLabel()
//    {
////        executeAfter(seconds: 1.0) {
////            self.messageLabel.messageUpdateType = .replyRemoved
////            UIView.animate(withDuration: 0.3) {
////                self.replyToMessageStack.alpha = 0
////                self.replyToMessageStack.isHidden = true
////                //            self.containerStackView.layoutIfNeeded()
////            } completion: { _ in
////                self.removeArrangedSubview(self.replyToMessageStack)
//////                self.replyToMessageStack.removeFromSuperview()
//////                self.messageLabel.layoutIfNeeded()
////                self.handleMessageLayout()
////                UIView.animate(withDuration: 0.2) {
////                    //            self.containerStackView.layoutIfNeeded()
////                    //
////                    self.superview?.layoutIfNeeded()
////                    print("is there superview?:", self.superview)
////                }
////            }
////            print(self.handleContentRelayout?() == nil)
////            self.handleContentRelayout?()
////        }
//    }
//    
    private func removeMessageToReplyLabel()
    {
        executeAfter(seconds: 1.0) {
            self.messageLabel.messageUpdateType = .replyRemoved
            UIView.animate(withDuration: 0.3) {
                self.replyToMessageStack.alpha = 0
//                self.replyToMessageStack.isHidden = true
                //            self.containerStackView.layoutIfNeeded()
            } completion: { _ in
                self.removeArrangedSubview(self.replyToMessageStack)
//                self.containerStackView.replyToMessageStack.removeFromSuperview()
                self.messageLabel.layoutIfNeeded()
//                self.containerStackView.handleMessageLayout()
                UIView.animate(withDuration: 0.3) {
                    //            self.containerStackView.layoutIfNeeded()
                    //
                    self.superview?.layoutIfNeeded()
                    
                }
                self.handleContentRelayout?()
            }
            print("done")
//            self.handleContentRelayout?()
        }
    }
    
    private func updateMessageToReply(_ message: Message)
    {
        guard let messageSenderName = viewModel.referencedMessageSenderName else {return}
        executeAfter(seconds: 4.0, block: { [weak self] in
            guard let self else {return}
            messageLabel.messageUpdateType = .edited
            let messageText = message.messageBody.isEmpty ? "Photo" : message.messageBody
            let replyLabelText = replyToMessageStack.createReplyMessageAttributedText(
                with: messageSenderName,
                messageText: messageText
            ) 
            let image = message.imagePath == nil ? nil : self.viewModel.retrieveReferencedImageData()
            self.replyToMessageStack.configure(with: replyLabelText, imageData: image)
            
            UIView.animate(withDuration: 0.5) {
                self.superview?.layoutIfNeeded()
            }
        })
    }
}

//MARK: - Computed properties
extension MessageContainerView
{
    private var messageComponentsWidth: CGFloat
    {
        let sideWidth = viewModel.messageAlignment == .right ? seenStatusMark.intrinsicContentSize.width : 0.0
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


// MARK: - message layout

extension MessageContainerView
{
    func handleMessageLayout()
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
}

//MARK: - image setup
extension MessageContainerView
{
    private func configureMessageImage(_ image: UIImage)
    {
        let newSize = image.getAspectRatio()
        
        resizeImage(image, toSize: newSize)
        let imageAttachementAttributed = getAttributedImageAttachment(size: newSize)
        
        if let messageText = viewModel.message?.messageBody, !messageText.isEmpty
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
        guard let imagePath = viewModel.resizedMessageImagePath else {return}
        
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
}

//MARK: Message attributed text
extension MessageContainerView
{
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
}

//MARK: cleanup

extension MessageContainerView
{
    func cleanupContent()
    {
        messageLabel.attributedText = nil
        timeStamp.text = nil
        messageImageView.image = nil
        seenStatusMark.attributedText = nil
        editedLabel.text = nil
        applyMessagePadding(strategy: .initial)
    }
}


//MARK: - enums
extension MessageContainerView
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



//// MARK: Message edit animation
//extension MessageContainerView
//{
//    private func testMessageTextEdit()
//    {
//        if messageLabel.attributedText?.string == "Pedro pascal Hi there Pedro pascal Hi there Pedro pascal Hi there Pedro pascal Hi there Pedro pascal with on this"
//        {
//            executeAfter(seconds: 3.0, block: {
//                self.messageLabel.messageUpdateType = .edited
//                self.messageLabel.attributedText = self.messageTextLabelLinkSetup(from: "Pedro pascal")
//
//                self.handleMessageLayout()
//
//                UIView.animate(withDuration: 0.3) {
//                    self.superview?.layoutIfNeeded()
//                }
//                self.handleContentRelayout?()
//            })
//        }
//    }
//}
