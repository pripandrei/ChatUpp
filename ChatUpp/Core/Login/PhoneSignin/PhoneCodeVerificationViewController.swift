//
//  PhoneCodeVerificationViewController.swift
//  ChatUpp
//
//  Created by Andrei Pripa on 11/29/23.
//

import UIKit
import NVActivityIndicatorView

final class PhoneCodeVerificationViewController: UIViewController , UITextFieldDelegate {
    
    weak var coordinator: Coordinator!
    
    private var phoneViewModel: PhoneSignInViewModel!
    
    private let smsTextField = CustomizedShadowTextField()
    private let verifyMessageButton = CustomizedShadowButton()
    private let messageCodeLogo = UIImageView()
    private let codeTextLabel = UILabel()
    
    private(set) lazy var activityIndicator: NVActivityIndicatorView = {
        let activityIndicator = NVActivityIndicatorView(frame: CGRect(x: 0, y: 0, width: 40, height: 40),
                                                        type: .circleStrokeSpin,
                                                        color: .link,
                                                        padding: 2)
        activityIndicator.translatesAutoresizingMaskIntoConstraints = false
        return activityIndicator
    }()
    
    convenience init(viewModel: PhoneSignInViewModel) {
        self.init()
        self.phoneViewModel = viewModel
    }

    override func viewDidLoad()
    {
        view.backgroundColor = #colorLiteral(red: 0.8039215803, green: 0.8039215803, blue: 0.8039215803, alpha: 1)
        setupSmsTextField()
        setupVerifySMSButton()
        setupBinder()
        setupPhoneImage()
        configureCodeTextLabel()
        Utilities.setGradientBackground(forView: view)
        setupActivityIndicatorConstraint()
    }
    
    //MARK: - Binding

    private func setupBinder()
    {
        phoneViewModel.userCreationStatus.bind { [weak self] creationStatus in
            guard let status = creationStatus else {return}
            Task { @MainActor in
                if status == .userExists {
                    self?.coordinator.dismissNaviagtionController()
                } else {
                    self?.coordinator.pushUsernameRegistration()
                }
                self?.activityIndicator.stopAnimating()
            }
        }
    }
    
    // loading indicator
    private func setupActivityIndicatorConstraint()
    {
        view.addSubview(activityIndicator)
        
        NSLayoutConstraint.activate([
            activityIndicator.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            activityIndicator.centerYAnchor.constraint(equalTo: view.centerYAnchor, constant: 10)
        ])
    }
    
    private func setupPhoneImage() {
        view.addSubview(messageCodeLogo)
        
        let image = UIImage(named: "message_code_2")
        messageCodeLogo.image = image
        
        messageCodeLogo.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            messageCodeLogo.topAnchor.constraint(equalTo: view.topAnchor, constant: 35),
            messageCodeLogo.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            messageCodeLogo.heightAnchor.constraint(equalToConstant: 190),
            messageCodeLogo.widthAnchor.constraint(equalToConstant: 220),
        ])
    }
    
    private func configureCodeTextLabel() {
        view.addSubview(codeTextLabel)
        
        codeTextLabel.text = "Enter code that you received"
        codeTextLabel.textColor = #colorLiteral(red: 0.8817898337, green: 0.8124251547, blue: 0.8326097798, alpha: 1)
        codeTextLabel.font =  UIFont.boldSystemFont(ofSize: 20)
        
        codeTextLabel.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            codeTextLabel.topAnchor.constraint(equalTo: messageCodeLogo.bottomAnchor, constant: -3),
            codeTextLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
        ])
    }
    
    func setupSmsTextField() {
        view.addSubview(smsTextField)
        
        smsTextField.delegate = self
        smsTextField.placeholder = "code number"
//        smsTextField.borderStyle = .roundedRect
        
        smsTextField.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            smsTextField.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            smsTextField.topAnchor.constraint(equalTo: view.topAnchor, constant: 270),
            smsTextField.heightAnchor.constraint(equalToConstant: 45),
            smsTextField.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 40),
            smsTextField.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -40)
        ])
    }
    
    func setupVerifySMSButton()
    {
        view.addSubview(verifyMessageButton)
       
        verifyMessageButton.configuration?.title = "Verify code"
        verifyMessageButton.addTarget(self, action: #selector(verifySMSButtonWasTapped), for: .touchUpInside)
        
        verifyMessageButton.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            verifyMessageButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            verifyMessageButton.topAnchor.constraint(equalTo: smsTextField.bottomAnchor, constant: 30),
            verifyMessageButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 73),
            verifyMessageButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -73),
            verifyMessageButton.heightAnchor.constraint(equalToConstant: 40)
        ])
    }
    
    @objc func verifySMSButtonWasTapped()
    {
        guard let code = smsTextField.text, !code.isEmpty else {return}
        phoneViewModel.signInViaPhone(usingVerificationCode: code)
        activityIndicator.startAnimating()
    }
}

