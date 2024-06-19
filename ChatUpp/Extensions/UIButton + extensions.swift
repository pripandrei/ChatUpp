//
//  UIButton + extensions.swift
//  ChatUpp
//
//  Created by Andrei Pripa on 6/18/24.
//

import Foundation
import UIKit


//extension UIButton {
//
//
//    func topShadow() {
//        layer.borderWidth = 1
//        layer.borderColor = #colorLiteral(red: 0.1995372854, green: 0.1759320898, blue: 0.1743296959, alpha: 1)
//        layer.cornerRadius = 20
//        var topShadowLayer = CAShapeLayer()
//
//        let customBounds = CGRect(x: bounds.origin.x, y: bounds.origin.y, width: bounds.width , height: bounds.height )
//
//        topShadowLayer.path = UIBezierPath(roundedRect: customBounds, cornerRadius: 20).cgPath
////        topShadowLayer.fillColor = UIColor.white.cgColor
//        topShadowLayer.shadowColor = UIColor.white.cgColor
////        topShadowLayer.borderWidth = 1.5
//        topShadowLayer.shadowPath = topShadowLayer.path
//        topShadowLayer.shadowOffset = CGSize(width: -2.0, height: -2.0)
//        topShadowLayer.shadowOpacity = 0.6
//        topShadowLayer.shadowRadius = 1.6
//
//        layer.insertSublayer(topShadowLayer, at: 0)
//    }
//
//    func bottomShadow() {
//        var bottomShadowLayer = CAShapeLayer()
//        bottomShadowLayer.path = UIBezierPath(roundedRect: bounds, cornerRadius: 20).cgPath
//        bottomShadowLayer.fillColor = UIColor.white.cgColor
//
//        bottomShadowLayer.shadowColor = UIColor.black.cgColor
////        bottomShadowLayer.shadowPath = bottomShadowLayer.path
//        bottomShadowLayer.shadowOffset = CGSize(width: 4.0, height: 4.0)
//        bottomShadowLayer.shadowOpacity = 0.8
//        bottomShadowLayer.shadowRadius = 5
//
//        layer.insertSublayer(bottomShadowLayer, at: 0)
//    }
//}

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

//
//var topShadowLayer = CAShapeLayer()
//
//var shadowPath = UIBezierPath(roundedRect: bounds, cornerRadius: 20)
////        topShadowLayer.path = shadowPath
//topShadowLayer.fillColor = UIColor.white.cgColor
//topShadowLayer.shadowColor = UIColor.white.cgColor
////        topShadowLayer.borderWidth = 1.5
//topShadowLayer.shadowPath = topShadowLayer.path
//topShadowLayer.shadowOffset = CGSize(width: -1.0, height: -1.0)
//topShadowLayer.shadowOpacity = 1
//topShadowLayer.shadowRadius = 0.6
//
//let boundss = CGRect(x: self.bounds.origin.x, y: self.bounds.origin.y, width: topShadowLayer.bounds.width / 2 , height: topShadowLayer.bounds.height / 2)
//let cutout = UIBezierPath(roundedRect: boundss, cornerRadius: 20).reversing()
//shadowPath.append(cutout)
//topShadowLayer.shadowPath = shadowPath.cgPath
//
//layer.insertSublayer(topShadowLayer, at: 0)
