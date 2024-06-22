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
    
    private let smsTextField = CustomizedShadowTextField()
    private let verifyMessageButton = CustomizedShadowButton()
    private let messageCodeImage = UIImageView()
    
    convenience init(viewModel: PhoneSignInViewModel) {
        self.init()
        self.phoneViewModel = viewModel
    }

    override func viewDidLoad() {
        view.backgroundColor = #colorLiteral(red: 0.8039215803, green: 0.8039215803, blue: 0.8039215803, alpha: 1)
        setupSmsTextField()
        setupVerifySMSButton()
        setupBinder()
        setupPhoneImage()
        Utilities.setGradientBackground(forView: view)
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
    
    private func setupPhoneImage() {
        view.addSubview(messageCodeImage)
        
        let image = UIImage(named: "message_code_2")
        messageCodeImage.image = image
        
        messageCodeImage.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            messageCodeImage.topAnchor.constraint(equalTo: view.topAnchor, constant: 50),
            messageCodeImage.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 70),
            messageCodeImage.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -70),
            messageCodeImage.heightAnchor.constraint(equalToConstant: 230),
        ])
    }
    
    func setupSmsTextField() {
        view.addSubview(smsTextField)
        
        smsTextField.delegate = self
        smsTextField.placeholder = "enter code"
//        smsTextField.borderStyle = .roundedRect
        
        smsTextField.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            smsTextField.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            smsTextField.topAnchor.constraint(equalTo: view.topAnchor, constant: 250),
//            smsTextField.widthAnchor.constraint(equalToConstant: 200),
//            smsTextField.heightAnchor.constraint(equalToConstant: 30)
            
//            smsTextField.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 43),
//            smsTextField.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -43),
            
            smsTextField.widthAnchor.constraint(equalToConstant: view.bounds.width * 0.7),
            smsTextField.heightAnchor.constraint(equalToConstant: 45)
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

