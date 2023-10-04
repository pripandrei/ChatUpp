//
//  ViewController.swift
//  ChatUpp
//
//  Created by Andrei Pripa on 6/26/23.
//

import UIKit
import GoogleSignIn

class LoginViewController: UIViewController {
    
    private var googleSignInButton = GIDSignInButton()
    private let loginViewModel = LoginViewModel()
    private let signUpText = "Don't have an account?"
    private let signUpLable: UILabel = UILabel()
    private let signUpButton = UIButton()
    private let logIn = UIButton()
    private let stackView = UIStackView()
    private var mailLogInField = UITextField()
    private var passwordLogInField = UITextField()
    lazy private var textFieldValidator = EmailCredentialsValidator(mailField: mailLogInField,
                                                                    passwordField: passwordLogInField,
                                                                    viewModel: loginViewModel)
    
    // MARK: - VC LIFEC YCLE
    override func viewDidLoad()
    {
        super.viewDidLoad()
        
        controllerMainSetup()
        
        view.backgroundColor = .white
        title = "Log in"
        navigationController?.navigationBar.prefersLargeTitles = true
    }
    
    private func controllerMainSetup() {
        setupMailTextField()
        setupPasswordTextField()
        configureStackView()
        setupLogInButton()
        setupSignUpLable()
        setupSignUpButton()
        configureSignInGoogleButton()
        setupBinder()
    }
    
    //MARK: - Binder
    
    private func setupBinder() {
        loginViewModel.loginStatus.bind { [weak self] status in
            if status == .userIsAuthenticated {
                self?.navigationController?.dismiss(animated: true)
            }
        }
    }
    
    // MARK: - Setup viewController
    
    private func configureSignInGoogleButton() {
        view.addSubview(googleSignInButton)
        
        googleSignInButton.colorScheme = .dark
        googleSignInButton.style = .wide
        googleSignInButton.layer.cornerRadius = 10
        googleSignInButton.addTarget(self, action: #selector(handleSignInWithGoogle), for: .touchUpInside)
        
        setSignInGoogleButtonConstraints()
    }
    
    private func setSignInGoogleButtonConstraints() {
        googleSignInButton.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            googleSignInButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            googleSignInButton.topAnchor.constraint(equalTo: signUpLable.bottomAnchor, constant: 100),
//            googleSignInButton.heightAnchor.constraint(equalToConstant: 110),
            googleSignInButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 40),
            googleSignInButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -40)
        ])
    }
    
    @objc private func handleSignInWithGoogle() {
        loginViewModel.googleSignIn()
    }

    private func setupSignUpLable() {
        view.addSubview(signUpLable)
        
        signUpLable.text = signUpText
        signUpLable.font = UIFont(name: "MalayalamSangamMN", size: 14.0)
        setSignUpLableConstraints()
    }
    
    private func setSignUpLableConstraints() {
        signUpLable.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            signUpLable.centerXAnchor.constraint(equalTo: logIn.centerXAnchor),
            signUpLable.topAnchor.constraint(equalTo: logIn.bottomAnchor, constant: 10),
            signUpLable.leadingAnchor.constraint(equalTo: logIn.leadingAnchor)
        ])
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
    
    private func setupLogInButton()
    {
        view.addSubview(logIn)
        
        logIn.configuration = .filled()
        logIn.configuration?.title = "Log in"
        logIn.configuration?.baseBackgroundColor = .systemPink
        logIn.addTarget(self, action: #selector(logInButtonTap), for: .touchUpInside)
        
        setLogInConstraints()
    }
    
    private func setLogInConstraints()
    {
        logIn.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            logIn.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            //            logIn.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -100.0),
            logIn.topAnchor.constraint(equalTo: passwordLogInField.bottomAnchor, constant: 40.0),
            logIn.widthAnchor.constraint(equalToConstant: 200),
            logIn.heightAnchor.constraint(equalToConstant: 50)
        ])
    }
    
    private func setupSignUpButton()
    {
        view.addSubview(signUpButton)
        
        signUpButton.configuration = .plain()
        signUpButton.configuration?.title = "Sign Up"
        signUpButton.addTarget(self, action: #selector(pushSignUpVC), for: .touchUpInside)
        signUpButton.configuration?.buttonSize = .small
        
        setSignUpButtonConstraints()
    }
    
    private func setSignUpButtonConstraints() {
        signUpButton.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            signUpButton.leadingAnchor.constraint(equalTo: signUpLable.trailingAnchor, constant: -65),
            signUpButton.topAnchor.constraint(equalTo: logIn.bottomAnchor, constant: 2)
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
    
    // MARK: - Navigation
    
    @objc func pushSignUpVC() {
        let signUpVC = EmailSignUpViewController()
        navigationController?.pushViewController(signUpVC, animated: true)
    }
    
    // MARK: - Login handler
    
    @objc func logInButtonTap()
    {
        let isValide = textFieldValidator.validate()
        if isValide {
            loginViewModel.signInWithEmail()
        }
    }
}





