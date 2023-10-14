//
//  CGFloat+Extension.swift
//  ChatUpp
//
//  Created by Andrei Pripa on 10/14/23.
//

import UIKit

extension CGFloat {
    func inverseValue() -> CGFloat {
        if self < 0 {
            return abs(self)
        } else if self > 0 {
            return -self
        }
        return 0.0
    }
}
