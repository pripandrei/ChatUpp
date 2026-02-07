//
//  TextImageMessageCell.swift
//  ChatUpp
//
//  Created by Andrei Pripa on 2/6/26.
//

import UIKit
import YYText
import Combine

final class TextImageMessageCell: UITableViewCell
{
    // MARK: - Properties
    private var contentContainerViewBottomConstraint: NSLayoutConstraint!
    private var contentContainerViewLeadingConstraint: NSLayoutConstraint!
    private var contentContainerViewTrailingConstraint: NSLayoutConstraint!
    private var messageImageViewBottomConstraint: NSLayoutConstraint?
    private var messageLayoutConfiguration: MessageLayoutConfiguration!
    private(set) var cellViewModel: MessageCellViewModel!
    
    private var subscribers = Set<AnyCancellable>()
    
    // MARK: - Message content views (moved from TextImageMessageContentView)
    private let containerView: ContainerView
    private var contentViewModel: MessageContentViewModel!
    private var messageComponentsView: MessageComponentsView = MessageComponentsView()
    private var messageLabel: MessageLabel?
    private(set) var messageImageView: UIImageView?
    private var reactionUIView: ReactionUIView?
    private var contentSubscribers = Set<AnyCancellable>()
    
    private var replyToMessageStackView: ReplyToMessageStackView?
    
//    lazy var replyToMessageStack: ReplyToMessageStackView = {
//        let margins: UIEdgeInsets = .init(top: 2, left: 0, bottom: 4, right: 0)
//        let replyToMessageStack = ReplyToMessageStackView(margin: margins)
//        return replyToMessageStack
//    }()
    
    var onRelayoutNeeded: (() -> Void)?
    
    var maxMessageWidth: CGFloat {
        if let imageSize {
            return imageSize.width
        }
        return Self.maxWidth - 23
    }
    
    private var imageSize: CGSize?

    private lazy var messageSenderNameLabel: UILabel = {
       let senderNameLabel = UILabel()
        senderNameLabel.numberOfLines = 1
        senderNameLabel.font = UIFont.systemFont(ofSize: 15, weight: .medium)
        senderNameLabel.textColor = messageSenderNameColor
        return senderNameLabel
    }()

    private var messageSenderNameColor: UIColor {
        let senderID = contentViewModel.message?.senderId
        return ColorScheme.color(for: senderID ?? "12345")
    }
    
    // MARK: - Avatar
    lazy var messageSenderAvatar: UIImageView = {
        let senderAvatar = UIImageView()
        senderAvatar.clipsToBounds = true
        senderAvatar.translatesAutoresizingMaskIntoConstraints = false
        return senderAvatar
    }()
    
    // MARK: - Static
    static var maxWidth: CGFloat {
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let window = windowScene.keyWindow else { return 295.0 }
        return window.bounds.width * 0.8
    }
    
    // MARK: - Lifecycle
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        self.containerView = ContainerView(
            spacing: 5.0,
            margin: .init(top: 6, left: 10, bottom: 6, right: 10)
        )
        
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        
        // Invert cell upside down
        transform = CGAffineTransform(scaleX: 1, y: -1)
        
        backgroundColor = .clear
        setupBackgroundSelectionView()
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Setup
    private func setupBackgroundSelectionView() {
        let selectedView = UIView()
        selectedView.backgroundColor = UIColor.clear
        selectedBackgroundView = selectedView
    }
    
    private func setupUI() {
        setupContainerView()
        setupMessageComponentsView()
    }
    
    private func setupContainerView() {
        contentView.addSubview(containerView)
        containerView.translatesAutoresizingMaskIntoConstraints = false
        
        containerView.layer.cornerRadius = 15
        containerView.clipsToBounds = true
        
        self.contentContainerViewBottomConstraint = containerView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -3)
        self.contentContainerViewBottomConstraint.priority = UILayoutPriority(rawValue: 999)
        self.contentContainerViewBottomConstraint.isActive = true
        
