//
//  StickerContentView.swift
//  ChatUpp
//
//  Created by Andrei Pripa on 9/19/25.
//

import UIKit
import Combine


final class StickerMessageContentView: UIView
{
    private var stickerView: StickerView = .init(size: .init(width: 300, height: 300))
    private let stickerComponentsView: MessageComponentsView = .init()
    private var replyToMessageStackView: ReplyToMessageStackView?
    private var cancellables = Set<AnyCancellable>()
    
    private var isRendering: Bool = false
    private var lastRenderTime: CFTimeInterval = 0
    
    convenience init()
    {
        self.init(frame: .zero)
        setupSticker()
        setupStickerComponentsView()
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
    private func setupStickerComponentsView()
    {
        addSubview(stickerComponentsView)
        stickerComponentsView.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            stickerComponentsView.trailingAnchor.constraint(equalTo: stickerView.trailingAnchor, constant: -8),
            stickerComponentsView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -5),
        ])
    }
    
    private func setupSticker()
    {
        addSubview(stickerView)
        stickerView.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
//            stickerView.topAnchor.constraint(equalTo: topAnchor, constant: 10),
//            stickerView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -10),
            stickerView.heightAnchor.constraint(equalToConstant: 170),
            stickerView.widthAnchor.constraint(equalTo: stickerView.heightAnchor),
        ])
    }
    
    private func adjustStickerAlignment(_ alignment: MessageAlignment)
    {
        let stickerSideConstraint = alignment == .right ?
        stickerView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -15) :
        stickerView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 15)
        stickerSideConstraint.isActive = true
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
            switch property
            {
            case .messageSeen, .seenBy: self?.updateMessageSeenStatus()
            default: break
            }
        }.store(in: &cancellables)
    }
    
    // MARK: - configuration
    
    func configure(with viewModel: MessageContentViewModel)
    {
        guard let message = viewModel.message else { return }
        
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
    }
}

// MARK: - Seen status update

extension StickerMessageContentView
{
    private func updateMessageSeenStatus()
    {
        executeAfter(seconds: 0.2, block: { [weak self] in
            self?.stickerComponentsView.messageComponentsStackView.setNeedsLayout()
            self?.stickerComponentsView.configureMessageSeenStatus()
            
            UIView.animate(withDuration: 0.3) {
                self?.superview?.layoutIfNeeded()
            }
        })
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
