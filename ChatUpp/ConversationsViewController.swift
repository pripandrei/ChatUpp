//
//  ConversationsViewController.swift
//  ChatUpp
//
//  Created by Andrei Pripa on 8/6/23.
//

import UIKit
import FirebaseAuth

protocol ConversationViewModelDelegate: AnyObject {
    func presentLogInForm()
}

class ConversationsViewController: UIViewController {
    
    var conversationsViewModel = ConversationsViewModel()

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .blue
//        conversationsViewModel.signOut()
        conversationsViewModel.delegate = self
        conversationsViewModel.validateUserAuthentication()
    }
}

extension ConversationsViewController:ConversationViewModelDelegate
{
    func presentLogInForm() {
        let nav = UINavigationController(rootViewController: LoginViewController())
        nav.modalPresentationStyle = .fullScreen
        present(nav, animated: true)
    }
}

final class ConversationsViewModel {
    
    weak var delegate: ConversationViewModelDelegate?
    
    func validateUserAuthentication() {
        
        let authUser = try? AuthenticationManager.shared.getAuthenticatedUser()
        
        guard let user = authUser else {
            delegate?.presentLogInForm()
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
