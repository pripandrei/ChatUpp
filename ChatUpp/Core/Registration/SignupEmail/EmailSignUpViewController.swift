//
//  SignUpViewController.swift
//  ChatUpp
//
//  Created by Andrei Pripa on 6/29/23.
//

import UIKit
import NVActivityIndicatorView

class EmailSignUpViewController: UIViewController {
    
    weak var coordinator: Coordinator?
    
    private var signUpViewModel = EmailSignupViewModel()
    private let stackView = UIStackView()
    private let signUpButton = CustomizedShadowButton(shadowType: .bodyItem)
    private var emailSignupField = CustomizedShadowTextField()
    private var passwordSignupField = CustomizedShadowTextField()
    private let doorLogo = UIImageView()
    private let provideEmailLabel = UILabel()
    
    lazy private var textFieldValidator = CredentialsValidator(
        mailField: emailSignupField,
        passwordField: passwordSignupField,
        validator: signUpViewModel
    )
    
    private(set) lazy var activityIndicator: NVActivityIndicatorView = {
        let activityIndicator = NVActivityIndicatorView(frame: CGRect(x: 0, y: 0, width: 40, height: 40),
                                                        type: .circleStrokeSpin,
                                                        color: .link,
                                                        padding: 2)
        activityIndicator.translatesAutoresizingMaskIntoConstraints = false
        return activityIndicator
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        Utilities.setGradientBackground(forView: view)
        controllerMainConfiguration()
    }
    
    deinit {
//        print("Sign Up email deinit !!")
    }
    
//MARK: - UI Configuration
    
    private func controllerMainConfiguration() {
        setEmailSignupField()
        setPasswordSignupField()
        configureStackView()
        setSignUpButton()
        setupEnvelopeImage()
        setupProvideEmailLabel()
        setupActivityIndicatorConstraint()
    }
    
    private func setupEnvelopeImage() {
        view.addSubview(doorLogo)
        
        let image = UIImage(named: "door_logo_2")
        doorLogo.image = image
        
        doorLogo.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            doorLogo.topAnchor.constraint(equalTo: view.topAnchor, constant: 35),
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
            provideEmailLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
        ])
    }

    private func setEmailSignupField()
    {
        emailSignupField.delegate = textFieldValidator
        emailSignupField.placeholder = "Provide an email"
        emailSignupField.translatesAutoresizingMaskIntoConstraints = false
    }
    
    private func setPasswordSignupField()
    {
        passwordSignupField.delegate = textFieldValidator
        passwordSignupField.placeholder = "Provide a password"
//        passwordSignupField.isSecureTextEntry = true
        
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
            signUpButton.heightAnchor.constraint(equalToConstant: 40)
        ])
    }
    
    private func setupActivityIndicatorConstraint()
    {
        view.addSubview(activityIndicator)
        
        NSLayoutConstraint.activate([
            activityIndicator.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            activityIndicator.topAnchor.constraint(equalTo: signUpButton.bottomAnchor, constant: 25)
        ])
    }
    
//MARK: - Validate & Signup
    
    @objc private func finishRegistration()
    {
        let isValid = textFieldValidator.validate()
        
        if isValid
        {
            activityIndicator.startAnimating()
            resignCurrentFirstResponder()
            signUpViewModel.signUp() { [weak self] registrationStatus in
                if registrationStatus == .success {
                    self?.activityIndicator.stopAnimating()
                    self?.coordinator?.pushUsernameRegistration()
                }
            }
        }
    }
    
    private func resignCurrentFirstResponder()
    {
        if emailSignupField.isFirstResponder
        {
            emailSignupField.resignFirstResponder()
        }
        if passwordSignupField.isFirstResponder
        {
            passwordSignupField.resignFirstResponder()
        }
    }
}
