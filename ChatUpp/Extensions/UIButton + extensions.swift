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
    
//    static func getTopShadowConfig(for type: buttonStyle) -> ShadowConfiguration
//    {
//        switch type
//        {
//        case .bodyItem:
//            return .init(shadowColor: UIColor.white,
//                         fillColor: nil,
//                         shadowOffset: CGSize(width: -2.0, height: -2.0),
//                         shadowOpacity: 0.5,
//                         shadowRadius: 3.0)
//        case .navigationItem:
//            return .init(shadowColor: #colorLiteral(red: 0.346744597, green: 0.251160413, blue: 0.3698410094, alpha: 1),
//                         fillColor: nil,
//                         shadowOffset: CGSize(width: -1.0, height: -1.0),
//                         shadowOpacity: 0.3,
//                         shadowRadius: 3.0)
//        }
//    }
    
//    static func getBottomShadowConfig(for type: buttonStyle) -> ShadowConfiguration
//    {
//        switch type
//        {
//        case .bodyItem:
//            return .init(shadowColor: UIColor.black,
//                         fillColor: UIColor.white,
//                         shadowOffset: CGSize(width: 4.0, height: 4.0),
//                         shadowOpacity: 0.8,
//                         shadowRadius: 2.5)
//        case .navigationItem:
//            return .init(shadowColor: UIColor.black,
//                         fillColor: nil,
//                         shadowOffset: CGSize(width: 1.0, height: 1.0),
//                         shadowOpacity: 0.6,
//                         shadowRadius: 1.5)
//        }
//    }
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
        
//        self.topShadowConfig = Self.getTopShadowConfig(for: .navigationItem)
//        self.bottomShadowConfig = Self.getBottomShadowConfig(for: .navigationItem)
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
    
    
    
//    private func setupTopShadow()
//       {
//   //        topShadowLayer = CAShapeLayer()
//           //        let customBounds = CGRect(x: bounds.origin.x, y: bounds.origin.y, width: bounds.width , height: bounds.height )
//           //        topShadowLayer.fillColor = UIColor.white.cgColor
//           topShadowLayer.path = UIBezierPath(roundedRect: bounds, cornerRadius: cornerRadius).cgPath
//   //        topShadowLayer.shadowColor = UIColor.white.cgColor
//   //        topShadowLayer.shadowColor = #colorLiteral(red: 0.5661385059, green: 0.4958345294, blue: 0.4932733774, alpha: 1)
////           topShadowLayer.shadowColor =  #colorLiteral(red: 0.7673342824, green: 0.6147488952, blue: 0.5844689012, alpha: 1)
////           topShadowLayer.shadowColor =  #colorLiteral(red: 0.8216122389, green: 0.6592230201, blue: 0.6279466748, alpha: 1)
////           topShadowLayer.shadowColor =  #colorLiteral(red: 0.8533291817, green: 0.6883010268, blue: 0.6738154292, alpha: 1)
//           topShadowLayer.shadowColor =  #colorLiteral(red: 0.769579947, green: 0.6207371354, blue: 0.6076716781, alpha: 1)
//           topShadowLayer.shadowPath = topShadowLayer.path
//           topShadowLayer.shadowOffset = CGSize(width: -0.9, height: -0.9)
//           topShadowLayer.shadowOpacity = 0.9
//           topShadowLayer.shadowRadius = 0.5
//
//           layer.insertSublayer(topShadowLayer, at: 0)
//       }
//
//       private func setupBottomShadow() {
//   //        bottomShadowLayer = CAShapeLayer()
//           bottomShadowLayer.path = UIBezierPath(roundedRect: bounds, cornerRadius: cornerRadius).cgPath
//   //        bottomShadowLayer.fillColor = UIColor.white.cgColor
//   //        bottomShadowLayer.fillColor = #colorLiteral(red: 0.50518924, green: 0.4056376219, blue: 0.4215570688, alpha: 1)
//           bottomShadowLayer.fillColor =  #colorLiteral(red: 0.3919434845, green: 0.3146837652, blue: 0.3270255327, alpha: 1)
//
//           bottomShadowLayer.shadowColor = UIColor.black.cgColor
//           //        bottomShadowLayer.shadowPath = bottomShadowLayer.path
//           bottomShadowLayer.shadowOffset = CGSize(width: 3.0, height: 3.0)
//           bottomShadowLayer.shadowOpacity = 0.8
//           bottomShadowLayer.shadowRadius = 2.5
//
//           layer.insertSublayer(bottomShadowLayer, at: 0)
//       }
//       
//    
    
    
//    private func layerConfiguration() {
//        layer.borderWidth = 1.0
////        layer.borderColor = #colorLiteral(red: 0.2589692865, green: 0.2283333046, blue: 0.2262536391, alpha: 1)
//        layer.borderColor =  #colorLiteral(red: 0.2884907424, green: 0.2526405454, blue: 0.2513317764, alpha: 1)
////        layer.borderColor = #colorLiteral(red: 0.1715064049, green: 0.157856971, blue: 0.138739109, alpha: 1)
//
//        layer.cornerRadius = cornerRadius
//    }
    
