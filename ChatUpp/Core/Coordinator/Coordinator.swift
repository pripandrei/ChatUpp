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
        guard let settingsViewController = tabBar.viewControllers?.first(where: { $0 is SettingsViewController }) as? SettingsViewController else {
            return
        }
        chatsViewController.coordinatorDelegate = self
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
//        let navControllerForTabBar = UINavigationController(rootViewController: ChatsViewController())
//        navControllerForTabBar.tabBarItem = UITabBarItem(title: "Chats", image: nil, tag: 1)
//        tabBar.viewControllers?[0] = navControllerForTabBar
        
//        chatsViewController?.removeFromParent()
//        chatsViewController = ChatsViewController()
//        (UIApplication.shared.connectedScenes.first as? UIWindowScene)?.windows.first?.rootViewController?.removeFromParent()
        self.tabBar = TabBarViewController()
        start()
//        (UIApplication.shared.connectedScenes.first as? UIWindowScene)?.windows.first?.rootViewController = tabBar
        Utilities.windowRoot = tabBar
    }
}




//
//var navigationControllerFromFirstTabBarItem: UINavigationController? {
//    guard let navController = tabBar?.viewControllers?.first as? UINavigationController else {
//        return nil
//    }
//    return navController
//}
//
//var chatsViewController: ChatsViewController? {
//    guard let chatsViewController = navigationControllerFromFirstTabBarItem?.viewControllers.first as? ChatsViewController else {
//        return nil
//    }
//    return chatsViewController
//}
//
//var settingsViewController: SettingsViewController? {
//    guard let settingsViewController = tabBar?.viewControllers?.first(where: { $0 is SettingsViewController }) as? SettingsViewController else {
//        return nil
//    }
//    return settingsViewController
//}
