//
//  SettingsViewController.swift
//  ChatUpp
//
//  Created by Andrei Pripa on 8/29/23.
//

import UIKit
import FirebaseAuth

class SettingsViewController: UIViewController {
    
    let settingsViewModel = SettingsViewModel()

    override func viewDidLoad() {
        super.viewDidLoad()
        setUpSignOutBtn()
        settingsViewModel.showSignInForm.bind { [weak self] showForm in
            if showForm {
                self?.presentLogInForm()
                self?.tabBarController?.selectedIndex = 0
            }
            
        }
        view.backgroundColor = .darkGray
    }
    
    let signOutBtn = UIButton()
    
    func setUpSignOutBtn() {
        view.addSubview(signOutBtn)
        
        signOutBtn.configuration = .filled()
        signOutBtn.configuration?.title = "Sign Out"
        signOutBtn.addTarget(self, action: #selector(settingsViewModel.signOut), for: .touchUpInside)
        signOutBtn.configuration?.buttonSize = .large
        
        setSignOutBtnConstraints()
    }
    
    private func setSignOutBtnConstraints() {
        signOutBtn.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
//            signOutBtn.centerXAnchor.constraint(equalTo: view.centerXAnchor, constant: 10)
            signOutBtn.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            signOutBtn.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])
    }
    
    func presentLogInForm() {
        // uncomment to show login instead of settings view
//        let nav = UINavigationController(rootViewController: LoginViewController())
        let nav = UINavigationController(rootViewController: LoginViewController())
        nav.modalPresentationStyle = .fullScreen
        present(nav, animated: true)
    }
}


final class SettingsViewModel {
    
    var showSignInForm: ObservableObject<Bool> = ObservableObject(false)
    
    @objc func signOut() {
        do {
            try Auth.auth().signOut()
            showSignInForm.value = true
            
        } catch {
            print("Error signing out")
        }
    }
}
