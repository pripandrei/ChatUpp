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
            stickerComponentsView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -8),
            stickerComponentsView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -5),
        ])
    }
    
    private func setupSticker()
    {
        addSubview(stickerRLottieView)
        stickerRLottieView.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            stickerRLottieView.topAnchor.constraint(equalTo: topAnchor),
            stickerRLottieView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -15),
            stickerRLottieView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -10),
//            stickerLottieView.heightAnchor.constraint(equalToConstant: 170),
            stickerRLottieView.widthAnchor.constraint(equalTo: stickerRLottieView.heightAnchor),
        ])
    }
    
    private func setupReplyToMessage(viewModel: MessageContentViewModel)
    {
        self.replyToMessageStackView = .init(margin: .init(top: 2, left: 2, bottom: 2, right: 2))
        addSubview(replyToMessageStackView!)
        
        replyToMessageStackView?.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            replyToMessageStackView!.topAnchor.constraint(equalTo: self.topAnchor),
            replyToMessageStackView!.leadingAnchor.constraint(equalTo: self.leadingAnchor, constant: 10),
            replyToMessageStackView!.widthAnchor.constraint(equalToConstant: 130)
        ])
        
        guard let messageSenderName = viewModel.referencedMessageSenderName
              /*let message = viewModel.referencedMessage*/ else {return}
        
        let messageText = viewModel.getTextForReplyToMessage()
//        let replyLabelText = replyToMessageStackView!.createReplyMessageAttributedText(
//            with: messageSenderName,
//            messageText: messageText
//        )
        
        let image = viewModel.getImageDataThumbnailFromReferencedMessage()
        replyToMessageStackView?.configure(senderName: messageSenderName, messageText: messageText, imageData: image)
//        self.replyToMessageStackView?.configure(
//            with: replyLabelText,
//            imageData: image)
        
        replyToMessageStackView?.setReplyInnerStackColors(
            background: ColorManager.stickerReplyToMessageBackgroundColor.withAlphaComponent(0.9),
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
