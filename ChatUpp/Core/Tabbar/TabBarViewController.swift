//
//  TabBarController.swift
//  ChatUpp
//
//  Created by Andrei Pripa on 8/30/23.
//

import UIKit
import Combine

protocol TabBarVisibilityProtocol: AnyObject
{
    func hideTabBar()
    func showTabBar()
}

class TabBarViewController: UITabBarController
{
//    private(set) weak var chatsVC: ChatsViewController?
//    private(set) weak var settingsVC: SettingsViewController?
//
//    private(set) var chatsNavigationController: UINavigationController?
//    private(set) var settingsNavigationController: UINavigationController?
    
    //    weak var coordinator: MainCoordinator?
    
    private var subscribers = Set<AnyCancellable>()

    public override func viewDidLoad()
    {
        super.viewDidLoad()
        
        view.backgroundColor = ColorManager.tabBarBackgroundColor
        tabBar.isHidden = true
//        self.delegate = self
    }
    
    private func setupTabBarViewControllers()
    {
        let chatsVC = ChatsViewController()
        let settingsVC = SettingsViewController()
        
        let chatsNavigationController = UINavigationController(rootViewController: chatsVC)
        let settingsNavigationController = UINavigationController(rootViewController: settingsVC)
        
        settingsNavigationController.tabBarItem = UITabBarItem(title: "Chats",
                                                               image: UIImage(named: "profile_icon"),
                                                               tag: 1)
        chatsNavigationController.tabBarItem = UITabBarItem(title: "Settings",
                                                            image: UIImage(named: "chats_icon"),
                                                            tag: 2)
        
//        chatsNavigationController.navigationBar.tintColor = ColorManager.actionButtonsTintColor
//        settingsNavigationController.navigationBar.tintColor = ColorManager.actionButtonsTintColor
        
        viewControllers = [chatsNavigationController,settingsNavigationController]
    }
    
    func setupTabBarController()
    {
//        chatsVC = ChatsViewController()
//        settingsVC = SettingsViewController()

        setupTabBarViewControllers()
        
//        viewControllers = [chatsNavigationController!,settingsNavigationController!]
        
        tabBar.isHidden = false
        setupTabarAppearance()
        setBindings()
    }
    
    
//    func setupTabBarController()
//    {
//           let chatsVC = ChatsViewController()
//           let settingsVC = SettingsViewController()
//           
//           let chatsNav = UINavigationController(rootViewController: chatsVC)
//           let settingsNav = UINavigationController(rootViewController: settingsVC)
//           
//           chatsNav.tabBarItem = UITabBarItem(title: "Chats", image: UIImage(named: "chats_icon"), tag: 1)
//           settingsNav.tabBarItem = UITabBarItem(title: "Settings", image: UIImage(named: "profile_icon"), tag: 2)
//           
//           viewControllers = [chatsNav, settingsNav]
//           tabBar.isHidden = false
//           
//           setupTabarAppearance()
//           setBindings()
//       }
    
   
    func setupTabarAppearance()
    {
        Utilities.setupNavigationBarAppearance()
        
        let tabBarAppearance = UITabBarAppearance()
        let tabBarItemAppearance = UITabBarItemAppearance()

        tabBarAppearance.backgroundColor = #colorLiteral(red: 0.4331829548, green: 0.2255868614, blue: 0.4133677185, alpha: 1).withAlphaComponent(0.3)
        tabBarAppearance.backgroundEffect = UIBlurEffect(style: .systemChromeMaterialDark)

        tabBarItemAppearance.selected.titleTextAttributes = [NSAttributedString.Key.foregroundColor: ColorManager.tabBarSelectedItemsTintColor]
        tabBarItemAppearance.selected.iconColor = ColorManager.tabBarSelectedItemsTintColor
        tabBarItemAppearance.normal.iconColor = ColorManager.tabBarNormalItemsTintColor
        tabBarItemAppearance.normal.titleTextAttributes = [NSAttributedString.Key.foregroundColor: ColorManager.tabBarNormalItemsTintColor, NSAttributedString.Key.font: UIFont.systemFont(ofSize: 10, weight: .medium)]

        tabBarAppearance.stackedLayoutAppearance = tabBarItemAppearance
        
        chatsNavigationController?.navigationBar.tintColor = ColorManager.actionButtonsTintColor
        settingsNavigationController?.navigationBar.tintColor = ColorManager.actionButtonsTintColor
//        addTabbarIcons()
        
        tabBar.standardAppearance = tabBarAppearance
        tabBar.scrollEdgeAppearance = tabBarAppearance
    }

