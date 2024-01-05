//
//  CollectionViewListHeader.swift
//  ChatUpp
//
//  Created by Andrei Pripa on 12/28/23.
//

import UIKit

//MARK: - CUSTOM HEADER CELL
// This custom header is for both settings and profile editin VC's
class CollectionViewListHeader: UICollectionViewListCell {
    
    lazy var stackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .vertical
        //        stackView.distribution = .fillEqually
//        stackView.spacing = 10
        stackView.alignment = .center
        
        stackView.addArrangedSubview(imageView)
        stackView.addArrangedSubview(nameLabel)
        stackView.setCustomSpacing(12, after: imageView)
        stackView.setCustomSpacing(3, after: nameLabel)
        
        addSubview(stackView)
    
        return stackView
    }()
    
    let imageView: UIImageView = {
        let imageView = UIImageView()
        imageView.layer.cornerRadius = 10
        imageView.clipsToBounds = true
        imageView.translatesAutoresizingMaskIntoConstraints = false
        return imageView
    }()
    
    var nameLabel: UILabel = {
        let name = UILabel()
        name.textAlignment = .center
        name.textColor = .white
        name.font = UIFont(name: "Helvetica", size: 25)
        name.translatesAutoresizingMaskIntoConstraints = false
        return name
    }()
    
    // Phone number and username
    let additionalCredentials: UILabel = {
        let name = UILabel()
        name.textAlignment = .center
        name.textColor = .white
        name.font = UIFont(name: "Helvetica", size: 18)
        name.translatesAutoresizingMaskIntoConstraints = false
        return name
    }()
    
    let newPhotoLabel: UILabel = {
        let name = UILabel()
        name.text = "Set New Photo"
        name.textAlignment = .center
        name.textColor = #colorLiteral(red: 0.6000000238, green: 0.6000000238, blue: 0.6000000238, alpha: 1)
        name.font = UIFont(name: "Helvetica", size: 18)
        name.translatesAutoresizingMaskIntoConstraints = false
        return name
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        setupStackViewConstraints()
        setupImageConstraints()
        setupNameConstraints()
//        setupAdditionalCredentialsConstraints()
    }
    
    
    func setupStackViewConstraints() {
        stackView.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            stackView.topAnchor.constraint(equalTo: topAnchor, constant: 10),
//            stackView.centerXAnchor.constraint(equalTo: centerXAnchor),
//            stackView.centerYAnchor.constraint(equalTo: centerYAnchor),
            stackView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -25),
        ])
    }
    
    func setupImageConstraints() {
        NSLayoutConstraint.activate([
            imageView.heightAnchor.constraint(equalToConstant: 110),
            imageView.widthAnchor.constraint(equalToConstant: 110),
        ])
    }
    
    func setupNameConstraints() {
        NSLayoutConstraint.activate([
            nameLabel.leadingAnchor.constraint(equalTo: leadingAnchor),
            nameLabel.trailingAnchor.constraint(equalTo: trailingAnchor),
            nameLabel.heightAnchor.constraint(equalToConstant: 30),
        ])
    }
    
    func setupAdditionalCredentialsConstraints() {
        stackView.addArrangedSubview(additionalCredentials)
//        stackView.setCustomSpacing(45, after: additionalCredentials)
        
        NSLayoutConstraint.activate([
//            additionalCredentials.topAnchor.constraint(equalTo: nameLabel.bottomAnchor, constant: 8),
            //            additionalCredentials.heightAnchor.constraint(equalToConstant: 110),
            //            additionalCredentials.widthAnchor.constraint(equalToConstant: 110),
            additionalCredentials.leadingAnchor.constraint(equalTo: leadingAnchor),
            additionalCredentials.trailingAnchor.constraint(equalTo: trailingAnchor),
            additionalCredentials.heightAnchor.constraint(equalToConstant: 20),
//            additionalCredentials.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -20)
        ])
    }
    
    func setupNewPhotoConstraints() {
        addSubview(newPhotoLabel)
        
        NSLayoutConstraint.activate([
            newPhotoLabel.topAnchor.constraint(equalTo: imageView.bottomAnchor, constant: 12),
            newPhotoLabel.leadingAnchor.constraint(equalTo: leadingAnchor),
            newPhotoLabel.trailingAnchor.constraint(equalTo: trailingAnchor),
            newPhotoLabel.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -20),
        ])
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}





