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

final class TextImageMessageContentView: ContainerView
{
    static var maxWidth: CGFloat
    {
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let window = windowScene.keyWindow else {return 295.0 }
        return window.bounds.width * 0.8
    }
    
    private var messageImageViewBottomConstraint: NSLayoutConstraint?
    
    private var viewModel: MessageContentViewModel!
    private var messageComponentsView: MessageComponentsView = MessageComponentsView()
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
        return TextImageMessageContentView.maxWidth - 23
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
        return ColorScheme.color(for: senderID ?? "12345")
    }
    
    init()
    {
        super.init(spacing: 2.0,
                   margin: .init(top: 6,
                                 left: 10,
                                 bottom: 6,
                                 right: 10))
        layer.cornerRadius = 15
        clipsToBounds = true
        setupMessageLabel()
        setupMessageComponentsView()
        configureMessageImageView()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}


//MARK: - message container configuration
extension TextImageMessageContentView
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
                guard let image = UIImage(data: imageData) else {return}
                self?.configureMessageImage(image)
            }).store(in: &subscribers)

        viewModel.$message
            .dropFirst()
            .receive(on: DispatchQueue.main)
            .compactMap({ $0 })
            .sink { [weak self] message in
                if message.isInvalidated { return }
                self?.updateMessage(message)
            }.store(in: &subscribers)
    }
}

//MARK: - message container configuration
extension TextImageMessageContentView
{
    func configure(with viewModel: MessageContentViewModel,
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
extension TextImageMessageContentView
{
    private func setupMessageComponentsView()
    {
        addSubview(messageComponentsView)
        messageComponentsView.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            messageComponentsView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -8),
            messageComponentsView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -5),
        ])
    }
    
    private func setupMessageLabel()
    {
        addArrangedSubview(messageLabel)
        messageLabel.numberOfLines = 0
        messageLabel.preferredMaxLayoutWidth = maxMessageWidth
        messageLabel.contentMode = .redraw
        messageLabel.clipsToBounds = true
    }
    
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
}


//MARK: Reply view update
extension TextImageMessageContentView
{
    private func setupMessageToReplyView()
    {
        guard let senderName = viewModel.referencedMessageSenderName else
        {
            removeArrangedSubview(replyToMessageStack)
            return
        }
        
        let replyLabelText = viewModel.getTextForReplyToMessage()
        let imageData: Data? = viewModel.getImageDataThumbnailFromReferencedMessage()
        replyToMessageStack.configure(senderName: senderName,
                                      messageText: replyLabelText,
                                      imageData: imageData)
        
        let index = messageLayoutConfiguration.shouldShowSenderName ? 1 : 0
    
        addArrangedSubview(replyToMessageStack, at: index)
        updateReplyToMessageColor()
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
        
        executeAfter(seconds: 0.6, block: { [weak self] in
            guard let self else {return}
            messageLabel.messageUpdateType = .edited
            let messageText = viewModel.getTextForReplyToMessage()
            let image = message.imagePath == nil ? nil : self.viewModel.retrieveReferencedImageData()
            self.replyToMessageStack.configure(senderName: messageSenderName,
                                               messageText: messageText,
                                               imageData: image)
            
            UIView.animate(withDuration: 0.5) {
                self.superview?.layoutIfNeeded()
            }
        })
    }
    
    private func updateReplyToMessageColor()
    {
        var backgroundColor: UIColor = ColorScheme.outgoingReplyToMessageBackgroundColor
        var barColor: UIColor = .white
        
        if viewModel.messageAlignment == .left {
            backgroundColor = messageSenderNameColor.withAlphaComponent(0.3)
            barColor = messageSenderNameColor
        }
        replyToMessageStack.setReplyInnerStackColors(background: backgroundColor,
                                                     barColor: barColor)
    }
}

//MARK: - Computed properties
extension TextImageMessageContentView
{
    private var messageLastLineTextWidth: CGFloat {
        messageLabel.textLayout?.lines.last?.width ?? 0.0
    }

    private var messageTextBoundingWidth: CGFloat {
        return messageLabel.textLayout?.textBoundingRect.width ?? 0.0
    }
}

// MARK: - message layout

extension TextImageMessageContentView
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
extension TextImageMessageContentView
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
extension TextImageMessageContentView
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
                                                 color: ColorScheme.messageLinkColor)
                
                attributedText.yy_setTextUnderline(decorator,
                                                   range: match.range)
                attributedText.yy_setTextHighlight(match.range,
                                                   color: ColorScheme.messageLinkColor,
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

extension TextImageMessageContentView
{
    func cleanupContent()
    {
        messageLabel.attributedText = nil
        messageImageView.image = nil
        removeSubscriers()
        applyMessagePadding(strategy: .initial)
        messageLabel.invalidateIntrinsicContentSize()
        messageComponentsView.cleanupContent()
//        layoutIfNeeded() // to relayout message label text
    }
    
    private func removeSubscriers()
    {
        subscribers.forEach { $0.cancel() }
        subscribers.removeAll()
    }
}



//MARK: - enums
extension TextImageMessageContentView
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
    }
}



// MARK: Message edit animation
extension TextImageMessageContentView
{
    private func updateMessage(_ message: Message)
    {
        executeAfter(seconds: 0.2, block: {
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
