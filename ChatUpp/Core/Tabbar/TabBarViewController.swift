//
//  TabBarController.swift
//  ChatUpp
//
//  Created by Andrei Pripa on 8/30/23.
//

import UIKit

protocol TabBarVisibilityProtocol: AnyObject
{
    func hideTabBar()
    func showTabBar()
}

class TabBarViewController: UITabBarController, UITabBarControllerDelegate
{
    private(set) var chatsVC: ChatsViewController?
    private(set) var settingsVC: SettingsViewController?

    private(set) var chatsNavigationController: UINavigationController?
    private(set) var settingsNavigationController: UINavigationController?

    public override func viewDidLoad()
    {
        super.viewDidLoad()
        
        view.backgroundColor = ColorManager.tabBarBackgroundColor
        tabBar.isHidden = true
        self.delegate = self
    }
    
    private func setupNavigationController()
    {
        guard let chatsVC = chatsVC,
              let settingsVC = settingsVC else { return }
        
        chatsNavigationController = UINavigationController(rootViewController: chatsVC)
        settingsNavigationController = UINavigationController(rootViewController: settingsVC)
        
        chatsNavigationController?.tabBarItem = UITabBarItem(title: "Chats", image: nil, tag: 1)
        settingsNavigationController?.tabBarItem = UITabBarItem(title: "Settings", image: nil, tag: 2)
        
        chatsNavigationController?.navigationBar.tintColor = ColorManager.actionButtonsTintColor
        settingsNavigationController?.navigationBar.tintColor = ColorManager.actionButtonsTintColor
    }
    
    func setupTabBarController()
    {
        chatsVC = ChatsViewController()
        settingsVC = SettingsViewController()

        setupNavigationController()
        
        viewControllers = [chatsNavigationController!,settingsNavigationController!]
        
        tabBar.isHidden = false
        
        setupTabarAppearance()
        
        setupNotificationForBadgeUpdate()
    }
    
    func setupTabarAppearance()
    {
        Utilities.setupNavigationBarAppearance()
        
        let tabBarAppearance = UITabBarAppearance()
        let tabBarItemAppearance = UITabBarItemAppearance()

        tabBarAppearance.backgroundColor = ColorManager.navigationBarBackgroundColor.withAlphaComponent(0.85)
        tabBarAppearance.backgroundEffect = UIBlurEffect(style: .light)

        tabBarItemAppearance.selected.titleTextAttributes = [NSAttributedString.Key.foregroundColor: ColorManager.tabBarSelectedItemsTintColor]
        tabBarItemAppearance.selected.iconColor = ColorManager.tabBarSelectedItemsTintColor
        tabBarItemAppearance.normal.iconColor = ColorManager.tabBarNormalItemsTintColor
        tabBarItemAppearance.normal.titleTextAttributes = [NSAttributedString.Key.foregroundColor: ColorManager.tabBarNormalItemsTintColor, NSAttributedString.Key.font: UIFont.systemFont(ofSize: 10, weight: .medium)]

        tabBarAppearance.stackedLayoutAppearance = tabBarItemAppearance
        
        addTabbarIcons()
        
        tabBar.standardAppearance = tabBarAppearance
        tabBar.scrollEdgeAppearance = tabBarAppearance
    }

    func addTabbarIcons() {
        if let tabBarItems = tabBar.items {
            let settingsItem = tabBarItems[1]
            let chatItem = tabBarItems[0]
            settingsItem.image = UIImage(named: "profile_icon")
            chatItem.image = UIImage(named: "chats_icon")
        }
    }
    
    @MainActor
    func destroyItems()
    {
        chatsVC?.cleanup()
        settingsVC?.cleanup()
        chatsVC = nil
        settingsVC = nil
        chatsNavigationController = nil
        settingsNavigationController = nil
        viewControllers?.removeAll()
    }
    
    deinit {
//        print("TABBAR Deninit")
    }
}

//MARK: - Notification for badge update

extension TabBarViewController
{
    private func setupNotificationForBadgeUpdate()
    {
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(updateBadgeCount(_ :)),
                                               name: .didUpdateUnseenMessageCount,
                                               object: nil)
    }
    
    @objc private func updateBadgeCount(_ notification: Notification)
    {
        guard let count = notification.userInfo?["unseen_messages_count"] as? Int,
              let tabItem = tabBar.items?.first else { return }

        let current = Int(tabItem.badgeValue ?? "0") ?? 0
        let newValue = current + count

        tabItem.badgeValue = newValue > 0 ? "\(newValue)" : nil
    }
}

//MARK: - Hide/show tab bar
extension TabBarViewController: TabBarVisibilityProtocol
{
    func hideTabBar()
    {
        guard tabBar.isHidden == false else { return }
        
//        let height = tabBar.bounds.size.height
        UIView.animate(withDuration: 0.3) {
            self.tabBar.frame.origin.y = UIScreen.main.bounds.maxY
            self.view.layoutIfNeeded()
        } completion: { _ in
            self.tabBar.isHidden = true
        }
    }
    
    func showTabBar()
    {
        guard tabBar.isHidden == true else { return }
        
        tabBar.isHidden = false
        let height = tabBar.bounds.size.height
        self.tabBar.frame.origin.y = UIScreen.main.bounds.maxY
        UIView.animate(withDuration: 0.3) {
            self.tabBar.frame.origin.y -= height
            self.view.layoutIfNeeded()
        }
    }
 
}

