//
//  UIView+Extensions.swift
//  ChatUpp
//
//  Created by Andrei Pripa on 9/26/23.
//

//import Foundation
import UIKit
import YYText

extension UIView
{
    func pin(to superView: UIView) {
        translatesAutoresizingMaskIntoConstraints                             = false
        topAnchor.constraint(equalTo: superView.topAnchor).isActive           = true
        bottomAnchor.constraint(equalTo: superView.bottomAnchor).isActive     = true
        leadingAnchor.constraint(equalTo: superView.leadingAnchor).isActive   = true
        trailingAnchor.constraint(equalTo: superView.trailingAnchor).isActive = true
    }
    
    func addSubviews(_ uiView: UIView...) {
        uiView.forEach { view in
            addSubview(view)
        }
    }
}

extension UIView
{
    func addBlurEffect(style: UIBlurEffect.Style = .systemThinMaterialDark,
                       backgroundColor: UIColor? = nil,
                       alpha: CGFloat = 0.5) -> UIVisualEffectView
    {
        let blurView = UIVisualEffectView(effect: UIBlurEffect(style: style))
        blurView.translatesAutoresizingMaskIntoConstraints = false
        
        if let backgroundColor = backgroundColor {
            blurView.backgroundColor = backgroundColor.withAlphaComponent(alpha)
        }
        
        insertSubview(blurView, at: 0)
        
        NSLayoutConstraint.activate([
            blurView.topAnchor.constraint(equalTo: topAnchor),
            blurView.leadingAnchor.constraint(equalTo: leadingAnchor),
            blurView.trailingAnchor.constraint(equalTo: trailingAnchor),
            blurView.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])
        
        return blurView
    }
    
}
