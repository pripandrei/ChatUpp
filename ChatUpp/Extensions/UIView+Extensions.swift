//
//  UIView+Extensions.swift
//  ChatUpp
//
//  Created by Andrei Pripa on 9/26/23.
//

//import Foundation
import UIKit

extension UIView {
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
