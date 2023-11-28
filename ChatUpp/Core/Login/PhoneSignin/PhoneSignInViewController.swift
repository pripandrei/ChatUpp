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
    let smsTextField = UITextField()
    let receiveMessageButton = UIButton()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
        setupSMSTextField()
        setupReceiveMessageButton()
    }
    
    func setupSMSTextField() {
        view.addSubview(smsTextField)
        
        smsTextField.delegate = self
        smsTextField.placeholder = "enter phone number"
        smsTextField.borderStyle = .roundedRect
        
        smsTextField.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            smsTextField.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            smsTextField.topAnchor.constraint(equalTo: view.topAnchor, constant: 250),
            smsTextField.widthAnchor.constraint(equalToConstant: 200),
            smsTextField.heightAnchor.constraint(equalToConstant: 40)
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
    
    @objc func receiveMessageButtonWasTapped() {
        guard let text = smsTextField.text, !text.isEmpty else {return}
        
        print(text)
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        smsTextField.resignFirstResponder()
        return true
    }
    
//    func textFieldDidBeginEditing(_ textField: UITextField) {
//        print("begin")
//    }
}
