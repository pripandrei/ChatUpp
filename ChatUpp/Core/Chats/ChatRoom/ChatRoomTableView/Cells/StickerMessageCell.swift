//
//  StickerMessageCell.swift
//  ChatUpp
//
//  Created by Andrei Pripa on 2/6/26.
//

import UIKit
import Combine

final class StickerMessageCell: UITableViewCell
{
    // MARK: - Properties
    private var contentContainerViewBottomConstraint: NSLayoutConstraint!
    private var contentContainerViewLeadingConstraint: NSLayoutConstraint!
    private var contentContainerViewTrailingConstraint: NSLayoutConstraint!
    private var messageLayoutConfiguration: MessageLayoutConfiguration!
    weak private(set) var cellViewModel: MessageCellViewModel!
    
    private var subscribers = Set<AnyCancellable>()
    
    // MARK: - Sticker-specific views 
    private var replyToMessageStackView: ReplyToMessageStackView?
    private let stickerComponentsView: MessageComponentsView
    weak private var viewModel: MessageContentViewModel?
    private var reactionUIView: ReactionUIView?
    private let containerView: ContainerView
    private let stickerView: StickerView 
    
    private var isStickerVisible: Bool = false
    private var isRendering: Bool = false
    private var lastRenderTime: CFTimeInterval = 0
    
    var onRelayoutNeeded: (() -> Void)?
    
    // MARK: - Avatar
    lazy var messageSenderAvatar: UIImageView = {
        let senderAvatar = UIImageView()
        senderAvatar.clipsToBounds = true
        senderAvatar.translatesAutoresizingMaskIntoConstraints = false
        return senderAvatar
    }()
    
    // MARK: - Lifecycle
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        let margin: UIEdgeInsets = .init(top: 6, left: 6, bottom: 12, right: 0)
        self.containerView = .init(spacing: 2.0, margin: margin)
        self.stickerView = .init(size: .init(width: 300, height: 300))
        self.stickerComponentsView = .init()
        
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
    
    deinit {
        FrameTicker.shared.remove(self)
//        stickerView.cleanup(withBufferDestruction: true)
        stickerComponentsView.cleanupContent()
        replyToMessageStackView?.removeFromSuperview()
        replyToMessageStackView = nil
        print("deinit StickerMessageCell")
    }

    
    // MARK: - Setup
    private func setupBackgroundSelectionView() {
        let selectedView = UIView()
        selectedView.backgroundColor = UIColor.clear
        selectedBackgroundView = selectedView
    }
    
    private func setupUI() {
        setupContainerView()
        setupSticker()
        setupStickerComponentsView()
    }
    
    private func setupContainerView()
    {
        contentView.addSubview(containerView)
        containerView.translatesAutoresizingMaskIntoConstraints = false
        
        containerView.backgroundColor = .clear
        
        self.contentContainerViewBottomConstraint = containerView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -3)
        self.contentContainerViewBottomConstraint.priority = UILayoutPriority(rawValue: 999)
        self.contentContainerViewBottomConstraint.isActive = true
        
