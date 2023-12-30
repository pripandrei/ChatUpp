//
//  ViewController.swift
//  ChatUpp
//
//  Created by Andrei Pripa on 6/26/23.
//

import UIKit
import GoogleSignIn


class LoginViewController: UIViewController {
    
    weak var coordinatorDelegate: Coordinator?
    private let loginViewModel = LoginViewModel()
    private let signUpLable: UILabel = UILabel()
    private let signUpButton = UIButton()
    private var mailSignInButton = UIButton(type: .system)
    private let phoneButton = UIButton()

    // MARK: - VC LIFEC YCLE
    override func viewDidLoad()
    {
        super.viewDidLoad()
        controllerMainSetup()
        
        view.backgroundColor = .white
        navigationController?.navigationBar.prefersLargeTitles = true
    }
    
    deinit {
        print("Login WAS DEINIT +++")
    }
    
    private func controllerMainSetup() {
        configureSignInGoogleButton()
        setupPhoneButton()
        setupMailButton()
        setupBinder()
        setupSignUpLable()
        setupSignUpButton()
    }
    
    //MARK: - Binder
    
    private func setupBinder() {
        loginViewModel.loginStatus.bind { [weak self] status in
            if status == .userIsAuthenticated {
                self?.coordinatorDelegate?.dismissNaviagtionController()
            }
        }
    }

    
    // MARK: - Setup viewController
    
    private func setupMailButton() {
        view.addSubview(mailSignInButton)

        mailSignInButton.configuration = .filled()
        mailSignInButton.configuration?.title = "Sign in with email"
        mailSignInButton.configuration?.baseBackgroundColor = .link
        mailSignInButton.addTarget(self, action: #selector(mailSignInButtonTapped), for: .touchUpInside)
        mailSignInButton.configuration?.image = UIImage(systemName: "envelope.fill")
        mailSignInButton.imageView?.contentMode = .scaleAspectFit
        
        mailSignInButton.configuration?.imagePadding = 30
        mailSignInButton.configuration?.contentInsets = NSDirectionalEdgeInsets(top: 0, leading: -50, bottom: 0, trailing: 0)

        mailSignInButton.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            mailSignInButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            mailSignInButton.topAnchor.constraint(equalTo: phoneButton.bottomAnchor, constant: 20),
            mailSignInButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 43),
            mailSignInButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -43),
            mailSignInButton.heightAnchor.constraint(equalToConstant: 40)
        ])
    }
    
    @objc func mailSignInButtonTapped() {
        coordinatorDelegate?.pushMailSignInController(viewModel: loginViewModel)
    }
    
    
    private func setupPhoneButton() {
        view.addSubview(phoneButton)
        
        phoneButton.configuration = .filled()
        phoneButton.configuration?.title = "Sign in with phone"
        phoneButton.configuration?.baseBackgroundColor = .link
        phoneButton.addTarget(self, action: #selector(phoneButtonTapped), for: .touchUpInside)
        phoneButton.configuration?.image = UIImage(systemName: "phone.fill")
        
        phoneButton.configuration?.imagePadding = 30
        phoneButton.configuration?.contentInsets = NSDirectionalEdgeInsets(top: 0, leading: -50, bottom: 0, trailing: 0)
        
        phoneButton.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            phoneButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            phoneButton.topAnchor.constraint(equalTo: googleSignInButton.bottomAnchor, constant: 20),
            phoneButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 43),
            phoneButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -43),
            phoneButton.heightAnchor.constraint(equalToConstant: 40)
        ])
    }
    
    @objc func phoneButtonTapped() {
        coordinatorDelegate?.pushPhoneSingInVC()
    }
    
    private var googleSignInButton = UIButton()
    
    private func configureSignInGoogleButton() {
        view.addSubview(googleSignInButton)
    
        googleSignInButton.configuration = .filled()
        googleSignInButton.configuration?.title = "Sign in with google"
        
        googleSignInButton.configuration?.baseBackgroundColor = .link
        googleSignInButton.addTarget(self, action: #selector(handleSignInWithGoogle), for: .touchUpInside)
        
        googleSignInButton.configuration?.imagePadding = 30
        googleSignInButton.configuration?.contentInsets = NSDirectionalEdgeInsets(top: 0, leading: -50, bottom: 0, trailing: 0)
        googleSignInButton.setImage(UIImage(named: "search"), for: .normal)
        
        setSignInGoogleButtonConstraints()
    }
    
    private func setSignInGoogleButtonConstraints() {
        googleSignInButton.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            googleSignInButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            googleSignInButton.topAnchor.constraint(equalTo: view.topAnchor, constant: view.bounds.height / 1.5),
            googleSignInButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 40),
            googleSignInButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -40),
            googleSignInButton.heightAnchor.constraint(equalToConstant: 40)
        ])
    }
    
    @objc private func handleSignInWithGoogle() {
        loginViewModel.googleSignIn()
    }

    private func setupSignUpLable() {
        view.addSubview(signUpLable)
        
        signUpLable.text = "Don't have an account?"
        signUpLable.font = UIFont(name: "MalayalamSangamMN", size: 16.0)
        setSignUpLableConstraints()
    }
    
    private func setSignUpLableConstraints() {
        signUpLable.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            signUpLable.topAnchor.constraint(equalTo: mailSignInButton.bottomAnchor, constant: 12),
            signUpLable.leadingAnchor.constraint(equalTo: mailSignInButton.leadingAnchor, constant: 40)
        ])
    }

    private func setupSignUpButton()
    {
        view.addSubview(signUpButton)
        
        signUpButton.configuration = .plain()
        signUpButton.configuration?.title = "Sign Up"
        signUpButton.configuration?.contentInsets = NSDirectionalEdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0)
        signUpButton.addTarget(self, action: #selector(pushSignUpVC), for: .touchUpInside)
        signUpButton.configuration?.buttonSize = .small
        
        
        setSignUpButtonConstraints()
    }
    
    private func setSignUpButtonConstraints() {
        signUpButton.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            signUpButton.leadingAnchor.constraint(equalTo: signUpLable.trailingAnchor, constant: 5),
            signUpButton.topAnchor.constraint(equalTo: mailSignInButton.bottomAnchor, constant: 10.5)
        ])
    }

    // MARK: - Navigation
    
    @objc func pushSignUpVC() {
        coordinatorDelegate?.pushSignUpVC()
    }
}





