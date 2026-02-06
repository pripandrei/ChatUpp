//
//  VoiceMessageCell.swift
//  ChatUpp
//
//  Created by Andrei Pripa on 2/6/26.
//

import UIKit
import SwiftUI
import Combine

final class VoiceMessageCell: UITableViewCell
{
    // MARK: - Properties
    private var contentContainerViewBottomConstraint: NSLayoutConstraint!
    private var contentContainerViewLeadingConstraint: NSLayoutConstraint!
    private var contentContainerViewTrailingConstraint: NSLayoutConstraint!
    private var messageLayoutConfiguration: MessageLayoutConfiguration!
    private(set) var cellViewModel: MessageCellViewModel!
    
    private var subscribers = Set<AnyCancellable>()
    
    // MARK: - Audio content views (moved from VoiceMessageContentView)
    private let containerView: ContainerView
    private let messageComponentsView: MessageComponentsView = .init()
    private var playbackControlPanel: VoicePlaybackControlPanelView!
    private var contentViewModel: MessageContentViewModel!
    private var contentCancellables = Set<AnyCancellable>()
    private var reactionUIView: ReactionUIView?
    private var playbackControlPanelUIView: UIView?
    
    var onRelayoutNeeded: (() -> Void)?
    
    lazy var replyToMessageStack: ReplyToMessageStackView = {
        let margins: UIEdgeInsets = .init(top: 2, left: 0, bottom: 4, right: 0)
        let replyToMessageStack = ReplyToMessageStackView(margin: margins)
        return replyToMessageStack
    }()
    
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
    
