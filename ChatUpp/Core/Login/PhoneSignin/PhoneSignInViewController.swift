//
//  PhoneSignInViewController.swift
//  ChatUpp
//
//  Created by Andrei Pripa on 11/28/23.
//

import UIKit
import FlagPhoneNumber

class PhoneSignInViewController: UIViewController , UITextFieldDelegate {
    
    weak var coordinator: Coordinator!
    
    let phoneViewModel = PhoneSignInViewModel()
    let customizedFPNTextField = CustomFPNTextField()
    let receiveMessageButton = CustomizedShadowButton()
    var isPhoneNumberValid: Bool = false
    
    let listController: FPNCountryListViewController = FPNCountryListViewController(style: .grouped)
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = #colorLiteral(red: 0.8039215803, green: 0.8039215803, blue: 0.8039215803, alpha: 1)
//        Utilities.adjustNavigationBarAppearance()
        setupPhoneTextField()
        setupListController()
        setupListControllerNavigationBarAppearance()
        setupReceiveMessageButton()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        Utilities.setGradientBackground(forView: view)
//        navigationController?.setNavigationBarHidden(false, animated: true)
    }
    
    func setupPhoneTextField() {
        view.addSubview(customizedFPNTextField)
        
        customizedFPNTextField.delegate = self
        customizedFPNTextField.borderStyle = .roundedRect
        customizedFPNTextField.displayMode = .list
        
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleTap(_:)))
        customizedFPNTextField.addGestureRecognizerToDialCode(tapGesture)
        
        customizedFPNTextField.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            customizedFPNTextField.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            customizedFPNTextField.topAnchor.constraint(equalTo: view.topAnchor, constant: 250),
            customizedFPNTextField.widthAnchor.constraint(equalToConstant: view.bounds.width * 0.7),
            customizedFPNTextField.heightAnchor.constraint(equalToConstant: 45)
        ])
        
//        customizedFPNTextField.applyShadows()
    }
    
    @objc func handleTap(_ sender: UITapGestureRecognizer) {
        presentListViewController()
    }
    
    func setupReceiveMessageButton() {
        view.addSubview(receiveMessageButton)
       
        receiveMessageButton.configuration?.title = "Receive message"
        receiveMessageButton.addTarget(self, action: #selector(receiveMessageButtonWasTapped), for: .touchUpInside)
        
        receiveMessageButton.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            receiveMessageButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            receiveMessageButton.topAnchor.constraint(equalTo: customizedFPNTextField.bottomAnchor, constant: 30),
            receiveMessageButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 73),
            receiveMessageButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -73),
            receiveMessageButton.heightAnchor.constraint(equalToConstant: 40)
        ])
    }
    
    @objc func receiveMessageButtonWasTapped() {
        guard isPhoneNumberValid, let number = customizedFPNTextField.getFormattedPhoneNumber(format: .E164) else { presentInvalidNumberAlert() ; return}
        Task {
            do {
                try await phoneViewModel.sendSmsToPhoneNumber(number)
                coordinator.pushPhoneCodeVerificationViewController(phoneViewModel: self.phoneViewModel)
            } catch {
                print("error sending sms to phone number: ", error.localizedDescription)
            }
        }
    }
    
    // INVALID NUMBER ALERT
    func presentInvalidNumberAlert() {
        let alert = UIAlertController(title: "Alert", message: "Please enter a valid phone number", preferredStyle: .alert)
        let okAction = UIAlertAction(title: "OK", style: .cancel)
        alert.addAction(okAction)
        present(alert, animated: true)
    }
    
    // FPN LIST VC SETUP
    func setupListController() {
        listController.setup(repository: customizedFPNTextField.countryRepository)
        listController.didSelect = { [weak self] country in
            self?.customizedFPNTextField.setFlag(countryCode: country.code)
        }
        listController.tableView.backgroundColor = #colorLiteral(red: 0.8039215803, green: 0.8039215803, blue: 0.8039215803, alpha: 1)
    }
    
    func setupListControllerNavigationBarAppearance() {
        let appearance = UINavigationBarAppearance()
        appearance.backgroundColor = #colorLiteral(red: 0.8039215803, green: 0.8039215803, blue: 0.8039215803, alpha: 1)
        listController.navigationController?.navigationBar.backgroundColor = #colorLiteral(red: 0.8039215803, green: 0.8039215803, blue: 0.8039215803, alpha: 1)
        listController.navigationController?.navigationBar.standardAppearance = appearance
        listController.navigationController?.navigationBar.scrollEdgeAppearance = appearance
    }
    
   // TEXTFIELD DELEGATE
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        customizedFPNTextField.resignFirstResponder()
        return true
    }
}

//MARK: - FPNTextField Delegate
extension PhoneSignInViewController: FPNTextFieldDelegate {
    func fpnDidSelectCountry(name: String, dialCode: String, code: String) {}
    
    func fpnDidValidatePhoneNumber(textField: FlagPhoneNumber.FPNTextField, isValid: Bool) {
        isPhoneNumberValid = isValid
    }
    func presentListViewController() {
        let navigationViewController = UINavigationController(rootViewController: listController)
//        navigationViewController.title = "Countries"
        setupListControllerNavigationBarAppearance()
        self.present(navigationViewController, animated: true)
    }
    func fpnDisplayCountryList() {
        presentListViewController()
    }
}

//MARK: - FPN LIST VC CELL CUSTOMIZATION
extension FPNCountryListViewController {
    open override func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        cell.backgroundColor = #colorLiteral(red: 0.8039215803, green: 0.8039215803, blue: 0.8039215803, alpha: 1)
    }
}