////
////  CollectionViewListHeader.swift
////  ChatUpp
////
////  Created by Andrei Pripa on 12/28/23.
////
//
//import UIKit
//
////MARK: - CUSTOM HEADER CELL
//// This custom header is for both settings and profile editin VC's
//class CollectionViewListHeader: UICollectionViewListCell {
//
//
//
//
//
//    // Phone number and username
//    lazy var additionalCredentials: UILabel = {
//        let name = UILabel()
////        name.text = "Andrei Pripa"
//        name.textAlignment = .center
//        name.textColor = .white
//        name.font = UIFont(name: "Helvetica", size: 19)
//        name.translatesAutoresizingMaskIntoConstraints = false
//        return name
//    }()
//
//    lazy var newPhotoLabel: UILabel = {
//        let name = UILabel()
//        name.text = "Set New Photo"
//        name.textAlignment = .center
//        name.textColor = #colorLiteral(red: 0.6000000238, green: 0.6000000238, blue: 0.6000000238, alpha: 1)
//        name.font = UIFont(name: "Helvetica", size: 18)
//        name.translatesAutoresizingMaskIntoConstraints = false
//        return name
//    }()
//
//    override init(frame: CGRect) {
//        super.init(frame: frame)
//        //       setupImageConstraints()
//        //       setupNameConstraints()
//        //       setupStackViewConstraints()
//        configureStack()
//        setupImageConstraints()
//        setupNameConstraints()
//    }
//
//    let stackView = UIStackView()
//
//    let imageView: UIImageView = {
//        let imageView = UIImageView()
//        imageView.contentMode = .scaleAspectFit
//        imageView.layer.cornerRadius = 10
//        imageView.clipsToBounds = true
//        imageView.translatesAutoresizingMaskIntoConstraints = false
//        return imageView
//    }()
//
//    var nameLabel: UILabel = {
//        let name = UILabel()
//        name.text = "Andrei Pripa and some text here"
//        name.textAlignment = .center
//        name.textColor = .black
//        name.font = UIFont(name: "Helvetica", size: 25)
//        name.translatesAutoresizingMaskIntoConstraints = false
//        return name
//    }()
//
//
//    func configureStack() {
//        addSubview(stackView)
//        stackView.axis = .vertical
////        stackView.distribution = .fillEqually
//        stackView.spacing = 10
//        stackView.alignment = .center
//        stackView.addArrangedSubview(imageView)
//        stackView.addArrangedSubview(nameLabel)
//        setupStackViewConstraints()
//    }
//
//    func setupStackViewConstraints() {
//        stackView.translatesAutoresizingMaskIntoConstraints = false
//
//        NSLayoutConstraint.activate([
//            stackView.centerXAnchor.constraint(equalTo: centerXAnchor),
//            stackView.centerYAnchor.constraint(equalTo: centerYAnchor),
//        ])
//    }
//
//    func setupImageConstraints() {
//        NSLayoutConstraint.activate([
//            imageView.heightAnchor.constraint(equalToConstant: 110),
//            imageView.widthAnchor.constraint(equalToConstant: 110),
//        ])
//    }
//
//
//    func setupNameConstraints() {
//        NSLayoutConstraint.activate([
//            nameLabel.leadingAnchor.constraint(equalTo: leadingAnchor),
//            nameLabel.trailingAnchor.constraint(equalTo: trailingAnchor),
//        ])
//    }
//    func setupAdditionalCredentialsConstraints() {
//        addSubview(additionalCredentials)
//
//        NSLayoutConstraint.activate([
//            additionalCredentials.topAnchor.constraint(equalTo: nameLabel.bottomAnchor, constant: 8),
//            //            additionalCredentials.heightAnchor.constraint(equalToConstant: 110),
//            //            additionalCredentials.widthAnchor.constraint(equalToConstant: 110),
//            additionalCredentials.leadingAnchor.constraint(equalTo: leadingAnchor),
//            additionalCredentials.trailingAnchor.constraint(equalTo: trailingAnchor),
//            additionalCredentials.centerXAnchor.constraint(equalTo: centerXAnchor),
//            additionalCredentials.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -20)
//        ])
//    }
//
//    func setupNewPhotoConstraints() {
//        addSubview(newPhotoLabel)
//
//        NSLayoutConstraint.activate([
//            newPhotoLabel.topAnchor.constraint(equalTo: imageView.bottomAnchor, constant: 12),
//            newPhotoLabel.leadingAnchor.constraint(equalTo: leadingAnchor),
//            newPhotoLabel.trailingAnchor.constraint(equalTo: trailingAnchor),
//            newPhotoLabel.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -20),
//        ])
//    }
//
//    required init?(coder: NSCoder) {
//        fatalError("init(coder:) has not been implemented")
//    }
//}