    // MARK: - Lifecycle
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        self.containerView = ContainerView(
            spacing: 2.0,
            margin: .init(top: 6, left: 10, bottom: 10, right: 10)
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
    
    deinit {
        print("deinit VoiceMessageCell")
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
        containerView.widthAnchor.constraint(lessThanOrEqualToConstant: 270).isActive = true
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
                       layoutConfiguration: MessageLayoutConfiguration)
    {
        guard let message = viewModel.message else {
            assert(false, "message should be valid at this point")
            return
        }
        
        cleanupCellContent()
        
        cellViewModel = viewModel
        messageLayoutConfiguration = layoutConfiguration
        contentViewModel = viewModel.messageContainerViewModel!
        
        // Set background color
        containerView.backgroundColor = cellViewModel.messageAlignment == .right ?
        ColorScheme.outgoingMessageBackgroundColor : ColorScheme.incomingMessageBackgroundColor
        
        setupBinding()
        configureAudioContent(with: viewModel.messageContainerViewModel!,
                              layoutConfiguration: layoutConfiguration)
        adjustMessageSide()
        setupSenderAvatar()
    }
    
    private func configureAudioContent(with viewModel: MessageContentViewModel,
                                       layoutConfiguration: MessageLayoutConfiguration)
    {
        guard let message = viewModel.message,
              let path = message.voicePath,
              let url = CacheManager.shared.getURL(for: path) else {
            fatalError("Audio path should be present")
        }
        
        let audioSamples = message.audioSamples
        
        setupSenderNameLabel()
        
        let controlPanelColorScheme = makeColorSchemeForControlPanel(basedOnAlignment: viewModel.messageAlignment)
        setupPlaybackControlPanel(withUrl: url,
                                  audioSamples: Array(audioSamples),
                                  colorScheme: controlPanelColorScheme)
        
        messageComponentsView.configure(viewModel: viewModel.messageComponentsViewModel)
        setupMessageToReplyView()
        setupContentBindings()
        
        if !message.reactions.isEmpty
        {
            self.reactionUIView = .init(from: message)
            containerView.addArrangedSubview(self.reactionUIView!.reactionView!,
                                             padding: .init(top: 7, left: 2, bottom: 0, right: 0),
                                             shouldFillWidth: false)
            setReactionViewTrailingConstraint()
        }
    }
    
    private func setupPlaybackControlPanel(withUrl URL: URL,
                                           audioSamples: [Float],
                                           colorScheme: VoicePlaybackControlPanelView.ColorScheme)
    {
        self.playbackControlPanel = .init(audioFileURL: URL,
                                          audioSamples: audioSamples,
                                          colorScheme: colorScheme)
        
        guard let view = UIHostingController(rootView: playbackControlPanel).view else { return }
        self.playbackControlPanelUIView = view
        view.backgroundColor = .clear
        
        containerView.addArrangedSubview(view)
         
        view.translatesAutoresizingMaskIntoConstraints = false
        
        view.heightAnchor.constraint(equalToConstant: 55).isActive = true
        view.widthAnchor.constraint(equalToConstant: 250).isActive = true
    }
    
    private func makeColorSchemeForControlPanel(basedOnAlignment alignment: MessageAlignment) -> VoicePlaybackControlPanelView.ColorScheme {
        switch alignment {
        case .right:
            return .init(backgroundColor: .init(ColorScheme.outgoingMessageBackgroundColor),
                        filledColor: .white,
                        unfilledColor: .init(ColorScheme.incomingMessageComponentsTextColor),
                        playButtonColor: .white)
        case .left:
            return .init(backgroundColor: .init(ColorScheme.incomingMessageBackgroundColor),
                        filledColor: .init((ColorScheme.sendMessageButtonBackgroundColor)),
                        unfilledColor: .init(ColorScheme.outgoingReplyToMessageBackgroundColor),
                        playButtonColor: .init(ColorScheme.sendMessageButtonBackgroundColor))
        default:
            fatalError("Unhandled alignment case: \(alignment)")
        }
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
    private func setupMessageToReplyView() {
        guard let senderName = contentViewModel.referencedMessageSenderName else {
            containerView.removeArrangedSubview(replyToMessageStack)
            return
        }
        
        let replyLabelText = contentViewModel.getTextForReplyToMessage()
        let imageData: Data? = contentViewModel.getImageDataThumbnailFromReferencedMessage()
        replyToMessageStack.configure(senderName: senderName,
                                      messageText: replyLabelText,
                                      imageData: imageData)
        
        let index = messageLayoutConfiguration.shouldShowSenderName ? 1 : 0
        
        containerView.addArrangedSubview(replyToMessageStack, at: index)
        updateReplyToMessageColor()
    }
    
    private func updateReplyToMessageColor() {
        var backgroundColor: UIColor = ColorScheme.outgoingReplyToMessageBackgroundColor
        var barColor: UIColor = .white
        
        if contentViewModel.messageAlignment == .left {
            backgroundColor = messageSenderNameColor.withAlphaComponent(0.3)
            barColor = messageSenderNameColor
        }
        replyToMessageStack.setReplyInnerStackColors(background: backgroundColor,
                                                     barColor: barColor)
    }
    
    private func setReactionViewTrailingConstraint() {
        reactionUIView?.reactionView?.trailingAnchor.constraint(lessThanOrEqualTo: self.messageComponentsView.leadingAnchor, constant: -10).isActive = true
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
        contentViewModel.messagePropertyUpdateSubject
            .sink { [weak self] property in
                self?.updateMessage(fieldValue: property)
            }.store(in: &contentCancellables)
    }
    
    // MARK: - Updates
    private func updateMessage(fieldValue: MessageObservedProperty) {
        executeAfter(seconds: 1.0, block: { [weak self] in
            switch fieldValue {
            case .messageSeen, .seenBy:
                self?.messageComponentsView.messageComponentsStackView.setNeedsLayout()
                self?.messageComponentsView.configureMessageSeenStatus()
            case .reactions:
                self?.manageReactionsSetup()
            default: break
            }
            
            UIView.animate(withDuration: 0.3) {
                self?.contentView.layoutIfNeeded()
            }
            
            self?.onRelayoutNeeded?()
        })
    }
    
    private func manageReactionsSetup() {
        if reactionUIView == nil,
           let message = contentViewModel.message {
            self.reactionUIView = .init(from: message)
            reactionUIView?.addReaction(to: containerView)
            setReactionViewTrailingConstraint()
        }
        if contentViewModel.message?.reactions.isEmpty == true {
            self.reactionUIView?.removeReaction(from: containerView)
            self.reactionUIView = nil
        } else {
            self.reactionUIView?.updateReactions(on: containerView)
        }
    }
    
    // MARK: - Cleanup
    private func cleanupCellContent()
    {
        if let panelView = playbackControlPanelUIView
        {
            containerView.removeArrangedSubview(panelView)
        }
        
        messageSenderAvatar.image = nil
        
        subscribers.forEach { $0.cancel() }
        subscribers.removeAll()
        
        contentCancellables.forEach { $0.cancel() }
        contentCancellables.removeAll()
        
        messageComponentsView.cleanupContent()
        
        if let reactionView = reactionUIView?.reactionView
        {
            containerView.removeArrangedSubview(reactionView)
            reactionUIView = nil
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
extension VoiceMessageCell
{
    private func adjustMessageSide()
    {
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

// MARK: - Protocol Conformances
extension VoiceMessageCell: TargetPreviewable {
    var contentContainer: UIView! {
        return nil // fix this TargetPreviewable
    }
}
extension VoiceMessageCell: MessageCellSeenable {}

extension VoiceMessageCell: MessageCellDragable {
    var messageID: String? {
        return cellViewModel.message?.id
    }
    
    var messageText: String? {
        return "Voice Message"
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
