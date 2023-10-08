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
//    var navigationController: UINavigationController {get set}
    
    func start()
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
        
        guard let chatsViewController = tabBar.navigationController?.viewControllers.first as? ChatsViewController else {
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
    
}
