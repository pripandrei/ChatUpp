//
//  StickerContentView.swift
//  ChatUpp
//
//  Created by Andrei Pripa on 9/19/25.
//

import UIKit
import Combine

final class StickerContentView: UIView
{
    private var stickerRLottieView: RLLottieView = .init(renderSize: .init(width: 300, height: 300))
    
    private let stickerComponentsView: MessageComponentsView = .init()
    
    private var cancellables = Set<AnyCancellable>()
    
    convenience init()
    {
        self.init(frame: .zero)
        setupSticker()
        setupStickerComponentsView()
    }
    
    private func setupStickerComponentsView()
    {
        addSubview(stickerComponentsView)
        stickerComponentsView.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            stickerComponentsView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -8),
            stickerComponentsView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: 3),
        ])
    }
    
    private func setupSticker()
    {
        addSubview(stickerRLottieView)
        stickerRLottieView.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            stickerRLottieView.topAnchor.constraint(equalTo: topAnchor),
            stickerRLottieView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -10),
            stickerRLottieView.bottomAnchor.constraint(equalTo: bottomAnchor),
//            stickerLottieView.heightAnchor.constraint(equalToConstant: 170),
            stickerRLottieView.widthAnchor.constraint(equalTo: stickerRLottieView.heightAnchor),
        ])
    }
 
    func setupBinding(publisher: AnyPublisher<Bool, Never>)
    {
        publisher.sink { [weak self] isSeen in
            if isSeen { self?.updateMessageSeenStatus() }
        }.store(in: &cancellables)
    }
    
    func configure(with viewModel: MessageContainerViewModel)
    {
        guard let message = viewModel.message else { return }
        
        setupBinding(publisher: viewModel.messageSeenStatusChangedSubject.eraseToAnyPublisher())
        
        stickerRLottieView.loadAnimation(named: message.sticker!)
        stickerRLottieView.setVisible(true)
        DisplayLinkManager.shered.addObject(stickerRLottieView)
        
        stickerComponentsView.configure(viewModel: viewModel.messageComponentsViewModel)
    }
    
    deinit {
        print("sticker view deinit")
        DisplayLinkManager.shered.cleanup(stickerRLottieView)
        stickerRLottieView.setVisible(false)
        stickerRLottieView.destroyAnimation()
        stickerComponentsView.cleanupContent()
    }
}

extension StickerContentView
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
