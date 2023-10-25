//
//  CustomCollectionViewCell.swift
//  ChatUpp
//
//  Created by Andrei Pripa on 10/11/23.
//

import UIKit

class ConversationCollectionViewCell: UICollectionViewCell {
    
    var customViewMaxWidthConstraint: NSLayoutConstraint!
    
    var messageTrailingConstraint: NSLayoutConstraint!
    var messageBottomConstraint: NSLayoutConstraint!
    
    let messageBody = UILabel()
    let leadingEdgeSpacing: CGFloat = 90.0
    let customView = UIView()
    let timeStamp = UILabel()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        //        backgroundColor = .lightGray
        setupContentViewConstraints()
        contentView.addSubview(customView)
        setupCustomViewConstraints()
        setupMessageUI()
        setupTimestampLabel()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func setupTimestampLabel() {
        customView.addSubview(timeStamp)
        
        //        timeStamp.bounds.size = CGSize(width: 25, height: 10)
        //        timeStamp.frame.origin = CGPoint(x: -timeStamp.bounds.width, y: -timeStamp.bounds.height)
        //        timeStamp.autoresizingMask = [.flexibleLeftMargin, .flexibleTopMargin]
        
        timeStamp.text = "21:45"
        timeStamp.textColor = #colorLiteral(red: 0.3529850841, green: 0.2052503526, blue: 0.187323451, alpha: 1)
        timeStamp.backgroundColor = .orange
        timeStamp.font = UIFont(name: "Helvetica", size: 13)
        timeStamp.sizeToFit()
        
        //        timeStamp.adjustsFontSizeToFitWidth = true
        setupTimestampConstraints()
    }
    
