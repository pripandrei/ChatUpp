//
//  UIButton + extensions.swift
//  ChatUpp
//
//  Created by Andrei Pripa on 6/18/24.
//

import Foundation
import UIKit

extension CustomizedShadowButton
{
    struct ShadowConfiguration
    {
        let shadowColor: UIColor
        let fillColor: UIColor?
        let shadowOffset: CGSize
        let shadowOpacity: Float
        let shadowRadius: Float
    }
    
    enum buttonStyle
    {
        case navigationItem
        case bodyItem
    }
    
    static func getTopShadowConfig(for type: buttonStyle) -> ShadowConfiguration
    {
        switch type
        {
        case .bodyItem:
            return .init(shadowColor: #colorLiteral(red: 0.769579947, green: 0.6207371354, blue: 0.6076716781, alpha: 1),
                         fillColor: nil,
                         shadowOffset: CGSize(width: -0.9, height: -0.9),
                         shadowOpacity: 0.9,
                         shadowRadius: 0.5)
        case .navigationItem:
            return .init(shadowColor: #colorLiteral(red: 0.346744597, green: 0.251160413, blue: 0.3698410094, alpha: 1),
                         fillColor: nil,
                         shadowOffset: CGSize(width: -1.0, height: -1.0),
                         shadowOpacity: 0.3,
                         shadowRadius: 3.0)
        }
    }
    
    static func getBottomShadowConfig(for type: buttonStyle) -> ShadowConfiguration
    {
        switch type
        {
        case .bodyItem:
            return .init(shadowColor: UIColor.black,
                         fillColor: #colorLiteral(red: 0.3919434845, green: 0.3146837652, blue: 0.3270255327, alpha: 1),
                         shadowOffset: CGSize(width: 3.0, height: 3.0),
                         shadowOpacity: 0.8,
                         shadowRadius: 2.5)
        case .navigationItem:
            return .init(shadowColor: UIColor.black,
                         fillColor: UIColor.white,
                         shadowOffset: CGSize(width: 1.0, height: 1.0),
                         shadowOpacity: 0.6,
                         shadowRadius: 1.5)
        }
    }
}

class CustomizedShadowButton: UIButton
{
    private let topShadowLayer: CAShapeLayer = .init()
    private let bottomShadowLayer: CAShapeLayer = .init()
    
    private let topShadowConfig: ShadowConfiguration
    private let bottomShadowConfig: ShadowConfiguration
    
    private lazy var cornerRadius = (bounds.height / 2).rounded()
    
