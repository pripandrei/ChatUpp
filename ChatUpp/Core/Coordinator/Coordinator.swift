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
    func handleSignOut()
    func openConversationVC(conversationID: String)
}

class MainCoordinator: Coordinator {
    
    var tabBar: TabBarViewController

    init(tabBar: TabBarViewController) {
        self.tabBar = tabBar
    }
    
    func start() {
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
        resetWindowRoot()
        start()
    }
    
    private func resetWindowRoot() {
        self.tabBar = TabBarViewController()
        Utilities.windowRoot = tabBar
    }
    
    func openConversationVC(conversationID: String) {
        let conversationVC = ConversationViewController(conversationID: conversationID)
        conversationVC.hidesBottomBarWhenPushed = true
        conversationVC.coordinatorDelegate = self
        tabBar.customNavigationController?.pushViewController(conversationVC, animated: true)
    }
}
