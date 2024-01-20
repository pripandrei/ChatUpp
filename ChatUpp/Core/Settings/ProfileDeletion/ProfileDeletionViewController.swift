//
//  ProfileDeletionViewController.swift
//  ChatUpp
//
//  Created by Andrei Pripa on 1/20/24.
//

import UIKit

class ProfileDeletionViewController: UIViewController {
    
    weak var coordinatorDelegate: Coordinator?
    
    lazy var verificationCodeTextField: UITextField = {
        let textField = UITextField()
        textField.placeholder = "Enter code here"
        textField.backgroundColor = .systemFill
        textField.borderStyle = .roundedRect
        textField.font = UIFont(name: "HelveticaNeue", size: 17)
        textField.textColor = .black
        return textField
    }()
    
    lazy var informationLabel: UILabel = {
        let infoLabel = UILabel()
        infoLabel.text = "In order to delete your account, we need to make sure it's you. Verification code will be sent to your phone number."
        infoLabel.textColor = .lightGray
        infoLabel.font =  UIFont(name: "HelveticaNeue", size: 14)
        infoLabel.numberOfLines = 0
        return infoLabel
    }()
    
    lazy var sendCodeButton: UIButton = {
        let button = UIButton()
        button.configuration = .filled()
        button.configuration?.title = "Get Code"
        button.configuration?.background.backgroundColor = .link
        button.layer.cornerRadius = 5
        button.clipsToBounds = true
        return button
    }()
    
    func setupInformationLabelConstraints() {
        informationLabel.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            informationLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            informationLabel.topAnchor.constraint(equalTo: view.topAnchor, constant: view.bounds.size.height / 6),
            informationLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 50),
            informationLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -50),
//            informationLabel.heightAnchor.constraint(equalToConstant: 40),
//            informationLabel.widthAnchor.constraint(equalToConstant: 300),
        ])
    }
    
    func setupTextViewConstraints() {
        verificationCodeTextField.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            verificationCodeTextField.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            verificationCodeTextField.topAnchor.constraint(equalTo: view.topAnchor, constant: view.bounds.size.height / 4),
            verificationCodeTextField.heightAnchor.constraint(equalToConstant: 40),
            verificationCodeTextField.widthAnchor.constraint(equalToConstant: 300),
        ])
    }
    
    func setupSendCodeButtonConstraints() {
        sendCodeButton.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            sendCodeButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            sendCodeButton.topAnchor.constraint(equalTo: view.topAnchor, constant: view.bounds.size.height / 3),
            sendCodeButton.heightAnchor.constraint(equalToConstant: 45),
            sendCodeButton.widthAnchor.constraint(equalToConstant: 100),
        ])
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .clouds
        view.addSubview(sendCodeButton)
        view.addSubview(verificationCodeTextField)
        view.addSubview(informationLabel)
        setupInformationLabelConstraints()
        setupSendCodeButtonConstraints()
        setupTextViewConstraints()
    }
}
