//
//  Coordinator.swift
//  ChatUpp
//
//  Created by Andrei Pripa on 10/8/23.
//

import Foundation
import UIKit
import SwiftUI
import Combine

protocol Coordinator: AnyObject {
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
    func showChatRoomInformationScreen(viewModel: ChatRoomInformationViewModel)
//    func subscribeToConversationOpenRequest()
}

class MainCoordinator: Coordinator, SwiftUI.ObservableObject {
    
    //    private weak var tabBar: TabBarViewController!  // Make weak
    //    private var subscribers = Set<AnyCancellable>()
    private var tabBar: TabBarViewController
    private var loginNavigationController: UINavigationController!
    
    
    init(tabBar: TabBarViewController) {
        self.tabBar = tabBar
//        tabBar.coordinator = self  // Set weak reference back
    }
    
    
//    deinit {
//        subscribers.forEach { $0.cancel() }
//        subscribers.removeAll()
//    }
    //    func subscribeToConversationOpenRequest()
    //    {
    //        MessageBannerPresenter.shared.requestChatOpenSubject
    //            .receive(on: DispatchQueue.main)
    //            .sink { [weak self] chat in
    //                let chatVM = ChatRoomViewModel(conversation: chat)
    //                self?.openConversationVC(conversationViewModel: chatVM)
    //            }.store(in: &subscribers)
    //    }
    //
    
    private func setupTabBarItems()
    {
        tabBar.setupTabBarController()
        tabBar.chatsViewController?.coordinatorDelegate = self
        tabBar.settingsViewController?.coordinatorDelegate = self
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
        loginNavigationController.pushViewController(signUpVC, animated: true)
    }
    
    func pushPhoneSingInVC() {
        let phoneSignInVC = PhoneSignInViewController()
        phoneSignInVC.coordinator = self
        loginNavigationController.pushViewController(phoneSignInVC, animated: true)
    }
    
    func presentLogInForm()
    {
        let loginVC = LoginViewController()
        loginVC.coordinatorDelegate = self
        
        loginNavigationController = UINavigationController(rootViewController: loginVC)
        
        loginNavigationController.modalTransitionStyle = .coverVertical
        loginNavigationController.modalPresentationStyle = .fullScreen
        tabBar.present(loginNavigationController, animated: true)
    }
    
    func pushUsernameRegistration() {
        let usernameRegistrationVC = UsernameRegistrationViewController()
        usernameRegistrationVC.coordinator = self
        loginNavigationController.pushViewController(usernameRegistrationVC, animated: true)
    }
    
    func handleSignOut()
    {
//        self.resetWindowRoot()
        Task { @MainActor in
            try? await Task.sleep(nanoseconds: 500_000_000)
            tabBar.destroyItems()
        }
        presentLogInForm()
    }
    
    private func resetWindowRoot()
    {
        self.tabBar = TabBarViewController()
        Utilities.windowRoot = tabBar
    }

    func openConversationVC(conversationViewModel: ChatRoomViewModel)
    {
        let conversationVC = ChatRoomViewController(conversationViewModel: conversationViewModel)
        conversationVC.hidesBottomBarWhenPushed = true
        conversationVC.coordinatorDelegate = self
        
        if let nav = tabBar.selectedViewController as? UINavigationController
        {
            nav.pushViewController(conversationVC, animated: true)
            nav.setNavigationBarHidden(false, animated: false)
        } else {
            tabBar.chatsNavigationController?.pushViewController(conversationVC, animated: true)
        }
    }
    
    func pushPhoneCodeVerificationViewController(phoneViewModel: PhoneSignInViewModel) {
        let phoneCodeVerificationVC = PhoneCodeVerificationViewController(viewModel: phoneViewModel)
        phoneCodeVerificationVC.coordinator = self
        loginNavigationController.pushViewController(phoneCodeVerificationVC, animated: true)
    }
    
    
    func dismissNaviagtionController()
    {
        setupTabBarItems()
        loginNavigationController.dismiss(animated: true)
        loginNavigationController = nil
//        tabBar.selectedIndex = 0
    }
    
    func pushMailSignInController(viewModel: LoginViewModel) {
        let mailVC = MailSignInViewController(viewModel: viewModel)
        loginNavigationController.pushViewController(mailVC, animated: true)
    }
    
    func pushProfileEditingVC(viewModel: ProfileEditingViewModel)
    {
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
    
    func showChatRoomInformationScreen(viewModel: ChatRoomInformationViewModel)
    {
        let chatRoomInfoScreen = ChatRoomInformationScreen(viewModel: viewModel)
        let hostingController = UIHostingController(rootView: chatRoomInfoScreen)
        
        Utilities.configureTransparentNavigationBarAppearance(for: hostingController)

        tabBar.chatsNavigationController?.pushViewController(hostingController, animated: true)
    }
}
