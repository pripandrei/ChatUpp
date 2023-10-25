//
//  String+Extensions.swift
//  ChatUpp
//
//  Created by Andrei Pripa on 10/25/23.
//

import Foundation
import UIKit

extension String {
    func getSize() -> CGSize {
        guard let font = UIFont(name: "HelveticaNeue", size: 18) else { return CGSize.zero }
        let attributes = [NSAttributedString.Key.font: font]
        return self.size(withAttributes: attributes)
    }
}
