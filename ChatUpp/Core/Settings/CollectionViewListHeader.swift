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

    let imageView: UIImageView = {
        let imageView = UIImageView()
       
        imageView.layer.cornerRadius = 10
        imageView.clipsToBounds = true
        imageView.translatesAutoresizingMaskIntoConstraints = false
        return imageView
    }()
    
    lazy var nameLabel: UILabel = {
        let name = UILabel()
//        name.text = "Andrei Pripa"
        name.textAlignment = .center
        name.textColor = .white
        name.font = UIFont(name: "Helvetica", size: 25)
        name.translatesAutoresizingMaskIntoConstraints = false
        return name
    }()
    
    // Phone number and username
    lazy var additionalCredentials: UILabel = {
        let name = UILabel()
//        name.text = "Andrei Pripa"
        name.textAlignment = .center
        name.textColor = .white
        name.font = UIFont(name: "Helvetica", size: 19)
        name.translatesAutoresizingMaskIntoConstraints = false
        return name
    }()
    
    lazy var newPhotoLabel: UILabel = {
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
       setupImageConstraints()
       setupNameConstraints()
   }
    
    func setupImageConstraints() {
        addSubview(imageView)
        
        NSLayoutConstraint.activate([
         imageView.topAnchor.constraint(equalTo: topAnchor, constant: 10),
         imageView.heightAnchor.constraint(equalToConstant: 110),
         imageView.widthAnchor.constraint(equalToConstant: 110),
         imageView.centerXAnchor.constraint(equalTo: centerXAnchor),
//         imageView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -20)
        ])
    }
    
    func setupNameConstraints() {
        addSubview(nameLabel)
        
        NSLayoutConstraint.activate([
            nameLabel.topAnchor.constraint(equalTo: imageView.bottomAnchor, constant: 15),
            nameLabel.leadingAnchor.constraint(equalTo: leadingAnchor),
            nameLabel.heightAnchor.constraint(equalToConstant: 30),
//            nameLabel.widthAnchor.constraint(equalToConstant: 30),
            nameLabel.trailingAnchor.constraint(equalTo: trailingAnchor),
            nameLabel.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -20)
        ])
    }
    
    func setupAdditionalCredentialsConstraints() {
        addSubview(additionalCredentials)
        
        NSLayoutConstraint.activate([
            additionalCredentials.topAnchor.constraint(equalTo: nameLabel.bottomAnchor, constant: 8),
//            additionalCredentials.heightAnchor.constraint(equalToConstant: 110),
//            additionalCredentials.widthAnchor.constraint(equalToConstant: 110),
            additionalCredentials.leadingAnchor.constraint(equalTo: leadingAnchor),
            additionalCredentials.trailingAnchor.constraint(equalTo: trailingAnchor),
            additionalCredentials.centerXAnchor.constraint(equalTo: centerXAnchor),
            additionalCredentials.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -20)
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
