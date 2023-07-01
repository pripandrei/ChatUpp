//
//  SignUpViewController.swift
//  ChatUpp
//
//  Created by Andrei Pripa on 6/29/23.
//

import UIKit

class SignUpViewController: UIViewController, UITextFieldDelegate {
    
    private let stackView = UIStackView()
    
    private let signUpButton = UIButton()

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Sign Up"
        view.backgroundColor = .white
        configureStackView()
        setStackViewConstraints()
        setSignUpButton()
    }
    
    lazy var textFields: [UITextField] =
    {
        let numberOfTextFields = 4
        var fields = [UITextField]()
        let textFieldTitles = ["Your firstName", "Your lastName", "Your mail", "Your password"]
        
        for number in 1...numberOfTextFields {
            let textField = CustomTextField()
            textField.tag = number
            textField.delegate = self
            textField.text = textFieldTitles[number - 1]
            fields.append(textField)
        }
        return fields
    }()
    
    private func configureStackView() {
        view.addSubview(stackView)
        
        textFields.forEach { field in
            stackView.addArrangedSubview(field)
        }
        stackView.axis = .vertical
        stackView.distribution = .fillEqually
        stackView.spacing = 20
    }
    
    private func setStackViewConstraints() {
        stackView.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            stackView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            stackView.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            stackView.widthAnchor.constraint(equalToConstant: 300),
            stackView.heightAnchor.constraint(equalToConstant: 260)
        ])
    }
    
    private func setSignUpButton() {
        view.addSubview(signUpButton)
        
        signUpButton.configuration = .filled()
        signUpButton.configuration?.title = "Sign Up"
        signUpButton.configuration?.baseBackgroundColor = .systemPink
        signUpButton.translatesAutoresizingMaskIntoConstraints = false
        signUpButton.addTarget(self, action: #selector(finishRegistration), for: .touchUpInside)
        
        NSLayoutConstraint.activate([
            signUpButton.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -100.0),
            signUpButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            signUpButton.widthAnchor.constraint(equalToConstant: 200),
            signUpButton.heightAnchor.constraint(equalToConstant: 50)
        ])
    }
    
    @objc func finishRegistration() {
        navigationController?.dismiss(animated: true)
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
        borderStyle = .roundedRect
        translatesAutoresizingMaskIntoConstraints = false
    }
}
