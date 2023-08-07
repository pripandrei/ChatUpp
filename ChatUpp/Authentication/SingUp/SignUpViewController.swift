//
//  SignUpViewController.swift
//  ChatUpp
//
//  Created by Andrei Pripa on 6/29/23.
//

import UIKit
import FirebaseAuth

class SignUpViewController: UIViewController, UITextFieldDelegate {
    
    private var signUpViewModel = SignUpEmailViewModel()
    
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
            textField.placeholder = textFieldTitles[number - 1]
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
    
    @objc func finishRegistration()
    {
        signUpViewModel.validateTextFields(using: textFields)
        
        if let navigationController = navigationController  {
            signUpViewModel.signUp() { registrationComplition in
                if registrationComplition == .success {
                    navigationController.popViewController(animated: true)
                    navigationController.dismiss(animated: true)
                }
            }
            
        }
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
    }
//
//    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
//        print("Letter Entered")
//        return true
//    }
}

enum UserRegistrationStatus {
    case success
    case failure
}

// MARK: - SignUpEmailViewModel

final class SignUpEmailViewModel {
    var email: String = ""
    var password: String = ""
    
    func validateTextFields(using textFields: [UITextField]) {
        for textField in textFields {
            guard let text = textField.text, !text.isEmpty else {
                print("\(RegistrationTextfields.allCases[textField.tag]) field is empty!")
                return
            }
            
            guard let textField = RegistrationTextfields(rawValue: textField.tag) else {
                return
            }
            
            switch textField {
            case .email: email = text
            case .password:
                if text.count < 6 {
                    print("password must contain > 6 character")
                    return
                }
                password = text
            default: break
            }
        }
    }
    
    func signUp(complition: @escaping (UserRegistrationStatus) -> Void) {
        AuthenticationManager.shared.createUser(email: email, password: password) { authDataResult in
            guard let authDataResult else {
                print("No authDataResult == nil")
                complition(.failure)
                return
            }
        
            complition(.success)
            print("Success!")
            print(authDataResult)
        }
    }
}

// MARK: - TextField initial setup

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


enum RegistrationTextfields: Int, CaseIterable {
    case name = 1, familyName, email, password
}
