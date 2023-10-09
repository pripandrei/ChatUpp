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
    
//    func start()
    func presentLogInForm()
    func handleSignOut()
    func initiateTabBarSetup()
}

class MainCoordinator: Coordinator {
    
    var tabBar: TabBarViewController

    init(tabBar: TabBarViewController) {
        self.tabBar = tabBar
    }
    
    func checkStatus() {
        do {
            try AuthenticationManager.shared.getAuthenticatedUser()
            initiateTabBarSetup()
        } catch {
            presentLogInForm()
        }
    }
    
    func initiateTabBarSetup() {
        tabBar.setupTabBarController()
        start()
    }
    
    private func start() {
        guard let navController = tabBar.customNavigationController,
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
    
    func handleSignOut() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            self.tabBar.selectedIndex = 0
        }
        resetWindowRoot()
//        start()
    }
    
    private func resetWindowRoot() {
//        self.tabBar = TabBarViewController()
//        Utilities.windowRoot = tabBar
        tabBar.setupTabBarController()
    }
}
