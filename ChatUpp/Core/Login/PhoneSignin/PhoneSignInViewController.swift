//
//  PhoneSignInViewController.swift
//  ChatUpp
//
//  Created by Andrei Pripa on 11/28/23.
//

import UIKit

class PhoneSignInViewController: UIViewController , UITextFieldDelegate {

    weak var coordinator: Coordinator!
    
    let phoneViewModel = PhoneSignInViewModel()
    let phoneTextField = UITextField()
    let receiveMessageButton = UIButton()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
        setupPhoneTextField()
        setupReceiveMessageButton()
    }
    
//    private func setupBinder() {
//        phoneViewModel.loginStatus.bind { [weak self] authStatus in
//            guard let status = authStatus, status == .userIsAuthenticated else {return}
//            guard let self else {return}
////            self?.coordinator.pushUsernameRegistration()
//            self.coordinator.pushPhoneCodeVerificationViewController(phoneViewModel: self.phoneViewModel)
////            self?.navigationController?.dismiss(animated: true)
//        }
//    }
    
    func setupPhoneTextField() {
        view.addSubview(phoneTextField)
        
        phoneTextField.delegate = self
        phoneTextField.placeholder = "enter phone number"
        phoneTextField.borderStyle = .roundedRect
        
        phoneTextField.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            phoneTextField.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            phoneTextField.topAnchor.constraint(equalTo: view.topAnchor, constant: 250),
            phoneTextField.widthAnchor.constraint(equalToConstant: 200),
            phoneTextField.heightAnchor.constraint(equalToConstant: 40)
        ])
    }
    
    func setupReceiveMessageButton() {
        view.addSubview(receiveMessageButton)
       
        receiveMessageButton.configuration = .filled()
        receiveMessageButton.configuration?.title = "Receive message"
        receiveMessageButton.addTarget(self, action: #selector(receiveMessageButtonWasTapped), for: .touchUpInside)
        
        receiveMessageButton.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            receiveMessageButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            receiveMessageButton.topAnchor.constraint(equalTo: phoneTextField.bottomAnchor, constant: 50),
            receiveMessageButton.widthAnchor.constraint(equalToConstant: 200),
            receiveMessageButton.heightAnchor.constraint(equalToConstant: 40)
        ])
    }

    @objc func receiveMessageButtonWasTapped() {
        guard let number = phoneTextField.text, !number.isEmpty else {return}
        
        Task {
            do {
                try await phoneViewModel.sendSmsToPhoneNumber(number)
                coordinator.pushPhoneCodeVerificationViewController(phoneViewModel: self.phoneViewModel)
            } catch {
                print("error sending sms to phone number: ", error.localizedDescription)
            }
        }
    }
    
   //MARK: - TEXTFIELD DELEGATE
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        phoneTextField.resignFirstResponder()
        return true
    }
}