//
//  ViewController.swift
//  ChatUpp
////
////  Created by Andrei Pripa on 6/26/23.
////
//
//import UIKit
//import GoogleSignIn
//
//
//class LoginViewController: UIViewController {
//
//    weak var coordinatorDelegate: Coordinator?
//
////    private var googleSignInButton = GIDSignInButton()
//    private let loginViewModel = LoginViewModel()
//    private let signUpLable: UILabel = UILabel()
//    private let signUpButton = UIButton()
//    private var mailSignInButton = UIButton()
//    private let phoneButton = UIButton()
//
//    // MARK: - VC LIFEC YCLE
//    override func viewDidLoad()
//    {
//        super.viewDidLoad()
//
//        controllerMainSetup()
//
//        view.backgroundColor = .white
////        title = "Log in"
//        navigationController?.navigationBar.prefersLargeTitles = true
//    }
//
//    deinit {
//        print("Login WAS DEINIT +++")
//    }
//
//    private func controllerMainSetup() {
//        configureSignInGoogleButton()
//        setupPhoneButton()
//        setupMailButton()
//        setupBinder()
//        setupSignUpLable()
//        setupSignUpButton()
//    }
//
//    //MARK: - Binder
//
//    private func setupBinder() {
//        loginViewModel.loginStatus.bind { [weak self] status in
//            if status == .userIsAuthenticated {
//                self?.coordinatorDelegate?.dismissNaviagtionController()
//            }
//        }
//    }
//
//
//    // MARK: - Setup viewController
//    let button = UIButton(type: .system)
//    private func setupMailButton() {
//        view.addSubview(mailSignInButton)
////
////        mailSignInButton.configuration = .filled()
////        mailSignInButton.configuration?.title = "Sign in with email"
////        mailSignInButton.configuration?.baseBackgroundColor = .link
////        mailSignInButton.addTarget(self, action: #selector(mailSignInButtonTapped), for: .touchUpInside)
////        mailSignInButton.configuration?.image = UIImage(systemName: "envelope.fill")
////
////        mailSignInButton.configuration?.imagePadding = 50
////        mailSignInButton.configuration?.contentInsets = NSDirectionalEdgeInsets(top: 0, leading: -55, bottom: 0, trailing: 0)
////
//
//
//
////        button.frame = CGRect(x: 100, y: 100, width: 80, height: 50)
//        button.backgroundColor = .link
//        button.setTitle("Sign in with email", for: .normal)
//        button.tintColor = .white
//        button.setTitleColor(.white, for: .normal)
//        button.titleLabel?.font = UIFont(name: "Helvetica", size: 18)
////        let img = UIImage(systemName: "envelope.fill")!
////        button.setImage(img, for: .normal)
////
////        mailSignInButton.setTitle("Sign in with email", for: .normal)
////        mailSignInButton.backgroundColor = .systemTeal
//
//        // Image font
//        let font = UIFont.systemFont(ofSize: 20)
//        let config = UIImage.SymbolConfiguration(font: font)
////
//        let img = UIImage(systemName: "envelope.fill", withConfiguration: config)!
//        button.setImage(img, for: .normal)
////        // Icon color
//////        mailSignInButton.tintColor = .white
////        mailSignInButton.imageView?.tintColor = .amethyst
////
////        mailSignInButton.setTitleColor(.white, for: .normal)
//////        mailSignInButton.setTitleColor(.magenta, for: .normal)
//        button.imageView?.contentMode = .scaleAspectFill
//        button.imageEdgeInsets = UIEdgeInsets(top: 1, left: -70, bottom: 1, right: 1)
////        mailSignInButton.contentHorizontalAlignment = .fill
////        mailSignInButton.contentVerticalAlignment = .fill
////        mailSignInButton.titleLabel?.textAlignment = .center
//        view.addSubview(button)
//        button.translatesAutoresizingMaskIntoConstraints = false
//        NSLayoutConstraint.activate([
//            button.centerXAnchor.constraint(equalTo: view.centerXAnchor),
//            button.topAnchor.constraint(equalTo: phoneButton.bottomAnchor, constant: 20),
//            button.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 43),
//            button.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -43),
//            button.heightAnchor.constraint(equalToConstant: 40)
//        ])
//    }
//
//    @objc func mailSignInButtonTapped() {
//        coordinatorDelegate?.pushMailSignInController(viewModel: loginViewModel)
//    }
//
//
//    private func setupPhoneButton() {
//        view.addSubview(phoneButton)
//
//        phoneButton.configuration = .filled()
//        phoneButton.configuration?.title = "Sign in with phone"
//        phoneButton.configuration?.baseBackgroundColor = .link
//        phoneButton.addTarget(self, action: #selector(phoneButtonTapped), for: .touchUpInside)
//        phoneButton.configuration?.image = UIImage(systemName: "phone.fill")
//
//        phoneButton.configuration?.imagePadding = 35
//        phoneButton.configuration?.contentInsets = NSDirectionalEdgeInsets(top: 0, leading: -45, bottom: 0, trailing: 0)
//
//        phoneButton.translatesAutoresizingMaskIntoConstraints = false
//
//        NSLayoutConstraint.activate([
//            phoneButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
//            phoneButton.topAnchor.constraint(equalTo: googleSignInButton.bottomAnchor, constant: 20),
//            phoneButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 43),
//            phoneButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -43),
//            phoneButton.heightAnchor.constraint(equalToConstant: 40)
//        ])
//    }
//
//    @objc func phoneButtonTapped() {
//        coordinatorDelegate?.pushPhoneSingInVC()
//    }
//
//    private var googleSignInButton = UIButton()
//
//    private func configureSignInGoogleButton() {
//        view.addSubview(googleSignInButton)
//
//        googleSignInButton.configuration = .filled()
//        googleSignInButton.configuration?.title = "Sign in with google"
//
//        googleSignInButton.configuration?.baseBackgroundColor = .link
//        googleSignInButton.addTarget(self, action: #selector(handleSignInWithGoogle), for: .touchUpInside)
//
//        googleSignInButton.configuration?.imagePadding = 35
//        googleSignInButton.configuration?.contentInsets = NSDirectionalEdgeInsets(top: 0, leading: -45, bottom: 0, trailing: 0)
//        googleSignInButton.setImage(UIImage(named: "search"), for: .normal)
//
//        setSignInGoogleButtonConstraints()
//    }
//
//    private func setSignInGoogleButtonConstraints() {
//        googleSignInButton.translatesAutoresizingMaskIntoConstraints = false
//
//        NSLayoutConstraint.activate([
//            googleSignInButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
//            googleSignInButton.topAnchor.constraint(equalTo: view.topAnchor, constant: view.bounds.height / 1.5),
//            googleSignInButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 40),
//            googleSignInButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -40),
//            googleSignInButton.heightAnchor.constraint(equalToConstant: 40)
//        ])
//    }
//
//    @objc private func handleSignInWithGoogle() {
//        loginViewModel.googleSignIn()
//    }
//
//    private func setupSignUpLable() {
//        view.addSubview(signUpLable)
//
//        signUpLable.text = "Don't have an account?"
//        signUpLable.font = UIFont(name: "MalayalamSangamMN", size: 16.0)
//        setSignUpLableConstraints()
//    }
//
//    private func setSignUpLableConstraints() {
//        signUpLable.translatesAutoresizingMaskIntoConstraints = false
//
//        NSLayoutConstraint.activate([
//            signUpLable.topAnchor.constraint(equalTo: button.bottomAnchor, constant: 12),
//            signUpLable.leadingAnchor.constraint(equalTo: button.leadingAnchor, constant: 40)
//        ])
//    }
//
//    private func setupSignUpButton()
//    {
//        view.addSubview(signUpButton)
//
//        signUpButton.configuration = .plain()
//        signUpButton.configuration?.title = "Sign Up"
//        signUpButton.configuration?.contentInsets = NSDirectionalEdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0)
//        signUpButton.addTarget(self, action: #selector(pushSignUpVC), for: .touchUpInside)
//        signUpButton.configuration?.buttonSize = .small
//
//
//        setSignUpButtonConstraints()
//    }
//
//    private func setSignUpButtonConstraints() {
//        signUpButton.translatesAutoresizingMaskIntoConstraints = false
//
//        NSLayoutConstraint.activate([
//            signUpButton.leadingAnchor.constraint(equalTo: signUpLable.trailingAnchor, constant: 5),
//            signUpButton.topAnchor.constraint(equalTo: button.bottomAnchor, constant: 10.5)
//        ])
//    }
//
//    // MARK: - Navigation
//
//    @objc func pushSignUpVC() {
//        coordinatorDelegate?.pushSignUpVC()
//    }
//}
//
//
//
//
//
