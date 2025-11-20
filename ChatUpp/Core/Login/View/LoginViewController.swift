//
//  ViewController.swift
//  ChatUpp
//
//  Created by Andrei Pripa on 6/26/23.
//

import UIKit
import GoogleSignIn


class LoginViewController: UIViewController, UINavigationControllerDelegate {
    
    weak var coordinatorDelegate: Coordinator?
    private let loginViewModel = LoginViewModel()
    private let signUpLable: UILabel = UILabel()
    private let signUpButton = UILabel()
    private var mailSignInButton = CustomizedShadowButton(type: .system)
    private let phoneButton = CustomizedShadowButton()
    private var googleSignInButton = CustomizedShadowButton()
    private let logoImage = UIImageView()

    // MARK: - VC LIFEC YCLE
    override func viewDidLoad()
    {
        super.viewDidLoad()
        navigationController?.delegate = self
        controllerMainSetup()
        Utilities.clearNavigationBarAppearance()
        Utilities.setGradientBackground(forView: view)
    }
  
    deinit {
//        print("Login WAS DEINIT +++")
    }
    
    private func controllerMainSetup() {
        configureSignInGoogleButton()
        setupPhoneButton()
        setupMailButton()
        setupBinder()
        setupSignUpLable()
        setupSignUpButton()
        setupLogoImage()
    }
    
    //MARK: - Binder
    
    private func setupBinder() {
        loginViewModel.loginStatus.bind { [weak self] status in
            if status == .userIsAuthenticated {
                self?.coordinatorDelegate?.dismissNaviagtionController()
            }
        }
    }
    
    private func setupLogoImage() {
        view.addSubview(logoImage)
        
        let image = UIImage(named: "paper_plane_mountain_1")
        logoImage.image = image
        
        logoImage.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            logoImage.topAnchor.constraint(equalTo: view.topAnchor, constant: 70),
//            logoImage.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 30),
//            logoImage.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -30),
            logoImage.heightAnchor.constraint(equalToConstant: 320),
            logoImage.widthAnchor.constraint(equalToConstant: 320),
            logoImage.centerXAnchor.constraint(equalTo: view.centerXAnchor),
        ])
    }

    
    // MARK: - Setup viewController
    
    private func setupMailButton() {
        view.addSubview(mailSignInButton)

        mailSignInButton.configuration?.title = "Sign in with email"
        mailSignInButton.addTarget(self, action: #selector(mailSignInButtonTapped), for: .touchUpInside)
        mailSignInButton.configuration?.image = UIImage(systemName: "envelope.fill")
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
        
        phoneButton.configuration?.title = "Sign in with phone"
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
    
    private func configureSignInGoogleButton() {
        view.addSubview(googleSignInButton)
    
        googleSignInButton.configuration?.title = "Sign in with google"
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
        signUpLable.font = UIFont(name: "Arial", size: 15.5)
        signUpLable.textColor = #colorLiteral(red: 0.7414833691, green: 0.7236128613, blue: 0.6889627277, alpha: 1)
        
        signUpLable.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            signUpLable.topAnchor.constraint(equalTo: mailSignInButton.bottomAnchor, constant: 22),
//            signUpLable.leadingAnchor.constraint(equalTo: mailSignInButton.leadingAnchor, constant: 40)
            signUpLable.centerXAnchor.constraint(equalTo: view.centerXAnchor, constant: -20)
        ])
    }

    private func setupSignUpButton()
    {
        view.addSubview(signUpButton)
        signUpButton.attributedText = NSAttributedString(string: "Sign Up", attributes: [.underlineStyle: NSUnderlineStyle.single.rawValue])
        signUpButton.font = UIFont.boldSystemFont(ofSize: 15)
        signUpButton.textColor = #colorLiteral(red: 0.4100970866, green: 0.7637808476, blue: 0.09740843836, alpha: 1)
        signUpButton.isUserInteractionEnabled = true
        
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(pushSignUpVC))
        signUpButton.addGestureRecognizer(tapGesture)
        
        signUpButton.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            signUpButton.leadingAnchor.constraint(equalTo: signUpLable.trailingAnchor, constant: 5),
            signUpButton.topAnchor.constraint(equalTo: mailSignInButton.bottomAnchor, constant: 20)
        ])
    }

    // MARK: - Navigation
    
    @objc func pushSignUpVC() {
        coordinatorDelegate?.pushSignUpVC()
    }
}


// MARK: - Gradient
extension LoginViewController {
    
    func setGradientBackground() {
        let colorTop = #colorLiteral(red: 0.6000000238, green: 0.5585549503, blue: 0.5448982104, alpha: 1).cgColor
        let colorBottom = #colorLiteral(red: 0.5186259388, green: 0.4503372039, blue: 0.5165727111, alpha: 1).cgColor
        
        let gradientLayer = CAGradientLayer()
        gradientLayer.colors = [colorTop, colorBottom]
        gradientLayer.locations = [0.0, 1.0]
        gradientLayer.frame = self.view.bounds
        
        self.view.layer.insertSublayer(gradientLayer, at: 0)
    }
}

