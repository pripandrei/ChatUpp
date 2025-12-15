//
//  AudioContentView.swift
//  ChatUpp
//
//  Created by Andrei Pripa on 10/21/25.
//

import UIKit
import SwiftUI

final class VoiceMessageContentView: ContainerView
{
    private let messageComponentsView: MessageComponentsView = .init()
    private var playbackControlPanel: VoicePlaybackControlPanelView!
    private let viewModel: MessageContentViewModel
    
    lazy var replyToMessageStack: ReplyToMessageStackView = {
        let margins: UIEdgeInsets = .init(top: 2, left: 0, bottom: 4, right: 0)
        let replyToMessageStack = ReplyToMessageStackView(margin: margins)
        return replyToMessageStack
    }()
    
    private var messageSenderNameColor: UIColor
    {
        let senderID = viewModel.message?.senderId
        return ColorScheme.color(for: senderID ?? "12345")
    }

    init(viewModel: MessageContentViewModel)
    {
        self.viewModel = viewModel
        super.init(spacing: 2.0,
                   margin: .init(top: 6,
                                 left: 10,
                                 bottom: 10,
                                 right: 10))
        layer.cornerRadius = 15
        clipsToBounds = true
        
        guard let path = viewModel.message?.voicePath,
              let url = CacheManager.shared.getURL(for: path),
              let audioSamples = viewModel.message?.audioSamples else { fatalError("Audio path should be present") }
        
        let controlPanelcolorScheme = makeColorSchemeForControlPanel(basedOnAlignment: viewModel.messageAlignment)
        setupPlaybackControlPanel(withUrl: url, audioSamples: Array(audioSamples), colorScheme: controlPanelcolorScheme)
        setupMessageComponentsView()
        messageComponentsView.configure(viewModel: viewModel.messageComponentsViewModel)
        setupMessageToReplyView()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
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
        view.isOpaque = true
        
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
        
        let index = viewModel.message?.seenBy.isEmpty == true ? 0 : 1 // this is a check for wheather chat is group or not (seenBy will be empty if its 1 to 1 chat)
    
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
}
