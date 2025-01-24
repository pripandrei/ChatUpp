//
//  Coordinator.swift
//  ChatUpp
//
//  Created by Andrei Pripa on 10/8/23.
//

import Foundation
import UIKit
import SwiftUI

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
    func openConversationVC(conversationViewModel: ChatRoomViewModel)
    func pushPhoneCodeVerificationViewController(phoneViewModel: PhoneSignInViewModel)
    func showProfileDeletionVC(viewModel: ProfileDeletionViewModel)
    
    func pushProfileEditingVC(viewModel:ProfileEditingViewModel)
    func dismissEditProfileVC()
    func showGroupCreationScreen()
}

class MainCoordinator: Coordinator, SwiftUI.ObservableObject {
    
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
        
        navControllerForLoginVC.modalTransitionStyle = .coverVertical
        navControllerForLoginVC.modalPresentationStyle = .fullScreen
        tabBar.present(navControllerForLoginVC, animated: true)
        
    }
    
    func pushUsernameRegistration() {
        let usernameRegistrationVC = UsernameRegistrationViewController()
        usernameRegistrationVC.coordinator = self
        navControllerForLoginVC.pushViewController(usernameRegistrationVC, animated: true)
    }
    
    func handleSignOut() {
//        self.resetWindowRoot()
        Task {
            try await Task.sleep(nanoseconds: 1_500_000_000)
            await tabBar.destroyItems()
        }
        presentLogInForm()
    }
    
    private func resetWindowRoot()
    {
        self.tabBar = TabBarViewController()
        Utilities.windowRoot = tabBar
    }
    
    func openConversationVC(conversationViewModel: ChatRoomViewModel) {
        let conversationVC = ChatRoomViewController(conversationViewModel: conversationViewModel)
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
    
    func pushProfileEditingVC(viewModel: ProfileEditingViewModel) {
        let profileEditingVC = ProfileEditingViewController(viewModel: viewModel)
        profileEditingVC.coordinatorDelegate = self
        let navController = UINavigationController(rootViewController: profileEditingVC)
        navController.modalPresentationStyle = .fullScreen
        navController.modalTransitionStyle = .crossDissolve
        tabBar.settingsNavigationController?.present(navController, animated: true)
    }
    
    func dismissEditProfileVC() {
        tabBar.settingsNavigationController?.dismiss(animated: true)
    }
    
    func showProfileDeletionVC(viewModel: ProfileDeletionViewModel) {
        let profileDeletionVC = ProfileDeletionViewController(viewModel: viewModel)
        
        profileDeletionVC.coordinatorDelegate = self
        profileDeletionVC.modalPresentationStyle = .pageSheet
        profileDeletionVC.modalTransitionStyle = .coverVertical
        tabBar.settingsNavigationController?.present(profileDeletionVC, animated: true)
    }
    
    func showGroupCreationScreen()
    {
        let groupCreationScreen = GroupCreationScreen().environmentObject(self)
        let hostingController = UIHostingController(rootView: groupCreationScreen)
        hostingController.modalPresentationStyle = .pageSheet
        hostingController.modalTransitionStyle = .coverVertical
        tabBar.present(hostingController, animated: true)
    }
}
