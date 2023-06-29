//
//  ViewController.swift
//  ChatUpp
//
//  Created by Andrei Pripa on 6/26/23.
//

import UIKit

class LoginViewController: UIViewController, UITextFieldDelegate {
    
    private let nextButton = UIButton()
    
    lazy private var mailTextField: UITextField = {
        let mailTextField = UITextField()
        mailTextField.delegate = self
        return mailTextField
    }()
    
    lazy var passwordTextField: UITextField = {
        let passwordTextfield = UITextField()
        passwordTextfield.delegate = self
        return passwordTextfield
    }()
    
    private func setUpMailTextField() {
        view.addSubview(mailTextField)
        
        var constraints = [NSLayoutConstraint]()
        
        mailTextField.text = "Enter mail here"
        mailTextField.borderStyle = .line
        mailTextField.translatesAutoresizingMaskIntoConstraints = false
        
        constraints.append(mailTextField.topAnchor.constraint(equalTo: view.topAnchor, constant: 330))
        constraints.append(mailTextField.centerXAnchor.constraint(equalTo: view.centerXAnchor))
        constraints.append(mailTextField.widthAnchor.constraint(equalToConstant: 200))
        constraints.append(mailTextField.heightAnchor.constraint(equalToConstant: 50))
        NSLayoutConstraint.activate(constraints)
    }
    
    private func setUpPasswordTextField()
    {
        view.addSubview(passwordTextField)
        
        passwordTextField.text = "Enter password here"
        passwordTextField.borderStyle = .line
        passwordTextField.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            passwordTextField.topAnchor.constraint(equalTo: mailTextField.topAnchor, constant: 80),
            passwordTextField.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            passwordTextField.widthAnchor.constraint(equalToConstant: 200),
            passwordTextField.heightAnchor.constraint(equalToConstant: 50)
        ])
    }
  
    override func viewDidLoad()
    {
        super.viewDidLoad()
        
        setUpNextButton()
        setUpMailTextField()
        setUpPasswordTextField()
        
        view.backgroundColor = .white
        title = "Sign in"
        
        navigationController?.navigationBar.prefersLargeTitles = true
    }
    
    private func setUpNextButton()
    {
        view.addSubview(nextButton)
        
        nextButton.configuration = .filled()
        nextButton.configuration?.title = "Sign up"
        nextButton.configuration?.baseBackgroundColor = .systemPink
        nextButton.translatesAutoresizingMaskIntoConstraints = false
        nextButton.addTarget(self, action: #selector(segueToSignUpVC), for: .touchUpInside)
        
        NSLayoutConstraint.activate([
            nextButton.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -100.0),
            nextButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            nextButton.widthAnchor.constraint(equalToConstant: 200),
            nextButton.heightAnchor.constraint(equalToConstant: 50)
        ])
    }
    
    @objc func segueToSignUpVC() {
        let signUpVC = SignUpViewController()
        navigationController?.pushViewController(signUpVC, animated: true)
    }

}
