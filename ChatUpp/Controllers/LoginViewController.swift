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
    
//    lazy private var mailTextField: UITextField = {
//        let mailTextField = UITextField()
//        mailTextField.delegate = self
//        return mailTextField
//    }()
//
//    lazy var passwordTextField: UITextField = {
//        let passwordTextfield = UITextField()
//        passwordTextfield.delegate = self
//        return passwordTextfield
//    }()
  
    override func viewDidLoad()
    {
        super.viewDidLoad()
        
        setUpNextButton()
        configureStackView()
        setStackViewConstraints()
        
//        setUpMailTextField()
//        setUpPasswordTextField()
        
        view.backgroundColor = .white
        title = "Sign in"
        
        navigationController?.navigationBar.prefersLargeTitles = true
    }
    
    func textFieldDidEndEditing(_ textField: UITextField) {
        if let text = textField.text {
            print(text)
        }
//        print(textField.text)
    }
    
    private func configureStackView() {
        view.addSubview(stackView)
        
        stackView.axis = .vertical
        stackView.distribution = .fillEqually
        stackView.spacing = 20
//        stackView.backgroundColor = .green
        
        addTextFieldToStackView()
    }
    
    private func setStackViewConstraints() {
        stackView.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            stackView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            stackView.bottomAnchor.constraint(equalTo: signUp.topAnchor, constant: -250),
            stackView.widthAnchor.constraint(equalToConstant: 200),
            stackView.heightAnchor.constraint(equalToConstant: 100)
        ])
    }
    
    private func addTextFieldToStackView() {
        let numberOfTextFields = 2
        
        let textFieldTitles = ["Enter mail here", "Enter password here"]
        
        for number in 1...numberOfTextFields {
            let textField = CustomTextField()
            textField.delegate = self
            textField.text = textFieldTitles[number - 1]
            stackView.addArrangedSubview(textField)
        }
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
    
//    private func setUpMailTextField() {
//        view.addSubview(mailTextField)
//
//        var constraints = [NSLayoutConstraint]()
//
//        mailTextField.text = "Enter mail here"
//        mailTextField.borderStyle = .line
//        mailTextField.translatesAutoresizingMaskIntoConstraints = false
//
//        constraints.append(mailTextField.topAnchor.constraint(equalTo: view.topAnchor, constant: 330))
//        constraints.append(mailTextField.centerXAnchor.constraint(equalTo: view.centerXAnchor))
//        constraints.append(mailTextField.widthAnchor.constraint(equalToConstant: 200))
//        constraints.append(mailTextField.heightAnchor.constraint(equalToConstant: 50))
//        NSLayoutConstraint.activate(constraints)
//    }
//
//    private func setUpPasswordTextField()
//    {
//        view.addSubview(passwordTextField)
//
//        passwordTextField.text = "Enter password here"
//        passwordTextField.borderStyle = .line
//        passwordTextField.translatesAutoresizingMaskIntoConstraints = false
//
//        NSLayoutConstraint.activate([
//            passwordTextField.topAnchor.constraint(equalTo: mailTextField.topAnchor, constant: 80),
//            passwordTextField.centerXAnchor.constraint(equalTo: view.centerXAnchor),
//            passwordTextField.widthAnchor.constraint(equalToConstant: 200),
//            passwordTextField.heightAnchor.constraint(equalToConstant: 50)
//        ])
//    }
    
    @objc func segueToSignUpVC() {
        let signUpVC = SignUpViewController()
        navigationController?.pushViewController(signUpVC, animated: true)
    }
}

class CustomTextField: UITextField {
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setUpTextField()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setUpTextField()
    }
    
    private func setUpTextField() {
        borderStyle = .line
        translatesAutoresizingMaskIntoConstraints = false
    }
}
