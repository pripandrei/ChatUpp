//
//  SignUpViewController.swift
//  ChatUpp
//
//  Created by Andrei Pripa on 6/29/23.
//

import UIKit
import FirebaseAuth

class SignUpViewController: UIViewController, UITextFieldDelegate {
    
    private var signUpViewModel = SignUpViewModel()
    
    private let stackView = UIStackView()
    private let signUpButton = UIButton()

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Sign Up"
        view.backgroundColor = .white
        configureStackView()
        setStackViewConstraints()
        setSignUpButton()
        let ad = ObservableObject(value: 4)
        print(ad.value)
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
    
    @objc func finishRegistration() {
        
        let textFieldsContainText = textFields.allSatisfy { textField in
            guard let text = textField.text, !text.isEmpty else {
                return false
            }
            
            guard let textField = RegistrationTextfields(rawValue: textField.tag) else {
                return false
            }
            
            switch textField {
            case .email: signUpViewModel.email = text
            case .password:
                if text.count < 6 { return false }
                signUpViewModel.password = text
            default: break
            }
            
//            switch textField.tag {
//            case 3: email = text
//            case 4:
//                if text.count < 6 { return false }
//                password = text
//            default: break
//            }
            return true
        }
        
        if let navigationController = navigationController, textFieldsContainText  {
            signUpViewModel.signUp()
            navigationController.popViewController(animated: true)
        }
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
    }
    
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        print("Letter Entered")
        return true
    }
}

final class SignUpViewModel {
    var email: String = ""
    var password: String = ""
    var textField = UITextField()
    
    func signUp() {
        Auth.auth().createUser(withEmail: email, password: password) { authResult, error in
            guard let result = authResult, error == nil else {
                fatalError("There was an error creating a user")
            }
            print(result.user)
        }
    }
}

enum RegistrationTextfields: Int {
    case name = 1, familyName, email, password
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

final class ObservableObject<T> {
    var value: T {
        didSet {
            listiner?(value)
        }
    }
    
    var listiner: ((T) -> Void)?
    
    init(value: T) {
        self.value = value
    }
    
    func bind(_ listiner: @escaping((T) -> Void)) {
        self.listiner = listiner
        listiner(value)
    }
}
