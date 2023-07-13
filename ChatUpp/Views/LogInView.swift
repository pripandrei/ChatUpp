//
//  LogInView.swift
//  ChatUpp
//
//  Created by Andrei Pripa on 7/2/23.
//

import UIKit

//class LogInView: UIView, UITextFieldDelegate {
//
//    private let signUpLable = "Don't have an account?"
//
//    private let logIn = UIButton()
//
//    private let stackView = UIStackView()
//
//    lazy private var mailLogInField: UITextField = {
//        let mailTextField = UITextField()
//        mailTextField.delegate = self
//        return mailTextField
//    }()
//
//    lazy var passwordLogInField: UITextField = {
//        let passwordTextfield = UITextField()
//        passwordTextfield.delegate = self
//        return passwordTextfield
//    }()
//
//    override func viewDidLoad()
//    {
//        super.viewDidLoad()
//
//        setupLogInButton()
//        setupMailTextField()
//        setupPasswordTextField()
//        configureStackView()
//
//        view.backgroundColor = .white
//        title = "Log in"
//
//        navigationController?.navigationBar.prefersLargeTitles = true
//    }
//
//    func textFieldDidEndEditing(_ textField: UITextField) {
//        if let text = textField.text {
//            print(text)
//        }
//    }
//
//    private func configureStackView() {
//        view.addSubview(stackView)
//
//        stackView.axis = .vertical
//        stackView.distribution = .fillEqually
//        stackView.spacing = 20
//
//        stackView.addArrangedSubview(mailLogInField)
//        stackView.addArrangedSubview(passwordLogInField)
//
//        setStackViewConstraints()
//    }
//
//    private func setStackViewConstraints() {
//        stackView.translatesAutoresizingMaskIntoConstraints = false
//
//        NSLayoutConstraint.activate([
//            stackView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
//            stackView.bottomAnchor.constraint(equalTo: logIn.topAnchor, constant: -250),
//            stackView.widthAnchor.constraint(equalToConstant: 300),
//            stackView.heightAnchor.constraint(equalToConstant: 120)
//        ])
//    }
//
//    private func setupLogInButton()
//    {
//        view.addSubview(logIn)
//
//        logIn.configuration = .filled()
//        logIn.configuration?.title = "Log in"
//        logIn.configuration?.baseBackgroundColor = .systemPink
//        logIn.addTarget(self, action: #selector(pushSignUpVC), for: .touchUpInside)
//
//        setLogInConstraints()
//    }
//
//    private func setLogInConstraints() {
//        logIn.translatesAutoresizingMaskIntoConstraints = false
//        NSLayoutConstraint.activate([
//            logIn.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -100.0),
//            logIn.centerXAnchor.constraint(equalTo: view.centerXAnchor),
//            logIn.widthAnchor.constraint(equalToConstant: 200),
//            logIn.heightAnchor.constraint(equalToConstant: 50)
//        ])
//    }
//
//    private func configureRegistrationLable()
//    {
//
//    }
//
//    private func setupSignUpButton()
//    {
//
//    }
//
//    private func setupMailTextField() {
//        view.addSubview(mailLogInField)
//
//        mailLogInField.text = "Enter mail here"
//        mailLogInField.borderStyle = .roundedRect
//        mailLogInField.translatesAutoresizingMaskIntoConstraints = false
//    }
//
//    private func setupPasswordTextField()
//    {
//        view.addSubview(passwordLogInField)
//
//        passwordLogInField.text = "Enter password here"
//        passwordLogInField.borderStyle = .roundedRect
//        passwordLogInField.translatesAutoresizingMaskIntoConstraints = false
//    }
//
//    @objc func pushSignUpVC() {
//        let signUpVC = SignUpViewController()
//        navigationController?.pushViewController(signUpVC, animated: true)
//    }
//
//}
