//
//  MailSignInViewController.swift
//  ChatUpp
//
//  Created by Andrei Pripa on 12/7/23.
//

import UIKit

final class MailSignInViewController: UIViewController {
    
    private var loginViewModel: LoginViewModel!
    private let stackView = UIStackView()
    private var mailLogInField = UITextField()
    private var passwordLogInField = UITextField()
    private let logInButton = UIButton()
    lazy private var textFieldValidator = EmailCredentialsValidator(mailField: mailLogInField,
                                                                    passwordField: passwordLogInField,
                                                                    viewModel: loginViewModel)

    init(viewModel: LoginViewModel) {
        super.init(nibName: nil, bundle: nil)
        self.loginViewModel = viewModel
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = .white
        
        configureStackView()
        setupMailTextField()
        setupPasswordTextField()
        setupLogInButton()
    }
    
    
    private func configureStackView() {
        view.addSubview(stackView)
        
        stackView.axis = .vertical
        stackView.distribution = .fillEqually
        stackView.spacing = 20
        
        stackView.addArrangedSubview(mailLogInField)
        stackView.addArrangedSubview(passwordLogInField)
        
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
    
    private func setupMailTextField() {
//        view.addSubview(mailLogInField)
        
        mailLogInField.delegate = textFieldValidator
        mailLogInField.placeholder = "Enter mail here"
        mailLogInField.borderStyle = .roundedRect
        mailLogInField.translatesAutoresizingMaskIntoConstraints = false
    }

    private func setupPasswordTextField()
    {
//        view.addSubview(passwordLogInField)

        passwordLogInField.delegate = textFieldValidator
        passwordLogInField.placeholder = "Enter password here"
        passwordLogInField.borderStyle = .roundedRect
        passwordLogInField.translatesAutoresizingMaskIntoConstraints = false
    }
    
    private func setupLogInButton()
    {
        view.addSubview(logInButton)
        
        logInButton.configuration = .filled()
        logInButton.configuration?.title = "Log in"
        logInButton.configuration?.baseBackgroundColor = .systemPink
        logInButton.addTarget(self, action: #selector(logInButtonTap), for: .touchUpInside)
        
        setLogInConstraints()
    }
    
    private func setLogInConstraints()
    {
        logInButton.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            logInButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            //            logIn.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -100.0),
            logInButton.topAnchor.constraint(equalTo: passwordLogInField.bottomAnchor, constant: 40.0),
            logInButton.widthAnchor.constraint(equalToConstant: 200),
            logInButton.heightAnchor.constraint(equalToConstant: 50)
        ])
    }
    
    @objc func logInButtonTap()
    {
        let isValide = textFieldValidator.validate()
        if isValide {
            loginViewModel.signInWithEmail()
        }
    }

}


