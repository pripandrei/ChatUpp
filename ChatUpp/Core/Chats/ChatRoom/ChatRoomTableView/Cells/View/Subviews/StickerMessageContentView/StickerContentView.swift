//
//  StickerContentView.swift
//  ChatUpp
//
//  Created by Andrei Pripa on 9/19/25.
//

import UIKit
import Combine


final class StickerMessageContentView: UIView, RelayoutNotifying
{
    private let stickerView :StickerView
    private let containerView :ContainerView
    private let stickerComponentsView :MessageComponentsView
    private var replyToMessageStackView :ReplyToMessageStackView?
    private var reactionUIView :ReactionUIView?
    private var viewModel :MessageContentViewModel?
    private var cancellables = Set<AnyCancellable>()
    
    private var isRendering :Bool = false
    private var lastRenderTime :CFTimeInterval = 0
    
    var onRelayoutNeeded: (() -> Void)?
    
    init()
    {
        let margin: UIEdgeInsets = .init(top: 6, left: 6, bottom: 12, right: 0)
        self.containerView = .init(spacing: 2.0,
                                   margin: margin)
        self.stickerView = .init(size: .init(width: 300, height: 300))
        self.stickerComponentsView = .init()
        
        super.init(frame: .zero)

        setupContainerView()
        setupSticker()
        setupStickerComponentsView()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    deinit
    {
        FrameTicker.shared.remove(self)
        stickerView.cleanup(withBufferDestruction: true)
        stickerComponentsView.cleanupContent()
        replyToMessageStackView?.removeFromSuperview()
        replyToMessageStackView = nil
//        print("deinit sticker content view")
    }
    
    //MARK: - UI setup
    
    private func setupContainerView()
    {
        addSubview(containerView)
        
        containerView.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            containerView.topAnchor.constraint(equalTo: topAnchor),
            containerView.bottomAnchor.constraint(equalTo: bottomAnchor),
        ])
    }
    
    private func setupSticker()
    {
        containerView.addArrangedSubview(stickerView)
        
        NSLayoutConstraint.activate([
            stickerView.heightAnchor.constraint(equalToConstant: 170),
            stickerView.widthAnchor.constraint(equalTo: stickerView.heightAnchor),
        ])
    }
    
    private func setupStickerComponentsView()
    {
        addSubview(stickerComponentsView)
        stickerComponentsView.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            stickerComponentsView.trailingAnchor.constraint(equalTo: stickerView.trailingAnchor, constant: 10),
            stickerComponentsView.topAnchor.constraint(equalTo: stickerView.bottomAnchor, constant: -10),
        ])
    }

    private func adjustStickerAlignment(_ alignment: MessageAlignment) // rename
    {
        let containerViewSideConstraint = alignment == .right ?
        containerView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -15) :
        containerView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 15)
        containerViewSideConstraint.isActive = true
    }

    private func setupReplyToMessage(viewModel: MessageContentViewModel)
    {
        self.replyToMessageStackView = .init(margin: .init(top: 2, left: 2, bottom: 2, right: 2))
        addSubview(replyToMessageStackView!)
        
        replyToMessageStackView?.translatesAutoresizingMaskIntoConstraints = false
        
        let replyToMessageSideConstraint = viewModel.messageAlignment == .right ?
        replyToMessageStackView!.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 15) :
        replyToMessageStackView!.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -15)

        NSLayoutConstraint.activate([
            replyToMessageStackView!.topAnchor.constraint(equalTo: self.topAnchor, constant: 5),
            replyToMessageSideConstraint,
            replyToMessageStackView!.widthAnchor.constraint(equalToConstant: 130)
        ])
  
        guard let messageSenderName = viewModel.referencedMessageSenderName else {return}
        
        let messageText = viewModel.getTextForReplyToMessage()
        let image = viewModel.getImageDataThumbnailFromReferencedMessage()
        replyToMessageStackView?.configure(senderName: messageSenderName,
                                           messageText: messageText,
                                           imageData: image)

        replyToMessageStackView?.setReplyInnerStackColors(
            background: ColorScheme.stickerReplyToMessageBackgroundColor.withAlphaComponent(0.9),
            barColor: .white)
    }
    
    // MARK: - binding
    
    private func setupBinding(publisher: AnyPublisher<MessageObservedProperty, Never>)
    {
        publisher.sink { [weak self] property in
            self?.updateMessage(fieldValue: property)
        }.store(in: &cancellables)
    }
    
    // MARK: - configuration
    
    func configure(with viewModel: MessageContentViewModel)
    {
        guard let message = viewModel.message else { return }
        self.viewModel = viewModel
        
        setupBinding(publisher: viewModel.messagePropertyUpdateSubject.eraseToAnyPublisher())
        
        if let stickerName = message.sticker
        {
            stickerView.setupSticker(stickerName)
            FrameTicker.shared.add(self)
        } else {
            print("Message with sticker type, missing sticker name !!!!")
        }
        
        stickerComponentsView.configure(viewModel: viewModel.messageComponentsViewModel)
        
        if viewModel.message?.repliedTo != nil
        {
            setupReplyToMessage(viewModel: viewModel)
        }
        
        adjustStickerAlignment(viewModel.messageAlignment)
        
        if !message.reactions.isEmpty
        {
            manageReactionsSetup(withAnimation: false)
        }
    }
}

// MARK: - Seen status update

extension StickerMessageContentView
{
    private func updateMessage(fieldValue: MessageObservedProperty)
    {
        executeAfter(seconds: 1.0, block: { [weak self] in
            switch fieldValue
            {
            case .messageSeen, .seenBy:
                self?.stickerComponentsView.messageComponentsStackView.setNeedsLayout()
                self?.stickerComponentsView.configureMessageSeenStatus()
            case .reactions:
                self?.manageReactionsSetup()
            default: break
            }
            
            UIView.animate(withDuration: 0.3) {
                self?.superview?.layoutIfNeeded()
            }
            
            self?.onRelayoutNeeded?()
        })
    }
    
    private func manageReactionsSetup(withAnimation animated: Bool = true)
    {
        if reactionUIView == nil,
           let message = viewModel?.message
        {
            self.reactionUIView = .init(from: message)
            reactionUIView?.addReaction(to: containerView, withAnimation: animated)
            setReactionViewTrailingConstraint()
        } else if viewModel?.message?.reactions.isEmpty == true
        {
            self.reactionUIView?.removeReaction(from: containerView)
            self.reactionUIView = nil
        } else {
            self.reactionUIView?.updateReactions(on: containerView)
        }
    }
    
    private func setReactionViewTrailingConstraint()
    {
        reactionUIView?.reactionView?.trailingAnchor.constraint(lessThanOrEqualTo: self.stickerComponentsView.leadingAnchor, constant: -10).isActive = true
    }
}


extension StickerMessageContentView: FrameTickRecievable
{
    func didReceiveFrameTick(deltaTime: TimeInterval)
    {
        guard !isRendering else { return }

        //  Drop frames if renderer lags
//        if CACurrentMediaTime() - lastRenderTime < (1.0 / 60.0)
//        {
//            return
//        }

        lastRenderTime = CACurrentMediaTime()
        isRendering = true

        ThorVGRenderQueue.shared.async { [weak self] in
            guard let self else { return }
            defer { self.isRendering = false }
            self.stickerView.render(deltaTime: deltaTime)
        }
    }
}
