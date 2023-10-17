//
//  SettingsViewController.swift
//  ChatUpp
//
//  Created by Andrei Pripa on 8/29/23.
//

import UIKit
import FirebaseAuth

class SettingsViewController: UIViewController {
    
    weak var coordinatorDelegate: Coordinator?
    
    let settingsViewModel = SettingsViewModel()
    let signOutBtn = UIButton()
    let tempLabelName: UILabel = UILabel()
    
    let tempCreateChatDocId: UIButton = UIButton()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupBinder()
        setUpSignOutBtn()
        configureTempLabelName()
        binding()
        configureTempCreateChatDocId()
        view.backgroundColor = .white
        
    }
    
    deinit {
        print("Settings ============ deinit")
    }
    
    private func configureTempCreateChatDocId() {
        view.addSubview(tempCreateChatDocId)
        
        tempCreateChatDocId.configuration = .filled()
        tempCreateChatDocId.configuration?.title = "CreateChatDocID"
        tempCreateChatDocId.addTarget(self, action: #selector(tempCreateChatDocIdTapped), for: .touchUpInside)
        tempCreateChatDocId.configuration?.buttonSize = .large
        
        configureTempCreateChatDocIdConstraints()
    }
    
    @objc func tempCreateChatDocIdTapped()  {
//        Task {
//            await settingsViewModel.createDocID()
//        }
    }
    
    private func configureTempCreateChatDocIdConstraints() {
        tempCreateChatDocId.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            tempCreateChatDocId.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            tempCreateChatDocId.centerYAnchor.constraint(equalTo: view.centerYAnchor, constant: -250),
            tempCreateChatDocId.heightAnchor.constraint(equalToConstant: 30),
            tempCreateChatDocId.widthAnchor.constraint(equalToConstant: 280)
        ])
    }

    private func configureTempLabelName() {
        view.addSubview(tempLabelName)
        
        configureTempLabelNameConstraints()
    }
    
    private func configureTempLabelNameConstraints() {
        tempLabelName.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            tempLabelName.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            tempLabelName.centerYAnchor.constraint(equalTo: view.centerYAnchor, constant: -150),
            tempLabelName.heightAnchor.constraint(equalToConstant: 30),
            tempLabelName.widthAnchor.constraint(equalToConstant: 320)
        ])
    }
    
    func binding() {
        settingsViewModel.setProfileName = { [weak self] name in
            self?.tempLabelName.text = name
        }
    }
    
// MARK: - Binder
    
    func setupBinder() {
        settingsViewModel.userIsSignedOut.bind { [weak self] isSignedOut in
            if isSignedOut == true {
                self?.coordinatorDelegate?.handleSignOut()
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
}
