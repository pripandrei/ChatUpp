//
//  UsernameRegistrationViewController.swift
//  ChatUpp
//
//  Created by Andrei Pripa on 9/17/23.
//

import UIKit
import Photos
import PhotosUI
import Kingfisher
import Combine

class UsernameRegistrationViewController: UIViewController {
    
    var coordinator: Coordinator!
    
    private let usernameRegistrationViewModel = UsernameRegistrationViewModel()
    private let usernameTextField: CustomizedShadowTextField = CustomizedShadowTextField()
    private let continueButton: UIButton = CustomizedShadowButton()
    private let profileImage: UIImageView = UIImageView()
    private let nameAndPhotoTextLabel: UILabel = UILabel()
    private var cancellables = Set<AnyCancellable>()
    
    
    // MARK: VC LIFE CYCLE
    override func viewDidLoad() {
        super.viewDidLoad()
        //        view.backgroundColor = .white
        Utilities.setGradientBackground(forView: view)
        configureUsernameTextField()
        configureContinueButton()
        setupProfileImage()
        setupNameAndPhotoLabel()
        configureBinding()
    }
    
    deinit {
//        print("Username VC was deinited !!!")
    }
    
    // MARK: - BINDING
    
    private func configureBinding() {
        usernameRegistrationViewModel.registrationCompleted.bind { [weak self] completed in
            if completed == true
            {
                Task { @MainActor in
                    self?.coordinator.dismissNaviagtionController()
                }
            }
        }
    }
    
    // MARK: - UI SETUP
    
    private func setupProfileImage() {
        view.addSubview(profileImage)
        
        profileImage.backgroundColor = .carrot
        profileImage.image = UIImage(named: "default_profile_photo")
        //        profileImage.contentMode = .scaleAspectFill
        
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(addProfilePhoto))
        profileImage.addGestureRecognizer(tapGesture)
        profileImage.isUserInteractionEnabled = true
        
        profileImage.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            profileImage.topAnchor.constraint(equalTo: view.topAnchor, constant: 70),
            profileImage.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            profileImage.heightAnchor.constraint(equalToConstant: 120),
            profileImage.widthAnchor.constraint(equalToConstant: 120),
        ])
    }
    
    private func configureContinueButton() {
        view.addSubview(continueButton)
        
        continueButton.configuration?.title = "Continue"
        continueButton.addTarget(self, action: #selector(continueButtonWasTapped), for: .touchUpInside)
        
        setContinueButtonConstraints()
    }
    
    private func setContinueButtonConstraints() {
        continueButton.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            continueButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            continueButton.topAnchor.constraint(equalTo: usernameTextField.bottomAnchor, constant: 30),
            continueButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 73),
            continueButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -73),
            continueButton.heightAnchor.constraint(equalToConstant: 40)
        ])
    }
    
    @objc private func continueButtonWasTapped()
    {
        if usernameRegistrationViewModel.validateName() == .valid
        {
            usernameRegistrationViewModel.finishRegistration()
        } else {
            usernameTextField.animateBorder()
        }
    }
    
    private func configureUsernameTextField() {
        view.addSubview(usernameTextField)
        usernameTextField.delegate = self
        
        usernameTextField.placeholder = "Enter Your name"
        //        usernameTextField.borderStyle = .roundedRect
        
        setUsernameTextFieldConstraints()
    }
    
    private func setUsernameTextFieldConstraints() {
        usernameTextField.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            usernameTextField.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            //            usernameTextField.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            usernameTextField.widthAnchor.constraint(equalToConstant: 300),
            usernameTextField.heightAnchor.constraint(equalToConstant: 50),
            usernameTextField.topAnchor.constraint(equalTo: view.topAnchor, constant: 290)
            
        ])
    }
    
    private func setupNameAndPhotoLabel() {
        view.addSubview(nameAndPhotoTextLabel)
        
        nameAndPhotoTextLabel.text = "Enter your name and \n add a profile photo"
        nameAndPhotoTextLabel.textColor = #colorLiteral(red: 0.8817898337, green: 0.8124251547, blue: 0.8326097798, alpha: 1)
        nameAndPhotoTextLabel.numberOfLines = 2
        nameAndPhotoTextLabel.textAlignment = .center
        nameAndPhotoTextLabel.font =  UIFont.boldSystemFont(ofSize: 19)
        
        nameAndPhotoTextLabel.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            nameAndPhotoTextLabel.topAnchor.constraint(equalTo: profileImage.bottomAnchor, constant: 30),
            nameAndPhotoTextLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
        ])
    }
}

//MARK: - Photo Picker setup
extension UsernameRegistrationViewController: PHPickerViewControllerDelegate {
    @objc func addProfilePhoto() {
        initiatePhotoPicker()
    }
    private func initiatePhotoPicker() {
        var pickerConfiguration = PHPickerConfiguration()
        pickerConfiguration.selectionLimit = 1
        pickerConfiguration.filter = .images
        let pickerVC = PHPickerViewController(configuration: pickerConfiguration)
        pickerVC.delegate = self
        present(pickerVC, animated: true)
    }
    
    
    // MARK: - PHPickerViewControllerDelegate
    func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
        picker.dismiss(animated: true)
        
        results.first?.itemProvider.loadObject(ofClass: UIImage.self) { image, error in
            
            guard error == nil else {return}
            guard let image = image as? UIImage else {return}
            
            Task { @MainActor in
                
                guard let cropedImage = await self.cropImage(image) else { return }
                
                let repository = ImageSampleRepository(image: cropedImage, type: .user)
                
                if let mediumImage = repository.samples[.medium]
                {
                    self.usernameRegistrationViewModel.setImageSampleRepository(repository)
                    self.profileImage.image = UIImage(data: mediumImage)
                }
            }
        }
    }
    
    private func cropImage(_ image: UIImage?) async -> UIImage? {
        guard let image else { return nil }
        
        let cropper = ImageCropper(image: image)
        cropper.presentCropViewController(from: self)
        
        return await withCheckedContinuation { continuation in
            cropper.$croppedImage
                .dropFirst()
                .first()
                .sink {
                    continuation.resume(returning: $0)
                }
                .store(in: &cancellables)
        }
    }
}

//MARK: - TextFieldDelegate
extension UsernameRegistrationViewController: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        usernameTextField.resignFirstResponder()
    }
    func textFieldDidChangeSelection(_ textField: UITextField) {
        if let text = textField.text {
            usernameRegistrationViewModel.username = text
        }
    }
}
