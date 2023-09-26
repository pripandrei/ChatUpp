//
//  TabBarController.swift
//  ChatUpp
//
//  Created by Andrei Pripa on 8/30/23.
//

import UIKit

class TabBarViewController: UITabBarController {
    public override func viewDidLoad() {
        super.viewDidLoad()
        
        setupTabBarController()
    }
    
    func setupTabBarController() {
        let firstVC = UINavigationController(rootViewController: ChatsViewController())
        firstVC.tabBarItem = UITabBarItem(title: "Chats", image: nil, tag: 1)
        
        let secondVC = SettingsViewController()
        secondVC.tabBarItem = UITabBarItem(title: "Settings", image: nil, tag: 2)
        
        viewControllers = [firstVC,secondVC]
    }
}
