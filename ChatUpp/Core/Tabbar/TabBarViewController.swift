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

class TabBarViewController: UITabBarController, UITabBarControllerDelegate
{
    private(set) var chatsVC: ChatsViewController?
    private(set) var settingsVC: SettingsViewController?

    private(set) var chatsNavigationController: UINavigationController?
    private(set) var settingsNavigationController: UINavigationController?
    
    private var subscribers = Set<AnyCancellable>()

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
    
        setBindings()
    }
    
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
        NotificationCenter.default.removeObserver(self)
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

