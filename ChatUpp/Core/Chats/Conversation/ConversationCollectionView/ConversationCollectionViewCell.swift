//
//  CustomCollectionViewCell.swift
//  ChatUpp
//
//  Created by Andrei Pripa on 10/11/23.
//

import UIKit

class ConversationCollectionViewCell: UICollectionViewCell {
    
    var messageMaxWidthConstraint: NSLayoutConstraint!
    
    let messageBody = UILabel()
    let leadingEdgeSpacing: CGFloat = 70.0
//    let label = UIButton()
    let customLabel = UILabel()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
//        backgroundColor = .lightGray
        setupContentViewConstraints()
        setupMessageUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func setupMessageUI() {
        customLabel.addSubview(messageBody)
        contentView.addSubview(customLabel)
        
        customLabel.backgroundColor = .green
        
        setupCustomViewConstraints()
        
        messageBody.backgroundColor = #colorLiteral(red: 0.6470323801, green: 0.3927372098, blue: 0.3783177137, alpha: 1)
        messageBody.textAlignment = .left
        messageBody.textColor = .white
        messageBody.font = UIFont(name: "HelveticaNeue", size: 19)
        messageBody.layer.cornerRadius = 15
//        messageBody.clipsToBounds = true
//        label.contentEdgeInsets = UIEdgeInsets(top: 5, left: 5, bottom: 5, right: 5)
//        label.configuration?.contentInsets = NSDirectionalEdgeInsets(top: 14, leading: 14, bottom: 14, trailing: 14)
//        label.adjustsFontSizeToFitWidth = true
//        label.minimumScaleFactor = 0.5
        messageBody.numberOfLines = 0
//        label.sizeToFit()

//        setMaxWidthConstraint()
        setupMessageConstraints()
    }
    
    func setupCustomViewConstraints() {
        customLabel.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            customLabel.topAnchor.constraint(equalTo: topAnchor),
            customLabel.bottomAnchor.constraint(equalTo: bottomAnchor),
            customLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -10),
//            customLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 10),
        ])
    }
  
    func setupMessageConstraints() {
        messageBody.translatesAutoresizingMaskIntoConstraints = false
 
        NSLayoutConstraint.activate([
            messageBody.topAnchor.constraint(equalTo: customLabel.topAnchor),
            messageBody.bottomAnchor.constraint(equalTo: customLabel.bottomAnchor),
            messageBody.trailingAnchor.constraint(equalTo: customLabel.trailingAnchor),
            messageBody.leadingAnchor.constraint(equalTo: customLabel.leadingAnchor),
           ])
    }
    
    var messageMaxWidth: CGFloat? {
        didSet {
            guard let maxWidth = messageMaxWidth else {return }
            messageMaxWidthConstraint = customLabel.widthAnchor.constraint(lessThanOrEqualToConstant: maxWidth - leadingEdgeSpacing)
            messageMaxWidthConstraint.isActive = true
        }
    }
    
    func setupContentViewConstraints() {
        contentView.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            contentView.leadingAnchor.constraint(equalTo: leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: trailingAnchor),
            contentView.topAnchor.constraint(equalTo: topAnchor),
            contentView.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])
    }
}

