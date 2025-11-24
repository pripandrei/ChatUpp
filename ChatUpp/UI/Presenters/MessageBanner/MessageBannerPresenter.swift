import UIKit
import SwiftUI
import Combine

final class MessageBannerPresenter
{
    static let shared = MessageBannerPresenter()
    private init() {}
    
    private var presentedBanner: UIView?
    private(set) var requestChatOpenSubject = PassthroughSubject<Chat, Never>()

    func presentBanner(usingBannerData bannerData: MessageBannerData)
    {
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let window = windowScene.keyWindow else {return}
        
        if let presentedBanner
        {
            animateBannerDismissal(presentedBanner)
        }
        
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
        
        presentedBanner = bannerView
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
        executeAfter(seconds: after)
        {
            print("execute after triggerd")
            // Animate up
            UIView.animate(withDuration: 0.4,
                           delay: 0,
                           options: .curveEaseIn) {
                banner.transform = CGAffineTransform(translationX: 0, y: -50)
            } completion: { _ in
                banner.removeFromSuperview()
                
                // Only set to nil if this banner is still the presented one
                if self.presentedBanner === banner {
                    self.presentedBanner = nil
                }
            }
        }
    }
}