        self.contentContainerViewLeadingConstraint = containerView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 0)
        self.contentContainerViewTrailingConstraint = containerView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -10)
        
        containerView.topAnchor.constraint(equalTo: contentView.topAnchor).isActive = true
        containerView.widthAnchor.constraint(lessThanOrEqualToConstant: Self.maxWidth).isActive = true
        containerView.widthAnchor.constraint(greaterThanOrEqualToConstant: 80).isActive = true
    }
    
    private func setupMessageComponentsView() {
        containerView.addSubview(messageComponentsView)
        messageComponentsView.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            messageComponentsView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -8),
            messageComponentsView.bottomAnchor.constraint(equalTo: containerView.bottomAnchor, constant: -5),
        ])
    }
    
    // MARK: - Configuration
    func configureCell(using viewModel: MessageCellViewModel,
                       layoutConfiguration: MessageLayoutConfiguration) {
        guard let message = viewModel.message else {
            assert(false, "message should be valid at this point")
            return
        }
        
        cleanupCellContent()
        
        cellViewModel = viewModel
        messageLayoutConfiguration = layoutConfiguration
        self.contentViewModel = viewModel.messageContainerViewModel!
        
        // Set background color
        containerView.backgroundColor = cellViewModel.messageAlignment == .right ?
            ColorScheme.outgoingMessageBackgroundColor : ColorScheme.incomingMessageBackgroundColor
        
        setupBinding()
        configureTextImageContent(with: viewModel.messageContainerViewModel!,
                                  layoutConfiguration: layoutConfiguration)
        adjustMessageSide()
        setupSenderAvatar()
    }
    
    private func configureTextImageContent(with viewModel: MessageContentViewModel,
                                           layoutConfiguration: MessageLayoutConfiguration) {
        guard let message = viewModel.message else {
            assert(false, "message should be valid at this point")
            return
        }
        if message.messageBody.contains("regex")
        {
            print("stop")
        }
        setupContentBindings()
        
        messageComponentsView.configure(viewModel: viewModel.messageComponentsViewModel)
        setupSenderNameLabel()
        setupMessageToReplyView()
        setupMessageLabel(with: message)
        
        if viewModel.message?.reactions.isEmpty == false
        {
            self.reactionUIView = .init(from: message)
            if message.type == .image && message.messageBody.isEmpty
            {
                constrainReactionUIViewToCellContent(withAnimation: false)
            } else {
                reactionUIView?.addReaction(to: containerView, withAnimation: false)
                setReactionViewTrailingConstraint()
            }
        }
    }
    
    func setupMessageLabel(with message: Message)
    {
        if let imageData = contentViewModel.retrieveImageData(),
           let image = UIImage(data: imageData) {
            configureMessageImage(image)
        } else if message.imagePath != nil {
            contentViewModel.fetchMessageImageData()
        }
        
        if !message.messageBody.isEmpty {
            createMessageLabel()
            showTextMessage(message.messageBody)
        }
    }
    
    func showTextMessage(_ text: String) {
        messageLabel?.attributedText = messageTextLabelLinkSetup(from: text)
        handleMessageLayout()
    }
    
    private func createMessageLabel()
    {
        let messageLabel: MessageLabel = .init()
        self.messageLabel = messageLabel
        containerView.addArrangedSubview(messageLabel)
        
        messageLabel.numberOfLines = 0
        messageLabel.preferredMaxLayoutWidth = maxMessageWidth
        messageLabel.contentMode = .redraw
        messageLabel.clipsToBounds = true
    }
    
    private func configureMessageImageView(withSize size: CGSize)
    {
        let imageView = UIImageView()
        let padding: UIEdgeInsets = .init(top: -2, left: -5, bottom: -2, right: -5)
        
        self.messageImageView = imageView
        
        containerView.addArrangedSubview(imageView, padding: padding, at: 0)
        containerView.containerStackView.sendSubviewToBack(imageView)
        
        imageView.layer.cornerRadius = 13
        imageView.clipsToBounds = true
          
        NSLayoutConstraint.activate([
            imageView.heightAnchor.constraint(equalToConstant: size.height),
            imageView.widthAnchor.constraint(equalToConstant: size.width)
        ])
    }
    
    private func setupSenderNameLabel() {
        guard messageLayoutConfiguration.shouldShowSenderName else {
            containerView.removeArrangedSubview(messageSenderNameLabel)
            return
        }
    
        if !containerView.contains(messageSenderNameLabel) {
            containerView.addArrangedSubview(messageSenderNameLabel, at: 0)
        }
        
        messageSenderNameLabel.text = contentViewModel.messageSender?.name
    }
    
    // MARK: - Reply Message
    private func setupMessageToReplyView()
    {
        guard let senderName = contentViewModel.referencedMessageSenderName else {
            return
        }
        
        // Create fresh every time (matches your pattern for messageLabel, messageImageView)
        let margins: UIEdgeInsets = .init(top: 2, left: 0, bottom: 4, right: 0)
        self.replyToMessageStackView = ReplyToMessageStackView(margin: margins)
        
        let replyLabelText = contentViewModel.getTextForReplyToMessage()
        let imageData: Data? = contentViewModel.getImageDataThumbnailFromReferencedMessage()
        replyToMessageStackView?.configure(senderName: senderName,
                                           messageText: replyLabelText,
                                           imageData: imageData)

        let index = messageLayoutConfiguration.shouldShowSenderName ? 1 : 0
        containerView.addArrangedSubview(replyToMessageStackView!, at: index)
        
        updateReplyToMessageColor()
    }
    
    private func removeMessageToReplyLabel() {
        executeAfter(seconds: 1.0) {
            self.messageLabel?.messageUpdateType = .replyRemoved
            UIView.animate(withDuration: 0.3) {
                self.replyToMessageStackView?.alpha = 0
            } completion: { _ in
                self.containerView.removeArrangedSubview(self.replyToMessageStackView!)
                self.messageLabel?.layoutIfNeeded()
                UIView.animate(withDuration: 0.3) {
                    self.contentView.layoutIfNeeded()
                }
                self.onRelayoutNeeded?()
            }
        }
    }

    private func updateMessageToReply(_ message: Message) {
        guard let messageSenderName = contentViewModel.referencedMessageSenderName else { return }
        
        executeAfter(seconds: 0.6, block: { [weak self] in
            guard let self else { return }
            self.messageLabel?.messageUpdateType = .edited
            let messageText = contentViewModel.getTextForReplyToMessage()
            let image = message.imagePath == nil ? nil : self.contentViewModel.retrieveReferencedImageData()
            self.replyToMessageStackView?.configure(senderName: messageSenderName,
                                               messageText: messageText,
                                               imageData: image)
            
            UIView.animate(withDuration: 0.5) {
                self.contentView.layoutIfNeeded()
            }
        })
    }
    
    private func updateReplyToMessageColor() {
        var backgroundColor: UIColor = ColorScheme.outgoingReplyToMessageBackgroundColor
        var barColor: UIColor = .white
        
        if contentViewModel.messageAlignment == .left {
            backgroundColor = messageSenderNameColor.withAlphaComponent(0.3)
            barColor = messageSenderNameColor
        }
        replyToMessageStackView?.setReplyInnerStackColors(background: backgroundColor,
                                                     barColor: barColor)
    }
    
    // MARK: - Binding
    private func setupBinding() {
        cellViewModel.senderImageDataSubject
            .receive(on: DispatchQueue.main)
            .sink(receiveValue: { [weak self] imageData in
                self?.messageSenderAvatar.image = UIImage(data: imageData)
            }).store(in: &subscribers)
        
        cellViewModel.visibilitySenderAvatarSubject
            .receive(on: DispatchQueue.main)
            .sink(receiveValue: { [weak self] shouldShow in
                self?.toggleMessageSenderAvatarVisibility(shouldShow: shouldShow)
            }).store(in: &subscribers)
    }
    
    private func setupContentBindings() {
        contentViewModel.$referencedMessage
            .dropFirst()
            .receive(on: DispatchQueue.main)
            .sink { [weak self] replyMessage in
                if let replyMessage {
                    self?.updateMessageToReply(replyMessage)
                } else {
                    self?.removeMessageToReplyLabel()
                }
            }.store(in: &contentSubscribers)
        
        contentViewModel.messageImageDataSubject
            .receive(on: DispatchQueue.main)
            .sink(receiveValue: { [weak self] imageData in
                guard let image = UIImage(data: imageData) else { return }
                self?.configureMessageImage(image)
            }).store(in: &contentSubscribers)

        contentViewModel.messagePropertyUpdateSubject
            .receive(on: DispatchQueue.main)
            .sink { [weak self] property in
                self?.updateMessage(fieldValue: property)
            }.store(in: &contentSubscribers)
    }
    
    // MARK: - Message Layout
    func handleMessageLayout() {
        createMessageTextLayout()
        let padding = contentViewModel.message?.reactions.isEmpty == true ? getMessagePaddingStrategy() : .initial
        applyMessagePadding(strategy: padding)
    }
    
    private func createMessageTextLayout()
    {
        guard let attributedText = messageLabel?.attributedText else {
            assertionFailure("messageLabel.attributedText should not be nil")
            return
        }
        let containerSize = CGSize(width: maxMessageWidth,
                                   height: CGFloat.greatestFiniteMagnitude)
        let textLayout = YYTextLayout(containerSize: CGSize(width: containerSize.width,
                                                            height: containerSize.height),
                                      text: attributedText)
        messageLabel?.textLayout = textLayout
    }
    
    private var messageLastLineTextWidth: CGFloat {
        messageLabel?.textLayout?.lines.last?.width ?? 0.0
    }

    private var messageTextBoundingWidth: CGFloat {
        return messageLabel?.textLayout?.textBoundingRect.width ?? 0.0
    }
    
    private func getMessagePaddingStrategy() -> TextPaddingStrategy {
        let padding = 4.0
        let expectedLineWidth = self.messageLastLineTextWidth + self.messageComponentsView.componentsWidth
        
        guard expectedLineWidth < (maxMessageWidth - padding) else {
            return .bottom
        }
        
        if expectedLineWidth > self.messageTextBoundingWidth {
            let difference = expectedLineWidth - self.messageTextBoundingWidth
            return .trailling(space: difference)
        }
        return .initial
    }
    
    private func applyMessagePadding(strategy paddingStrategy: TextPaddingStrategy) {
        messageLabel?.textContainerInset = paddingStrategy.padding
        messageLabel?.invalidateIntrinsicContentSize()
    }
    
    private func setReactionViewTrailingConstraint() {
        reactionUIView?.reactionView?.trailingAnchor.constraint(lessThanOrEqualTo: self.messageComponentsView.leadingAnchor, constant: -10).isActive = true
    }
    
    // MARK: - Image Setup
    private func configureMessageImage(_ image: UIImage) {
        let newSize = image.getAspectRatio()
        self.imageSize = newSize
        configureMessageImageView(withSize: newSize)
        resizeImage(image, toSize: newSize)
    }

    private func resizeImage(_ image: UIImage, toSize size: CGSize) {
        guard let imagePath = contentViewModel.resizedMessageImagePath else { return }
        
        if let image = CacheManager.shared.getCachedImage(forKey: imagePath) {
            self.messageImageView?.image = image
            return
        }
        
        DispatchQueue.global().async {
            guard let image = image.resize(to: size) else { return }
            
            CacheManager.shared.cacheImage(image: image, key: imagePath)
            
            DispatchQueue.main.async {
                self.messageImageView?.image = image
            }
        }
    }
    
    // MARK: - Attributed Text
    private func messageTextLabelLinkSetup(from text: String) -> NSAttributedString? {
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
                
                attributedText.yy_setTextUnderline(decorator, range: match.range)
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
    
    private func makeAttributedString(for text: String) -> NSMutableAttributedString? {
        let attributes: [NSAttributedString.Key : Any] = [
            .font: UIFont(name: "Helvetica", size: 16)!,
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
    
    // MARK: - Updates
    private func updateMessage(fieldValue: MessageObservedProperty) {
        executeAfter(seconds: 1.0) { [weak self] in
            guard let self = self else { return }
            self.messageLabel?.messageUpdateType = .edited
            
            if cellViewModel.message!.messageBody.contains("regex") || cellViewModel.message!.type == .imageText
            {
                print("stop")
            }
            
            switch fieldValue {
            case .messageBody(let text):
                if self.messageLabel == nil
                {
                    createMessageLabel()
                    messageComponentsView.layoutSubviews()
                }
                self.messageLabel?.attributedText = self.messageTextLabelLinkSetup(from: text)
                self.handleMessageLayout()
            case .isEdited:
                self.messageComponentsView.updateEditedLabel()
                self.handleMessageLayout()
            case .messageSeen, .seenBy:
                self.messageComponentsView.messageComponentsStackView.setNeedsLayout()
                self.messageComponentsView.configureMessageSeenStatus()
                
                if self.contentViewModel.message?.type != .image {
                    self.handleMessageLayout()
                }
            case .reactions:
                if cellViewModel.message?.type != .image {
                    self.handleMessageLayout()
                }
                self.manageReactionsSetup()
            default: break
            }

            UIView.animate(withDuration: 0.3) {
                self.contentView.layoutIfNeeded()
            }
            self.onRelayoutNeeded?()
        }
    }
    
    private func manageReactionsSetup()
    {
        if reactionUIView == nil,
            let message = contentViewModel.message
        {
            self.reactionUIView = .init(from: message)
            if message.type == .image
            {
                constrainReactionUIViewToCellContent(withAnimation: true)
            } else {
                reactionUIView?.addReaction(to: containerView)
                setReactionViewTrailingConstraint()
            }
        }
        if contentViewModel.message?.reactions.isEmpty == true
        {
            // remove if image code here
            if contentViewModel?.message?.type == .image
            {
                removeReactionUIViewFromCellContent(withAnimation: true)
            } else {
                self.reactionUIView?.removeReaction(from: containerView)
                self.reactionUIView = nil
            }
            
        } else {
            //update if image code here
            self.reactionUIView?.updateReactions(on: containerView)
        }
    }
    
    private func removeReactionUIViewFromCellContent(withAnimation animate: Bool)
    {
        guard let reactionUIView = self.reactionUIView?.reactionView else { return }
        
        contentContainerViewBottomConstraint.isActive = false
        
        self.contentContainerViewBottomConstraint = containerView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -3)
        self.contentContainerViewBottomConstraint.priority = UILayoutPriority(rawValue: 999)
        self.contentContainerViewBottomConstraint.isActive = true
        
        reactionUIView.removeFromSuperview()
        
        if animate
        {
            UIView.animate(withDuration: 0.4) {
                self.contentView.layoutIfNeeded()
            }
        }
        
        self.reactionUIView?.cleanup()
        self.reactionUIView = nil
    }
    
    private func constrainReactionUIViewToCellContent(withAnimation animate: Bool)
    {
        guard let reactionUIView = self.reactionUIView?.reactionView else { return }
        
        contentContainerViewBottomConstraint.isActive = false
        
        contentView.addSubview(reactionUIView)
        reactionUIView.translatesAutoresizingMaskIntoConstraints = false
        
        contentContainerViewBottomConstraint = containerView.bottomAnchor.constraint(equalTo: reactionUIView.topAnchor, constant: -3)
        contentContainerViewBottomConstraint.priority = UILayoutPriority(999)
        contentContainerViewBottomConstraint.isActive = true
        
        NSLayoutConstraint.activate([
            reactionUIView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -7),
            reactionUIView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -3)
        ])
        
        guard animate else {return}
        
        reactionUIView.alpha = 0.2
        reactionUIView.transform = .init(scaleX: 0.1, y: 0.1)
        
        UIView.animate(withDuration: 0.6, delay: 0, usingSpringWithDamping: 0.8, initialSpringVelocity: 0)
        {
            UIView.animate(withDuration: 0.2, delay: 0.3)
            {
                reactionUIView.transform = .init(scaleX: 1.2, y: 1.2)
                reactionUIView.alpha = 1.0
                
                UIView.animate(withDuration: 0.2, delay: 0.5) {
                    reactionUIView.transform = .identity
                }
            }
        }
    }
    
    // MARK: - Cleanup
    private func cleanupCellContent()
    {
        messageSenderAvatar.image = nil
        
        if let imageView = messageImageView {
            containerView.removeArrangedSubview(imageView)
            messageImageView?.image = nil
            messageImageView = nil
        }
        
        if let messageLabel = messageLabel {
            containerView.removeArrangedSubview(messageLabel)
            self.messageLabel = nil
        }
        imageSize = nil
        
        subscribers.forEach { $0.cancel() }
        subscribers.removeAll()
        
        contentSubscribers.forEach { $0.cancel() }
        contentSubscribers.removeAll()

        if let reactionView = reactionUIView?.reactionView
        {
            if cellViewModel.message?.type == .image && cellViewModel.message?.messageBody.isEmpty == true
            {
                removeReactionUIViewFromCellContent(withAnimation: false)
            } else {
                containerView.removeArrangedSubview(reactionView)
                reactionUIView = nil
            }
        }
//        reactionUIView?.removeReaction(from: containerView)
//        reactionUIView = nil
        
        if let replyStack = replyToMessageStackView {
            containerView.removeArrangedSubview(replyStack)
            replyToMessageStackView = nil
        }
        
        UIView.performWithoutAnimation {
            self.contentView.layoutIfNeeded()
        }
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        // Views stay in place - just cleanup will happen in configure
    }
}

