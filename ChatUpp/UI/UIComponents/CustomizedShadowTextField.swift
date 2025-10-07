//
//  CustomizedShadowTextField.swift
//  ChatUpp
//
//  Created by Andrei Pripa on 9/22/25.
//

import UIKit

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
            textColor = #colorLiteral(red: 0.9970493562, green: 0.9588443194, blue: 0.9372033194, alpha: 1)
            font = .boldSystemFont(ofSize: 16)
            setupPlaceholderApperance(withColor: #colorLiteral(red: 0.8415537822, green: 0.7419982449, blue: 0.7352401063, alpha: 1))
        }
    }
    
    private func setupPlaceholderApperance(withColor color: UIColor)
    {
        attributedPlaceholder = NSAttributedString(string: placeholder!, attributes: [NSAttributedString.Key.foregroundColor: color])
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
    
    func animateBorder()
    {
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.error)
        
        UIView.animate(withDuration: 0.3) {
            self.layer.borderColor = #colorLiteral(red: 0.8009483814, green: 0.263946712, blue: 0.4296012521, alpha: 1)
            self.innerTopShadowLayer.shadowColor = #colorLiteral(red: 0.8541589975, green: 0.1646220684, blue: 0.2478865087, alpha: 1)
            self.innerBottomShadowLayer.shadowColor = #colorLiteral(red: 0.9945252538, green: 0.2054752707, blue: 0.415672183, alpha: 1)
        } completion: { _ in
            UIView.animate(withDuration: 0.3) {
                self.layer.borderColor = #colorLiteral(red: 0.6480519045, green: 0.6017470402, blue: 0.5859600679, alpha: 1)
                self.innerTopShadowLayer.shadowColor = #colorLiteral(red: 0.2635404468, green: 0.2457663417, blue: 0.2927972674, alpha: 1)
                self.innerBottomShadowLayer.shadowColor = #colorLiteral(red: 0.8560417295, green: 0.8963857889, blue: 0.8623355031, alpha: 1)
            }
        }
    }
}
