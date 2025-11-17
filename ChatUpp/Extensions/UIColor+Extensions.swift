//
//  Color+Extensions.swift
//  ChatUpp
//
//  Created by Andrei Pripa on 11/17/25.
//

import UIKit

extension UIColor
{
    /// Returns a color darker or lighter by a given percentage
    /// - Parameter percentage: positive = lighter, negative = darker, range -1.0 ... 1.0
    ///
    func adjust(by percentage: CGFloat) -> UIColor
    {
        var r: CGFloat=0, g: CGFloat=0, b: CGFloat=0, a: CGFloat=0
        guard self.getRed(&r, green: &g, blue: &b, alpha: &a) else { return self }
        
        let p = max(min(percentage, 1.0), -1.0) // clamp
        
        return UIColor(
            red: min(max(r + p, 0), 1.0),
            green: min(max(g + p, 0), 1.0),
            blue: min(max(b + p, 0), 1.0),
            alpha: a
        )
    }
}