// MARK: - Avatar Management
extension TextImageMessageCell {
    private func adjustMessageSide() {
        let leadingConstant = messageLayoutConfiguration.leadingConstraintConstant
        
        switch cellViewModel.messageAlignment {
        case .right:
            contentContainerViewLeadingConstraint.isActive = false
            contentContainerViewTrailingConstraint.isActive = true
        case .left:
            contentContainerViewTrailingConstraint.isActive = false
            contentContainerViewLeadingConstraint.isActive = true
            contentContainerViewLeadingConstraint.constant = leadingConstant
        case .center:
            break
        }
    }
    
    private func setupSenderAvatar() {
        guard messageLayoutConfiguration.shouldShowAvatar else {
            messageSenderAvatar.removeFromSuperview()
            return
        }
    
        if !contentView.contains(messageSenderAvatar) {
            contentView.addSubview(messageSenderAvatar)
            setupSenderAvatarConstraints()
        }

        messageSenderAvatar.layer.cornerRadius = (messageLayoutConfiguration.avatarSize?.width ?? 35) / 2
        
        if let imageData = cellViewModel.retrieveSenderAvatarData(ofSize: "small") {
            messageSenderAvatar.image = UIImage(data: imageData)
        } else {
            messageSenderAvatar.image = UIImage(named: "default_profile_photo")
        }
        messageSenderAvatar.isHidden = false
        messageSenderAvatar.alpha = 1.0
    }
    
