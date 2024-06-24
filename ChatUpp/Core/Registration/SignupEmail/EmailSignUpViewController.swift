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
    private let signUpButton = CustomizedShadowButton()
    private var emailSignupField = CustomizedShadowTextField()
    private var passwordSignupField = CustomizedShadowTextField()
    private let doorLogo = UIImageView()
    private let provideEmailLabel = UILabel()
    lazy private var textFieldValidator = EmailCredentialsValidator(mailField: emailSignupField,
                                                                    passwordField: passwordSignupField,
                                                                    viewModel: signUpViewModel)
    override func viewDidLoad() {
        super.viewDidLoad()
//        view.backgroundColor = #colorLiteral(red: 0.1411764771, green: 0.3960784376, blue: 0.5647059083, alpha: 1)
        Utilities.setGradientBackground(forView: view)
        controllerMainConfiguration()
    }
    
//MARK: - UI Configuration
    
    private func controllerMainConfiguration() {
        setEmailSignupField()
        setPasswordSignupField()
        configureStackView()
        setSignUpButton()
        setupEnvelopeImage()
        setupProvideEmailLabel()
    }
    
    private func setupEnvelopeImage() {
        view.addSubview(doorLogo)
        
        let image = UIImage(named: "door_logo_2")
        doorLogo.image = image
        
        doorLogo.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            doorLogo.topAnchor.constraint(equalTo: view.topAnchor, constant: 35),
//            doorLogo.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 75),
            doorLogo.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            doorLogo.heightAnchor.constraint(equalToConstant: 200),
            doorLogo.widthAnchor.constraint(equalToConstant: 230),
        ])
    }
    
    private func setupProvideEmailLabel() {
        view.addSubview(provideEmailLabel)
        
        provideEmailLabel.text = "What's your email address?"
        provideEmailLabel.textColor = #colorLiteral(red: 0.8817898337, green: 0.8124251547, blue: 0.8326097798, alpha: 1)
        provideEmailLabel.font =  UIFont.boldSystemFont(ofSize: 20)
       
        provideEmailLabel.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            provideEmailLabel.topAnchor.constraint(equalTo: doorLogo.bottomAnchor, constant: 0),
//            provideEmailLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 65),
            provideEmailLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
        ])
    }

    private func setEmailSignupField()
    {
        emailSignupField.delegate = textFieldValidator
        emailSignupField.placeholder = "Provide an email"
//        emailSignupField.borderStyle = .roundedRect
        emailSignupField.translatesAutoresizingMaskIntoConstraints = false
    }
    
    private func setPasswordSignupField()
    {
        passwordSignupField.delegate = textFieldValidator
        passwordSignupField.placeholder = "Provide a password"
//        passwordSignupField.borderStyle = .roundedRect
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
            stackView.topAnchor.constraint(equalTo: view.topAnchor, constant: 280),
//            stackView.widthAnchor.constraint(equalToConstant: 300),
            stackView.heightAnchor.constraint(equalToConstant: 120),
            stackView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 40),
            stackView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -40)
        ])
    }
    
    private func setSignUpButton() {
        view.addSubview(signUpButton)
        
        signUpButton.configuration?.title = "Sign Up"
        signUpButton.addTarget(self, action: #selector(finishRegistration), for: .touchUpInside)
        
        signUpButton.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            signUpButton.topAnchor.constraint(equalTo: stackView.bottomAnchor, constant: 35.0),
            signUpButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            signUpButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 73),
            signUpButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -73),
//            signUpButton.widthAnchor.constraint(equalToConstant: 200),
            signUpButton.heightAnchor.constraint(equalToConstant: 40)
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
