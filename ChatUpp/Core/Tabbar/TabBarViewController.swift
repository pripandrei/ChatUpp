//
//  TabBarController.swift
//  ChatUpp
//
//  Created by Andrei Pripa on 8/30/23.
//

import UIKit

class TabBarViewController: UITabBarController {
    
    var customNavigationController: UINavigationController?
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        
        setupTabBarController()
    }
    
    func setupTabBarController() {
        let navController = UINavigationController(rootViewController: ChatsViewController())
        navController.tabBarItem = UITabBarItem(title: "Chats", image: nil, tag: 1)
        self.customNavigationController = navController
    
        let secondVC = SettingsViewController()
        secondVC.tabBarItem = UITabBarItem(title: "Settings", image: nil, tag: 2)
        
        viewControllers = [navController,secondVC]
    }
    
    deinit {
        print("TABBAR Deninit")
    }
}
