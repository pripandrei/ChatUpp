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
    private var playbackControlPanel: AudioControlPanelView?
    
    override init(spacing: CGFloat = 0, margin: UIEdgeInsets = .zero)
    {
        super.init(spacing: 2.0,
                   margin: .init(top: 6,
                                 left: 10,
                                 bottom: 6,
                                 right: 10))
        
        layer.cornerRadius = 15
        clipsToBounds = true
        setupPlaybackControlPanel()
        setupMessageComponentsView()
    }
    
//    init()
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupPlaybackControlPanel()
    {
        self.playbackControlPanel = .init()
        guard let view = UIHostingController(rootView: playbackControlPanel).view else {return}
        addArrangedSubview(view)
        
        view.translatesAutoresizingMaskIntoConstraints = false
        view.heightAnchor.constraint(equalToConstant: 65).isActive = true
//        view.widthAnchor.constraint(equalToConstant: 200).isActive = true
        
    }
    
    func configure(with viewModel: MessageContentViewModel)
    {
        messageComponentsView.configure(viewModel: viewModel.messageComponentsViewModel)
        
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
    
    
    
}
