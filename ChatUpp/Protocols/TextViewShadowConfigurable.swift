//
//  TextViewShadowConfigurable.swift
//  ChatUpp
//
//  Created by Andrei Pripa on 4/7/24.
//

import Foundation
import UIKit

protocol TextViewShadowConfigurable {
    func setupTopShadow()
    func setupBottomShadow()
}

extension TextViewShadowConfigurable where Self: UITextField
{
    func setupTopShadow() {
        self.borderStyle = .none
        self.layer.cornerRadius = self.intrinsicContentSize.height/2
        self.layer.borderWidth = 1.5
        self.layer.borderColor = #colorLiteral(red: 0.822324276, green: 0.8223242164, blue: 0.8223242164, alpha: 1)
        self.backgroundColor = #colorLiteral(red: 0.7896713614, green: 0.7896713614, blue: 0.7896713614, alpha: 1)
        
        let innerShadow = CALayer()
        innerShadow.frame = self.bounds
        
        // Shadow path (1pt ring around bounds)
        let radius = self.intrinsicContentSize.height/2
        let path = UIBezierPath(roundedRect: innerShadow.bounds.insetBy(dx: -7, dy: -7), cornerRadius: radius)
        let cutout = UIBezierPath(roundedRect: innerShadow.bounds, cornerRadius: radius).reversing()
        
        path.append(cutout)
        
        innerShadow.shadowPath = path.cgPath
        innerShadow.masksToBounds = true
        
        // Shadow properties
        innerShadow.shadowColor = #colorLiteral(red: 0.2635404468, green: 0.2457663417, blue: 0.2927972674, alpha: 1)
        innerShadow.shadowOffset = CGSize(width: 3.5, height: 3.5)
        innerShadow.shadowOpacity = 0.7
        innerShadow.shadowRadius = 1.8
        innerShadow.cornerRadius = self.intrinsicContentSize.height/2
        self.layer.addSublayer(innerShadow)
    }
    
    func setupBottomShadow() {
        let shadowLayer = CALayer()
        //
        shadowLayer.frame = self.bounds
        shadowLayer.shadowColor = #colorLiteral(red: 0.8560417295, green: 0.8963857889, blue: 0.8623355031, alpha: 1).cgColor
        shadowLayer.shadowOffset = CGSize(width: 1.0, height: 1.0)
        shadowLayer.shadowOpacity = 0.7
        shadowLayer.shadowRadius = 1.3
        shadowLayer.masksToBounds = true
        shadowLayer.cornerRadius = self.intrinsicContentSize.height/2
        //        shadowLayer.borderWidth = 1
        
        // Adjust the position of the shadow to the bottom right
        let radius = self.intrinsicContentSize.height/2
        let shadowPath = UIBezierPath(roundedRect: shadowLayer.bounds.offsetBy(dx: -3.5, dy: -3.5), cornerRadius: radius)
        let cutout = UIBezierPath(roundedRect: shadowLayer.bounds, cornerRadius: radius).reversing()
        
        shadowPath.append(cutout)
        shadowLayer.shadowPath = shadowPath.cgPath
        //        layoutIfNeeded()
        self.layer.addSublayer(shadowLayer)
    }
}