    func setupTimestampConstraints() {
        timeStamp.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            //            timeStamp.heightAnchor.constraint(equalToConstant: 20),
            //            timeStamp.widthAnchor.constraint(equalToConstant: 40),
            timeStamp.bottomAnchor.constraint(equalTo: customView.bottomAnchor),
            timeStamp.trailingAnchor.constraint(equalTo: customView.trailingAnchor),
//            timeStamp.leadingAnchor.constraint(equalTo: customView.leadingAnchor)
        ])
    }
    
    func setupMessageUI() {
        customView.addSubview(messageBody)
        
        customView.backgroundColor = .green
        
        messageBody.backgroundColor = #colorLiteral(red: 0.6470323801, green: 0.3927372098, blue: 0.3783177137, alpha: 1)
        messageBody.textAlignment = .left
        messageBody.textColor = .white
        messageBody.font = UIFont(name: "HelveticaNeue", size: 18)
        messageBody.layer.cornerRadius = 15
        messageBody.setContentCompressionResistancePriority(.required, for: .vertical)

        //        messageBody.lineBreakMode = .byWordWrapping
        //        messageBody.clipsToBounds = true
        //        label.contentEdgeInsets = UIEdgeInsets(top: 5, left: 5, bottom: 5, right: 5)
        //        label.configuration?.contentInsets = NSDirectionalEdgeInsets(top: 14, leading: 14, bottom: 14, trailing: 14)
        //        label.adjustsFontSizeToFitWidth = true
        //        label.minimumScaleFactor = 0.5
        messageBody.numberOfLines = 0
//        messageBody.sizeToFit()
        
        setupMessageConstraints()
    }
    
    var customViewHeightConstraint: NSLayoutConstraint!
    
    func setupCustomViewConstraints() {
        customView.translatesAutoresizingMaskIntoConstraints = false
        customView.setContentCompressionResistancePriority(.required, for: .vertical)
        customViewHeightConstraint = customView.heightAnchor.constraint(equalTo: heightAnchor)
        customViewHeightConstraint.isActive = true
    
        NSLayoutConstraint.activate([
            customView.topAnchor.constraint(equalTo: topAnchor),
            customView.bottomAnchor.constraint(equalTo: bottomAnchor),
            customView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -10),
        ])
    }
    
    func setupMessageConstraints() {
        messageBody.translatesAutoresizingMaskIntoConstraints = false
                messageTrailingConstraint = messageBody.trailingAnchor.constraint(equalTo: customView.trailingAnchor)
                messageBottomConstraint = messageBody.bottomAnchor.constraint(equalTo: customView.bottomAnchor)
                messageBottomConstraint.isActive = true
                messageTrailingConstraint.isActive = true
        NSLayoutConstraint.activate([
            messageBody.topAnchor.constraint(equalTo: customView.topAnchor),
            messageBody.leadingAnchor.constraint(equalTo: customView.leadingAnchor),
        ])
    }
    
    lazy var newConstraint  = NSLayoutConstraint(item: messageBody,
                                                   attribute: .trailing,
                                                   relatedBy: .equal,
                                                   toItem: timeStamp,
                                                   attribute: .leading,
                                                   multiplier: 1.0,
                                                   constant: 0.0)
    
    var customViewMaxWidth: CGFloat? {
        didSet {
            guard let maxWidth = customViewMaxWidth else {return }
            customViewMaxWidthConstraint = customView.widthAnchor.constraint(lessThanOrEqualToConstant: maxWidth - leadingEdgeSpacing)
            customViewMaxWidthConstraint.isActive = true
            if messageBody.text == "Protect your Cloud Firestore resources from abuse, such as billing fraud or phishing Protect your Cloud Firestore resources from abuse, such as billing fraud or phishing Protect your Cloud Firestore resources from abuse, such as billing fraud or phishing" {
                print("Aha: message Frame ", messageBody.bounds)
                print("Aha: messageBody.textBoundingRect ", messageBody.textBoundingRect)
                print("Aha: messageBody.intrinsicContentSize ", messageBody.intrinsicContentSize)
                print("=============================")
                print("Aha: customView Frame ", customView.frame)
                print("Aha: customView.intrinsicContentSize ", messageBody.intrinsicContentSize)
            }
        }
    }

    func handlePositioning() {
//        if messageBody.text! == "*Protect your Cloud Firestore resources from abuse" {
//            print("when normal", messageBody.textBoundingRect.size)
//        }
        //            messageTrailingConstraint.constant = -timeStamp.bounds.width
        
//        customViewMaxWidthConstraint.constant = customViewMaxWidthConstraint.constant + 20
//        messageTrailingConstraint.isActive = false
        self.layoutIfNeeded()
//        self.layoutSubviews()
//        messageTrailingConstraint.constant = 0
//        messageBody.transform = CGAffineTransform(translationX: 0, y: 0)
        let spaceForTimeStemp = timeStamp.bounds.width

        let lastLineString = getMessageLastLine(for: messageBody.text!, in: messageBody)
        let lastLineWidth = lastLineString.getSize().width
        let lastLineWithTimestempWidth = lastLineWidth + timeStamp.bounds.width
        let messageContainerWidth = messageBody.textBoundingRect.width
        
        if messageBody.text == "Protect your Cloud Firestone uyuy o" {
            print("r")
        }
        
        messageTrailingConstraint.isActive = true
        newConstraint.isActive = false
        if lastLineWithTimestempWidth > messageContainerWidth {
//            let spaceForTimeStemp = timeStamp.bounds.width
            if lastLineWithTimestempWidth.rounded(.up) < customViewMaxWidthConstraint.constant  {
                                
//                messageBody.textcont = 100
//                messageTrailingConstraint.constant = -spaceForTimeStemp
                
                messageTrailingConstraint.isActive = false
               
                newConstraint.isActive = true
//                layoutIfNeeded()
            } else {
                let textWithNewLine = messageBody.text! + "\n"
                messageBody.text = textWithNewLine
            }
        }
        
        //            if (customLabel.frame.width > (lastLineWidth + timeStamp.bounds.width)) && messageBody.maxNumberOfLines == 1 {
        //                timeStamp.frame.origin = CGPoint(x: messageBody.textBoundingRect.width, y: messageBody.textBoundingRect.height - timeStamp.bounds.height)
        //            } else {
        //                timeStamp.frame.origin = CGPoint(x: messageBody.textBoundingRect.width - timeStamp.bounds.width, y: messageBody.textBoundingRect.height - timeStamp.bounds.height)
        //            }
    }
    
    
    func getMessageLastLine(for text: String, in label: UILabel) -> String {
        let adjustedLabelSize = CGRect(x: 0, y: 0, width: label.textBoundingRect.width, height: label.textBoundingRect.height + 10)
        
        let attributedText = NSAttributedString(string: text, attributes: [.font: label.font!])
        
        let framesetter = CTFramesetterCreateWithAttributedString(attributedText)
        
        let path = CGMutablePath()
        path.addRect(adjustedLabelSize)
        
        let frame = CTFramesetterCreateFrame(framesetter, CFRange(location: 0, length: 0), path, nil)
        let lines = CTFrameGetLines(frame) as! [CTLine]
        
        guard let lastLine = lines.last else {return ""}
        
        let range = CTLineGetStringRange(lastLine)
        let start = text.index(text.startIndex, offsetBy: range.location)
        let end = text.index(start, offsetBy: range.length)
        let lineText = String(text[start..<end])
        
//        if lineText == "resources from abuse, such as billing" {
//            print("")
//        }
        
//        if text == "*Protect your Cloud Firestore resources from abuse" {
//            print(lineText)
//        }
        return lineText
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


extension String {
    func getSize() -> CGSize {
        guard let font = UIFont(name: "HelveticaNeue", size: 18) else { return CGSize.zero }
        let attributes = [NSAttributedString.Key.font: font]
        return self.size(withAttributes: attributes)
    }
}


extension UILabel {
    
    var textBoundingRect: CGRect {
        let maxSize = CGSize(width: frame.size.width, height: CGFloat(MAXFLOAT))
        let text = (self.text ?? "") as NSString
        let rect = text.boundingRect(with: maxSize, options: .usesLineFragmentOrigin, attributes: [.font: font!], context: nil)
        
        return rect
    }
    
    var maxNumberOfLines: Int {
        let textHeight = self.textBoundingRect.height
        let lineHeight = font.lineHeight
        return Int(ceil(textHeight / lineHeight))
    }
}




// MARK: - MESSAGE LAST LINE WIDTH

//    func textRectMeasuremets(message: NSAttributedString, labelWidth: CGFloat) -> (CGFloat, CGRect) {
//        // Create instances of NSLayoutManager, NSTextContainer and NSTextStorage
//        self.layoutIfNeeded()
//        let labelSize = CGSize(width: labelWidth, height: .infinity)
//        let layoutManager = NSLayoutManager()
//        let textContainer = NSTextContainer(size: labelSize)
//        let textStorage = NSTextStorage(attributedString: message)
//
//        // Configure layoutManager and textStorage
//        layoutManager.addTextContainer(textContainer)
//        textStorage.addLayoutManager(layoutManager)
//
//        // Configure textContainer
//        textContainer.lineFragmentPadding = 0.0
//        textContainer.lineBreakMode = .byWordWrapping
//        textContainer.maximumNumberOfLines = 0
//
//        layoutManager.glyphRange(for: textContainer)
//        let sizeHight = layoutManager.usedRect(for: textContainer)
//
//        let lastGlyphIndex = layoutManager.glyphIndexForCharacter(at: message.length - 1)
//        let lastLineFragmentRect = layoutManager.lineFragmentUsedRect(forGlyphAt: lastGlyphIndex,
//                                                                      effectiveRange: nil)
//        return (lastLineFragmentRect.maxX, sizeHight)
//    }
