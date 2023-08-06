//
//  ViewController.swift
//  ChatUpp
//
//  Created by Andrei Pripa on 6/26/23.
//

import UIKit
import FirebaseAuth

class LoginViewController: UIViewController, UITextFieldDelegate {
    
    // Try elements idea with all the signUpss
    
    private let signUpText = "Don't have an account?"
    
    private let signUpLable: UILabel = UILabel()
    
    private let signUpButton = UIButton()
    
    private let logIn = UIButton()
    
    private let stackView = UIStackView()
    
    lazy private var mailLogInField: UITextField = {
        let mailTextField = UITextField()
        mailTextField.delegate = self
        return mailTextField
    }()

    lazy var passwordLogInField: UITextField = {
        let passwordTextfield = UITextField()
        passwordTextfield.delegate = self
        return passwordTextfield
    }()
  
    override func viewDidLoad()
    {
        super.viewDidLoad()
        
        setupLogInButton()
        setupSignUpLable()
        setupSignUpButton()
        setupMailTextField()
        setupPasswordTextField()
        configureStackView()
        
        view.backgroundColor = .white
        title = "Log in"
        
        navigationController?.navigationBar.prefersLargeTitles = true
    }
    
    func textFieldDidEndEditing(_ textField: UITextField) {
        if let text = textField.text {
            print(text)
        }
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
            stackView.bottomAnchor.constraint(equalTo: logIn.topAnchor, constant: -250),
            stackView.widthAnchor.constraint(equalToConstant: 300),
            stackView.heightAnchor.constraint(equalToConstant: 120)
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
            logIn.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -100.0),
            logIn.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            logIn.widthAnchor.constraint(equalToConstant: 200),
            logIn.heightAnchor.constraint(equalToConstant: 50)
        ])
    }
    
    private func setupSignUpButton()
    {
        view.addSubview(signUpButton)
        
        signUpButton.configuration = .plain()
        signUpButton.configuration?.title = "SignUp"
        signUpButton.configuration?.baseBackgroundColor = .blue
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
        view.addSubview(mailLogInField)

        mailLogInField.placeholder = "Enter mail here"
        mailLogInField.borderStyle = .roundedRect
        mailLogInField.translatesAutoresizingMaskIntoConstraints = false
    }

    private func setupPasswordTextField()
    {
        view.addSubview(passwordLogInField)

        passwordLogInField.placeholder = "Enter password here"
        passwordLogInField.borderStyle = .roundedRect
        passwordLogInField.translatesAutoresizingMaskIntoConstraints = false
    }
    
    @objc func pushSignUpVC() {
        let signUpVC = SignUpViewController()
        navigationController?.pushViewController(signUpVC, animated: true)
    }
    
    @objc func logInButtonTap() {
        
        guard let email = mailLogInField.text,
              let password = passwordLogInField.text,
                !email.isEmpty,
                !password.isEmpty else {
            print("Some fields are empty")
            return
        }
        
        
        FirebaseAuth.Auth.auth().signIn(withEmail: email, password: password) { authResult, error in
            guard let result = authResult, error == nil else {
                print("Could not log you in")
                return
            }
            
            print(result)
        }
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
    }
}




