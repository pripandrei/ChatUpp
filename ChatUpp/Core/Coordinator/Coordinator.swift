//
//  Coordinator.swift
//  ChatUpp
//
//  Created by Andrei Pripa on 10/8/23.
//

import Foundation
import UIKit

protocol Coordinator: AnyObject {
    var tabBar: TabBarViewController { get set }
    func start()
    func presentLogInForm()
}

class MainCoordinator: Coordinator {
    
    var tabBar: TabBarViewController

    init(tabBar: TabBarViewController) {
        self.tabBar = tabBar
    }
    

    func start() {
        guard let navController = tabBar.viewControllers?.first as? UINavigationController,
        let chatsViewController = navController.viewControllers.first as? ChatsViewController else {
            return
        }
        chatsViewController.coordinatorDelegate = self
        
        guard let settingsViewController = tabBar.viewControllers?.first(where: { $0 is SettingsViewController }) as? SettingsViewController else {
            return
        }
        settingsViewController.coordinatorDelegate = self
 
    }
    
    func presentLogInForm() {
        let loginVC = LoginViewController()
        loginVC.coordinatorDelegate = self
        
        let navController = UINavigationController(rootViewController: loginVC)
        
        navController.modalPresentationStyle = .fullScreen
        tabBar.present(navController, animated: true)
    }
    
    func resetTabBarItemNavigationController() {
        let navControllerForTabBar = UINavigationController(rootViewController: ChatsViewController())
        navControllerForTabBar.tabBarItem = UITabBarItem(title: "Chats", image: nil, tag: 1)
        tabBar.viewControllers?[0] = navControllerForTabBar
        
    }
}
