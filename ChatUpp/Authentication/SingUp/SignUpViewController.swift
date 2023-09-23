//
//  SignUpViewController.swift
//  ChatUpp
//
//  Created by Andrei Pripa on 6/29/23.
//

import UIKit
import FirebaseAuth

class SignUpViewController: UIViewController {
    
    private var signUpViewModel = SignUpEmailViewModel()
    private let stackView = UIStackView()
    private let signUpButton = UIButton()
    private var emailSignupField = UITextField()
    private var passwordSignupField = UITextField()
    lazy private var textFieldValidator = EmailCredentialsValidator(mailField: emailSignupField,
                                                                    passwordField: passwordSignupField,
                                                                    viewModel: signUpViewModel)
    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Sign Up"
        view.backgroundColor = .white
        controllerMainConfiguration()
    }
    
    private func controllerMainConfiguration() {
        setEmailSignupField()
        setPasswordSignupField()
        configureStackView()
        setSignUpButton()
    }
    
    private func setEmailSignupField()
    {
        emailSignupField.delegate = textFieldValidator
        emailSignupField.placeholder = "Provide an email"
        emailSignupField.borderStyle = .roundedRect
        emailSignupField.translatesAutoresizingMaskIntoConstraints = false
        
    }
    
    private func setPasswordSignupField()
    {
        passwordSignupField.delegate = textFieldValidator
        passwordSignupField.placeholder = "Provide a password"
        passwordSignupField.borderStyle = .roundedRect
        passwordSignupField.translatesAutoresizingMaskIntoConstraints = false
    }
    
//    lazy var textFields: [UITextField] =
//    {
//        let numberOfTextFields = 4
//        var fields = [UITextField]()
//        let textFieldTitles = ["Your firstName", "Your lastName", "Your mail", "Your password"]
//
//        for number in 1...numberOfTextFields {
//            let textField = CustomTextField()
//            textField.tag = number
//            textField.delegate = self
//            textField.placeholder = textFieldTitles[number - 1]
//            fields.append(textField)
//        }
//        return fields
//    }()
    
    private func configureStackView() {
        view.addSubview(stackView)
        
//        textFields.forEach { field in
//            stackView.addArrangedSubview(field)
//        }
        stackView.axis = .vertical
        stackView.distribution = .fillEqually
        stackView.spacing = 20
        
        stackView.addArrangedSubview(emailSignupField)
        stackView.addArrangedSubview(passwordSignupField)
        
        setStackViewConstraints()
    }
    
    private func setStackViewConstraints() {
        stackView.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            stackView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            stackView.topAnchor.constraint(equalTo: view.topAnchor, constant: 230),
//            stackView.widthAnchor.constraint(equalToConstant: 300),
            stackView.heightAnchor.constraint(equalToConstant: 120),
            stackView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 40),
            stackView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -40)
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
    
    @objc private func finishRegistration()
    {
//        let validationResult = signUpViewModel.validateTextFields(using: textFields)
//        if validationResult == .invalid {
//            return
//        }
        
        if let navigationController = navigationController  {
            signUpViewModel.signUp() { registrationStatus in
                if registrationStatus == .success{
                    let usernameRegistrationVC = UsernameRegistrationViewController()
                    navigationController.pushViewController(usernameRegistrationVC, animated: true)
                }
            }
        }
    }
}

// MARK: - SignUpEmailViewModel

final class SignUpEmailViewModel: EmailValidator {

    var email: String = ""
    var password: String = ""
    
    func validateCredentials() throws {
        
    }
    
    func validateTextFields(using textFields: [UITextField]) -> ValidationStatus {
        for textField in textFields {
            guard let text = textField.text, !text.isEmpty else {
                print("\(RegistrationTextfields.allCases[textField.tag - 1]) field is empty!")
                return .invalid
            }
            
            guard let textField = RegistrationTextfields(rawValue: textField.tag) else {
                return .invalid
            }
            
            switch textField {
            case .email: email = text
            case .password:
                if text.count < 6 {
                    print("password must contain > 6 character")
                    return .invalid
                }
                password = text
            default: break
            }
        }
        return .valid
    }
    
    func signUp(complition: @escaping (UserRegistrationStatus) -> Void) {
        AuthenticationManager.shared.signUpUser(email: email, password: password) { authDataResult in
            guard let authDataResult else {
                print("No authDataResult == nil")
                complition(.failure)
                return
            }
            UserManager.shared.createNewUser(with: authDataResult) { isCreated in
                if isCreated {
                   print("User was created!")
                } else {
                    print("Error creating user")
                }
            }
            complition(.success)
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

enum UserRegistrationStatus {
    case success
    case failure
}


// TODO: - Remove this block after poping name textfields

//    func textFieldDidBeginEditing(_ textField: UITextField) {
//        stackView.translatesAutoresizingMaskIntoConstraints = true
//            animateViewMoving(true, moveValue: 80)
//    }
//
//    func textFieldDidEndEditing(_ textField: UITextField) {
//        stackView.translatesAutoresizingMaskIntoConstraints = false
//            animateViewMoving(false, moveValue: 80)
//    }
//
//    func animateViewMoving(_ up: Bool, moveValue: CGFloat){
//        let movement: CGFloat = (up ? -moveValue : moveValue)
//
//        UIView.animate(withDuration: 0.3, delay: 0.0, animations: {
//            self.stackView.frame = CGRectOffset(self.stackView.frame, 0, movement)
//        })
//    }
