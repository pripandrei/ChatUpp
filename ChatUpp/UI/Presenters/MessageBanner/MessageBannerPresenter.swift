import UIKit
import SwiftUI
import Combine

final class MessageBannerPresenter
{
    static let shared = MessageBannerPresenter()
    private init() {}
    
    private var presentedBanner: UIView?
    private var bannerDismissalTask: Task<Void, Never>?
    private(set) var requestChatOpenSubject = PassthroughSubject<Chat, Never>()
    
    func presentBanner(usingBannerData bannerData: MessageBannerData)
    {
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let window = windowScene.keyWindow else { return }
        
        // Dismiss current baner if another is shown
        if let currentBanner = presentedBanner {
            bannerDismissalTask?.cancel()
            animateBannerDismissal(currentBanner)
        }
        
        let messageNotificationVM = MessageNotificationBannerViewModel(messageBannerData: bannerData)
        let messageBanner = MessageNotificationBannerView(viewModel: messageNotificationVM)
        let controller = UIHostingController(rootView: messageBanner)
        let bannerView = controller.view!
        bannerView.backgroundColor = .clear
        
        messageNotificationVM.onTap = {
            self.bannerDismissalTask?.cancel()
            self.requestChatOpenSubject.send(bannerData.chat)
            self.animateBannerDismissal(bannerView)
        }
        
        window.addSubview(bannerView)
        bannerView.translatesAutoresizingMaskIntoConstraints = false
        bannerView.centerXAnchor.constraint(equalTo: window.centerXAnchor).isActive = true
        bannerView.topAnchor.constraint(equalTo: window.topAnchor, constant: -100).isActive = true
        bannerView.widthAnchor.constraint(equalToConstant: UIScreen.main.bounds.width - 50).isActive = true
        
        presentedBanner = bannerView
        animateBannerPresentation(bannerView)
    }
    private func animateBannerPresentation(_ banner: UIView)
    {
        UIView.animate(withDuration: 0.3, delay: 0, options: .curveEaseOut) {
            banner.transform = CGAffineTransform(translationX: 0, y: 100)
        } completion: { _ in
            self.scheduleAutoDismiss(for: banner)
        }
    }

    private func scheduleAutoDismiss(for banner: UIView)
    {
        bannerDismissalTask?.cancel()
        bannerDismissalTask = Task {
            try? await Task.sleep(nanoseconds: 5_000_000_000)
            guard !Task.isCancelled else { return }
            await MainActor.run {
                self.animateBannerDismissal(banner)
            }
        }
    }
    private func animateBannerDismissal(_ banner: UIView)
    {
        UIView.animate(withDuration: 0.3,
                       delay: 0,
                       options: .curveEaseIn) {
            banner.transform = CGAffineTransform(translationX: 0, y: -50)
        } completion: { _ in
            banner.removeFromSuperview()
            
            if banner === self.presentedBanner {
                self.presentedBanner = nil
            }
        }
    }
}
