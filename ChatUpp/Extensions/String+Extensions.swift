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
}
