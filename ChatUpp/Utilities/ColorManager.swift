//
//  ColorManager.swift
//  ChatUpp
//
//  Created by Andrei Pripa on 2/9/25.
//

import UIKit

struct ColorManager
{
    private static let colors: [UIColor] = [#colorLiteral(red: 0.5666766763, green: 0.2653866708, blue: 0.3898352087, alpha: 1), #colorLiteral(red: 0.3151230216, green: 0.3269421458, blue: 0.5721591115, alpha: 1), #colorLiteral(red: 0.1290415525, green: 0.4660907388, blue: 0.1841244996, alpha: 1), #colorLiteral(red: 0.5664714575, green: 0.3413798809, blue: 0.1262274683, alpha: 1), #colorLiteral(red: 0.4946692586, green: 0.2387150526, blue: 0.537415266, alpha: 1)]
    
    static func color(for objectID: String) -> UIColor
    {
        let hashValue = objectID.hashValue
        let index = abs(hashValue) % colors.count
        return colors[index]
    }
}
