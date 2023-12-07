//
//  ViewController.swift
//  ChatUpp
//
//  Created by Andrei Pripa on 6/26/23.
//

import UIKit
import GoogleSignIn


class LoginViewController: UIViewController {
    
    weak var coordinatorDelegate: Coordinator?
    
    private var googleSignInButton = GIDSignInButton()
    private let loginViewModel = LoginViewModel()
    private let signUpLable: UILabel = UILabel()
    private let signUpButton = UIButton()
    private var mailSignInButton = UIButton()
    private let phoneButton = UIButton()

    // MARK: - VC LIFEC YCLE
    override func viewDidLoad()
    {
        super.viewDidLoad()
        
        controllerMainSetup()
        
        view.backgroundColor = .white
//        title = "Log in"
        navigationController?.navigationBar.prefersLargeTitles = true
    }
    
    deinit {
        print("Login WAS DEINIT +++")
    }
    
    private func controllerMainSetup() {
        configureSignInGoogleButton()
        setupPhoneButton()
        setupMailButton()
        setupBinder()
        setupSignUpLable()
        setupSignUpButton()
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
    
    private func setupMailButton() {
        view.addSubview(mailSignInButton)
        
        mailSignInButton.configuration = .filled()
        mailSignInButton.configuration?.title = "Sign in with email"
        mailSignInButton.configuration?.baseBackgroundColor = .link
        mailSignInButton.addTarget(self, action: #selector(mailSignInButtonTapped), for: .touchUpInside)
        
        mailSignInButton.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            mailSignInButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            mailSignInButton.topAnchor.constraint(equalTo: phoneButton.bottomAnchor, constant: 20),
//            mailSignInButton.widthAnchor.constraint(equalToConstant: googleSignInButton.bounds.width),
            mailSignInButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 43),
            mailSignInButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -43),
            mailSignInButton.heightAnchor.constraint(equalToConstant: 40)
        ])
    }
    
    @objc func mailSignInButtonTapped() {
        coordinatorDelegate?.pushMailSignInController(viewModel: loginViewModel)
    }
    
    
    private func setupPhoneButton() {
        view.addSubview(phoneButton)
        
        phoneButton.configuration = .filled()
        phoneButton.configuration?.title = "Sign in with phone"
        phoneButton.configuration?.baseBackgroundColor = .link
        phoneButton.addTarget(self, action: #selector(phoneButtonTapped), for: .touchUpInside)
        
        phoneButton.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            phoneButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            phoneButton.topAnchor.constraint(equalTo: googleSignInButton.bottomAnchor, constant: 20),
            phoneButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 43),
            phoneButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -43),
            phoneButton.heightAnchor.constraint(equalToConstant: 40)
        ])
    }
    
    @objc func phoneButtonTapped() {
        coordinatorDelegate?.pushPhoneSingInVC()
    }
    
    private func configureSignInGoogleButton() {
        view.addSubview(googleSignInButton)
        
        googleSignInButton.colorScheme = .dark
        googleSignInButton.style = .wide
//        googleSignInButton.layer.cornerRadius = 10
        googleSignInButton.addTarget(self, action: #selector(handleSignInWithGoogle), for: .touchUpInside)
        
        setSignInGoogleButtonConstraints()
    }
    
    private func setSignInGoogleButtonConstraints() {
        googleSignInButton.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            googleSignInButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            googleSignInButton.topAnchor.constraint(equalTo: view.topAnchor, constant: view.bounds.height / 1.5),
            googleSignInButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 40),
            googleSignInButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -40)
        ])
    }
    
    @objc private func handleSignInWithGoogle() {
        loginViewModel.googleSignIn()
    }

    private func setupSignUpLable() {
        view.addSubview(signUpLable)
        
        signUpLable.text = "Don't have an account?"
        signUpLable.font = UIFont(name: "MalayalamSangamMN", size: 16.0)
        setSignUpLableConstraints()
    }
    
    private func setSignUpLableConstraints() {
        signUpLable.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            signUpLable.topAnchor.constraint(equalTo: mailSignInButton.bottomAnchor, constant: 12),
            signUpLable.leadingAnchor.constraint(equalTo: mailSignInButton.leadingAnchor, constant: 40)
        ])
    }

    private func setupSignUpButton()
    {
        view.addSubview(signUpButton)
        
        signUpButton.configuration = .plain()
        signUpButton.configuration?.title = "Sign Up"
        signUpButton.configuration?.contentInsets = NSDirectionalEdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0)
        signUpButton.addTarget(self, action: #selector(pushSignUpVC), for: .touchUpInside)
        signUpButton.configuration?.buttonSize = .small
        
        setSignUpButtonConstraints()
    }
    
    private func setSignUpButtonConstraints() {
        signUpButton.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            signUpButton.leadingAnchor.constraint(equalTo: signUpLable.trailingAnchor, constant: 5),
            signUpButton.topAnchor.constraint(equalTo: mailSignInButton.bottomAnchor, constant: 10.5)
        ])
    }

    // MARK: - Navigation
    
    @objc func pushSignUpVC() {
        coordinatorDelegate?.pushSignUpVC()
    }
}





