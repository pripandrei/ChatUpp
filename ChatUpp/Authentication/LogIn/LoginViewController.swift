//
//  ViewController.swift
//  ChatUpp
//
//  Created by Andrei Pripa on 6/26/23.
//

import UIKit
import FirebaseAuth

class LoginViewController: UIViewController, UITextFieldDelegate {
    
    private let loginViewModel = LoginViewModel()
    
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
        setupBinder()
        
        view.backgroundColor = .white
        title = "Log in"
        navigationController?.navigationBar.prefersLargeTitles = true
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
            stackView.centerYAnchor.constraint(equalTo: view.centerYAnchor),
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
    
    // MARK: - Navigation
    
    @objc func pushSignUpVC() {
        let signUpVC = SignUpViewController()
        navigationController?.pushViewController(signUpVC, animated: true)
    }
    
    // MARK: - Login handler
    
    @objc func logInButtonTap()
    {
//        let validationResult = loginViewModel.validateCredentials()
//        if validationResult == .valid {
//            loginViewModel.signIn()
//        }
        
        do {
            try loginViewModel.validateCredentialss()
            loginViewModel.signIn()
        } catch CredentialsError.emptyMail {
            print("Mail is empty")
        } catch CredentialsError.empyPassword {
            print("Password is empty")
        } catch CredentialsError.shortPassword  {
            print("Password must not be shorter than 6 character")
        } catch {
            print("Something went wrong validating credentials")
        }
        
    }
    
// MARK: - TextFields delegate
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        return textField.resignFirstResponder()
    }
    
    func textFieldShouldEndEditing(_ textField: UITextField) -> Bool {
        if let text = textField.text {
            print(text)
            switch textField {
            case mailLogInField: loginViewModel.email = text
            case passwordLogInField: loginViewModel.password = text
            default: break
            }
        }
        return true
    }
}

// MARK: - LoginViewModel

final class LoginViewModel {
    
    var email: String = ""
    var password: String = ""
    
    var loginStatus: ObservableObject<LoginStatus?> = ObservableObject(nil)

//    func validateCredentials() -> ValidationStatus {
//        guard !email.isEmpty,
//              !password.isEmpty else {
//            print("Some fields are empty")
//            return .invalid
//        }
//        return .valid
//    }
    
//    96rjjtswpg8z5aoolidmokoe6
    
    func validateCredentialss() throws {
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
    
    func signIn() {
        AuthenticationManager.shared.signIn(email: email, password: password) { [weak self] authRestult in
            guard let _ = authRestult else {
                return
            }
            self?.loginStatus.value = .loggedIn
        }
    }
}

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
