//
//  String+Extensions.swift
//  ChatUpp
//
//  Created by Andrei Pripa on 10/25/23.
//

import Foundation
import UIKit

extension String
{
    func getSize() -> CGSize {
        guard let font = UIFont(name: "HelveticaNeue", size: 17) else { return CGSize.zero }
        let attributes: [NSAttributedString.Key: Any] = [.font: font,
                          .foregroundColor: UIColor.white,
                          .paragraphStyle: {
                              let paragraphStyle = NSMutableParagraphStyle()
                              paragraphStyle.alignment = .left
                              paragraphStyle.lineBreakMode = .byWordWrapping
                              return paragraphStyle
                          }()]
        return self.size(withAttributes: attributes)
    }
    
    func addSuffix(_ sufix: String) -> Self
    {
        if self.hasSuffix(".jpeg") {
            return self.replacingOccurrences(of: ".jpeg", with: "_\(sufix).jpeg")
        }
        if self.hasSuffix(".jpg") {
            return self.replacingOccurrences(of: ".jpg", with: "_\(sufix).jpg")
        }
        return self
    }
    
    func removeSuffix(_ sufix: String) -> Self
    {
        if self.hasSuffix(".jpeg") {
            return self.replacingOccurrences(of: "_\(sufix).jpeg", with: ".jpeg")
        }
        if self.hasSuffix(".jpg") {
            return self.replacingOccurrences(of: "_\(sufix).jpg", with: ".jpg")
        }
        return self
    }
    
    func normalizedSerachText() -> Self
    {
        let delimiters = CharacterSet(charactersIn: " /.:!?;[]%$£@^&()-+=<>,")
        
        return self
            .folding(options: .diacriticInsensitive, locale: .current)
            .components(separatedBy: delimiters)
            .joined(separator: " ")
            .split(whereSeparator: \.isWhitespace)
            .joined(separator: " ")
    }
}