    private func setupSenderAvatarConstraints() {
        guard let avatarSize = messageLayoutConfiguration.avatarSize else { return }
        
        messageSenderAvatar.trailingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: -8).isActive = true
        messageSenderAvatar.bottomAnchor.constraint(equalTo: contentView.bottomAnchor).isActive = true
        messageSenderAvatar.widthAnchor.constraint(equalToConstant: avatarSize.width).isActive = true
        messageSenderAvatar.heightAnchor.constraint(equalToConstant: avatarSize.height).isActive = true
    }
    
    func toggleMessageSenderAvatarVisibility(shouldShow: Bool) {
        if shouldShow && messageSenderAvatar.image == nil {
            self.messageLayoutConfiguration = messageLayoutConfiguration.updateShowAvatar(true)
            setupSenderAvatar()
        }
        UIView.animate(withDuration: 0.3) {
            if shouldShow {
                self.messageSenderAvatar.isHidden = false
            }
            self.messageSenderAvatar.alpha = shouldShow ? 1.0 : 0.0
        } completion: { _ in
            if !shouldShow {
                self.messageSenderAvatar.isHidden = true
            }
        }
    }
}

// MARK: - Supporting Types
extension TextImageMessageCell {
    enum TextPaddingStrategy {
        case initial
        case bottom
        case trailling(space: CGFloat)
        case image
        
