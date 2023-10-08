//
//  Coordinator.swift
//  ChatUpp
//
//  Created by Andrei Pripa on 10/8/23.
//

import Foundation
import UIKit

protocol Coordinator: AnyObject {
    var tabBar: UITabBarController { get set }
    func start()
    func presentLogInForm()
}

class MainCoordinator: Coordinator {
    
    var tabBar: UITabBarController
//    var navigationController: UINavigationController
    
//    init(navigationController: UINavigationController) {
//        self.navigationController = navigationController
//    }
    
    init(tabBar: UITabBarController) {
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
        
//        let chatsVC = ChatsViewController()
//        chatsVC.coordinatorDelegate = self
//        navigationController.pushViewController(chatsVC, animated: true)
    }
    
    func presentLogInForm() {
        let loginVC = LoginViewController()
        loginVC.coordinatorDelegate = self
        
        let navController = UINavigationController(rootViewController: loginVC)
        
        navController.modalPresentationStyle = .fullScreen
        tabBar.present(navController, animated: true)
    }
    
}
