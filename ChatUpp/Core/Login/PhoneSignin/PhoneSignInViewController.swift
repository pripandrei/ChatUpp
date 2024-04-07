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
    let receiveMessageButton = UIButton()
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
        
        customizedFPNTextField.layoutIfNeeded()
        customizedFPNTextField.setupTopShadow()
        customizedFPNTextField.setupBottomShadow()
    }
    
    @objc func handleTap(_ sender: UITapGestureRecognizer) {
        presentListViewController()
    }
    
    func setupReceiveMessageButton() {
        view.addSubview(receiveMessageButton)
       
        receiveMessageButton.configuration = .filled()
        receiveMessageButton.configuration?.title = "Receive message"
        receiveMessageButton.addTarget(self, action: #selector(receiveMessageButtonWasTapped), for: .touchUpInside)
        
        receiveMessageButton.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            receiveMessageButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            receiveMessageButton.topAnchor.constraint(equalTo: customizedFPNTextField.bottomAnchor, constant: 30),
            receiveMessageButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 43),
            receiveMessageButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -43),
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


//MARK: - CUSTOMIZED FLAG PHONE NUMBER TEXTFIELD
class CustomFPNTextField: FPNTextField, TextViewShadowConfigurable {
    
    private let separatorBetweenDialCodeAndTextPhone: UIView = UIView()
    
    var dialCodeAndFlagButtonMainContainer: UIView? {
        return flagButton.superview
    }
    
    convenience init() {
        self.init(frame: .zero)
        
        setupSeparator()
        moveRightDialCodeAndFlagButtonMainContainer()
    }
    override init(frame: CGRect) {
        super.init(frame: frame)
    }
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // GESTURES
    func addGestureRecognizerToDialCode(_ tapGestureRecognizer: UITapGestureRecognizer) {
        dialCodeAndFlagButtonMainContainer?.addGestureRecognizer(tapGestureRecognizer)
    }
    
    // TEXTVIEW UI SETUP
    private func moveRightDialCodeAndFlagButtonMainContainer() {
        dialCodeAndFlagButtonMainContainer?.subviews.forEach({ view in
            view.transform = CGAffineTransform(translationX: 5, y: 0)
        })
    }
    
    func setupSeparator() {
        dialCodeAndFlagButtonMainContainer?.addSubview(separatorBetweenDialCodeAndTextPhone)
        separatorBetweenDialCodeAndTextPhone.backgroundColor = .black
        
        separatorBetweenDialCodeAndTextPhone.translatesAutoresizingMaskIntoConstraints = false
        
        separatorBetweenDialCodeAndTextPhone.widthAnchor.constraint(equalToConstant: 1).isActive = true
        separatorBetweenDialCodeAndTextPhone.heightAnchor.constraint(equalToConstant: self.intrinsicContentSize.height).isActive = true
        separatorBetweenDialCodeAndTextPhone.leadingAnchor.constraint(equalTo: dialCodeAndFlagButtonMainContainer!.trailingAnchor, constant: 8).isActive = true
        separatorBetweenDialCodeAndTextPhone.centerYAnchor.constraint(equalTo: dialCodeAndFlagButtonMainContainer!.centerYAnchor).isActive = true
    }
}

//MARK: - TEXTFIELD TEXT RECT ADJUST
extension CustomFPNTextField {
    open override func textRect(forBounds bounds: CGRect) -> CGRect {
        var rect = super.textRect(forBounds: bounds)
        rect.origin.x += 20
        rect.size.width -= 30
        return rect
    }
    open override func editingRect(forBounds bounds: CGRect) -> CGRect {
        return textRect(forBounds: bounds)
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



