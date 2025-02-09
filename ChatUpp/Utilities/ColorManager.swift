//
//  ColorManager.swift
//  ChatUpp
//
//  Created by Andrei Pripa on 2/9/25.
//

import UIKit

struct ColorManager
{
    private static let colors: [UIColor] = [.systemRed, .systemBlue, .systemGreen, .systemOrange, .systemPurple]
    
    static func color(for objectID: String) -> UIColor
    {
        let hashValue = objectID.hashValue
        let index = abs(hashValue) % colors.count
        return colors[index]
    }
}