//    private func setupTopShadow()
//    {
//        topShadowLayer.path = UIBezierPath(roundedRect: bounds,
//                                           cornerRadius: cornerRadius).cgPath
//        topShadowLayer.shadowPath = topShadowLayer.path
//        
//        topShadowLayer.fillColor = self.bottomShadowConfig.fillColor?.cgColor
//        topShadowLayer.shadowColor = self.bottomShadowConfig.shadowColor.cgColor
//        topShadowLayer.shadowOffset = self.bottomShadowConfig.shadowOffset
//        topShadowLayer.shadowOpacity = self.bottomShadowConfig.shadowOpacity
//        topShadowLayer.shadowRadius = CGFloat(self.bottomShadowConfig.shadowRadius)
//        
//        layer.insertSublayer(topShadowLayer, at: 0)
//    }
//    
//    private func setupBottomShadow()
//    {
//        bottomShadowLayer.path = UIBezierPath(roundedRect: bounds,
//                                              cornerRadius: cornerRadius).cgPath
//        bottomShadowLayer.shadowPath = bottomShadowLayer.path
//        
//        bottomShadowLayer.fillColor = self.bottomShadowConfig.fillColor?.cgColor
//        bottomShadowLayer.shadowColor = self.bottomShadowConfig.shadowColor.cgColor
//        //        bottomShadowLayer.shadowPath = bottomShadowLayer.path
//        bottomShadowLayer.shadowOffset = self.bottomShadowConfig.shadowOffset
//        bottomShadowLayer.shadowOpacity = self.bottomShadowConfig.shadowOpacity
//        bottomShadowLayer.shadowRadius = CGFloat(self.bottomShadowConfig.shadowRadius)
//        
//        layer.insertSublayer(bottomShadowLayer, at: 0)
//    }
    
    
    
    
    ////// ========= final here
    private func setupTopShadow()
    {
        //        topShadowLayer.fillColor = UIColor.white.cgColor
        topShadowLayer.path = UIBezierPath(roundedRect: bounds,
                                           cornerRadius: cornerRadius).cgPath
//        topShadowLayer.shadowColor = UIColor.white.cgColor
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
                bottomShadowLayer.shadowPath = bottomShadowLayer.path
        bottomShadowLayer.shadowOffset = bottomShadowConfig.shadowOffset
        bottomShadowLayer.shadowOpacity = bottomShadowConfig.shadowOpacity
        bottomShadowLayer.shadowRadius = CGFloat(bottomShadowConfig.shadowRadius)
        
        layer.insertSublayer(bottomShadowLayer, at: 0)
    }
//    
    
    
    
    
//
//    private func setupTopShadow()
//    {
////        topShadowLayer = CAShapeLayer()
//        //        let customBounds = CGRect(x: bounds.origin.x, y: bounds.origin.y, width: bounds.width , height: bounds.height )
//        //        topShadowLayer.fillColor = UIColor.white.cgColor
//        topShadowLayer.path = UIBezierPath(roundedRect: bounds, cornerRadius: cornerRadius).cgPath
//        topShadowLayer.shadowColor = UIColor.white.cgColor
//        topShadowLayer.shadowPath = topShadowLayer.path
//        topShadowLayer.shadowOffset = CGSize(width: -2.0, height: -2.0)
//        topShadowLayer.shadowOpacity = 0.5
//        topShadowLayer.shadowRadius = 3.0
//
//        layer.insertSublayer(topShadowLayer, at: 0)
//    }
//
//    private func setupBottomShadow() {
////        bottomShadowLayer = CAShapeLayer()
//        bottomShadowLayer.path = UIBezierPath(roundedRect: bounds, cornerRadius: cornerRadius).cgPath
//        bottomShadowLayer.fillColor = UIColor.white.cgColor
//
//        bottomShadowLayer.shadowColor = UIColor.black.cgColor
//        //        bottomShadowLayer.shadowPath = bottomShadowLayer.path
//        bottomShadowLayer.shadowOffset = CGSize(width: 4.0, height: 4.0)
//        bottomShadowLayer.shadowOpacity = 0.8
//        bottomShadowLayer.shadowRadius = 2.5
//
//        layer.insertSublayer(bottomShadowLayer, at: 0)
//    }
    
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
        configuration.background.backgroundColor =  #colorLiteral(red: 0.2099263668, green: 0.151156038, blue: 0.2217666507, alpha: 1)
         
        // Capsule shape
        configuration.background.cornerRadius = sizeConstant / 2
        configuration.background.strokeWidth = 1

        configuration.background.strokeColor =  #colorLiteral(red: 0.3804821372, green: 0.3410403132, blue: 0.3833082914, alpha: 1)
        
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


