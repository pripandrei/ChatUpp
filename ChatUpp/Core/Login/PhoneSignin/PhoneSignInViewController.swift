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
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = #colorLiteral(red: 0.8039215803, green: 0.8039215803, blue: 0.8039215803, alpha: 1)
//        Utilities.adjustNavigationBarAppearance()
        setupPhoneTextField()
        setupReceiveMessageButton()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
//        navigationController?.setNavigationBarHidden(false, animated: true)
    }
    
    func setupPhoneTextField() {
        view.addSubview(customizedFPNTextField)
        
        customizedFPNTextField.delegate = self
//        phoneNumberTextField.placeholder = "enter phone number"
        customizedFPNTextField.borderStyle = .roundedRect
        
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
//        phoneNumberTextField.setupShadows()
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
//            receiveMessageButton.widthAnchor.constraint(equalToConstant: 200),
//            receiveMessageButton.heightAnchor.constraint(equalToConstant: 40)
            
            receiveMessageButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 43),
            receiveMessageButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -43),
            receiveMessageButton.heightAnchor.constraint(equalToConstant: 40)
        ])
    }

    @objc func receiveMessageButtonWasTapped() {
        guard let number = customizedFPNTextField.getFormattedPhoneNumber(format: .E164), !number.isEmpty else {return}
        
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
    
    //MARK: - GESTURE
    
    func addGestureRecognizerToDialCode(_ tapGestureRecognizer: UITapGestureRecognizer) {
        dialCodeAndFlagButtonMainContainer?.addGestureRecognizer(tapGestureRecognizer)
    }
    
    //MARK: - TEXTVIEW UI SETUP
    
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
        //        separatorBetweenDialCodeAndTextPhone.centerYAnchor.constraint(equalTo: self.centerYAnchor).isActive = true
        //        separatorBetweenDialCodeAndTextPhone.leadingAnchor.constraint(equalTo: dialCodeView!.trailingAnchor, constant: 7).isActive = true
    }
}


//MARK: - TEXTFIELD TEXTRECT ADJUST
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


