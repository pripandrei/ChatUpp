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
    let customLabel = UIView()
    let timeStamp = UILabel()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
//        backgroundColor = .lightGray
        setupContentViewConstraints()
        setupMessageUI()
//        setupTimestampLabel()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func setupTimestampLabel() {
        customLabel.addSubview(timeStamp)
        
//        timeStamp.backgroundColor = #colorLiteral(red: 0.397593677, green: 0.2409784794, blue: 0.2313092649, alpha: 1)
        timeStamp.text = "21:45"
        timeStamp.textColor = #colorLiteral(red: 0.3529850841, green: 0.2052503526, blue: 0.187323451, alpha: 1)
        timeStamp.adjustsFontSizeToFitWidth = true
        setupTimestampConstraints()
    }
    
    func setupTimestampConstraints() {
        timeStamp.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            timeStamp.heightAnchor.constraint(equalToConstant: 20),
            timeStamp.widthAnchor.constraint(equalToConstant: 40),
            timeStamp.bottomAnchor.constraint(equalTo: customLabel.bottomAnchor),
            timeStamp.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -10),
//            timeStamp.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 10),
        ])
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
//        messageBody.lineBreakMode = .byWordWrapping
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
//            calculateWidthOfLastLine(text: messageBody.text!)
//            print("===", messageBody.maxNumberOfLines)
            
            let attributedText = NSAttributedString(string: messageBody.text!, attributes: [.font: messageBody.font!])
            let lastLineMax3X = lastLineMaxX(message: attributedText, labelWidth: maxWidth - leadingEdgeSpacing)
            print(lastLineMax3X)
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
    
    // MARK: - MESSAGE LAST LINE WIDTH
    
    func lastLineMaxX(message: NSAttributedString, labelWidth: CGFloat) -> CGFloat {
        // Create instances of NSLayoutManager, NSTextContainer and NSTextStorage
        self.layoutIfNeeded()
        let labelSize = CGSize(width: labelWidth, height: .infinity)
        let layoutManager = NSLayoutManager()
        let textContainer = NSTextContainer(size: labelSize)
        let textStorage = NSTextStorage(attributedString: message)
        
        // Configure layoutManager and textStorage
        layoutManager.addTextContainer(textContainer)
        textStorage.addLayoutManager(layoutManager)
        
        // Configure textContainer
        textContainer.lineFragmentPadding = 0.0
        textContainer.lineBreakMode = .byWordWrapping
        textContainer.maximumNumberOfLines = 0
        
        let lastGlyphIndex = layoutManager.glyphIndexForCharacter(at: message.length - 1)
        let lastLineFragmentRect = layoutManager.lineFragmentUsedRect(forGlyphAt: lastGlyphIndex,
                                                                      effectiveRange: nil)
        return lastLineFragmentRect.maxX
    }
}


extension UILabel {
    var maxNumberOfLines: Int {
        self.layoutIfNeeded()
        let maxSize = CGSize(width: frame.size.width, height: CGFloat(MAXFLOAT))
        let text = (self.text ?? "") as NSString
        let textHeight = text.boundingRect(with: maxSize, options: .usesLineFragmentOrigin, attributes: [.font: font!], context: nil).height
        let lineHeight = font.lineHeight
        return Int(ceil(textHeight / lineHeight))
    }
}
