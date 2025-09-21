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

extension MessageContainerView
{
//    static var maxWidth: CGFloat = 295.0
    static var maxWidth: CGFloat
    {
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let window = windowScene.keyWindow else {return 295.0 }
        return window.bounds.width * 0.8
    }
}

final class MessageContainerView: ContainerView
{
    private var messageImageViewBottomConstraint: NSLayoutConstraint?
    
    private var viewModel: MessageContainerViewModel!
    private var messageComponentsView: MessageComponentsView = MessageComponentsView()
//    private var messageComponentsStackView: UIStackView = UIStackView()
//    private var seenStatusMark = YYLabel()
//    private var editedLabel: UILabel = UILabel()
//    private var timeStamp = YYLabel()
    private var messageLabel = MessageLabel()
    private(set) var messageImageView = UIImageView()
    private var subscribers = Set<AnyCancellable>()
    
    lazy var replyToMessageStack: ReplyToMessageStackView = {
        let margins: UIEdgeInsets = .init(top: 2, left: 0, bottom: 4, right: 0)
        let replyToMessageStack = ReplyToMessageStackView(margin: margins)
        return replyToMessageStack
    }()
    
    private var messageLayoutConfiguration: MessageLayoutConfiguration!
    
    var handleContentRelayout: (() -> Void)?
    
    var maxMessageWidth: CGFloat {
        return MessageContainerView.maxWidth - 23
    }

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
    
    override init()
    {
        super.init()
        setupSelf()
        setupMessageLabel()
        setupMessageComonentsView()
//        setupMessageComponentsStackView()
//        setupTimestamp()
//        setupEditedLabel()
        configureMessageImageView()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

//MARK: - Setup self
extension MessageContainerView
{
    private func setupSelf()
    {
        spacing = 2
        margins = .init(top: 6, left: 10, bottom: 6, right: 10)
        layer.cornerRadius = 15
        clipsToBounds = true
    }
}

//MARK: - message container configuration
extension MessageContainerView
{
    private func setupBindings()
    {
        viewModel.$referencedMessage
            .dropFirst()
            .receive(on: DispatchQueue.main)
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
//        
        viewModel.$message
            .dropFirst()
            .receive(on: DispatchQueue.main)
            .compactMap({ $0 })
            .sink { [weak self] message in
                if message.isInvalidated { return }
                self?.testMessageTextEdit(message)
//                self?.setupMessageLabel(with: message)
            }.store(in: &subscribers)
        
//        viewModel.$updatedText
//            .receive(on: DispatchQueue.main)
//            .compactMap({ $0 })
//            .sink { [weak self] text in
////                if message.isInvalidated { return }
////                self?.setupMessageLabel(with: message)
//                self?.testMessageTextEdit(text)
//            }.store(in: &subscribers)
    }
}

//MARK: - message container configuration
extension MessageContainerView
{
    func configure(with viewModel: MessageContainerViewModel,
                   layoutConfiguration: MessageLayoutConfiguration)
    {
        guard let message = viewModel.message else {
            assert(false, "message should be valid at this point")
            return
        }
        
        cleanupContent()
        
        self.viewModel = viewModel
        setupBindings()
        self.messageLayoutConfiguration = layoutConfiguration
        
        messageComponentsView.configure(viewModel: viewModel.messageComponentsViewModel)
        setupSenderNameLabel()
        setupMessageToReplyView()
        setupMessageLabel(with: message)
    }
    
    func setupMessageLabel(with message: Message)
    {
        if let imageData = viewModel.retrieveImageData(),
           let image = UIImage(data: imageData) {
            showImageMessage(image, text: message.messageBody)
        } else if message.imagePath != nil {
            viewModel.fetchMessageImageData()
        } else {
            showTextMessage(message.messageBody)
        }
    }
    
    func showTextMessage(_ text: String)
    {
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
    private func setupMessageComonentsView()
    {
        addSubview(messageComponentsView)
        messageComponentsView.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            messageComponentsView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -8),
            messageComponentsView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -5),
        ])
    }
    
//    private func setupMessageComponentsStackView()
//    {
//        addSubview(messageComponentsStackView)
//        
//        messageComponentsStackView.addArrangedSubview(editedLabel)
//        messageComponentsStackView.addArrangedSubview(timeStamp)
//        messageComponentsStackView.addArrangedSubview(seenStatusMark)
//        
//        messageComponentsStackView.axis = .horizontal
//        messageComponentsStackView.alignment = .center
//        messageComponentsStackView.distribution = .equalSpacing
//        messageComponentsStackView.spacing = 3
//        messageComponentsStackView.clipsToBounds = true
//        messageComponentsStackView.translatesAutoresizingMaskIntoConstraints = false
//        
//        NSLayoutConstraint.activate([
//            messageComponentsStackView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -8),
//            messageComponentsStackView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -5),
//        ])
//    }
    
    private func setupMessageLabel()
    {
        addArrangedSubview(messageLabel)
        messageLabel.numberOfLines = 0
        messageLabel.preferredMaxLayoutWidth = maxMessageWidth
        messageLabel.contentMode = .redraw
//        messageLabel.layer.cornerRadius = 15
        messageLabel.clipsToBounds = true
    }
    
