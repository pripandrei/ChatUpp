//
//  ConversationsViewController.swift
//  ChatUpp
//
//  Created by Andrei Pripa on 8/6/23.
//

import UIKit
import FirebaseAuth

class ConversationsViewController: UIViewController {
    
    var conversationsViewModel = ConversationsViewModel()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
//        conversationsViewModel.signOut()
        setupBinding()
//        conversationsViewModel.validateUserAuthentication()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        conversationsViewModel.validateUserAuthentication()
    }
    
    private func setupBinding() {
        conversationsViewModel.showSignInForm.bind { [weak self] showForm in
            if showForm == true {
                self?.presentLogInForm()
            }
        }
    }
}

extension ConversationsViewController
{
    func presentLogInForm() {
        let nav = UINavigationController(rootViewController: LoginViewController())
        nav.modalPresentationStyle = .fullScreen
        present(nav, animated: true)
    }
}

final class ConversationsViewModel {
    
    var showSignInForm: ObservableObject<Bool> = ObservableObject(false)
    
    func validateUserAuthentication() {
        
        let authUser = try? AuthenticationManager.shared.getAuthenticatedUser()
        
        guard let user = authUser else {
            showSignInForm.value = true
            return
        }
        print("User:", user)
    }
}

public class TabBarViewController: UITabBarController {
    public override func viewDidLoad() {
        super.viewDidLoad()
        
        setupTabBarController()
    }
    
    func setupTabBarController() {
        let firstVC = ConversationsViewController()
        firstVC.tabBarItem = UITabBarItem(title: "Chats", image: nil, tag: 1)
        
        let secondVC = SettingsViewController()
        secondVC.tabBarItem = UITabBarItem(title: "Settings", image: nil, tag: 2)
        
        viewControllers = [firstVC,secondVC]
    }
    
}
