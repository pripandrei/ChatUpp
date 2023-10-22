//
//  AppDelegate.swift
//  ChatUpp
//
//  Created by Andrei Pripa on 6/26/23.
//

import UIKit
import Firebase
import IQKeyboardManagerSwift

@main
class AppDelegate: UIResponder, UIApplicationDelegate {
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        
//        IQKeyboardManager.shared.enable = true
        FirebaseApp.configure()
        
        Utilities.setupNavigationBarAppearance()
        
        return true
    }

    // MARK: UISceneSession Lifecycle

    func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        // Called when a new scene session is being created.
        // Use this method to select a configuration to create the new scene with.
        return UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
    }

    func application(_ application: UIApplication, didDiscardSceneSessions sceneSessions: Set<UISceneSession>) {
        // Called when the user discards a scene session.
        // If any sessions were discarded while the application was not running, this will be called shortly after application:didFinishLaunchingWithOptions.
        // Use this method to release any resources that were specific to the discarded scenes, as they will not return.
    }


}






//import UIKit
//
//class ConversationCollectionViewCell: UICollectionViewCell {
//    
//    var messageMaxWidthConstraint: NSLayoutConstraint!
//    
//    let messageBody = UILabel()
//    let leadingEdgeSpacing: CGFloat = 70.0
////    let label = UIButton()
//    let customLabel = UIView()
//    let timeStamp = UILabel()
//    
//    override init(frame: CGRect) {
//        super.init(frame: frame)
////        backgroundColor = .lightGray
//        setupContentViewConstraints()
//        contentView.addSubview(customLabel)
//        setupCustomViewConstraints()
////        createChatView()
////        setupMessageUI()
////        setupTimestampLabel()
//    }
//    
//    required init?(coder: NSCoder) {
//        fatalError("init(coder:) has not been implemented")
//    }
//    
//    func setupTimestampLabel() {
//        customLabel.addSubview(timeStamp)
//        
////        timeStamp.backgroundColor = #colorLiteral(red: 0.397593677, green: 0.2409784794, blue: 0.2313092649, alpha: 1)
//        timeStamp.text = "21:45"
//        timeStamp.textColor = #colorLiteral(red: 0.3529850841, green: 0.2052503526, blue: 0.187323451, alpha: 1)
//        timeStamp.adjustsFontSizeToFitWidth = true
//        setupTimestampConstraints()
//    }
//    
//    func setupTimestampConstraints() {
//        timeStamp.translatesAutoresizingMaskIntoConstraints = false
//        
//        NSLayoutConstraint.activate([
//            timeStamp.heightAnchor.constraint(equalToConstant: 20),
//            timeStamp.widthAnchor.constraint(equalToConstant: 40),
//            timeStamp.bottomAnchor.constraint(equalTo: customLabel.bottomAnchor),
//            timeStamp.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -10),
////            timeStamp.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 10),
//        ])
//    }
//
//    func setupMessageUI() {
//        customLabel.addSubview(messageBody)
//        contentView.addSubview(customLabel)
//        
//        customLabel.backgroundColor = .green
//        
//        setupCustomViewConstraints()
//        
//        messageBody.backgroundColor = #colorLiteral(red: 0.6470323801, green: 0.3927372098, blue: 0.3783177137, alpha: 1)
//        messageBody.textAlignment = .left
//        messageBody.textColor = .white
//        messageBody.font = UIFont(name: "HelveticaNeue", size: 19)
//        messageBody.layer.cornerRadius = 15
////        messageBody.lineBreakMode = .byWordWrapping
////        messageBody.clipsToBounds = true
////        label.contentEdgeInsets = UIEdgeInsets(top: 5, left: 5, bottom: 5, right: 5)
////        label.configuration?.contentInsets = NSDirectionalEdgeInsets(top: 14, leading: 14, bottom: 14, trailing: 14)
////        label.adjustsFontSizeToFitWidth = true
////        label.minimumScaleFactor = 0.5
//        messageBody.numberOfLines = 0
////        label.sizeToFit()
//        
////        setMaxWidthConstraint()
//        setupMessageConstraints()
//    }
//    
//    
//    func setupCustomViewConstraints() {
//        customLabel.translatesAutoresizingMaskIntoConstraints = false
//        
//        NSLayoutConstraint.activate([
//            customLabel.topAnchor.constraint(equalTo: topAnchor),
//            customLabel.bottomAnchor.constraint(equalTo: bottomAnchor),
//            customLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -10),
////            customLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 10),
//        ])
//    }
//  
//    func setupMessageConstraints() {
//        messageBody.translatesAutoresizingMaskIntoConstraints = false
// 
//        NSLayoutConstraint.activate([
//            messageBody.topAnchor.constraint(equalTo: customLabel.topAnchor),
//            messageBody.bottomAnchor.constraint(equalTo: customLabel.bottomAnchor),
//            messageBody.trailingAnchor.constraint(equalTo: customLabel.trailingAnchor),
//            messageBody.leadingAnchor.constraint(equalTo: customLabel.leadingAnchor),
//           ])
//    }
//    
//    var messageMaxWidth: CGFloat? {
//        didSet {
//            guard let maxWidth = messageMaxWidth else {return }
//            messageMaxWidthConstraint = customLabel.widthAnchor.constraint(lessThanOrEqualToConstant: maxWidth - leadingEdgeSpacing)
//            messageMaxWidthConstraint.isActive = true
////            calculateWidthOfLastLine(text: messageBody.text!)
////            print("===", messageBody.maxNumberOfLines)
//            createChatView()
////            let attributedText = NSAttributedString(string: messageBody.text!, attributes: [.font: messageBody.font!])
////            let lastLineMax3X = lastLineMaxX(message: attributedText, labelWidth: maxWidth - leadingEdgeSpacing)
////            print(lastLineMax3X)
//        }
//    }
//
//    func setupContentViewConstraints() {
//        contentView.translatesAutoresizingMaskIntoConstraints = false
//        
//        NSLayoutConstraint.activate([
//            contentView.leadingAnchor.constraint(equalTo: leadingAnchor),
//            contentView.trailingAnchor.constraint(equalTo: trailingAnchor),
//            contentView.topAnchor.constraint(equalTo: topAnchor),
//            contentView.bottomAnchor.constraint(equalTo: bottomAnchor)
//        ])
//    }
//    
//    // MARK: - MESSAGE LAST LINE WIDTH
//    
//    let textView = UILabel()
//    func createChatView() {
//        customLabel.addSubview(textView)
////        contentView.addSubview(customLabel)
////        setupCustomViewConstraints()
//        guard let msgViewMaxWidth = messageMaxWidth else {return} // 80% of screen width
//
////        let message = "Filler text is text flexibleLeftMargin: true tha"
//
//        // Main container view
////        let customLabel = UIView(frame: CGRect(x: UIScreen.main.bounds.width * 0.1, y: 150, width: msgViewMaxWidth, height: 0))
//        customLabel.backgroundColor = .red
//        customLabel.clipsToBounds = true
//        customLabel.layer.cornerRadius = 5
//
//        let readStatusImg = UIImageView()
//        readStatusImg.image = UIImage(named: "double-tick-indicator.png")
//        readStatusImg.frame.size = CGSize(width: 12, height: 12)
//
//        let timeLabel = UILabel()
//        timeLabel.font = UIFont.systemFont(ofSize: 10)
//        timeLabel.text = "12:12 AM"
//        timeLabel.sizeToFit()
//        timeLabel.textColor = .gray
////        timeLabel.backgroundColor = .orange
//        
////        let textView = UITextView()
////        textView.isEditable = false
////        textView.isScrollEnabled = false
////        textView.showsVerticalScrollIndicator =  false
////        textView.showsHorizontalScrollIndicator = false
//        textView.backgroundColor = .magenta
////        textView.text = message
//        textView.backgroundColor = .cyan
//        textView.numberOfLines = 0
//        
////        func setupMessageConstraints() {
//            textView.translatesAutoresizingMaskIntoConstraints = false
//     
//            NSLayoutConstraint.activate([
//                textView.topAnchor.constraint(equalTo: customLabel.topAnchor),
//                textView.bottomAnchor.constraint(equalTo: customLabel.bottomAnchor),
//                textView.trailingAnchor.constraint(equalTo: customLabel.trailingAnchor),
//                textView.leadingAnchor.constraint(equalTo: customLabel.leadingAnchor),
//               ])
////        }
//        
//        
//        // Wrap time label and status image in single view
//        // Here stackview can be used if ios 9 below are not support by your app.
//        let rightBottomView = UIView()
//        let rightBottomViewHeight: CGFloat = 16
//        // Here 7 pts is used to keep distance between timestamp and status image
//        // and 5 pts is used for trail space.
//        rightBottomView.frame.size = CGSize(width: readStatusImg.frame.width + 7 + timeLabel.frame.width + 5, height: rightBottomViewHeight)
//        rightBottomView.addSubview(timeLabel)
//        readStatusImg.frame.origin = CGPoint(x: timeLabel.frame.width + 7, y: 0)
//        rightBottomView.addSubview(readStatusImg)
//        rightBottomView.backgroundColor = .orange
//
//        // Fix right and bottom margin
////        rightBottomView.autoresizingMask = [.flexibleLeftMargin, .flexibleTopMargin]
//
//        
//        customLabel.addSubview(rightBottomView)
//
//        // Update textview height
////        textView.sizeToFit()
//        // Update message view size with textview size
////        customLabel.frame.size = textView.frame.size
//
//        // Keep at right bottom in parent view
////        rightBottomView.frame.origin = CGPoint(x: customLabel.bounds.width - rightBottomView.bounds.width, y: customLabel.bounds.height - rightBottomView.bounds.height)
//        let layoutManager = NSLayoutManager()
//        let textContainer = NSTextContainer(size: customLabel.bounds.size)
//        let textStorage = NSTextStorage(attributedString:NSAttributedString(string: textView.text!))
//        layoutManager.addTextContainer(textContainer)
//        textStorage.addLayoutManager(layoutManager)
//        // Get glyph index in textview, make sure there is atleast one character present in message
//        let lastGlyphIndex = layoutManager.glyphIndexForCharacter(at: textView.text!.count - 1)
//        // Get CGRect for last character
//        let lastLineFragmentRect = layoutManager.lineFragmentUsedRect(forGlyphAt: lastGlyphIndex, effectiveRange: nil)
//
//        // Check whether enough space is avaiable to show in last line of message, if not add extra height for timestamp
//        print(lastLineFragmentRect.maxX, textView.frame.width)
////        customLabel.frame.size.width += (rightBottomView.bounds.width + 5)
////        textView.trailingAnchor.constraint(equalTo: customLabel.trailingAnchor,constant: -(rightBottomView.bounds.width - 5)).isActive = true
//        if lastLineFragmentRect.maxX < (msgViewMaxWidth - rightBottomView.frame.width) && textView.bounds.height < 31 {
////            customLabel.frame.size.width += (rightBottomView.bounds.width + 5)
//            textView.trailingAnchor.constraint(equalTo: customLabel.trailingAnchor,constant: -(rightBottomView.bounds.width - 5)).isActive = true
//            rightBottomView.translatesAutoresizingMaskIntoConstraints = false
////            rightBottomView.centerXAnchor.constraint(equalTo: customLabel.centerXAnchor).isActive = true
////            rightBottomView.centerYAnchor.constraint(equalTo: customLabel.centerYAnchor).isActive = true
//            rightBottomView.bottomAnchor.constraint(equalTo: customLabel.bottomAnchor).isActive = true
//            rightBottomView.leftAnchor.constraint(equalTo: textView.rightAnchor).isActive = true
//            rightBottomView.topAnchor.constraint(equalTo: customLabel.topAnchor).isActive = true
//            rightBottomView.rightAnchor.constraint(equalTo: customLabel.rightAnchor).isActive = true
//
//        } else if lastLineFragmentRect.maxX > (textView.frame.width - rightBottomView.frame.width) {
//            // Subtracting 5 to reduce little top spacing for timestamp
//            rightBottomView.autoresizingMask = [.flexibleLeftMargin, .flexibleTopMargin]
//            customLabel.frame.size.height += (rightBottomViewHeight - 5)
//
//        }
////        self.layoutIfNeeded()
//    }
//    
//    
//    
//    func lastLineMaxX(message: NSAttributedString, labelWidth: CGFloat) -> CGFloat {
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
//        let lastGlyphIndex = layoutManager.glyphIndexForCharacter(at: message.length - 1)
//        let lastLineFragmentRect = layoutManager.lineFragmentUsedRect(forGlyphAt: lastGlyphIndex,
//                                                                      effectiveRange: nil)
//        return lastLineFragmentRect.maxX
//    }
//}
//
//extension UILabel {
//    var maxNumberOfLines: Int {
//        self.layoutIfNeeded()
//        let maxSize = CGSize(width: frame.size.width, height: CGFloat(MAXFLOAT))
//        let text = (self.text ?? "") as NSString
//        let textHeight = text.boundingRect(with: maxSize, options: .usesLineFragmentOrigin, attributes: [.font: font!], context: nil).height
//        let lineHeight = font.lineHeight
//        return Int(ceil(textHeight / lineHeight))
//    }
//}