        var padding: UIEdgeInsets {
            switch self {
            case .image: return UIEdgeInsets(top: 2, left: 2, bottom: 2, right: 2)
            case .bottom: return UIEdgeInsets(top: 0, left: 0, bottom: 15, right: 0)
            case .initial: return UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
            case .trailling (let space): return UIEdgeInsets(top: 0, left: 0, bottom: 0, right: space + 3.0)
            }
        }
    }
}

// MARK: - Protocol Conformances
extension TextImageMessageCell: TargetPreviewable
{
    var contentContainer: UIView! {
        return containerView // fix this TargetPreviewable
    }
}
extension TextImageMessageCell: MessageCellSeenable {}

extension TextImageMessageCell: MessageCellDragable {
    var messageID: String? {
        return cellViewModel.message?.id
    }
    
    var messageText: String? {
        switch cellViewModel.message?.type {
        case .image: return "Photo"
        case .text, .imageText: return getFilteredMessageText()
        default: return nil
        }
    }
    
    var messageImage: UIImage? {
        if let imageData = cellViewModel.messageContainerViewModel?.getImageDataThumbnailFromMessage() {
            return UIImage(data: imageData)
        }
        return nil
    }
    
    var messageSenderName: String? {
        cellViewModel.messageSender?.name
    }
    
    private func getFilteredMessageText() -> String? {
        if let text = cellViewModel.message?.messageBody {
            let cleaned = text.replacingOccurrences(
                of: #"^[ \n￼]+"#,
                with: "",
                options: .regularExpression
            )
            return cleaned.isEmpty ? nil : cleaned
        }
        return nil
    }
}

// MARK: - Type Cast Helper
extension TextImageMessageCell {
    var messageContentView: TextImageMessageCell? {
        return self
    }
}
