//
//  ColorManager.swift
//  ChatUpp
//
//  Created by Andrei Pripa on 2/9/25.
//

import UIKit

struct ColorManager
{
//    static let oldMainAppColor: UIColor = #colorLiteral(red: 0.1411764771, green: 0.3960784376, blue: 0.5647059083, alpha: 1)
    
    static let appBackgroundColor: UIColor = #colorLiteral(red: 0.5204173923, green: 0.4565206766, blue: 0.5178095698, alpha: 1)
    static let navigationBarColor: UIColor = #colorLiteral(red: 0.3509210348, green: 0.3164287806, blue: 0.3256990314, alpha: 1)
    static let tabBarColor: UIColor = #colorLiteral(red: 0.6482783556, green: 0.5804365277, blue: 0.5887902379, alpha: 1)
    static let cellSelectionColor: UIColor = #colorLiteral(red: 0.3262649179, green: 0.3006753623, blue: 0.3011517525, alpha: 1)
    
    private static let messageBackgroundColor: [UIColor] = [#colorLiteral(red: 0.5666766763, green: 0.2653866708, blue: 0.3898352087, alpha: 1), #colorLiteral(red: 0.3151230216, green: 0.3269421458, blue: 0.5721591115, alpha: 1), #colorLiteral(red: 0.1290415525, green: 0.4660907388, blue: 0.1841244996, alpha: 1), #colorLiteral(red: 0.5664714575, green: 0.3413798809, blue: 0.1262274683, alpha: 1), #colorLiteral(red: 0.4946692586, green: 0.2387150526, blue: 0.537415266, alpha: 1)]
    
    static func color(for objectID: String) -> UIColor
    {
        let hashValue = objectID.hashValue
        let index = abs(hashValue) % messageBackgroundColor.count
        return messageBackgroundColor[index]
    }
}
