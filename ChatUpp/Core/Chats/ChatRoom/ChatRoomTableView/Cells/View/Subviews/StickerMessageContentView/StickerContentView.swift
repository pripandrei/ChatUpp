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
    private var stickerRLottieView: RLLottieView = .init(renderSize: .init(width: 300, height: 300))
    private let stickerComponentsView: MessageComponentsView = .init()
    private var replyToMessageStackView: ReplyToMessageStackView?
    private var cancellables = Set<AnyCancellable>()
    
    convenience init()
    {
        self.init(frame: .zero)
        setupSticker()
        setupStickerComponentsView()
    }
    
    deinit {
//        print("sticker view deinit")
        DisplayLinkManager.shered.cleanup(stickerRLottieView)
        stickerRLottieView.setVisible(false)
        stickerRLottieView.destroyAnimation()
        stickerComponentsView.cleanupContent()
        replyToMessageStackView?.removeFromSuperview()
        replyToMessageStackView = nil
    }
    
    //MARK: - UI setup
    private func setupStickerComponentsView()
    {
        addSubview(stickerComponentsView)
        stickerComponentsView.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            stickerComponentsView.trailingAnchor.constraint(equalTo: stickerRLottieView.trailingAnchor, constant: -8),
            stickerComponentsView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -5),
        ])
    }
    
    private func setupSticker()
    {
        addSubview(stickerRLottieView)
        stickerRLottieView.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            stickerRLottieView.topAnchor.constraint(equalTo: topAnchor, constant: 10),
            stickerRLottieView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -10),
            stickerRLottieView.widthAnchor.constraint(equalTo: stickerRLottieView.heightAnchor),
        ])
    }
    
    private func adjustStickerAlignment(_ alignment: MessageAlignment)
    {
        let stickerSideConstraint = alignment == .right ?
        stickerRLottieView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -15) :
        stickerRLottieView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 15)
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
    
    func setupBinding(publisher: AnyPublisher<Bool, Never>)
    {
        publisher.sink { [weak self] isSeen in
            if isSeen { self?.updateMessageSeenStatus() }
        }.store(in: &cancellables)
    }
    
    // MARK: - configuration
    
    func configure(with viewModel: MessageContentViewModel)
    {
        guard let message = viewModel.message else { return }
        
        setupBinding(publisher: viewModel.messageSeenStatusChangedSubject.eraseToAnyPublisher())
        
        stickerRLottieView.loadAnimation(named: message.sticker!)
        stickerRLottieView.setVisible(true)
        DisplayLinkManager.shered.addObject(stickerRLottieView)
        
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
        executeAfter(seconds: 3.0, block: {
            self.stickerComponentsView.messageComponentsStackView.setNeedsLayout()
            self.stickerComponentsView.configureMessageSeenStatus()
            
            UIView.animate(withDuration: 0.3) {
                self.superview?.layoutIfNeeded()
            }
        })
    }
}
