//
//  MessageBannerPresenter.swift
//  ChatUpp
//
//  Created by Andrei Pripa on 8/18/25.
//


import UIKit
import SwiftUI
import Combine

struct MessageBannerData
{
    let chat: Chat
    let message: Message
    let avatar: Data?
    let titleName: String
    let contentThumbnail: Data?
}

final class MessageBannerPresenter
{
    static let shared = MessageBannerPresenter()
    private init() {}
    
    private(set) var requestChatOpenSubject = PassthroughSubject<Chat, Never>()

    func presentBanner(usingBannerData bannerData: MessageBannerData)
    {
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let window = windowScene.keyWindow else {return}
        
        let messageNotificationVM = MessageNotificationBannerViewModel(messageBannerData: bannerData)
        
        let messageBanner = MessageNotificationBannerView(viewModel: messageNotificationVM)
        
        let messageBannerHostingController = UIHostingController(
            rootView: messageBanner)
        
        let bannerView = messageBannerHostingController.view!
        bannerView.backgroundColor = .clear
        
        messageNotificationVM.onTap = {
            self.requestChatOpenSubject.send(bannerData.chat)
            self.animateBannerDismissal(bannerView)
        }

        window.addSubview(bannerView)
        
        bannerView.translatesAutoresizingMaskIntoConstraints = false

        // Position horizontally centered and set fixed width (optional)
        bannerView.centerXAnchor.constraint(equalTo: window.centerXAnchor).isActive = true
        bannerView.topAnchor.constraint(equalTo: window.topAnchor, constant: -100).isActive = true
        bannerView.widthAnchor.constraint(equalToConstant: UIScreen.main.bounds.width - 50).isActive = true
        
        animateBannerPresentation(bannerView)
    }
    
    private func animateBannerPresentation(_ banner: UIView)
    {
        UIView.animate(withDuration: 0.4,
                       delay: 0,
                       options: .curveEaseOut) {
            banner.transform = CGAffineTransform(translationX: 0, y: 100)
        } completion: { _ in
            self.animateBannerDismissal(banner, after: 5.0)
        }
    }
    
    private func animateBannerDismissal(_ banner: UIView, after: Double = 0.0)
    {
        executeAfter(seconds: after) {
            // Animate up
            UIView.animate(withDuration: 0.4,
                           delay: 0,
                           options: .curveEaseIn) {
                banner.transform = CGAffineTransform(translationX: 0, y: -50)
            } completion: { _ in
                banner.removeFromSuperview()
            }
        }
    }
}
