//
//  CollectionViewListHeader.swift
//  ChatUpp
//
//  Created by Andrei Pripa on 12/28/23.
//

import UIKit

//MARK: - CUSTOM HEADER CELL
class CollectionViewListHeader: UICollectionViewListCell {

    let imageView: UIImageView = {
        let imageView = UIImageView()
        imageView.layer.cornerRadius = 10
        imageView.clipsToBounds = true
        imageView.translatesAutoresizingMaskIntoConstraints = false
        return imageView
    }()
    
    let textLabel: UILabel = {
        let name = UILabel()
//        name.text = "Andrei Pripa"
        name.textAlignment = .center
        name.textColor = .white
        name.font = UIFont(name: "Helvetica", size: 25)
        name.translatesAutoresizingMaskIntoConstraints = false
        return name
    }()

   override init(frame: CGRect) {
    super.init(frame: frame)
       addSubview(imageView)
       addSubview(textLabel)
      
       NSLayoutConstraint.activate([
        imageView.topAnchor.constraint(equalTo: topAnchor, constant: 10),
        imageView.heightAnchor.constraint(equalToConstant: 110),
        imageView.widthAnchor.constraint(equalToConstant: 110),
        imageView.centerXAnchor.constraint(equalTo: centerXAnchor),
 
        textLabel.topAnchor.constraint(equalTo: imageView.bottomAnchor, constant: 8),
        textLabel.leadingAnchor.constraint(equalTo: leadingAnchor),
        textLabel.trailingAnchor.constraint(equalTo: trailingAnchor),
        textLabel.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -20)
       ])
   }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
