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

class UsernameRegistrationViewController: UIViewController {
    
    var coordinator: Coordinator!
    
    private let usernameRegistrationViewModel = UsernameRegistrationViewModel()
    private let usernameTextField: UITextField = CustomizedShadowTextField()
    private let continueButton: UIButton = CustomizedShadowButton()
    private let profileImage: UIImageView = UIImageView()
    private let nameAndPhotoTextLabel: UILabel = UILabel()
    
    
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
        print("Username VC was deinited !!!")
    }
    
    // MARK: - BINDING
    
    private func configureBinding() {
        usernameRegistrationViewModel.finishRegistration.bind { [weak self] finishRegistration in
            if let finish = finishRegistration, finish == true {
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
        continueButton.addTarget(self, action: #selector(manageContinueButtonTap), for: .touchUpInside)
        
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
    
    @objc private func manageContinueButtonTap() {
        
        if usernameRegistrationViewModel.validateName() == .valid {
            usernameRegistrationViewModel.updateUser()
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
    
    func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
        picker.dismiss(animated: true)
        
        results.forEach { result in
            result.itemProvider.loadObject(ofClass: UIImage.self) { [weak self] reading, error in
                guard let self = self else {return}
            
                guard let image = reading as? UIImage,
                      error == nil else { print("Could not read image"); return }
                
                let downsampledImage = downsampleImage(image)
                self.saveImageData(downsampledImage)
                
                Utilities.saveImageToDocumentDirectory(downsampledImage, to: "profile_selected.jpg")
                
                Task { @MainActor in
                    self.profileImage.image = downsampledImage
                }
            }
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

extension UsernameRegistrationViewController
{
//    private func resizeImage(_ image: UIImage) -> UIImage
//    {
//        let targetSize = CGSize(width: 1280, height: 1280)
//        let resizedImage = image.kf.resize(to: targetSize, for: .aspectFit)
//        return resizedImage
//    }
    
    private func downsampleImage(_ image: UIImage) -> UIImage
    {
        let newSize = ImageSize.User.original
        let resizedImage = image.resize(newSize)
        guard let data = resizedImage.jpegData(compressionQuality: 0.6) else {return image}
        
        return UIImage(data: data) ?? image
    }
    
    private func saveImageData(_ image: UIImage)
    {
        usernameRegistrationViewModel.profileImageData = image.jpegData(compressionQuality: 1.0)
    }
}


