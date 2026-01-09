//
//  UnseenMessagesBadge.swift
//  ChatUpp
//
//  Created by Andrei Pripa on 11/21/24.
//

import UIKit

class UnseenMessagesBadge: UILabel
{
    private let padding: CGFloat = 5
    
    var unseenCount: Int = 0 {
        didSet {
//            updateBadge()
        }
    }
    
    override var intrinsicContentSize: CGSize
    {
        let textSize = super.intrinsicContentSize
        let height = textSize.height + padding
        let width = max(height, textSize.width + (padding * 2))
        
        return CGSize(width: width, height: height)
    }
    
    override func layoutSubviews()
    {
        super.layoutIfNeeded()
        
        clipsToBounds = true
        layer.masksToBounds = true
        layer.cornerRadius = intrinsicContentSize.height / 2
        invalidateIntrinsicContentSize()
    }

//    private func updateBadge()
//    {
//        guard unseenCount != 0 else {
//            UIView.animate(withDuration: 0.3, delay: 0.0) { self.layer.opacity = 0.0 }
//            return
//        }
//        
//        UIView.animate(withDuration: 0.3, delay: 0.0) { self.layer.opacity = 1.0 }
//        
//        self.text = "\(self.unseenCount)"
//        self.layoutIfNeeded()
//    }
    
    func updateBadge(_ value: Int)
    {
        print("counter now",unseenCount + value)
        self.unseenCount = max(0, unseenCount + value)
        self.text = "\(self.unseenCount)"
        self.layoutIfNeeded()
    }
}
