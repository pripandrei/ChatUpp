//
//  UsernameRegistrationViewController.swift
//  ChatUpp
//
//  Created by Andrei Pripa on 9/17/23.
//

import UIKit

class UsernameRegistrationViewController: UIViewController, UITextFieldDelegate {
    
    private let usernameRegistrationViewModel = UsernameRegistrationViewModel()
    
    private let usernameTextField: UITextField = UITextField()
    
    private let continueButton: UIButton = UIButton()
    
    // MARK: VC LIFE CYCLE

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
        configureUsernameTextField()
        configureContinueButton()
        configureBinding()
    }
    
    // MARK: - BINDING
    
    private func configureBinding() {
        usernameRegistrationViewModel.finishRegistration.bind { finishRegistration in
            if let finish = finishRegistration, finish == true {
                self.navigationController?.dismiss(animated: true)
            }
        }
    }
    
    // MARK: - UI SETUP
    
    private func configureContinueButton() {
        view.addSubview(continueButton)
        
        continueButton.configuration = .filled()
        continueButton.configuration?.title = "Continue"
        continueButton.configuration?.baseBackgroundColor = .systemPink
        continueButton.addTarget(self, action: #selector(manageContinueButtonTap), for: .touchUpInside)
        
        setContinueButtonConstraints()
    }
    
    @objc private func manageContinueButtonTap() {
        
        if usernameRegistrationViewModel.validateName() == .valid {
            usernameRegistrationViewModel.updateUser()
        }
    }
    

    
    private func setContinueButtonConstraints() {
        continueButton.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            continueButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            continueButton.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -110),
            continueButton.widthAnchor.constraint(equalToConstant: 200),
            continueButton.heightAnchor.constraint(equalToConstant: 50)
        ])
    }
    
    private func configureUsernameTextField() {
        view.addSubview(usernameTextField)
        usernameTextField.delegate = self
        
        usernameTextField.placeholder = "Enter Your name"
        usernameTextField.borderStyle = .roundedRect
        
        setUsernameTextFieldConstraints()
    }
    
    private func setUsernameTextFieldConstraints() {
        usernameTextField.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            usernameTextField.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            usernameTextField.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            usernameTextField.widthAnchor.constraint(equalToConstant: 300),
            usernameTextField.heightAnchor.constraint(equalToConstant: 50)
        ])
    }
}

//MARK: - TextFieldDelegate

extension UsernameRegistrationViewController {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        usernameTextField.resignFirstResponder()
    }
    func textFieldDidChangeSelection(_ textField: UITextField) {
        if let text = textField.text {
            usernameRegistrationViewModel.username = text
        }
    }
}
