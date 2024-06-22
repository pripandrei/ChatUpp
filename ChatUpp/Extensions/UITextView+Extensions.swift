//
//  UITextView+Extensions.swift
//  ChatUpp
//
//  Created by Andrei Pripa on 6/22/24.
//


import UIKit
import FlagPhoneNumber

class CustomizedShadowTextField: UITextField, TextViewShadowConfigurable {
    var innerTopShadowLayer: CALayer!
    var innerBottomShadowLayer: CALayer!
    
    override init(frame: CGRect) {
        super.init(frame: frame)
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        if innerTopShadowLayer == nil {
            configureLayer()
            applyShadows()
            textColor = .black
            attributedPlaceholder = NSAttributedString(string: placeholder!, attributes: [NSAttributedString.Key.foregroundColor: UIColor.gray])
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func configureLayer() {
        self.borderStyle = .none
        self.backgroundColor = #colorLiteral(red: 0.6334663358, green: 0.5882036454, blue: 0.5727719872, alpha: 1)
        self.layer.cornerRadius = self.intrinsicContentSize.height/2
        self.layer.borderWidth = 1.5
        self.layer.borderColor = #colorLiteral(red: 0.6480519045, green: 0.6017470402, blue: 0.5859600679, alpha: 1)
    }
}

//MARK: - TEXTFIELD TEXT RECT ADJUST
extension CustomizedShadowTextField {
    open override func textRect(forBounds bounds: CGRect) -> CGRect {
        var rect = super.textRect(forBounds: bounds)
        rect.origin.x += 20
        rect.size.width -= 30
        return rect
    }
    open override func editingRect(forBounds bounds: CGRect) -> CGRect {
        return textRect(forBounds: bounds)
    }
}



//MARK: - CUSTOMIZED FLAG PHONE NUMBER TEXTFIELD
class CustomFPNTextField: FPNTextField, TextViewShadowConfigurable {
    
    var innerTopShadowLayer: CALayer!
    var innerBottomShadowLayer: CALayer!
    
    private let separatorBetweenDialCodeAndTextPhone: UIView = UIView()
    
    var dialCodeAndFlagButtonMainContainer: UIView? {
        return flagButton.superview
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        if innerTopShadowLayer == nil {
            configureLayer()
            applyShadows()
            textColor = .black
            attributedPlaceholder = NSAttributedString(string: placeholder!, attributes: [NSAttributedString.Key.foregroundColor: UIColor.gray])
        }
    }
    convenience init() {
        self.init(frame: .zero)
        
        setupSeparator()
        moveRightDialCodeAndFlagButtonMainContainer()
    }
    override init(frame: CGRect) {
        super.init(frame: frame)
    }
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func configureLayer() {
        self.borderStyle = .none
        self.backgroundColor = #colorLiteral(red: 0.7896713614, green: 0.7896713614, blue: 0.7896713614, alpha: 1)
        self.layer.cornerRadius = self.intrinsicContentSize.height/2
        self.layer.borderWidth = 1.5
        self.layer.borderColor = #colorLiteral(red: 0.822324276, green: 0.8223242164, blue: 0.8223242164, alpha: 1)
    }
    
    // GESTURES
    func addGestureRecognizerToDialCode(_ tapGestureRecognizer: UITapGestureRecognizer) {
        dialCodeAndFlagButtonMainContainer?.addGestureRecognizer(tapGestureRecognizer)
    }
    
    // TEXTVIEW UI SETUP
    private func moveRightDialCodeAndFlagButtonMainContainer() {
        dialCodeAndFlagButtonMainContainer?.subviews.forEach({ view in
            view.transform = CGAffineTransform(translationX: 5, y: 0)
        })
    }
    
    func setupSeparator() {
        dialCodeAndFlagButtonMainContainer?.addSubview(separatorBetweenDialCodeAndTextPhone)
        separatorBetweenDialCodeAndTextPhone.backgroundColor = .black
        
        separatorBetweenDialCodeAndTextPhone.translatesAutoresizingMaskIntoConstraints = false
        
        separatorBetweenDialCodeAndTextPhone.widthAnchor.constraint(equalToConstant: 1).isActive = true
        separatorBetweenDialCodeAndTextPhone.heightAnchor.constraint(equalToConstant: self.intrinsicContentSize.height).isActive = true
        separatorBetweenDialCodeAndTextPhone.leadingAnchor.constraint(equalTo: dialCodeAndFlagButtonMainContainer!.trailingAnchor, constant: 8).isActive = true
        separatorBetweenDialCodeAndTextPhone.centerYAnchor.constraint(equalTo: dialCodeAndFlagButtonMainContainer!.centerYAnchor).isActive = true
    }
}

//MARK: - TEXTFIELD TEXT RECT ADJUST
extension CustomFPNTextField {
    open override func textRect(forBounds bounds: CGRect) -> CGRect {
        var rect = super.textRect(forBounds: bounds)
        rect.origin.x += 20
        rect.size.width -= 30
        return rect
    }
    open override func editingRect(forBounds bounds: CGRect) -> CGRect {
        return textRect(forBounds: bounds)
    }
}
