//
//  PhoneCodeVerificationViewController.swift
//  ChatUpp
//
//  Created by Andrei Pripa on 11/29/23.
//

import UIKit

final class PhoneCodeVerificationViewController: UIViewController , UITextFieldDelegate {
    
    weak var coordinator: Coordinator!
    
    private var phoneViewModel: PhoneSignInViewModel!
    
    private let smsTextField = UITextField()
    private let verifyMessageButton = CustomizedShadowButton()
    
    convenience init(viewModel: PhoneSignInViewModel) {
        self.init()
        self.phoneViewModel = viewModel
    }

    override func viewDidLoad() {
        view.backgroundColor = .white
        setupSmsTextField()
        setupVerifySMSButton()
        setupBinder()
    }
    
    //MARK: - Binding

    private func setupBinder() {
        phoneViewModel.userCreationStatus.bind { [weak self] creationStatus in
            guard let status = creationStatus else {return}
            Task { @MainActor in
                if status == .userExists {
                    self?.coordinator.dismissNaviagtionController()
                } else {
                    self?.coordinator.pushUsernameRegistration()
                }
            }
        }
    }
    
    func setupSmsTextField() {
        view.addSubview(smsTextField)
        
        smsTextField.delegate = self
        smsTextField.placeholder = "enter code"
        smsTextField.borderStyle = .roundedRect
        
        smsTextField.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            smsTextField.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            smsTextField.topAnchor.constraint(equalTo: view.topAnchor, constant: 250),
//            smsTextField.widthAnchor.constraint(equalToConstant: 200),
//            smsTextField.heightAnchor.constraint(equalToConstant: 30)
            
            smsTextField.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 43),
            smsTextField.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -43),
            smsTextField.heightAnchor.constraint(equalToConstant: 40)
            
        ])
    }
    
    func setupVerifySMSButton() {
        view.addSubview(verifyMessageButton)
       
        verifyMessageButton.configuration?.title = "Verify code"
        verifyMessageButton.addTarget(self, action: #selector(verifySMSButtonWasTapped), for: .touchUpInside)
        
        verifyMessageButton.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            verifyMessageButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            verifyMessageButton.topAnchor.constraint(equalTo: smsTextField.bottomAnchor, constant: 30),
//            verifyMessageButton.widthAnchor.constraint(equalToConstant: 200),
//            verifyMessageButton.heightAnchor.constraint(equalToConstant: 40)
            
            verifyMessageButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 73),
            verifyMessageButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -73),
            verifyMessageButton.heightAnchor.constraint(equalToConstant: 40)
        ])
    }
    
    @objc func verifySMSButtonWasTapped() {
        guard let code = smsTextField.text, !code.isEmpty else {return}
        phoneViewModel.signInViaPhone(usingVerificationCode: code)
    }
}

