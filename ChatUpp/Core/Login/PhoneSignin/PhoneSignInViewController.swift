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
        view.backgroundColor = #colorLiteral(red: 0.1411764771, green: 0.3960784376, blue: 0.5647059083, alpha: 1)
//        Utilities.adjustNavigationBarAppearance()
        setupPhoneTextField()
        setupReceiveMessageButton()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
//        navigationController?.setNavigationBarHidden(false, animated: true)
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
//            phoneTextField.widthAnchor.constraint(equalToConstant: 250),
//            phoneTextField.heightAnchor.constraint(equalToConstant: 40)
            
            phoneTextField.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 43),
            phoneTextField.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -43),
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
            receiveMessageButton.topAnchor.constraint(equalTo: phoneTextField.bottomAnchor, constant: 30),
//            receiveMessageButton.widthAnchor.constraint(equalToConstant: 200),
//            receiveMessageButton.heightAnchor.constraint(equalToConstant: 40)
            
            receiveMessageButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 43),
            receiveMessageButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -43),
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
