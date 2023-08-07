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
        view.backgroundColor = .blue
//        conversationsViewModel.signOut()
        conversationsViewModel.showSignInForm.bind { [weak self] value in
            if value == true {
                self?.presentLogInForm()
            }
        }
//        conversationsViewModel.logInFormHandler = { [weak self] in
//            self?.presentLogInForm()
//        }
        conversationsViewModel.validateUserAuthentication()
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
    
    var showSignInForm: ObservableObject<Bool> = ObservableObject(value: false)
    
    var logInFormHandler: (() -> Void)?
    
    func validateUserAuthentication() {
        
        let authUser = try? AuthenticationManager.shared.getAuthenticatedUser()
        
        guard let user = authUser else {
//            logInFormHandler?()
            showSignInForm.value = true
            return
        }
        print("User:", user)
    }
    
    func signOut() {
        do {
            try Auth.auth().signOut()
        } catch {
            print("Error signing out")
        }
    }
}
