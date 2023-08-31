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
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
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
        showSignInForm.value = false
        print("User:", user)
    }
}