//    private func setupEditedLabel()
//    {
////        messageComponentsStackView.insertArrangedSubview(editedLabel, at: 0)
//        editedLabel.font = UIFont(name: "Helvetica", size: 13)
//    }
    
//    private func setupTimestamp()
//    {
//        timeStamp.font = UIFont(name: "HelveticaNeue", size: 13)
//    }
    
    func configureMessageImageView()
    {
        self.addSubview(messageImageView)
        self.sendSubviewToBack(messageImageView)
        
        messageImageView.layer.cornerRadius = 13
        messageImageView.clipsToBounds = true
        messageImageView.translatesAutoresizingMaskIntoConstraints = false
        
        self.messageImageViewBottomConstraint = messageImageView.bottomAnchor.constraint(equalTo: self.bottomAnchor, constant: -2)
        
        NSLayoutConstraint.activate([
            messageImageView.leadingAnchor.constraint(equalTo: self.leadingAnchor, constant: 2),
            messageImageView.trailingAnchor.constraint(equalTo: self.trailingAnchor, constant: -2),
            messageImageView.topAnchor.constraint(equalTo: messageLabel.topAnchor, constant: -4),
        ])
    }
    
    private func setupSenderNameLabel()
    {
        guard messageLayoutConfiguration.shouldShowSenderName else
        {
            removeArrangedSubview(messageSenderNameLabel)
            return
        }
    
        if !contains(messageSenderNameLabel)
        {
            addArrangedSubview(messageSenderNameLabel, at: 0)
        }
        
        messageSenderNameLabel.text = viewModel.messageSender?.name
    }
    
//    private func getColorForMessageComponents() -> UIColor
//    {
//        var color: UIColor = ColorManager.outgoingMessageComponentsTextColor
//        
//        if let viewModel = viewModel
//        {
//            if viewModel.message?.type == .image {
//                color = .white
//            } else {
//                color = viewModel.messageAlignment == .left ? ColorManager.incomingMessageComponentsTextColor : ColorManager.outgoingMessageComponentsTextColor
//            }
//        }
//        return color
//    }
}

//MARK: - Update message components

extension MessageContainerView
{
//    private func updateStackViewComponentsAppearance()
//    {
//        let messageType = viewModel.message?.type
//        if messageType == .image
//        {
//            messageComponentsStackView.backgroundColor = #colorLiteral(red: 0.121735774, green: 0.1175989285, blue: 0.1221210584, alpha: 1).withAlphaComponent(0.5)
//            messageComponentsStackView.isLayoutMarginsRelativeArrangement = true
//            messageComponentsStackView.layoutMargins = UIEdgeInsets(top: 3, left: 8, bottom: 3, right: 8)
//            messageComponentsStackView.layer.cornerRadius = 12
//        } else {
//            messageComponentsStackView.backgroundColor = .clear
//            messageComponentsStackView.isLayoutMarginsRelativeArrangement = false
//            messageComponentsStackView.layoutMargins = .zero
//            messageComponentsStackView.layer.cornerRadius = .zero
//        }
//        
//        updateStackViewComponentsColor()
//    }
    
    private func updateReplyToMessageColor()
    {
        var backgroundColor: UIColor = ColorManager.outgoingReplyToMessageBackgroundColor
        var barColor: UIColor = .white
        
        if viewModel.messageAlignment == .left {
            backgroundColor = messageSenderNameColor.withAlphaComponent(0.3)
            barColor = messageSenderNameColor
        }
        replyToMessageStack.setReplyInnerStackColors(background: backgroundColor,
                                                     barColor: barColor)
    }
    
//    private func updateStackViewComponentsColor() {
//        timeStamp.textColor = getColorForMessageComponents()
//        editedLabel.textColor = getColorForMessageComponents()
//    }
    
//    private func updateEditedLabel()
//    {
//        if viewModel.message?.isEdited == true
//        {
//            editedLabel.text = "edited"
//        }
//    }
    
//    func configureMessageSeenStatus()
//    {
//        guard let message = viewModel.message,
//            viewModel.messageAlignment == .right else {return}
////        if message.type == .text && message.messageBody == "" {return}
//        
//        let isSeen = message.messageSeen ?? (message.seenBy.count > 1)
//
//        let iconSize = isSeen ? CGSize(width: 16, height: 11) : CGSize(width: 12, height: 13)
//        
//        let seenIconColor: UIColor = viewModel.message?.type == .image ? .white : ColorManager.messageSeenStatusIconColor
//        let seenStatusIcon = isSeen ? SeenStatusIcon.double.rawValue : SeenStatusIcon.single.rawValue
//        guard let seenStatusIconImage = UIImage(named: seenStatusIcon)?
//            .withTintColor(seenIconColor)
//            .resize(to: iconSize) else {return}
//        
//        let imageAttributedString = NSMutableAttributedString.yy_attachmentString(
//            withContent: seenStatusIconImage,
//            contentMode: .center,
//            attachmentSize: seenStatusIconImage.size,
//            alignTo: UIFont(name: "Helvetica", size: 14)!,
//            alignment: .center)
//        
//        seenStatusMark.attributedText = imageAttributedString
//    }
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
    
