//
//  ViewController.swift
//  ChatUpp
//
//  Created by Andrei Pripa on 6/26/23.
//

import UIKit

class LoginViewController: UIViewController, UITextFieldDelegate {
    
    private let signUp = UIButton()
    
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
        
        setUpNextButton()
        setUpMailTextField()
        setUpPasswordTextField()
        configureStackView()
        setStackViewConstraints()
        
        view.backgroundColor = .white
        title = "Sign in"
        
        navigationController?.navigationBar.prefersLargeTitles = true
    }
    
    func textFieldDidEndEditing(_ textField: UITextField) {
        if let text = textField.text {
            print(text)
        }
    }
    
    private func configureStackView() {
        view.addSubview(stackView)
        
        stackView.axis = .vertical
        stackView.distribution = .fillEqually
        stackView.spacing = 20
        
        stackView.addArrangedSubview(mailLogInField)
        stackView.addArrangedSubview(passwordLogInField)
    }
    
    private func setStackViewConstraints() {
        stackView.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            stackView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            stackView.bottomAnchor.constraint(equalTo: signUp.topAnchor, constant: -250),
            stackView.widthAnchor.constraint(equalToConstant: 300),
            stackView.heightAnchor.constraint(equalToConstant: 100)
        ])
    }
    
    private func setUpNextButton()
    {
        view.addSubview(signUp)
        
        signUp.configuration = .filled()
        signUp.configuration?.title = "Sign up"
        signUp.configuration?.baseBackgroundColor = .systemPink
        signUp.translatesAutoresizingMaskIntoConstraints = false
        signUp.addTarget(self, action: #selector(segueToSignUpVC), for: .touchUpInside)
        
        NSLayoutConstraint.activate([
            signUp.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -100.0),
            signUp.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            signUp.widthAnchor.constraint(equalToConstant: 200),
            signUp.heightAnchor.constraint(equalToConstant: 50)
        ])
    }
    
    private func setUpMailTextField() {
        view.addSubview(mailLogInField)

        mailLogInField.text = "Enter mail here"
        mailLogInField.borderStyle = .roundedRect
        mailLogInField.translatesAutoresizingMaskIntoConstraints = false

    }

    private func setUpPasswordTextField()
    {
        view.addSubview(passwordLogInField)

        passwordLogInField.text = "Enter password here"
        passwordLogInField.borderStyle = .roundedRect
        passwordLogInField.translatesAutoresizingMaskIntoConstraints = false
    }
    
    @objc func segueToSignUpVC() {
        let signUpVC = SignUpViewController()
        navigationController?.pushViewController(signUpVC, animated: true)
    }
}


