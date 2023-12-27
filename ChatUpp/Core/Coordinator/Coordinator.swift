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
    func pushSignUpVC()
    func pushPhoneSingInVC()
    func pushUsernameRegistration()
    func dismissNaviagtionController()
    func pushMailSignInController(viewModel: LoginViewModel)
    func openConversationVC(conversationViewModel: ConversationViewModel)
    func pushPhoneCodeVerificationViewController(phoneViewModel: PhoneSignInViewModel)
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
        signUpVC.coordinator = self
        navControllerForLoginVC.pushViewController(signUpVC, animated: true)
    }
    
    func pushPhoneSingInVC() {
        let phoneSignInVC = PhoneSignInViewController()
        phoneSignInVC.coordinator = self
        navControllerForLoginVC.pushViewController(phoneSignInVC, animated: true)
    }
    
    func presentLogInForm() {
        let loginVC = LoginViewController()
        loginVC.coordinatorDelegate = self
        
        navControllerForLoginVC = UINavigationController(rootViewController: loginVC)
        
        navControllerForLoginVC.modalPresentationStyle = .fullScreen
        tabBar.present(navControllerForLoginVC, animated: true)
    }
    
    func pushUsernameRegistration() {
        let usernameRegistrationVC = UsernameRegistrationViewController()
        usernameRegistrationVC.coordinator = self
        navControllerForLoginVC.pushViewController(usernameRegistrationVC, animated: true)
    }
    
    func handleSignOut() {
        resetWindowRoot()
        start()
        presentLogInForm()
//        tabBar.selectedIndex = 0
    }
    
    private func resetWindowRoot() {
        self.tabBar = TabBarViewController()
        self.tabBar.selectedIndex = 1
        Utilities.windowRoot = tabBar
    }
    
    func openConversationVC(conversationViewModel: ConversationViewModel) {
        let conversationVC = ConversationViewController(conversationViewModel: conversationViewModel)
        conversationVC.hidesBottomBarWhenPushed = true
        conversationVC.coordinatorDelegate = self
        tabBar.customNavigationController?.pushViewController(conversationVC, animated: true)
    }
    
    func pushPhoneCodeVerificationViewController(phoneViewModel: PhoneSignInViewModel) {
        let phoneCodeVerificationVC = PhoneCodeVerificationViewController(viewModel: phoneViewModel)
        phoneCodeVerificationVC.coordinator = self
        navControllerForLoginVC.pushViewController(phoneCodeVerificationVC, animated: true)
    }
    
    
    func dismissNaviagtionController() {
        navControllerForLoginVC.dismiss(animated: true)
        tabBar.selectedIndex = 0
    }
    
    func pushMailSignInController(viewModel: LoginViewModel) {
        let mailVC = MailSignInViewController(viewModel: viewModel)
        navControllerForLoginVC.pushViewController(mailVC, animated: true)
    }
}
