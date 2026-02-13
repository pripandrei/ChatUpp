//
//  UIButton + extensions.swift
//  ChatUpp
//
//  Created by Andrei Pripa on 6/18/24.
//

import Foundation
import UIKit

class CustomizedShadowButton: UIButton {
    
    private var topShadowLayer: CAShapeLayer!
    private var bottomShadowLayer: CAShapeLayer!
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        appearanceConfiguration()
        layerConfiguration()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        if topShadowLayer == nil {
            topShadow()
            bottomShadow()
        }
    }
    
    private func appearanceConfiguration() {
        configuration = .bordered()
        configuration?.baseBackgroundColor = #colorLiteral(red: 0.2957182135, green: 0.2616393649, blue: 0.2596545649, alpha: 1)
        configuration?.baseForegroundColor = .white
        configuration?.cornerStyle = .capsule
        imageView?.contentMode = .scaleAspectFit
    }
    
    private func layerConfiguration() {
        layer.borderWidth = 1.0
        layer.borderColor = #colorLiteral(red: 0.2589692865, green: 0.2283333046, blue: 0.2262536391, alpha: 1)
        layer.cornerRadius = 20
    }
    
    private  func topShadow() {
        topShadowLayer = CAShapeLayer()
        //        let customBounds = CGRect(x: bounds.origin.x, y: bounds.origin.y, width: bounds.width , height: bounds.height )
        //        topShadowLayer.fillColor = UIColor.white.cgColor
        topShadowLayer.path = UIBezierPath(roundedRect: bounds, cornerRadius: 20).cgPath
        topShadowLayer.shadowColor = UIColor.white.cgColor
        topShadowLayer.shadowPath = topShadowLayer.path
        topShadowLayer.shadowOffset = CGSize(width: -2.0, height: -2.0)
        topShadowLayer.shadowOpacity = 0.5
        topShadowLayer.shadowRadius = 3.0
        
        layer.insertSublayer(topShadowLayer, at: 0)
    }
    
    private func bottomShadow() {
        bottomShadowLayer = CAShapeLayer()
        bottomShadowLayer.path = UIBezierPath(roundedRect: bounds, cornerRadius: 20).cgPath
        bottomShadowLayer.fillColor = UIColor.white.cgColor
        
        bottomShadowLayer.shadowColor = UIColor.black.cgColor
        //        bottomShadowLayer.shadowPath = bottomShadowLayer.path
        bottomShadowLayer.shadowOffset = CGSize(width: 4.0, height: 4.0)
        bottomShadowLayer.shadowOpacity = 0.8
        bottomShadowLayer.shadowRadius = 2.5
        
        layer.insertSublayer(bottomShadowLayer, at: 0)
    }
}

extension UIButton
{
    static func makePriorToLiquidGlassToolbarItemButton(_ text: String?,
                                                        image: UIImage?,
                                                        sizeConstant: CGFloat,
                                                        action: Selector,
                                                        on target: UIViewController) -> UIButton
    {
        var configuration = UIButton.Configuration.plain()
        configuration.baseForegroundColor = .white
        configuration.image = image
//        configuration.background.backgroundColor = ColorScheme.messageTextFieldBackgroundColor.withAlphaComponent(0.9)
        configuration.background.backgroundColor = #colorLiteral(red: 0.2099263668, green: 0.151156038, blue: 0.2217666507, alpha: 1)
         
        // Capsule shape
        configuration.background.cornerRadius = sizeConstant / 2
        configuration.background.strokeWidth = 1

        configuration.background.strokeColor = #colorLiteral(red: 0.3804821372, green: 0.3410403132, blue: 0.3833082914, alpha: 1)
        
        if let text
        {
            configuration.attributedTitle = AttributedString(
                text,
                attributes: AttributeContainer([
                    .font: UIFont.systemFont(ofSize: 17, weight: .medium)
                ])
            )
        }
        
        let button = UIButton(configuration: configuration)
        
        button.translatesAutoresizingMaskIntoConstraints = false
        button.heightAnchor.constraint(equalToConstant: sizeConstant).isActive = true

        button.addTarget(target, action: action, for: .touchUpInside)
        
        if image != nil && text == nil
        {
            // only image is passed so make button rounded
            button.widthAnchor.constraint(equalToConstant: sizeConstant).isActive = true
        }
        
        return button
    }
    
    @available(iOS 26.0, *)
    static func makeToolbarItemLiquidButton(_ text: String?,
                                            image: UIImage?,
                                            sizeConstant: CGFloat,
                                            action: Selector,
                                            on target: UIViewController) -> UIButton
    {
        var configuration = UIButton.Configuration.borderless()
        configuration.image = image
//        configuration.background.backgroundColor = .clear
    
        if let text
        {
            configuration.attributedTitle = AttributedString(
                text,
                attributes: AttributeContainer([
                    .foregroundColor: UIColor.white,
                    .font: UIFont.systemFont(ofSize: 17, weight: .medium)
                ])
            )
        }
        
        let button = UIButton(configuration: configuration)
        button.addTarget(target, action: action, for: .touchUpInside)
//        button.tintAdjustmentMode = .normal
        return button
    }
    
    static func makeToolbarItemButton(_ text: String?,
                                      image: UIImage?,
                                      sizeConstant: CGFloat,
                                      action: Selector,
                                      on target: UIViewController) -> UIButton
    {
        if #available(iOS 26, *),
           checkUIDesignRequiresCompatibility == false
        {
            return makeToolbarItemLiquidButton(text,
                                               image: image,
                                               sizeConstant: sizeConstant,
                                               action: action,
                                               on: target)
        } else {
            return makePriorToLiquidGlassToolbarItemButton(text,
                                                           image: image,
                                                           sizeConstant: sizeConstant,
                                                           action: action,
                                                           on: target)
        }
    }
    
}

