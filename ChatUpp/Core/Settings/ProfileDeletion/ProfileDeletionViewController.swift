//
//  ProfileDeletionViewController.swift
//  ChatUpp
//
//  Created by Andrei Pripa on 1/20/24.
//

import UIKit

final class ProfileDeletionViewController: UIViewController {
    
    weak var coordinatorDelegate: Coordinator?
    var profileDeletionViewModel: ProfileDeletionViewModel!

    init(viewModel: ProfileDeletionViewModel) {
        super.init(nibName: nil, bundle: nil)
        self.profileDeletionViewModel = viewModel
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupBinder()
    }
    
    func setupUI() {
        view.backgroundColor = .clouds
        view.addSubview(sendCodeButton)
        view.addSubview(verificationCodeTextField)
        view.addSubview(informationLabel)
        view.addSubview(deleteAccountButton)
        setupInformationLabelConstraints()
        setupSendCodeButtonConstraints()
        setupTextViewConstraints()
        setupDeleteAccountButtonConstraints()
    }
    
    func setupBinder() {
        profileDeletionViewModel.userIsSignedOut.bind { [weak self] isSignedOut in
            if isSignedOut == true {
                Task { @MainActor in
                    self?.coordinatorDelegate?.handleSignOut()
                }
            }
        }
    }
    
    lazy var verificationCodeTextField: UITextField = {
        let textField = UITextField()
        textField.placeholder = "Enter code here"
        textField.backgroundColor = .systemFill
        textField.borderStyle = .roundedRect
        textField.font = UIFont(name: "HelveticaNeue", size: 17)
        textField.textColor = .black
        return textField
    }()
    
    lazy var informationLabel: UILabel = {
        let infoLabel = UILabel()
        infoLabel.text = "In order to delete your account, we need to make sure it's you. Verification code will be sent to your phone number."
        infoLabel.textColor = .systemGray
        infoLabel.font =  UIFont(name: "HelveticaNeue", size: 14.5)
        infoLabel.numberOfLines = 0
        return infoLabel
    }()
    
    lazy var sendCodeButton: UIButton = {
        let button = UIButton()
        button.configuration = .filled()
        button.configuration?.title = "Get Code"
        button.configuration?.background.backgroundColor = .link
        button.layer.cornerRadius = 5
        button.clipsToBounds = true
        button.addTarget(self, action: #selector(sendCodeButtonTapped), for: .touchUpInside)
        return button
    }()
    
    lazy var deleteAccountButton: UIButton = {
        let button = UIButton()
        button.configuration = .filled()
        button.configuration?.title = "Delete Account"
        button.configuration?.background.backgroundColor = .systemRed
        button.layer.cornerRadius = 5
        button.clipsToBounds = true
        button.addTarget(self, action: #selector(deleteAccount), for: .touchUpInside)
        return button
    }()
    
    @objc func deleteAccount() {
        guard let code = verificationCodeTextField.text, !code.isEmpty else {return}
        
        Task {
            try await profileDeletionViewModel.reauthenticateUser(usingCode: code)
            createAlertController()
        }
    }
    
    func createAlertController() {
        let alert = UIAlertController(title: "Alert", message: "Delete this account? This acction can not be undone!", preferredStyle: .alert)
        let cancel = UIAlertAction(title: "Cancel", style: .cancel)
        let delete = UIAlertAction(title: "Delete", style: .destructive) { _ in
            Task {
                await self.profileDeletionViewModel.deleteUser()
                self.profileDeletionViewModel.signOut()
            }
        }
        alert.addAction(cancel)
        alert.addAction(delete)
        
        present(alert, animated: true)
    }
    
    @objc func sendCodeButtonTapped() {
        Task {
            try await profileDeletionViewModel.sendSMSCode()
        }
    }
    
    func setupDeleteAccountButtonConstraints() {
        deleteAccountButton.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            deleteAccountButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            deleteAccountButton.topAnchor.constraint(equalTo: sendCodeButton.bottomAnchor, constant: 20),
            deleteAccountButton.heightAnchor.constraint(equalToConstant: 45),
            deleteAccountButton.widthAnchor.constraint(equalToConstant: 110),
//            deleteAccountButton.heightAnchor.constraint(equalToConstant: 40),
//            deleteAccountButton.widthAnchor.constraint(equalToConstant: 300),
        ])
    }
    
    func setupInformationLabelConstraints() {
        informationLabel.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            informationLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            informationLabel.topAnchor.constraint(equalTo: view.topAnchor, constant: view.bounds.size.height / 8),
            informationLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 50),
            informationLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -50),
//            informationLabel.heightAnchor.constraint(equalToConstant: 40),
//            informationLabel.widthAnchor.constraint(equalToConstant: 300),
        ])
    }
    
    func setupTextViewConstraints() {
        verificationCodeTextField.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            verificationCodeTextField.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            verificationCodeTextField.topAnchor.constraint(equalTo: view.topAnchor, constant: view.bounds.size.height / 4),
            verificationCodeTextField.heightAnchor.constraint(equalToConstant: 40),
            verificationCodeTextField.widthAnchor.constraint(equalToConstant: 300),
        ])
    }
    
    func setupSendCodeButtonConstraints() {
        sendCodeButton.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            sendCodeButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            sendCodeButton.topAnchor.constraint(equalTo: view.topAnchor, constant: view.bounds.size.height / 3),
            sendCodeButton.heightAnchor.constraint(equalToConstant: 45),
            sendCodeButton.widthAnchor.constraint(equalToConstant: 110),
        ])
    }
}

extension ProfileDeletionViewController: UITextFieldDelegate {
    
    
}
