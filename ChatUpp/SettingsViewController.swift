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
    let signOutBtn = UIButton()

    override func viewDidLoad() {
        super.viewDidLoad()
        setupBinder()
        setUpSignOutBtn()
        view.backgroundColor = .white
    }
    
    deinit {
        print("Settings ============ deinit")
    }
    
// MARK: - Binder
    
    func setupBinder() {
        settingsViewModel.userIsSignedOut.bind { [weak self] isSignedOut in
            if isSignedOut == true {
                self?.presentLogInForm()
                self?.tabBarController?.selectedIndex = 0
            }
        }
    }
    
// MARK: - setup ViewController
    
    func setUpSignOutBtn() {
        view.addSubview(signOutBtn)
        
        signOutBtn.configuration = .filled()
        signOutBtn.configuration?.title = "Sign Out"
        signOutBtn.addTarget(settingsViewModel, action: #selector(settingsViewModel.signOut), for: .touchUpInside)
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
    
// MARK: - Navigation
    
    func presentLogInForm() {
        let nav = UINavigationController(rootViewController: LoginViewController())
        nav.modalPresentationStyle = .fullScreen
        present(nav, animated: true)
    }
}

// MARK: - Settings View Model

final class SettingsViewModel {

    var userIsSignedOut: ObservableObject<Bool> = ObservableObject(false)
    
    @objc func signOut() {
        do {
            try Auth.auth().signOut()
            userIsSignedOut.value = true
        } catch {
            print("Error signing out")
        }
    }
}
