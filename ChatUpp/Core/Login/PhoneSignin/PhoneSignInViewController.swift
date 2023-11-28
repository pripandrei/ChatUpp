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
    let smsTextField = UITextField()
    let receiveMessageButton = UIButton()
    let verifyMessageButton = UIButton()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
        setupPhoneTextField()
        setupSmsTextField() 
        setupReceiveMessageButton()
        setupVerifyMessageButton()
    }
    
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
    
    func setupSmsTextField() {
        view.addSubview(smsTextField)
        
        smsTextField.delegate = self
        smsTextField.placeholder = "enter sms number"
        smsTextField.borderStyle = .roundedRect
        
        smsTextField.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            smsTextField.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            smsTextField.topAnchor.constraint(equalTo: phoneTextField.bottomAnchor, constant: 40),
            smsTextField.widthAnchor.constraint(equalToConstant: 200),
            smsTextField.heightAnchor.constraint(equalToConstant: 30)
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
            receiveMessageButton.topAnchor.constraint(equalTo: smsTextField.bottomAnchor, constant: 50),
            receiveMessageButton.widthAnchor.constraint(equalToConstant: 200),
            receiveMessageButton.heightAnchor.constraint(equalToConstant: 40)
        ])
    }
    
    
    func setupVerifyMessageButton() {
        view.addSubview(verifyMessageButton)
       
        verifyMessageButton.configuration = .filled()
        verifyMessageButton.configuration?.title = "Verify"
        verifyMessageButton.addTarget(self, action: #selector(verifyMessageButtonWasTapped), for: .touchUpInside)
        
        verifyMessageButton.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            verifyMessageButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            verifyMessageButton.topAnchor.constraint(equalTo: receiveMessageButton.bottomAnchor, constant: 30),
            verifyMessageButton.widthAnchor.constraint(equalToConstant: 200),
            verifyMessageButton.heightAnchor.constraint(equalToConstant: 40)
        ])
    }
    
    @objc func receiveMessageButtonWasTapped() {
        guard let text = phoneTextField.text, !text.isEmpty else {return}
        
        
    }
    
    @objc func verifyMessageButtonWasTapped() {
        
    }
    
    
    
   //MARK: - TEXTFIELD DELEGATE
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        phoneTextField.resignFirstResponder()
        return true
    }
    
//    func textFieldDidBeginEditing(_ textField: UITextField) {
//        print("begin")
//    }
}
