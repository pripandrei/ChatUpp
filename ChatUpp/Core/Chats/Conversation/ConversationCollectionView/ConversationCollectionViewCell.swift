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
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .lightGray
        setupContentViewConstraints()
        setupMessageUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func setupMessageUI() {
        contentView.addSubview(messageBody)
        messageBody.backgroundColor = .systemCyan
        messageBody.textAlignment = .left
        messageBody.backgroundColor = #colorLiteral(red: 0.4779014587, green: 0.4183443785, blue: 0.4153498709, alpha: 1)
//        label.contentEdgeInsets = UIEdgeInsets(top: 5, left: 5, bottom: 5, right: 5)
//        label.configuration?.contentInsets = NSDirectionalEdgeInsets(top: 14, leading: 14, bottom: 14, trailing: 14)
//        label.adjustsFontSizeToFitWidth = true
//        label.minimumScaleFactor = 0.5
        messageBody.numberOfLines = 0
//        label.sizeToFit()

//        setMaxWidthConstraint()
        setupMessageConstraints()
    }
  
    func setupMessageConstraints() {
        messageBody.translatesAutoresizingMaskIntoConstraints = false
 
        NSLayoutConstraint.activate([
               messageBody.topAnchor.constraint(equalTo: topAnchor),
               messageBody.bottomAnchor.constraint(equalTo: bottomAnchor),
               messageBody.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -10),
//               label.leadingAnchor.constraint(greaterThanOrEqualTo: leadingAnchor, constant:  10),
           ])
    }
    
//    func setMaxWidthConstraint() {
//        maxWidthConstraint = label.widthAnchor.constraint(lessThanOrEqualToConstant: 330)
//        maxWidthConstraint.isActive = true
////        maxWidthConstraint.constant = 320
////        setupLabel()
//        UIApplication.shared.keyWindow?.frame.width
//    }
    
    var messageMaxWidth: CGFloat? {
        didSet {
            guard let maxWidth = messageMaxWidth else {return }
            messageMaxWidthConstraint = messageBody.widthAnchor.constraint(lessThanOrEqualToConstant: maxWidth - leadingEdgeSpacing)
            messageMaxWidthConstraint.isActive = true
//            maxWidthConstraint.constant = maxWidth - 70
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







//func setupLabel() {
//    addSubview(button)
//        button.contentEdgeInsets = UIEdgeInsets(top: 5, left: 5, bottom: 5, right: 5)
//        button.setTitle("Your multi-line text here", for: .normal)
//        button.tintColor = .white
//        button.isUserInteractionEnabled = false
//        button.backgroundColor = .brown
//        
//        // Set the number of lines for the titleLabel
//        button.titleLabel?.numberOfLines = 0
//        button.titleLabel?.lineBreakMode = .byWordWrapping
//
//        // Calculate the required size for the button based on the content
//        let buttonSize = button.intrinsicContentSize
//
//        // Update the button's frame to fit the content
//        button.frame = CGRect(x: button.frame.origin.x, y: button.frame.origin.y, width: buttonSize.width, height: buttonSize.height)
//
//    setupLabelConstraints()
//}
//
//
//
//func setupLabelConstraints() {
//        button.translatesAutoresizingMaskIntoConstraints = false
//        NSLayoutConstraint.activate([
//            button.topAnchor.constraint(equalTo: topAnchor, constant: 5),
//            button.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -5),
//            button.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -10),
//            button.leadingAnchor.constraint(greaterThanOrEqualTo: leadingAnchor, constant: self.frame.width * 0.2),
//        ])
//    }
//}


//import UIKit
//
//class ConversationCollectionViewCell: UICollectionViewCell {
//    
//    let label = UILabel()
//    
//    override init(frame: CGRect) {
//        super.init(frame: frame)
//        backgroundColor = .lightGray
//        setupLabel()
//    }
//    
//    required init?(coder: NSCoder) {
//        fatalError("init(coder:) has not been implemented")
//    }
//    
//    func setupLabel() {
//        contentView.addSubview(label)
//        addSubview(label)
//        label.backgroundColor = .systemCyan
//        label.textAlignment = .left
//        label.backgroundColor = #colorLiteral(red: 0.4779014587, green: 0.4183443785, blue: 0.4153498709, alpha: 1)
////        label.sizeToFit()
//        label.adjustsFontSizeToFitWidth = true
////        label.minimumScaleFactor = 0.5
//        label.numberOfLines = 0
//        let buttn = UIButton()
//        
//        
//        setupLabelConstraints()
//    }
//
//  
//    
//    func setupLabelConstraints() {
//        label.translatesAutoresizingMaskIntoConstraints = false
//        NSLayoutConstraint.activate([
//            label.topAnchor.constraint(equalTo: topAnchor),
//            label.bottomAnchor.constraint(equalTo: bottomAnchor),
//            label.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -10),
//            label.leadingAnchor.constraint(greaterThanOrEqualTo: leadingAnchor, constant: self.frame.width * 0.2),
////            label.widthAnchor.constrailes
////            label.leadingAnchor.constraint(equalTo: leadingAnchor)
//        ])
//    }
//}
//
//
//class TestLabel: UILabel {
//
//}
