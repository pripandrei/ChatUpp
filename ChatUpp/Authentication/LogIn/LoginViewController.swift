//
//  ViewController.swift
//  ChatUpp
//
//  Created by Andrei Pripa on 6/26/23.
//

import UIKit
import SwiftUI
import FirebaseAuth
import GoogleSignIn
import GoogleSignInSwift

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
        let tabBarr = (UIApplication.shared.connectedScenes.first as? UIWindowScene)?.windows.first?.rootViewController
//        tabBarr?.tabBarController?.children
        let nav = (tabBarr as? UITabBarController)?.children.first
        let vc = ((nav as? UINavigationController)?.topViewController) as? ConversationsViewController
        print("===Vc", vc?.presentedViewController?.children)
    }
    
    //MARK: - Binder
    
    private func setupBinder() {
        loginViewModel.loginStatus.bind { [weak self] status in
            if status == .loggedIn {
                self?.navigationController?.dismiss(animated: true)
            }
        }
    }
    
    // MARK: - setup viewController
    
    private func configureSignInGoogleButton() {
        view.addSubview(googleSignInButton)
        
        googleSignInButton.colorScheme = .dark
        googleSignInButton.style = .wide
        googleSignInButton.addTarget(self, action: #selector(handleSignInWithGoogle), for: .touchUpInside)
        
        setSignInGoogleButtonConstraints()
    }
    
    private func setSignInGoogleButtonConstraints() {
        googleSignInButton.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            googleSignInButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            googleSignInButton.topAnchor.constraint(equalTo: signUpLable.bottomAnchor, constant: 60),
            googleSignInButton.heightAnchor.constraint(equalToConstant: 50),
            googleSignInButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 40),
            googleSignInButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -40)
        ])
    }
    
    @objc private func handleSignInWithGoogle() {
        
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
        let signUpVC = SignUpViewController()
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

// MARK: - LoginViewModel

final class LoginViewModel {
    
    //MARK: - Sign in through email
    
    var email: String = ""
    var password: String = ""
    
    var loginStatus: ObservableObject<LoginStatus?> = ObservableObject(nil)
    
    func validateEmailCredentials() throws {
        guard !email.isEmpty else {
            throw CredentialsError.emptyMail
        }
        guard !password.isEmpty else {
            throw CredentialsError.empyPassword
        }
        guard password.count > 6 else {
            throw CredentialsError.shortPassword
        }
    }
    
    func signInWithEmail() {
        AuthenticationManager.shared.signIn(email: email, password: password) { [weak self] authRestult in
            guard let _ = authRestult else {
                return
            }
            self?.loginStatus.value = .loggedIn
        }
    }
    
    //MARK: - Sign in through google
    
    func googleSignIn() throws {
        
        guard let loginVC = Utilities.findLoginViewControllerInHierarchy() else {
            throw URLError(.cannotFindHost)
        }
        
        GIDSignIn.sharedInstance.signIn(withPresenting: loginVC) { GIDSignInResult, error in
            
        }
    }
}

extension LoginViewModel: EmailValidator {}

enum LoginStatus {
    case loggedIn
    case loggedOut
}

enum ValidationStatus {
    case valid
    case invalid
}

enum ResposneStatus {
    case success
    case failed
}

enum CredentialsError: Error {
    case emptyMail
    case empyPassword
    case shortPassword
}


