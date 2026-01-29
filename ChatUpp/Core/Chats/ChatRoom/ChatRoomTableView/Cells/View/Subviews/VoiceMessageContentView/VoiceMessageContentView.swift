//
//  AudioContentView.swift
//  ChatUpp
//
//  Created by Andrei Pripa on 10/21/25.
//

import UIKit
import SwiftUI
import Combine

final class VoiceMessageContentView: ContainerView
{
    private let messageComponentsView: MessageComponentsView = .init()
    private var playbackControlPanel: VoicePlaybackControlPanelView!
    private let viewModel: MessageContentViewModel
    private var cancellables = Set<AnyCancellable>()
    private var messageLayoutConfiguration: MessageLayoutConfiguration!
    
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
    
    private var messageSenderNameColor: UIColor
    {
        let senderID = viewModel.message?.senderId
        return ColorScheme.color(for: senderID ?? "12345")
    }

    init(viewModel: MessageContentViewModel,
         messageLayoutConfiguration: MessageLayoutConfiguration)
    {
        self.viewModel = viewModel
        super.init(spacing: 2.0,
                   margin: .init(top: 6,
                                 left: 10,
                                 bottom: 10,
                                 right: 10))
        layer.cornerRadius = 15
        clipsToBounds = true
        
        self.messageLayoutConfiguration = messageLayoutConfiguration
        
        guard let path = viewModel.message?.voicePath,
              let url = CacheManager.shared.getURL(for: path),
              let audioSamples = viewModel.message?.audioSamples else { fatalError("Audio path should be present") }
        
        setupSenderNameLabel()
        
        let controlPanelcolorScheme = makeColorSchemeForControlPanel(basedOnAlignment: viewModel.messageAlignment)
        setupPlaybackControlPanel(withUrl: url, audioSamples: Array(audioSamples), colorScheme: controlPanelcolorScheme)
        setupMessageComponentsView()
        messageComponentsView.configure(viewModel: viewModel.messageComponentsViewModel)
        setupMessageToReplyView()
        setupBings()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    deinit
    {
        print("deinit voice message content view")
        cancellables.forEach { cancelable in
            cancelable.cancel()
        }
        cancellables.removeAll()
        messageComponentsView.cleanupContent()
    }
    
    // Bindings
    
    private func setupBings()
    {
        viewModel.messagePropertyUpdateSubject
            .sink { [weak self] property in
                if case .messageSeen = property {
                    self?.updateMessageSeenStatus()
                }
            }.store(in: &cancellables)
    }
    
    private func setupPlaybackControlPanel(withUrl URL: URL,
                                           audioSamples: [Float],
                                           colorScheme: VoicePlaybackControlPanelView.ColorScheme)
    {
        self.playbackControlPanel = .init(audioFileURL: URL,
                                          audioSamples: audioSamples,
                                          colorScheme: colorScheme)
        
        guard let view = UIHostingController(rootView: playbackControlPanel).view else {return}
        view.backgroundColor = .clear
//        view.isOpaque = true
        
        addArrangedSubview(view)
        
        view.translatesAutoresizingMaskIntoConstraints = false
        
        view.heightAnchor.constraint(equalToConstant: 55).isActive = true
        view.widthAnchor.constraint(equalToConstant: 250).isActive = true
    }
    
    private func setupMessageComponentsView()
    {
        addSubview(messageComponentsView)
        messageComponentsView.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            messageComponentsView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -8),
            messageComponentsView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -5),
        ])
    }
    
    private func makeColorSchemeForControlPanel(basedOnAlignment alignment: MessageAlignment) ->  VoicePlaybackControlPanelView.ColorScheme
    {
        switch alignment
        {
        case .right: return .init(backgroundColor: .init(ColorScheme.outgoingMessageBackgroundColor),
                                  filledColor: .white,
                                  unfilledColor: .init(ColorScheme.incomingMessageComponentsTextColor),
                                  playButtonColor: .white)
        case .left: return .init(backgroundColor: .init(ColorScheme.incomingMessageBackgroundColor),
                                 filledColor: .init((ColorScheme.sendMessageButtonBackgroundColor)),
                                 unfilledColor: .init(ColorScheme.outgoingReplyToMessageBackgroundColor),
                                 playButtonColor: .init(ColorScheme.sendMessageButtonBackgroundColor))
        default:
            fatalError("Unhandled alignment case: \(alignment)")
        }
    }
    
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
    
    private func updateMessageSeenStatus()
    {
        executeAfter(seconds: 0.2, block: { [weak self] in
            self?.messageComponentsView.messageComponentsStackView.setNeedsLayout()
            self?.messageComponentsView.configureMessageSeenStatus()
            
            UIView.animate(withDuration: 0.3) {
                self?.superview?.layoutIfNeeded()
            }
        })
    }
}

//MARK: Sender name setup
extension VoiceMessageContentView
{
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

