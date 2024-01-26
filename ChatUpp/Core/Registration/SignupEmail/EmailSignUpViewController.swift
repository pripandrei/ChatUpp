//
//  SignUpViewController.swift
//  ChatUpp
//
//  Created by Andrei Pripa on 6/29/23.
//

import UIKit
import FirebaseAuth

class EmailSignUpViewController: UIViewController {
    
    weak var coordinator: Coordinator?
    
    private var signUpViewModel = EmailSignupViewModel()
    private let stackView = UIStackView()
    private let signUpButton = UIButton()
    private var emailSignupField = UITextField()
    private var passwordSignupField = UITextField()
    lazy private var textFieldValidator = EmailCredentialsValidator(mailField: emailSignupField,
                                                                    passwordField: passwordSignupField,
                                                                    viewModel: signUpViewModel)
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = #colorLiteral(red: 0.1411764771, green: 0.3960784376, blue: 0.5647059083, alpha: 1)
        controllerMainConfiguration()
    }
    
//MARK: - UI Configuration
    
    private func controllerMainConfiguration() {
        setEmailSignupField()
        setPasswordSignupField()
        configureStackView()
        setSignUpButton()
    }

    private func setEmailSignupField()
    {
        emailSignupField.delegate = textFieldValidator
        emailSignupField.placeholder = "Provide an email"
        emailSignupField.borderStyle = .roundedRect
        emailSignupField.translatesAutoresizingMaskIntoConstraints = false
    }
    
    private func setPasswordSignupField()
    {
        passwordSignupField.delegate = textFieldValidator
        passwordSignupField.placeholder = "Provide a password"
        passwordSignupField.borderStyle = .roundedRect
        passwordSignupField.translatesAutoresizingMaskIntoConstraints = false
    }
    
    private func configureStackView() {
        view.addSubview(stackView)
        
        stackView.axis = .vertical
        stackView.distribution = .fillEqually
        stackView.spacing = 20
        
        stackView.addArrangedSubview(emailSignupField)
        stackView.addArrangedSubview(passwordSignupField)
        
        setStackViewConstraints()
    }
    
    private func setStackViewConstraints() {
        stackView.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            stackView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            stackView.topAnchor.constraint(equalTo: view.topAnchor, constant: 230),
//            stackView.widthAnchor.constraint(equalToConstant: 300),
            stackView.heightAnchor.constraint(equalToConstant: 120),
            stackView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 40),
            stackView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -40)
        ])
    }
    
    private func setSignUpButton() {
        view.addSubview(signUpButton)
        
        signUpButton.configuration = .filled()
        signUpButton.configuration?.title = "Sign Up"
        signUpButton.configuration?.baseBackgroundColor = .systemPink
        signUpButton.translatesAutoresizingMaskIntoConstraints = false
        signUpButton.addTarget(self, action: #selector(finishRegistration), for: .touchUpInside)
        
        NSLayoutConstraint.activate([
            signUpButton.topAnchor.constraint(equalTo: stackView.bottomAnchor, constant: 50.0),
            signUpButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            signUpButton.widthAnchor.constraint(equalToConstant: 200),
            signUpButton.heightAnchor.constraint(equalToConstant: 50)
        ])
    }
    
//MARK: - Validate & Signup
    
    @objc private func finishRegistration()
    {
        let isValid = textFieldValidator.validate()
        if isValid {
            signUpViewModel.signUp() { registrationStatus in
                if registrationStatus == .success {
                    self.coordinator?.pushUsernameRegistration()
                }
            }
        }
    }
}
