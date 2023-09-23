//
//  UsernameRegistrationViewController.swift
//  ChatUpp
//
//  Created by Andrei Pripa on 9/17/23.
//

import UIKit

//MARK: - Username Registration View Model

final class UsernameRegistrationViewModel {
    
    var username: String = ""
    
//    var userPhoto: UIImage?
    
    func validateName() -> ValidationStatus {
        if !self.username.isEmpty {
            return .valid
        }
        return .invalid
    }
    
    let finishRegistration: ObservableObject<Bool?> = ObservableObject(nil)
    
    func updateUser() {
        let userID = try! AuthenticationManager.shared.getAuthenticatedUser().uid
        
        UserManager.shared.updateUser(with: userID, usingName: username) { [weak self] status in
            if status == .success {
                self?.finishRegistration.value = true
            }
        }
    }
}

class UsernameRegistrationViewController: UIViewController, UITextFieldDelegate {
    
    private let usernameRegistrationViewModel = UsernameRegistrationViewModel()
    
    private let usernameTextField: UITextField = UITextField()
    
    private let continueButton: UIButton = UIButton()

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
        configureUsernameTextField()
        configureContinueButton()
        configureBinding()
    }
    
    private func configureBinding() {
        usernameRegistrationViewModel.finishRegistration.bind { finishRegistration in
            if let finish = finishRegistration, finish == true {
                self.navigationController?.dismiss(animated: true)
            }
        }
    }
    
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
//        if usernameRegistrationViewModel.validateUsernameTextField(usernameTextField) == .valid {
//            usernameRegistrationViewModel.updateUser()
//        }
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
