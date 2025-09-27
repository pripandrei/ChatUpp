//
//  UITextView+Extensions.swift
//  ChatUpp
//
//  Created by Andrei Pripa on 6/22/24.
//

import UIKit
import FlagPhoneNumber

//MARK: - TEXTFIELD TEXT RECT ADJUST
extension CustomizedShadowTextField
{
    open override func textRect(forBounds bounds: CGRect) -> CGRect
    {
        var rect = super.textRect(forBounds: bounds)
        let shiftSize = 20.0
        rect.origin.x += shiftSize
        rect.size.width -= (shiftSize * 2)
        return rect
    }
    open override func editingRect(forBounds bounds: CGRect) -> CGRect {
        return textRect(forBounds: bounds)
    }
}

//MARK: - TEXTFIELD TEXT RECT ADJUST
extension CustomFPNTextField
{
    open override func textRect(forBounds bounds: CGRect) -> CGRect {
        var rect = super.textRect(forBounds: bounds)
        let shiftSize = 20.0
        rect.origin.x += shiftSize
        rect.size.width -= (shiftSize * 2)
        return rect
    }
    open override func editingRect(forBounds bounds: CGRect) -> CGRect {
        return textRect(forBounds: bounds)
    }
}

extension UITextView {
    var textBoundingRect: CGRect {
        let maxSize = CGSize(width: frame.size.width, height: CGFloat(MAXFLOAT))
        let text = (self.text ?? "") as NSString
        let rect = text.boundingRect(with: maxSize, options: .usesLineFragmentOrigin, attributes: [.font: font!], context: nil)
        
        return rect
    }
}
