////
////  ViewController.swift
////  ChatUpp
////
////  Created by Andrei Pripa on 6/26/23.
////

import UIKit
import GoogleSignIn
import AVFoundation

class LoginViewController: UIViewController, UINavigationControllerDelegate
{
    weak var coordinatorDelegate: Coordinator?
    private var player: AVPlayer?
    private let loginViewModel = LoginViewModel()
    private let signUpLable: UILabel = UILabel()
    private let signUpButton = UILabel()
//    private var mailSignInButton = CustomizedShadowButton(type: .system)
    private var mailSignInButton = CustomizedShadowButton(shadowType: .navigationItem)
    private let phoneButton = CustomizedShadowButton(shadowType: .navigationItem)
    private var googleSignInButton = CustomizedShadowButton(shadowType: .navigationItem)
    private let logoImage = UIImageView()
    private let signupStackView = UIStackView()

    // MARK: - VC LIFEC YCLE
    override func viewDidLoad()
    {
        super.viewDidLoad()
        navigationController?.delegate = self
        controllerMainSetup()
        NavigationBarAppearance.configureTransparentNavigationBarAppearance(for: self)
        Utilities.setGradientBackground(forView: view)
        setupAppActiveNotification()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        player?.play()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        player?.pause()
    }
    
    deinit {
        //        print("Login WAS DEINIT +++")
    }
    
    private func controllerMainSetup() {
        setupVideoBackground()
        configureSignInGoogleButton()
        setupPhoneButton()
        setupMailButton()
        setupBinder()
        setupSingupStackView()
        setupSignUpLable()
        setupSignUpButton()
//        setupLogoImage()
    }
    
    //MARK: - Binder
    
    private func setupBinder() {
        loginViewModel.loginStatus.bind { [weak self] status in
            if status == .userIsAuthenticated {
                self?.coordinatorDelegate?.dismissNaviagtionController()
            }
        }
    }
    
    //MARK: - Notification
    private func setupAppActiveNotification()
    {
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(appDidBecomeActive),
                                               name: UIApplication.didBecomeActiveNotification,
                                               object: nil)
    }
    
    @objc private func appDidBecomeActive()
    {
        player?.play()
    }
    
    // UI Setup
    
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
    
    private func setupSingupStackView()
    {
        view.addSubview(signupStackView)
        signupStackView.axis = .horizontal
        signupStackView.spacing = 6
        
        signupStackView.addArrangedSubview(signUpLable)
        signupStackView.addArrangedSubview(signUpButton)
        
        signupStackView.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            signupStackView.topAnchor.constraint(equalTo: mailSignInButton.bottomAnchor, constant: 22),
            signupStackView.centerXAnchor.constraint(equalTo: mailSignInButton.centerXAnchor)
        ])
    }

    private func setupSignUpLable()
    {
        signUpLable.text = "Don't have an account?"
        signUpLable.font = UIFont(name: "Arial", size: 15.5)
        signUpLable.textColor = #colorLiteral(red: 0.7414833691, green: 0.7236128613, blue: 0.6889627277, alpha: 1)
    }

    private func setupSignUpButton()
    {
        signUpButton.attributedText = NSAttributedString(string: "Sign Up", attributes: [.underlineStyle: NSUnderlineStyle.single.rawValue])
        signUpButton.font = UIFont.boldSystemFont(ofSize: 15)
        signUpButton.textColor = #colorLiteral(red: 0.4100970866, green: 0.7637808476, blue: 0.09740843836, alpha: 1)
        signUpButton.isUserInteractionEnabled = true
        
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(pushSignUpVC))
        signUpButton.addGestureRecognizer(tapGesture)
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

// Background video setup
extension LoginViewController
{
    private func addGradientDimView()
    {
        let gradientView = UIView(frame: view.bounds)
        gradientView.isUserInteractionEnabled = false   // let UI pass taps if needed
        gradientView.autoresizingMask = [.flexibleWidth, .flexibleHeight]

        // Create gradient layer
        let gradient = CAGradientLayer()
        gradient.frame = gradientView.bounds

        gradient.colors = [
            UIColor.black.withAlphaComponent(1).cgColor,  // bottom: darker
            UIColor.black.withAlphaComponent(0.7).cgColor,  // middle
            UIColor.black.withAlphaComponent(0.5).cgColor,  // middle
            UIColor.clear.cgColor                           // top: bright
        ]

        gradient.locations = [0.0, 0.3, 0.5, 0.8]   // adjust as needed
        gradient.startPoint = CGPoint(x: 0.5, y: 1.0)  // bottom center
        gradient.endPoint   = CGPoint(x: 0.5, y: 0.0)  // top center

        gradientView.layer.addSublayer(gradient)

        // insert above the video, below UI
        view.insertSubview(gradientView, at: 1)
    }
    
    private func setupVideoBackground()
    {
//        guard let path = Bundle.main.path(forResource: "background_video_2", ofType: "mp4") else { return }
        guard let path = Bundle.main.path(forResource: "paperPlane_flight_1", ofType: "mp4") else { return }
        let url = URL(fileURLWithPath: path)
        
        player = AVPlayer(url: url)
        player?.actionAtItemEnd = .none
        
        let playerLayer = AVPlayerLayer(player: player)
        playerLayer.frame = view.bounds
        playerLayer.videoGravity = .resizeAspectFill
        
        // Insert video BELOW all subviews (index 0)
        view.layer.insertSublayer(playerLayer, at: 0)
        addGradientDimView()
        // Add dim overlay ABOVE video
        let dimView = UIView(frame: view.bounds)
        dimView.backgroundColor = #colorLiteral(red: 0.1993816495, green: 0.1580790281, blue: 0.165407449, alpha: 1).withAlphaComponent(0.5)
        dimView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        view.insertSubview(dimView, at: 1)
        
        // Loop video
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(loopVideo),
            name: .AVPlayerItemDidPlayToEndTime,
            object: player?.currentItem
        )
        
        player?.play()
    }
    
    @objc private func loopVideo() {
        player?.seek(to: .zero)
        player?.play()
    }
}