        self.contentContainerViewLeadingConstraint = containerView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 0)
        self.contentContainerViewTrailingConstraint = containerView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20)
        
        containerView.topAnchor.constraint(equalTo: contentView.topAnchor).isActive = true
        // Don't set any width constraint here - let adjustStickerAlignment handle it
    }
    
    private func setupSticker() {
        containerView.addArrangedSubview(stickerView)
        
        NSLayoutConstraint.activate([
            stickerView.heightAnchor.constraint(equalToConstant: 170),
            stickerView.widthAnchor.constraint(equalTo: stickerView.heightAnchor),
        ])
    }
    
    private func setupStickerComponentsView() {
        contentView.addSubview(stickerComponentsView)
        stickerComponentsView.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            stickerComponentsView.trailingAnchor.constraint(equalTo: stickerView.trailingAnchor, constant: 0),
            stickerComponentsView.topAnchor.constraint(equalTo: stickerView.bottomAnchor, constant: -10),
        ])
    }
    
    private func adjustStickerAlignment(_ alignment: MessageAlignment)
    {
        contentContainerViewLeadingConstraint.isActive = false
        contentContainerViewTrailingConstraint.isActive = false
        
        let containerViewSideConstraint = alignment == .right ?
            containerView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -15) :
            containerView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 15)
        containerViewSideConstraint.isActive = true
    }
    
    private func setupReplyToMessage(viewModel: MessageContentViewModel)
    {
        self.replyToMessageStackView = .init(margin: .init(top: 2, left: 2, bottom: 2, right: 2))
        contentView.addSubview(replyToMessageStackView!)
        
        replyToMessageStackView?.translatesAutoresizingMaskIntoConstraints = false
        
        let replyToMessageSideConstraint = viewModel.messageAlignment == .right ?
        replyToMessageStackView!.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 15) :
        replyToMessageStackView!.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -15)

        NSLayoutConstraint.activate([
            replyToMessageStackView!.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 5),
            replyToMessageSideConstraint,
            replyToMessageStackView!.widthAnchor.constraint(equalToConstant: 130)
        ])
  
        guard let messageSenderName = viewModel.referencedMessageSenderName else { return }
        
        let messageText = viewModel.getTextForReplyToMessage()
        let image = viewModel.getImageDataThumbnailFromReferencedMessage()
        replyToMessageStackView?.configure(senderName: messageSenderName,
                                           messageText: messageText,
                                           imageData: image)

        replyToMessageStackView?.setReplyInnerStackColors(
            background: ColorScheme.stickerReplyToMessageBackgroundColor.withAlphaComponent(0.9),
            barColor: .white)
    }
    
    // MARK: - Configuration
    func configureCell(using viewModel: MessageCellViewModel,
                       layoutConfiguration: MessageLayoutConfiguration)
    {
        guard let _ = viewModel.message else {
            assert(false, "message should be valid at this point")
            return
        }
        
        cleanupCellContent()
        
        cellViewModel = viewModel
        messageLayoutConfiguration = layoutConfiguration
        self.viewModel = viewModel.messageContainerViewModel
        
        setupBinding()
        configureStickerContent(with: viewModel.messageContainerViewModel!)
        adjustMessageSide()
        setupSenderAvatar()
    }
    
    private func configureStickerContent(with viewModel: MessageContentViewModel)
    {
        guard let message = viewModel.message else { return }
         
        setupMessagePropertyBinding(publisher: viewModel.messagePropertyUpdateSubject.eraseToAnyPublisher())
        
        if let stickerName = message.sticker {
            stickerView.setupSticker(stickerName)
//            FrameTicker.shared.add(self)
            print("Added to Thicker in cell: \(self.hashValue)")
        } else {
            print("Message with sticker type, missing sticker name !!!!")
        }
        
        stickerComponentsView.configure(viewModel: viewModel.messageComponentsViewModel)
        
        if viewModel.message?.repliedTo != nil {
            setupReplyToMessage(viewModel: viewModel)
        }
        
        if !message.reactions.isEmpty {
            manageReactionsSetup(withAnimation: false)
        }
    }
    
    func setVisible(_ visible: Bool)
    {
        isStickerVisible = visible
        if visible {
            FrameTicker.shared.add(self)
        } else {
            FrameTicker.shared.remove(self)
        }
    }
    
    // MARK: - Binding
    private func setupBinding()
    {
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
    
    private func setupMessagePropertyBinding(publisher: AnyPublisher<MessageObservedProperty, Never>)
    {
        publisher.sink { [weak self] property in
            self?.updateMessage(fieldValue: property)
        }.store(in: &subscribers)
    }
    
    // MARK: - Updates
    private func updateMessage(fieldValue: MessageObservedProperty) {
        executeAfter(seconds: 1.0, block: { [weak self] in
            switch fieldValue {
            case .messageSeen, .seenBy:
                self?.stickerComponentsView.messageComponentsStackView.setNeedsLayout()
                self?.stickerComponentsView.configureMessageSeenStatus()
            case .reactions:
                if self?.manageReactionsSetup() == .updateInPlace
                {
                    return
                }
            default: break
            }
            
            UIView.animate(withDuration: 0.3) {
                self?.contentView.layoutIfNeeded()
            }
            
            self?.onRelayoutNeeded?()
        })
    }
    
    @discardableResult
    private func manageReactionsSetup(withAnimation animated: Bool = true) -> ReactionModificationState
    {
        if reactionUIView == nil,
           let message = viewModel?.message {
            self.reactionUIView = .init(from: message)
            reactionUIView?.addReaction(to: containerView, withAnimation: animated)
            setReactionViewTrailingConstraint()
            return .added
        } else if viewModel?.message?.reactions.isEmpty == true {
            self.reactionUIView?.removeReaction(from: containerView)
            self.reactionUIView = nil
            return .removed
        } else {
            self.reactionUIView?.updateReactions(on: containerView)
            return .updateInPlace
        }
    }
    
    private func setReactionViewTrailingConstraint() {
        reactionUIView?.reactionView?.trailingAnchor.constraint(lessThanOrEqualTo: self.stickerComponentsView.leadingAnchor, constant: -10).isActive = true
    }
    
    // MARK: - Cleanup
    private func cleanupCellContent()
    {
        messageSenderAvatar.image = nil
        
        subscribers.forEach { subscriber in
            subscriber.cancel()
        }
        subscribers.removeAll()

        replyToMessageStackView?.removeFromSuperview()
        replyToMessageStackView = nil
        
        if let reactionView = reactionUIView?.reactionView
        {
            containerView.removeArrangedSubview(reactionView)
            reactionUIView = nil
        }
        
        stickerView.cleanup(withBufferDestruction: false)
        // Layout with no animation
        UIView.performWithoutAnimation {
            self.contentView.layoutIfNeeded()
        }
    }
    
//    override func prepareForReuse() {
//        super.prepareForReuse()
//        // Views stay in place - just cleanup data
//        FrameTicker.shared.remove(self)
//    }
}

// MARK: - Avatar Management

extension StickerMessageCell {
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
    
    private func setupSenderAvatar()
    {
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

// MARK: - Frame Rendering
extension StickerMessageCell: FrameTickRecievable
{
    func didReceiveFrameTick(deltaTime: TimeInterval)
    {
        guard !isRendering else { return }
        
        lastRenderTime = CACurrentMediaTime()
        isRendering = true

        ThorVGRenderQueue.shared.async { [weak self] in
            guard let self else { return }
            defer { self.isRendering = false }
            self.stickerView.render(deltaTime: deltaTime)
        }
    }
}

// MARK: - Protocol Conformances
extension StickerMessageCell: TargetPreviewable
{
    var contentContainer: UIView! { // fix this
        return containerView
    }
}
extension StickerMessageCell: MessageCellSeenable {}

extension StickerMessageCell: MessageCellDragable {
    var messageID: String? {
        return cellViewModel.message?.id
    }
    
    var messageText: String? {
        return "Sticker"
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
}