    init(shadowType: buttonStyle)
    {
        self.topShadowConfig = Self.getTopShadowConfig(for: shadowType)
        self.bottomShadowConfig = Self.getBottomShadowConfig(for: shadowType)
        super.init(frame: .zero)
        
        appearanceConfiguration()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func layoutSubviews()
    {
        super.layoutSubviews()
        setupTopShadow()
        setupBottomShadow()
    }
    
    private func appearanceConfiguration()
    {
        configuration = .bordered()
        configuration?.cornerStyle = .capsule
        configuration?.baseBackgroundColor = #colorLiteral(red: 0.2957182135, green: 0.2616393649, blue: 0.2596545649, alpha: 1)
        configuration?.baseForegroundColor = .white
        
        configuration?.background.cornerRadius = 17
        configuration?.background.strokeWidth = 0.6
        configuration?.background.strokeColor = #colorLiteral(red: 0.504460752, green: 0.4418102503, blue: 0.439527154, alpha: 1)
        
        imageView?.contentMode = .scaleAspectFit
    }
 
    private func setupTopShadow()
    {
        topShadowLayer.path = UIBezierPath(roundedRect: bounds,
                                           cornerRadius: cornerRadius).cgPath

        topShadowLayer.shadowColor = topShadowConfig.shadowColor.cgColor
        topShadowLayer.shadowPath = topShadowLayer.path
        topShadowLayer.shadowOffset = topShadowConfig.shadowOffset
        topShadowLayer.shadowOpacity = topShadowConfig.shadowOpacity
        topShadowLayer.shadowRadius = CGFloat(topShadowConfig.shadowRadius)
        
        layer.insertSublayer(topShadowLayer, at: 0)
    }
    
    private func setupBottomShadow()
    {
        bottomShadowLayer.path = UIBezierPath(roundedRect: bounds, cornerRadius: cornerRadius).cgPath
        bottomShadowLayer.fillColor = bottomShadowConfig.fillColor?.cgColor
        
        bottomShadowLayer.shadowColor = bottomShadowConfig.shadowColor.cgColor
//        bottomShadowLayer.shadowPath = bottomShadowLayer.path
        bottomShadowLayer.shadowOffset = bottomShadowConfig.shadowOffset
        bottomShadowLayer.shadowOpacity = bottomShadowConfig.shadowOpacity
        bottomShadowLayer.shadowRadius = CGFloat(bottomShadowConfig.shadowRadius)
        
        layer.insertSublayer(bottomShadowLayer, at: 0)
    }
    
    func setTitle(_ text: String)
    {
        configuration?.attributedTitle = AttributedString(
            text,
            attributes: AttributeContainer([
                .foregroundColor: UIColor.white,
                .font: UIFont.systemFont(ofSize: 17, weight: .medium)
            ])
        )
    }
}

extension UIButton
{
//    static func makePriorToLiquidGlassToolbarItemButton(_ text: String?,
//                                                        image: UIImage?,
//                                                        sizeConstant: CGFloat,
//                                                        action: Selector,
//                                                        on target: UIViewController) -> UIButton
//    {
//        var configuration = UIButton.Configuration.plain()
//        configuration.baseForegroundColor = .white
//        configuration.image = image
//        configuration.background.backgroundColor =  #colorLiteral(red: 0.2099263668, green: 0.151156038, blue: 0.2217666507, alpha: 1)
//         
//        // Capsule shape
//        configuration.background.cornerRadius = sizeConstant / 2
//        configuration.background.strokeWidth = 1
//
//        configuration.background.strokeColor =  #colorLiteral(red: 0.3804821372, green: 0.3410403132, blue: 0.3833082914, alpha: 1)
//        
//        if let text
//        {
//            configuration.attributedTitle = AttributedString(
//                text,
//                attributes: AttributeContainer([
//                    .font: UIFont.systemFont(ofSize: 17, weight: .medium)
//                ])
//            )
//        }
//        
//        let button = UIButton(configuration: configuration)
//        
//        button.translatesAutoresizingMaskIntoConstraints = false
//        button.heightAnchor.constraint(equalToConstant: sizeConstant).isActive = true
//
//        button.addTarget(target, action: action, for: .touchUpInside)
//        
//        if image != nil && text == nil
//        {
//            // only image is passed so make button rounded
//            button.widthAnchor.constraint(equalToConstant: sizeConstant).isActive = true
//        }
//        
//        return button
//    }
    
    static func makePriorToLiquidGlassToolbarItemButton(_ text: String?,
                                                        image: UIImage?,
                                                        action: Selector,
                                                        on target: UIViewController) -> UIButton
    {
        let button = CustomizedShadowButton(shadowType: .navigationItem)
        button.configuration?.image = image
        
        if let text {
            button.setTitle(text)
        }
        
        button.configuration?.baseBackgroundColor = #colorLiteral(red: 0.210408628, green: 0.15214324, blue: 0.2235487998, alpha: 1)
        button.addTarget(target,
                         action: action,
                         for: .touchUpInside)
        return button
    }
    
    
    @available(iOS 26.0, *)
    static func makeToolbarItemLiquidButton(_ text: String?,
                                            image: UIImage?,
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
                                      action: Selector,
                                      on target: UIViewController) -> UIButton
    {
        if #available(iOS 26, *),
           checkUIDesignRequiresCompatibility == false
        {
            return makeToolbarItemLiquidButton(text,
                                               image: image,
                                               action: action,
                                               on: target)
        } else {
            return makePriorToLiquidGlassToolbarItemButton(text,
                                                           image: image,
                                                           action: action,
                                                           on: target)
        }
    }
}
