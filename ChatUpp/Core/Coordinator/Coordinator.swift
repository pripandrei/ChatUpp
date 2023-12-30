//
//  Coordinator.swift
//  ChatUpp
//
//  Created by Andrei Pripa on 10/8/23.
//

import Foundation
import UIKit

protocol Coordinator: AnyObject {
//    var tabBar: TabBarViewController { get set }
    
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
    
    func pushProfileEditingVC()
}

class MainCoordinator: Coordinator {
    
    private var tabBar: TabBarViewController
    private var navControllerForLoginVC: UINavigationController!

    init(tabBar: TabBarViewController) {
        self.tabBar = tabBar
    }
    
    private func setupTabBarItems() {
        tabBar.setupTabBarController()
        tabBar.chatsVC?.coordinatorDelegate = self
        tabBar.settingsVC?.coordinatorDelegate = self
    }
    
    func start() {
        do {
            try AuthenticationManager.shared.getAuthenticatedUser()
            setupTabBarItems()
        } catch {
            presentLogInForm()
        }
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
        
        navControllerForLoginVC.modalTransitionStyle = .crossDissolve
        navControllerForLoginVC.modalPresentationStyle = .fullScreen
        tabBar.present(navControllerForLoginVC, animated: true)
        
    }
    
    func pushUsernameRegistration() {
        let usernameRegistrationVC = UsernameRegistrationViewController()
        usernameRegistrationVC.coordinator = self
        navControllerForLoginVC.pushViewController(usernameRegistrationVC, animated: true)
    }
    
    func handleSignOut() {
//        resetWindowRoot()
//        tabBar.cleanupTabBarItems()

        self.resetWindowRoot()
        presentLogInForm()
        print("se")
    }
    
    private func resetWindowRoot() {
        self.tabBar = TabBarViewController()
//        self.tabBar.selectedIndex = 0
        Utilities.windowRoot = tabBar
    }
    
    func openConversationVC(conversationViewModel: ConversationViewModel) {
        let conversationVC = ConversationViewController(conversationViewModel: conversationViewModel)
        conversationVC.hidesBottomBarWhenPushed = true
        conversationVC.coordinatorDelegate = self
        tabBar.chatsNavigationController?.pushViewController(conversationVC, animated: true)
    }
    
    func pushPhoneCodeVerificationViewController(phoneViewModel: PhoneSignInViewModel) {
        let phoneCodeVerificationVC = PhoneCodeVerificationViewController(viewModel: phoneViewModel)
        phoneCodeVerificationVC.coordinator = self
        navControllerForLoginVC.pushViewController(phoneCodeVerificationVC, animated: true)
    }
    
    
    func dismissNaviagtionController() {
        setupTabBarItems()
        navControllerForLoginVC.dismiss(animated: true)
        navControllerForLoginVC = nil
//        tabBar.selectedIndex = 0
    }
    
    func pushMailSignInController(viewModel: LoginViewModel) {
        let mailVC = MailSignInViewController(viewModel: viewModel)
        navControllerForLoginVC.pushViewController(mailVC, animated: true)
    }
    
    func pushProfileEditingVC() {
        let profileEditingVC = ProfileEditingViewController()
        profileEditingVC.coordinatorDelegate = self
        
        tabBar.settingsNavigationController?.modalTransitionStyle = .crossDissolve
        tabBar.settingsNavigationController?.modalPresentationStyle = .fullScreen
        tabBar.settingsNavigationController?.pushViewController(profileEditingVC, animated: false)
    }
}








//Timer.scheduledTimer(withTimeInterval: 0.5, repeats: false) { [weak self] _ in
//
//    self?.tabBar.customNavigationController?.viewControllers[0] = ChatsViewController()
//    self?.tabBar.viewControllers?[1].removeFromParent()
//    self?.tabBar.viewControllers?.append(SettingsViewController())
//    self?.tabBar.viewControllers?[1] = SettingsViewController()
//    self?.start()
//}
