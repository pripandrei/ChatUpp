//
//  UILabel+Extensions.swift
//  ChatUpp
//
//  Created by Andrei Pripa on 10/25/23.
//

import UIKit

extension UILabel
{
    var textBoundingRect: CGRect {
        let maxSize = CGSize(width: frame.size.width, height: CGFloat(MAXFLOAT))
        let text = (self.text ?? "") as NSString
        let rect = text.boundingRect(with: maxSize, options: .usesLineFragmentOrigin, attributes: [.font: font!], context: nil)
        
        return rect
    }
    var maxNumberOfLines: Int {
        let textHeight = self.textBoundingRect.height
        let lineHeight = font.lineHeight
        return Int(ceil(textHeight / lineHeight))
    }
}
