//
//  TabBarController.swift
//  ChatUpp
//
//  Created by Andrei Pripa on 8/30/23.
//

import UIKit

class TabBarViewController: UITabBarController, UITabBarControllerDelegate {
    
    private(set) var chatsVC: ChatsViewController?
    private(set) var settingsVC: SettingsViewController?

    private(set) var chatsNavigationController: UINavigationController?
    private(set) var settingsNavigationController: UINavigationController?

    public override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = #colorLiteral(red: 0.1411764771, green: 0.3960784376, blue: 0.5647059083, alpha: 1)
        tabBar.isHidden = true
        self.delegate = self
    }
    
    func setupTabBarController() {
        chatsVC = ChatsViewController()
        settingsVC = SettingsViewController()
    
        chatsNavigationController = UINavigationController(rootViewController: chatsVC!)
        settingsNavigationController = UINavigationController(rootViewController: settingsVC!)
        
        chatsNavigationController?.tabBarItem = UITabBarItem(title: "Chats", image: nil, tag: 1)
        settingsNavigationController?.tabBarItem = UITabBarItem(title: "Settings", image: nil, tag: 2)
        
        viewControllers = [chatsNavigationController!,settingsNavigationController!]
        
        tabBar.isHidden = false
        
        setupTabarAppearance()
//        if let settingsItem = tabBar.items?.last {
//            settingsItem.isEnabled = false
//        }
    }
    
    func setupTabarAppearance() {
        let tabBarAppearance = UITabBarAppearance()
        let tabBarItemAppearance = UITabBarItemAppearance()
        
//        guard let customFont = UIFont(name: "HelveticaNeue-Bold", size: 10) else  {
//            return
//        }
//
        var cusstomFont = (UIFont(name: "HelveticaNeue-Bold", size: 10) != nil) ? UIFont(name: "HelveticaNeue-Bold", size: 10) : UIFont.systemFont(ofSize: 10, weight: .bold)
        tabBarAppearance.backgroundColor = #colorLiteral(red: 0.1057919934, green: 0.2902272344, blue: 0.4154375792, alpha: 1).withAlphaComponent(0.9)
        tabBarItemAppearance.selected.titleTextAttributes = [NSAttributedString.Key.foregroundColor: #colorLiteral(red: 0, green: 0.6879786849, blue: 1, alpha: 1)]
        tabBarItemAppearance.selected.iconColor = #colorLiteral(red: 0, green: 0.6879786849, blue: 1, alpha: 1)
        tabBarItemAppearance.normal.iconColor = #colorLiteral(red: 0.4879326224, green: 0.617406249, blue: 0.6558095217, alpha: 1)
        tabBarItemAppearance.normal.titleTextAttributes = [NSAttributedString.Key.foregroundColor: #colorLiteral(red: 0.4879326224, green: 0.617406249, blue: 0.6558095217, alpha: 1)]
        tabBarItemAppearance.normal.titleTextAttributes = [NSAttributedString.Key.font: UIFont.systemFont(ofSize: 10, weight: .bold)]
        tabBarAppearance.stackedLayoutAppearance = tabBarItemAppearance
        
//     #colorLiteral(red: 0.4879326224, green: 0.617406249, blue: 0.6558095217, alpha: 1)
        addTabbarIcons()
        
        tabBar.standardAppearance = tabBarAppearance
        tabBar.scrollEdgeAppearance = tabBarAppearance
    }

    func addTabbarIcons() {
        if let tabBarItems = tabBar.items {
            let settingsItem = tabBarItems[1]
            let chatItem = tabBarItems[0]
            settingsItem.image = UIImage(named: "profile_icon")
            chatItem.image = UIImage(named: "Icon-App-29x29")
        }
    }
    
    
    private var shouldEnableSecondItem: Bool = false
    
//    func tabBarController(_ tabBarController: UITabBarController, shouldSelect viewController: UIViewController) -> Bool {
//        if shouldEnableSecondItem {
//            return true
//        }
//        return false
//    }
    
    deinit {
        print("TABBAR Deninit")
    }
}
