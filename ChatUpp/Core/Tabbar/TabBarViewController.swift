//
//  TabBarController.swift
//  ChatUpp
//
//  Created by Andrei Pripa on 8/30/23.
//

import UIKit

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
        print("TABBAR Deninit")
    }
}
