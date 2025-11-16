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

    init(viewModel: MessageContentViewModel)
    {
        super.init(spacing: 2.0,
                   margin: .init(top: 6,
                                 left: 10,
                                 bottom: 12,
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
        
        view.heightAnchor.constraint(equalToConstant: 60).isActive = true
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
        case .right: return .init(backgroundColor: .init(ColorManager.outgoingMessageBackgroundColor),
                                  filledColor: .white,
                                  unfilledColor: .init(ColorManager.incomingMessageComponentsTextColor),
                                  playButtonColor: .white)
        case .left: return .init(backgroundColor: .init(ColorManager.incomingMessageBackgroundColor),
                                 filledColor: .init((ColorManager.sendMessageButtonBackgroundColor)),
                                 unfilledColor: .init(ColorManager.outgoingReplyToMessageBackgroundColor),
                                 playButtonColor: .init(ColorManager.sendMessageButtonBackgroundColor))
        default:
            fatalError("Unhandled alignment case: \(alignment)")
        }
    }
    
}
