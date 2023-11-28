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
    func openConversationVC(conversationViewModel: ConversationViewModel)
    func pushSignUpVC()
}

class MainCoordinator: Coordinator {
    
    var tabBar: TabBarViewController
    
    var navControllerForLoginVC: UINavigationController!

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
    
    func pushSignUpVC() {
        let signUpVC = EmailSignUpViewController()
//        signUpVC.coordinatorDelegate = self
        navControllerForLoginVC.pushViewController(signUpVC, animated: true)
    }
    
   
    func presentLogInForm() {
        let loginVC = LoginViewController()
        loginVC.coordinatorDelegate = self
        
        navControllerForLoginVC = UINavigationController(rootViewController: loginVC)
        
        navControllerForLoginVC.modalPresentationStyle = .fullScreen
        tabBar.present(navControllerForLoginVC, animated: true)
    }
    
    func handleSignOut() {
        resetWindowRoot()
        start()
    }
    
    private func resetWindowRoot() {
        self.tabBar = TabBarViewController()
        Utilities.windowRoot = tabBar
    }
    
    func openConversationVC(conversationViewModel: ConversationViewModel) {
        let conversationVC = ConversationViewController(conversationViewModel: conversationViewModel)
        conversationVC.hidesBottomBarWhenPushed = true
        conversationVC.coordinatorDelegate = self
        tabBar.customNavigationController?.pushViewController(conversationVC, animated: true)
    }
}
