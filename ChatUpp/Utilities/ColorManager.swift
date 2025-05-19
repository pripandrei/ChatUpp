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
    
//    static let appBackgroundColor: UIColor = #colorLiteral(red: 0.3515735269, green: 0.3108177483, blue: 0.3511140943, alpha: 1)
    static let appBackgroundColor: UIColor = #colorLiteral(red: 0.2894964814, green: 0.2559292912, blue: 0.289111197, alpha: 1)
    static let navigationBarBackgroundColor: UIColor = #colorLiteral(red: 0.2511927187, green: 0.2273778915, blue: 0.2333565354, alpha: 1)
    static let navigationSearchFieldBackgroundColor: UIColor = #colorLiteral(red: 0.3212527633, green: 0.2840082049, blue: 0.3208295405, alpha: 1)
    static let tabBarBackgroundColor: UIColor = navigationBarBackgroundColor
    static let tabBarItemsTintColor: UIColor = actionButtonsTintColor
    static let cellSelectionBackgroundColor: UIColor = #colorLiteral(red: 0.3262649179, green: 0.3006753623, blue: 0.3011517525, alpha: 1)
    static let actionButtonsTintColor: UIColor = #colorLiteral(red: 0.468229115, green: 0.2259758115, blue: 0.5086464882, alpha: 1)
    static let mainAppBackgroundColorGradientTop: UIColor = #colorLiteral(red: 0.468229115, green: 0.2259758115, blue: 0.5086464882, alpha: 1)
    static let mainAppBackgroundColorGradientBottom: UIColor = #colorLiteral(red: 0.468229115, green: 0.2259758115, blue: 0.5086464882, alpha: 1)
    
    
    private static let messageBackgroundColors: [UIColor] = [#colorLiteral(red: 0.5666766763, green: 0.2653866708, blue: 0.3898352087, alpha: 1), #colorLiteral(red: 0.3151230216, green: 0.3269421458, blue: 0.5721591115, alpha: 1), #colorLiteral(red: 0.1290415525, green: 0.4660907388, blue: 0.1841244996, alpha: 1), #colorLiteral(red: 0.5664714575, green: 0.3413798809, blue: 0.1262274683, alpha: 1), #colorLiteral(red: 0.4946692586, green: 0.2387150526, blue: 0.537415266, alpha: 1)]
    
    static func color(for objectID: String) -> UIColor
    {
        let hashValue = objectID.hashValue
        let index = abs(hashValue) % messageBackgroundColors.count
        return messageBackgroundColors[index]
    }
}