        addArrangedSubview(replyToMessageStack, at: index)
        updateReplyToMessageColor()
//        replyToMessageStack.widthAnchor.constraint(equalTo: containerStackView.widthAnchor).isActive = true
    }
    
    private func removeMessageToReplyLabel()
    {
        executeAfter(seconds: 1.0) {
            self.messageLabel.messageUpdateType = .replyRemoved
            UIView.animate(withDuration: 0.3) {
                self.replyToMessageStack.alpha = 0
//                self.replyToMessageStack.isHidden = true
            } completion: { _ in
                self.removeArrangedSubview(self.replyToMessageStack)
                self.messageLabel.layoutIfNeeded()
//                self.containerStackView.handleMessageLayout()
                UIView.animate(withDuration: 0.3) {
                    self.superview?.layoutIfNeeded()
                }
                self.handleContentRelayout?()
            }
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
            self.replyToMessageStack.configure(
                with: replyLabelText,
                imageData: image)
            
            UIView.animate(withDuration: 0.5) {
                self.superview?.layoutIfNeeded()
            }
        })
    }
}

//MARK: - Computed properties
extension MessageContainerView
{
//    private var messageComponentsWidth: CGFloat
//    {
//        let sideWidth = viewModel?.messageAlignment == .right ? seenStatusMark.intrinsicContentSize.width : 0.0
//        return timeStamp.intrinsicContentSize.width + sideWidth + editedMessageWidth + 4.0
//    }

    private var messageLastLineTextWidth: CGFloat {
        messageLabel.textLayout?.lines.last?.width ?? 0.0
    }

    private var messageTextBoundingWidth: CGFloat {
        return messageLabel.textLayout?.textBoundingRect.width ?? 0.0
    }
    
//    private var editedMessageWidth: CGFloat {
//        return editedLabel.intrinsicContentSize.width
//    }
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
//        applyMessagePadding(strategy: .initial)
    }
    
    /// padding strategy
    ///
    private func getMessagePaddingStrategy() -> TextPaddingStrategy
    {
        let padding = 4.0 // additional safe space
        let expectedLineWidth = self.messageLastLineTextWidth + self.messageComponentsView.componentsWidth
        
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
            self.messageImageViewBottomConstraint?.isActive = false
        } else {
            self.messageLabel.attributedText = imageAttachementAttributed
            self.messageImageViewBottomConstraint?.isActive = true
//            applyMessagePadding(strategy: .image)
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
//        timeStamp.text = nil
        messageImageView.image = nil
//        seenStatusMark.attributedText = nil
//        editedLabel.text = nil
        removeSubscriers()
        applyMessagePadding(strategy: .initial)
        messageLabel.invalidateIntrinsicContentSize()
        messageComponentsView.cleanupContent()
        layoutIfNeeded() // to relayout message label text
    }
    
    private func removeSubscriers()
    {
        subscribers.forEach { $0.cancel() }
        subscribers.removeAll()
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
            case .bottom: return UIEdgeInsets(top: 0, left: 0, bottom: 15, right: 0)
//            case .initial: return UIEdgeInsets(top: 6, left: 10, bottom: 6, right: 10)
            case .initial: return UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
            case .trailling (let space): return UIEdgeInsets(top: 0, left: 0, bottom: 0, right: space + 3.0)
            }
        }
        
//        var padding: UIEdgeInsets
//        {
//            switch self {
//            case .image: return UIEdgeInsets(top: 2, left: 2, bottom: 2, right: 2)
//            case .bottom: return UIEdgeInsets(top: 6, left: 10, bottom: 20, right: 10)
//            case .initial: return UIEdgeInsets(top: 6, left: 10, bottom: 6, right: 10)
//            case .trailling (let space): return UIEdgeInsets(top: 6, left: 10, bottom: 6, right: space + 10 + 3.0)
//            }
//        }
    }
}



// MARK: Message edit animation
extension MessageContainerView
{
    private func testMessageTextEdit(_ message: Message, _ text: String = "")
    {
        executeAfter(seconds: 3.0, block: {
            self.messageLabel.messageUpdateType = .edited
            self.messageLabel.attributedText = self.messageTextLabelLinkSetup(from: message.messageBody)
            self.messageComponentsView.updateEditedLabel()
            self.messageComponentsView.messageComponentsStackView.setNeedsLayout()
            self.messageComponentsView.configureMessageSeenStatus()
            
            self.handleMessageLayout()
            UIView.animate(withDuration: 0.3) {
                self.superview?.layoutIfNeeded()
            }
            self.handleContentRelayout?()
        })
    }
}
