//
//  TextViewShadowConfigurable.swift
//  ChatUpp
//
//  Created by Andrei Pripa on 4/7/24.
//

import Foundation
import UIKit

protocol TextViewShadowConfigurable: AnyObject
{
    var innerTopShadowLayer: CALayer! {get set}
    var innerBottomShadowLayer: CALayer! {get set}
    func setupTopShadow()
    func setupBottomShadow()
}

extension TextViewShadowConfigurable where Self: UITextField
{
    func setupTopShadow() {
        innerTopShadowLayer = CALayer()
        innerTopShadowLayer.frame = self.bounds
        
        // Shadow path (1pt ring around bounds)
        let radius = self.intrinsicContentSize.height/2
        let path = UIBezierPath(roundedRect: innerTopShadowLayer.bounds.insetBy(dx: -7, dy: -7), cornerRadius: radius)
        let cutout = UIBezierPath(roundedRect: innerTopShadowLayer.bounds, cornerRadius: radius).reversing()
        
        path.append(cutout)
        
        innerTopShadowLayer.shadowPath = path.cgPath
        innerTopShadowLayer.masksToBounds = true
        
        // Shadow properties
        innerTopShadowLayer.shadowColor = #colorLiteral(red: 0.2635404468, green: 0.2457663417, blue: 0.2927972674, alpha: 1)
        innerTopShadowLayer.shadowOffset = CGSize(width: 3.5, height: 3.5)
        innerTopShadowLayer.shadowOpacity = 0.7
        innerTopShadowLayer.shadowRadius = 1.8
        innerTopShadowLayer.cornerRadius = self.intrinsicContentSize.height/2
        self.layer.addSublayer(innerTopShadowLayer)
    }
    
    func setupBottomShadow() {
        innerBottomShadowLayer = CALayer()
        //
        innerBottomShadowLayer.frame = self.bounds
        innerBottomShadowLayer.shadowColor = #colorLiteral(red: 0.8560417295, green: 0.8963857889, blue: 0.8623355031, alpha: 1).cgColor
        innerBottomShadowLayer.shadowOffset = CGSize(width: 1.0, height: 1.0)
        innerBottomShadowLayer.shadowOpacity = 0.7
        innerBottomShadowLayer.shadowRadius = 1.3
        innerBottomShadowLayer.masksToBounds = true
        innerBottomShadowLayer.cornerRadius = self.intrinsicContentSize.height/2
        //        shadowLayer.borderWidth = 1
        
        // Adjust the position of the shadow to the bottom right
        let radius = self.intrinsicContentSize.height/2
        let shadowPath = UIBezierPath(roundedRect: innerBottomShadowLayer.bounds.offsetBy(dx: -3.5, dy: -3.5), cornerRadius: radius)
        let cutout = UIBezierPath(roundedRect: innerBottomShadowLayer.bounds, cornerRadius: radius).reversing()
        
        shadowPath.append(cutout)
        innerBottomShadowLayer.shadowPath = shadowPath.cgPath
        //        layoutIfNeeded()
        self.layer.addSublayer(innerBottomShadowLayer)
    }
    
    func applyShadows() {
        setupTopShadow()
        setupBottomShadow()
    }
}

