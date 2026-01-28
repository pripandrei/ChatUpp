//
//  ProfileDeletionViewController.swift
//  ChatUpp
//
//  Created by Andrei Pripa on 1/20/24.
//

import UIKit

final class ProfileDeletionViewController: UIViewController
{
    
    weak var coordinatorDelegate: Coordinator?
    var profileDeletionViewModel: ProfileDeletionViewModel!
    
    //MARK: LIFECYCLE

    init(viewModel: ProfileDeletionViewModel)
    {
        super.init(nibName: nil, bundle: nil)
        self.profileDeletionViewModel = viewModel
    }
    
    override func viewDidLoad()
    {
        super.viewDidLoad()
        setupUI()
        setupBinder()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
    
    //MARK: - Binder
    
    func setupBinder() {
        profileDeletionViewModel.userIsSignedOut.bind { [weak self] isSignedOut in
            if isSignedOut == true {
                Task { @MainActor in
                    self?.coordinatorDelegate?.handleSignOut()
                }
            }
        }
    }
    
    //MARK: - SETUP UI

    lazy var informationLabel: UILabel = {
        let infoLabel = UILabel()
        infoLabel.text = "In order to delete your account, we need to make sure it's you. Verification code will be sent to your phone number."
        infoLabel.textColor = .white
        infoLabel.font =  UIFont(name: "HelveticaNeue", size: 18)
        infoLabel.numberOfLines = 0
        return infoLabel
    }()
    
    lazy var verificationCodeTextField: CustomizedShadowTextField = {
        let textField = CustomizedShadowTextField()
        
        let placeholderText = NSAttributedString(string: "Enter code here")
        textField.attributedPlaceholder = placeholderText
        textField.delegate = self
        return textField
    }()
    
    lazy var sendCodeButton: CustomizedShadowButton = {
        let button = CustomizedShadowButton()
        button.configuration?.title = "Get Code"
        button.addTarget(self, action: #selector(sendCodeButtonTapped), for: .touchUpInside)
        return button
    }()
    
    func setupUI()
    {
        view.backgroundColor = ColorScheme.appBackgroundColor
        view.addSubview(sendCodeButton)
        view.addSubview(verificationCodeTextField)
        view.addSubview(informationLabel)
        setupInformationLabelConstraints()
        setupVerificationCodeTextFieldConstraints()
        setupSendCodeButtonConstraints()
    }
    
    //MARK: - SETUP CONSTRAINTS
    
    func setupInformationLabelConstraints() {
        informationLabel.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            informationLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            informationLabel.topAnchor.constraint(equalTo: view.topAnchor, constant: view.bounds.size.height / 12),
            informationLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 50),
            informationLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -50),
        ])
    }
    
    func setupVerificationCodeTextFieldConstraints()
    {
        verificationCodeTextField.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            verificationCodeTextField.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            verificationCodeTextField.topAnchor.constraint(equalTo: view.topAnchor, constant: view.bounds.size.height / 4),
            verificationCodeTextField.heightAnchor.constraint(equalToConstant: 40),
            verificationCodeTextField.widthAnchor.constraint(equalToConstant: 300),
        ])
    }
    
    func setupSendCodeButtonConstraints()
    {
        sendCodeButton.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            sendCodeButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
//            sendCodeButton.topAnchor.constraint(equalTo: view.topAnchor, constant: view.bounds.size.height / 2.8),
            sendCodeButton.topAnchor.constraint(equalTo: verificationCodeTextField.bottomAnchor,
                                                constant: 50),
            sendCodeButton.heightAnchor.constraint(equalToConstant: 40),
            sendCodeButton.widthAnchor.constraint(equalToConstant: 220),
        ])
    }
    
    
    //MARK: - ALERT CONTROLLERS
    
    private func createDeletionAlertController() {
        let alert = UIAlertController(title: "Alert", message: "Delete this account? This acction can not be undone!", preferredStyle: .alert)
        let cancel = UIAlertAction(title: "Cancel", style: .cancel)
        let delete = UIAlertAction(title: "Delete", style: .destructive) { _ in
            Task {
                do {
                    try await self.profileDeletionViewModel.deleteUser()
                    self.profileDeletionViewModel.signOut()
                } catch {
                    print("Error while deleting User!: ", error.localizedDescription)
                }
            }
        }
        alert.addAction(cancel)
        alert.addAction(delete)
        present(alert, animated: true)
    }
    
    private func createIncorectCodeAlertController() {
        let alert = UIAlertController(title: "Alert", message: "Incorect code, please try again!", preferredStyle: .alert)
        let okay = UIAlertAction(title: "OK", style: .default)

        alert.addAction(okay)
        
        present(alert, animated: true)
    }
    
    //MARK: - BUTTON ACTIONS
    
    @objc func deleteAccount()
    {
        guard let code = verificationCodeTextField.text, !code.isEmpty else {return}
        
        Task {
            do {
                try await profileDeletionViewModel.reauthenticateUser(usingCode: code)
                createDeletionAlertController()
            } catch {
                print("Could not reauthenticate via phone code: ", error)
            }
        }
    }
    
    @objc func sendCodeButtonTapped()
    {
        Task
        {
            do {
                try await profileDeletionViewModel.sendSMSCode()
            } catch {
                print("Could not send sms code \(error)")
            }
        }
    }
}

//MARK: - TEXT FIELD DELEGATE

extension ProfileDeletionViewController: UITextFieldDelegate {
    
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool
    {
        guard let code = textField.text, code.count == 5 else {return true}
        guard let text = code as NSString? else {return true}
        
        let updatedText = text.replacingCharacters(in: range, with: string)
        Task {
            do {
                try await profileDeletionViewModel.reauthenticateUser(usingCode: updatedText)
                createDeletionAlertController()
                textField.text = ""
            } catch {
                createIncorectCodeAlertController()
                textField.text = ""
                print("Could not reauthenticate via phone code: ", error)
            }
        }
        return true
    }
}
