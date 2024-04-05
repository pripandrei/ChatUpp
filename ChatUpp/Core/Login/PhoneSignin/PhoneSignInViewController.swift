//
//  PhoneSignInViewController.swift
//  ChatUpp
//
//  Created by Andrei Pripa on 11/28/23.
//

import UIKit
import FlagPhoneNumber


protocol TextViewShadowConfigurable {
    func setupTopShadow()
    func setupBottomShadow()
}

extension TextViewShadowConfigurable where Self: UITextField
{
    func setupTopShadow() {
        self.borderStyle = .none
        self.layer.cornerRadius = self.intrinsicContentSize.height/2
        self.layer.borderWidth = 1.5
        self.layer.borderColor = #colorLiteral(red: 0.822324276, green: 0.8223242164, blue: 0.8223242164, alpha: 1)
        self.backgroundColor = #colorLiteral(red: 0.7896713614, green: 0.7896713614, blue: 0.7896713614, alpha: 1)
        
        let innerShadow = CALayer()
        innerShadow.frame = self.bounds
        
        // Shadow path (1pt ring around bounds)
        let radius = self.intrinsicContentSize.height/2
        let path = UIBezierPath(roundedRect: innerShadow.bounds.insetBy(dx: -7, dy: -7), cornerRadius: radius)
        let cutout = UIBezierPath(roundedRect: innerShadow.bounds, cornerRadius: radius).reversing()
        
        path.append(cutout)
        
        innerShadow.shadowPath = path.cgPath
        innerShadow.masksToBounds = true
        
        // Shadow properties
        innerShadow.shadowColor = #colorLiteral(red: 0.2635404468, green: 0.2457663417, blue: 0.2927972674, alpha: 1)
        innerShadow.shadowOffset = CGSize(width: 3.5, height: 3.5)
        innerShadow.shadowOpacity = 0.7
        innerShadow.shadowRadius = 1.8
        innerShadow.cornerRadius = self.intrinsicContentSize.height/2
        self.layer.addSublayer(innerShadow)
    }
    
    func setupBottomShadow() {
        let shadowLayer = CALayer()
        //
        shadowLayer.frame = self.bounds
        shadowLayer.shadowColor = #colorLiteral(red: 0.8560417295, green: 0.8963857889, blue: 0.8623355031, alpha: 1).cgColor
        shadowLayer.shadowOffset = CGSize(width: 1.0, height: 1.0)
        shadowLayer.shadowOpacity = 0.7
        shadowLayer.shadowRadius = 1.3
        shadowLayer.masksToBounds = true
        shadowLayer.cornerRadius = self.intrinsicContentSize.height/2
        //        shadowLayer.borderWidth = 1
        
        // Adjust the position of the shadow to the bottom right
        let radius = self.intrinsicContentSize.height/2
        let shadowPath = UIBezierPath(roundedRect: shadowLayer.bounds.offsetBy(dx: -3.5, dy: -3.5), cornerRadius: radius)
        let cutout = UIBezierPath(roundedRect: shadowLayer.bounds, cornerRadius: radius).reversing()
        
        shadowPath.append(cutout)
        shadowLayer.shadowPath = shadowPath.cgPath
        //        layoutIfNeeded()
        self.layer.addSublayer(shadowLayer)
    }
}


class PhoneSignInViewController: UIViewController , UITextFieldDelegate {
    
    weak var coordinator: Coordinator!
    
    let phoneViewModel = PhoneSignInViewModel()
    let phoneNumberTextField = CustomizedShadowTextField()
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
        view.addSubview(phoneNumberTextField)
        
        phoneNumberTextField.delegate = self
//        phoneNumberTextField.placeholder = "enter phone number"
        phoneNumberTextField.borderStyle = .roundedRect
        
        phoneNumberTextField.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            phoneNumberTextField.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            phoneNumberTextField.topAnchor.constraint(equalTo: view.topAnchor, constant: 250),
            phoneNumberTextField.widthAnchor.constraint(equalToConstant: view.bounds.width * 0.7),
            phoneNumberTextField.heightAnchor.constraint(equalToConstant: 45)
        ])
        
        phoneNumberTextField.layoutIfNeeded()
        phoneNumberTextField.setupTopShadow()
        phoneNumberTextField.setupBottomShadow()
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
            receiveMessageButton.topAnchor.constraint(equalTo: phoneNumberTextField.bottomAnchor, constant: 30),
