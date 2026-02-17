//
//  MailSignInViewController.swift
//  ChatUpp
//
//  Created by Andrei Pripa on 12/7/23.
//

import UIKit
import NVActivityIndicatorView

final class MailSignInViewController: UIViewController {
    
    private var loginViewModel: LoginViewModel!
    private let stackView = UIStackView()
    private var mailLogInField = CustomizedShadowTextField()
    private var passwordLogInField = CustomizedShadowTextField()
    private let logInButton = CustomizedShadowButton(shadowType: .bodyItem)
    private let envelopeLogo = UIImageView()
    private let signInWithEmailLabel = UILabel()
    
    lazy private var textFieldValidator = CredentialsValidator(
        mailField: mailLogInField,
        passwordField: passwordLogInField,
        validator: loginViewModel
    )
    
    deinit
    {
//       print("MailSignInViewController deinit")
    }
    
    private(set) lazy var activityIndicator: NVActivityIndicatorView = {
        let activityIndicator = NVActivityIndicatorView(frame: CGRect(x: 0, y: 0, width: 40, height: 40),
                                                        type: .circleStrokeSpin,
                                                        color: .link,
                                                        padding: 2)
        activityIndicator.translatesAutoresizingMaskIntoConstraints = false
        return activityIndicator
    }()
    
    init(viewModel: LoginViewModel) {
        super.init(nibName: nil, bundle: nil)
        self.loginViewModel = viewModel
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
//        view.backgroundColor = #colorLiteral(red: 0.1411764771, green: 0.3960784376, blue: 0.5647059083, alpha: 1)
        
        configureStackView()
        setupMailTextField()
        setupPasswordTextField()
        setupLogInButton()
        setupEnvelopeImage()
        configureSignInWithEmailLabel()
        setupActivityIndicatorConstraint()
        Utilities.setGradientBackground(forView: view)
    }

    
    private func setupEnvelopeImage() {
        view.addSubview(envelopeLogo)
        
        let image = UIImage(named: "envelope_4")
        envelopeLogo.image = image
        
        envelopeLogo.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            envelopeLogo.topAnchor.constraint(equalTo: view.topAnchor, constant: 35),
            envelopeLogo.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            envelopeLogo.heightAnchor.constraint(equalToConstant: 180),
            envelopeLogo.widthAnchor.constraint(equalToConstant: 210),
        ])
    }
    
    private func configureSignInWithEmailLabel() {
        view.addSubview(signInWithEmailLabel)
        
        signInWithEmailLabel.text = "Sign in with email"
        signInWithEmailLabel.textColor = #colorLiteral(red: 0.8817898337, green: 0.8124251547, blue: 0.8326097798, alpha: 1)
        signInWithEmailLabel.font =  UIFont.boldSystemFont(ofSize: 20)
        
        signInWithEmailLabel.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            signInWithEmailLabel.topAnchor.constraint(equalTo: envelopeLogo.bottomAnchor, constant: -3),
            signInWithEmailLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
        ])        
    }
    
    private func configureStackView() {
        view.addSubview(stackView)
        
        stackView.axis = .vertical
        stackView.distribution = .fillEqually
        stackView.spacing = 20
        
        stackView.addArrangedSubview(mailLogInField)
        stackView.addArrangedSubview(passwordLogInField)
        
        setStackViewConstraints()
    }
    
    private func setStackViewConstraints() {
        stackView.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            stackView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            stackView.topAnchor.constraint(equalTo: view.topAnchor, constant: 260),
            stackView.heightAnchor.constraint(equalToConstant: 120),
            stackView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 40),
            stackView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -40)
        ])
    }
    
    private func setupMailTextField() {
//        view.addSubview(mailLogInField)
        
        mailLogInField.delegate = textFieldValidator
        mailLogInField.placeholder = "Enter mail here"
        mailLogInField.borderStyle = .roundedRect
        mailLogInField.translatesAutoresizingMaskIntoConstraints = false
    }

    private func setupPasswordTextField()
    {
//        view.addSubview(passwordLogInField)

        passwordLogInField.delegate = textFieldValidator
        passwordLogInField.placeholder = "Enter password here"
        passwordLogInField.borderStyle = .roundedRect
        passwordLogInField.translatesAutoresizingMaskIntoConstraints = false
    }
    
    private func setupLogInButton()
    {
        view.addSubview(logInButton)
        
        logInButton.configuration?.title = "Log in"
        logInButton.addTarget(self, action: #selector(logInButtonTap), for: .touchUpInside)
        
        setLogInConstraints()
    }
    
    private func setLogInConstraints()
    {
        logInButton.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            logInButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            logInButton.topAnchor.constraint(equalTo: stackView.bottomAnchor, constant: 35),
            logInButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 73),
            logInButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -73),
            //            logIn.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -100.0),
//            logInButton.widthAnchor.constraint(equalToConstant: 200),
            logInButton.heightAnchor.constraint(equalToConstant: 40)
        ])
    }
    
    @objc func logInButtonTap()
    {
        let isValide = textFieldValidator.validate()

        if isValide
        {
            resignCurrentFirstResponder()
            activityIndicator.startAnimating()
            loginViewModel.signInWithEmail()
        }
    }
    
    private func setupActivityIndicatorConstraint()
    {
        view.addSubview(activityIndicator)
        
        NSLayoutConstraint.activate([
            activityIndicator.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            activityIndicator.topAnchor.constraint(equalTo: logInButton.bottomAnchor, constant: 25)
        ])
    }
    
    private func resignCurrentFirstResponder()
    {
        if mailLogInField.isFirstResponder
        {
            mailLogInField.resignFirstResponder()
        }
        if passwordLogInField.isFirstResponder
        {
            passwordLogInField.resignFirstResponder()
        }
    }
}