func createButtonItem(title: String?, image: UIImage?, tintColor: UIColor = .white, prominentBorderSide: ViewSide? = .top) -> UIButton
{
    var config = UIButton.Configuration.plain()
    
    config.image = image
    config.title = title
    
    config.imagePlacement = .leading
    config.imagePadding = 8
    
    config.baseForegroundColor = tintColor
    
    if title != nil {
        config.titleTextAttributesTransformer = UIConfigurationTextAttributesTransformer { incoming in
            var outgoing = incoming
            outgoing.font = .systemFont(ofSize: 13, weight: .medium)
            return outgoing
        }
    }
    
    let size: CGFloat = 37.0
    
    if image != nil {
        let imageConfig = UIImage.SymbolConfiguration(pointSize: size / 2)
        config.preferredSymbolConfigurationForImage = imageConfig
    }
    
    config.contentInsets = NSDirectionalEdgeInsets(top: 5, leading: 5, bottom: 5, trailing: 5)
    
    let button = UIButton(configuration: config)
    
    button.backgroundColor =  #colorLiteral(red: 0.2959649265, green: 0.261515528, blue: 0.2578511536, alpha: 1)
    button.layer.cornerRadius = size / 2
    button.layer.borderWidth = 1
    button.layer.borderColor =  #colorLiteral(red: 0.5125256181, green: 0.4497631192, blue: 0.4526336193, alpha: 1).cgColor
    
    button.translatesAutoresizingMaskIntoConstraints = false
    
    // If only image (no title), make it a perfect circle
    if title == nil && image != nil {
        NSLayoutConstraint.activate([
            button.widthAnchor.constraint(equalToConstant: size),
            button.heightAnchor.constraint(equalToConstant: size)
        ])
    } else {
        // If title exists, allow width to expand
        NSLayoutConstraint.activate([
            button.widthAnchor.constraint(greaterThanOrEqualToConstant: size),
            button.heightAnchor.constraint(equalToConstant: size)
        ])
        
        // Adjust corner radius for pill shape when button expands
        button.layer.cornerRadius = size / 2
    }
    
    // Add prominent border on specific side
    if let side = prominentBorderSide {
        // Need to add border after layout, so use layoutSubviews
        button.layoutIfNeeded()
        addProminentBorder(to: button, side: side, size: size)
    }
    
    return button
}

enum ViewSide {
    case top, bottom, left, right
}

func addProminentBorder(to button: UIButton, side: ViewSide, size: CGFloat) {
    let borderThickness: CGFloat = 3.0
    let borderColor = UIColor.systemBlue.cgColor // or any color you want
    
    let border = CALayer()
    border.backgroundColor = borderColor
    border.name = "prominentBorder" // so you can identify/remove it later if needed
    
    // Get the actual button frame
    let frame = button.bounds.isEmpty ? CGRect(x: 0, y: 0, width: size, height: size) : button.bounds
    
    switch side {
    case .top:
        border.frame = CGRect(x: 0, y: 0, width: frame.width, height: borderThickness)
    case .bottom:
        border.frame = CGRect(x: 0, y: frame.height - borderThickness, width: frame.width, height: borderThickness)
    case .left:
        border.frame = CGRect(x: 0, y: 0, width: borderThickness, height: frame.height)
    case .right:
        border.frame = CGRect(x: frame.width - borderThickness, y: 0, width: borderThickness, height: frame.height)
    }
    
    button.layer.addSublayer(border)
}

//// Usage example:
//let icon = UIImage(systemName: "star.fill")
//let button = createButton(
//    title: "Option",
//    image: icon,
//    tintColor: UIColor(ColorScheme.actionButtonsTintColor)
//)
//
//// With nil values:
//let buttonNoImage = createButton(title: "Text Only", image: nil, tintColor: .blue)
//let buttonNoText = createButton(title: nil, image: icon, tintColor: .blue)


class HighlightedButton: UIButton {
    private var highlightLayer: CAShapeLayer?
    
    override func layoutSubviews() {
        super.layoutSubviews()
        updateHighlight()
    }
    
    private func updateHighlight() {
        highlightLayer?.removeFromSuperlayer()
        
        let shapeLayer = CAShapeLayer()
        shapeLayer.lineWidth = 2.5
        shapeLayer.strokeColor = UIColor.white.withAlphaComponent(0.35).cgColor
        shapeLayer.fillColor = UIColor.clear.cgColor
        shapeLayer.lineCap = .round
        
        let path = UIBezierPath()
        let radius = bounds.height / 2 - 1.5
        let center = CGPoint(x: bounds.height / 2, y: bounds.height / 2)
        
        // Draw arc on top-left portion (adjust angles as needed)
        path.addArc(withCenter: center,
                    radius: radius,
                    startAngle: .pi * 1.15,  // top-left
                    endAngle: .pi * 0.35,    // top-right
                    clockwise: true)
        
        shapeLayer.path = path.cgPath
        layer.addSublayer(shapeLayer)
        highlightLayer = shapeLayer
    }
}