//            receiveMessageButton.widthAnchor.constraint(equalToConstant: 200),
//            receiveMessageButton.heightAnchor.constraint(equalToConstant: 40)
            
            receiveMessageButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 43),
            receiveMessageButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -43),
            receiveMessageButton.heightAnchor.constraint(equalToConstant: 40)
        ])
    }

    @objc func receiveMessageButtonWasTapped() {
        guard let number = phoneNumberTextField.text, !number.isEmpty else {return}
        
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
        phoneNumberTextField.resignFirstResponder()
        return true
    }
}

    //MARK: - CUSTOMIZED TEXTFIELD WITH SHADOWS

class CustomizedShadowTextField: UITextField, TextViewShadowConfigurable {
    
//    convenience init() {
//        self.init(frame: .zero)
//        
//    }
//    override init(frame: CGRect) {
//        super.init(frame: frame)
//    }
//    required init?(coder: NSCoder) {
//        fatalError("init(coder:) has not been implemented")
//    }
//    
    
//    func setupShadows() {
//        setupTopShadow()
//        setupBottomShadow()
//    }
//
//    private func setupTopShadow() {
//        self.borderStyle = .none
//        self.layer.cornerRadius = self.intrinsicContentSize.height/2
//        self.layer.borderWidth = 1.5
//        self.layer.borderColor = #colorLiteral(red: 0.822324276, green: 0.8223242164, blue: 0.8223242164, alpha: 1)
//        self.backgroundColor = #colorLiteral(red: 0.7896713614, green: 0.7896713614, blue: 0.7896713614, alpha: 1)
//
//        let innerShadow = CALayer()
//        innerShadow.frame = self.bounds
//
//        // Shadow path (1pt ring around bounds)
//        let radius = self.intrinsicContentSize.height/2
//        let path = UIBezierPath(roundedRect: innerShadow.bounds.insetBy(dx: -7, dy: -7), cornerRadius: radius)
//        let cutout = UIBezierPath(roundedRect: innerShadow.bounds, cornerRadius: radius).reversing()
//
//        path.append(cutout)
//
//        innerShadow.shadowPath = path.cgPath
//        innerShadow.masksToBounds = true
//
//        // Shadow properties
//        innerShadow.shadowColor = #colorLiteral(red: 0.2635404468, green: 0.2457663417, blue: 0.2927972674, alpha: 1)
//        innerShadow.shadowOffset = CGSize(width: 3.5, height: 3.5)
//        innerShadow.shadowOpacity = 0.7
//        innerShadow.shadowRadius = 1.8
//        innerShadow.cornerRadius = self.intrinsicContentSize.height/2
//        self.layer.addSublayer(innerShadow)
//    }
//
//    private func setupBottomShadow() {
//        let shadowLayer = CALayer()
//
//        shadowLayer.frame = self.bounds
//        shadowLayer.shadowColor = #colorLiteral(red: 0.8560417295, green: 0.8963857889, blue: 0.8623355031, alpha: 1).cgColor
//        shadowLayer.shadowOffset = CGSize(width: 1.0, height: 1.0)
//        shadowLayer.shadowOpacity = 0.7
//        shadowLayer.shadowRadius = 1.3
//        shadowLayer.masksToBounds = true
//        shadowLayer.cornerRadius = self.intrinsicContentSize.height/2
//        //        shadowLayer.borderWidth = 1
//
//        // Adjust the position of the shadow to the bottom right
//        let radius = self.intrinsicContentSize.height/2
//        let shadowPath = UIBezierPath(roundedRect: shadowLayer.bounds.offsetBy(dx: -3.5, dy: -3.5), cornerRadius: radius)
//        let cutout = UIBezierPath(roundedRect: shadowLayer.bounds, cornerRadius: radius).reversing()
//
//        shadowPath.append(cutout)
//        shadowLayer.shadowPath = shadowPath.cgPath
////        layoutIfNeeded()
//        self.layer.addSublayer(shadowLayer)
//    }
}