    // ++++++ =======
//    func addTabbarIcons() {
//        if let tabBarItems = tabBar.items {
//            let settingsItem = tabBarItems[1]
//            let chatItem = tabBarItems[0]
//            settingsItem.image = UIImage(named: "profile_icon")
//            chatItem.image = UIImage(named: "chats_icon")
//        }
//    }
    
//    @MainActor
//    func destroyItems()
//    {
//        // Cancel any Combine subscriptions held by this tab bar
//        subscribers.forEach { $0.cancel() }
//        subscribers.removeAll()
//
//        // Remove NotificationCenter observers (not usually necessary with modern Combine)
//        NotificationCenter.default.removeObserver(self)
//
//        // Let child view controllers clean up
//        chatsVC?.cleanup()
//        settingsVC?.cleanup()
//
//        // Clear navigation controllers and their view controller stacks
//        chatsNavigationController?.viewControllers = []
//        settingsNavigationController?.viewControllers = []
//
//        // Break references
//        chatsVC = nil
//        settingsVC = nil
//        chatsNavigationController = nil
//        settingsNavigationController = nil
//
//        // Remove view controllers from UITabBarController completely
//        viewControllers = nil
//
//        // Clear tab bar items explicitly just in case
//        tabBar.items?.forEach { item in
//            item.badgeValue = nil
//            item.image = nil
//            item.title = nil
//        }
//        tabBar.setNeedsLayout()
//    }

    
    @MainActor
    func destroyItems()
    {
        NotificationCenter.default.removeObserver(self)
        ChatManager.shared.resetTotalUnseenMessageCount()
        
        subscribers.forEach { subscriber in
            subscriber.cancel()
        }
        subscribers.removeAll()
        
        chatsViewController?.cleanup()
        settingsViewController?.cleanup()
//        chatsVC = nil
//        settingsVC = nil
//        chatsNavigationController = nil
//        settingsNavigationController = nil
        viewControllers?.removeAll()
        viewControllers = nil
    }
    
    deinit {
        print("TABBAR Deninit")
    }
}

//MARK: - Tab bar child items

extension TabBarViewController
{
    var chatsNavigationController: UINavigationController?
    {
        return viewControllers?.first as? UINavigationController
    }
    
    var settingsNavigationController: UINavigationController?
    {
        return viewControllers?[safe: 1] as? UINavigationController
    }

    var chatsViewController: ChatsViewController?
    {
        chatsNavigationController?.viewControllers.first as? ChatsViewController
    }
    
    var settingsViewController: SettingsViewController?
    {
        settingsNavigationController?.viewControllers.first as? SettingsViewController
    }
    
}

//MARK: - Notification for badge update

extension TabBarViewController
{
    private func setBindings()
    {
        ChatManager.shared.$totalUnseenMessageCount
            .receive(on: DispatchQueue.main)
            .sink { [weak self] count in
                guard let tabItem = self?.tabBar.items?.first else { return }
                tabItem.badgeValue = count > 0 ? "\(count)" : nil
            }.store(in: &subscribers)
    }
}

//MARK: - Hide/show tab bar
extension TabBarViewController: TabBarVisibilityProtocol
{
    func hideTabBar()
    {
        guard tabBar.isHidden == false else { return }

        UIView.animate(withDuration: 0.3)
        {
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
        
        UIView.animate(withDuration: 0.3)
        {
            self.tabBar.frame.origin.y -= height
            self.view.layoutIfNeeded()
        }
    }
}

