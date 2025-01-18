//
//  InputBarContainer.swift
//  ChatUpp
//
//  Created by Andrei Pripa on 1/18/25.
//

import UIKit

// MARK: - Modified container for gesture trigger
final class InputBarContainer: UIView
{
    // since closeImageView frame is not inside it's super view (inputBarContainer)
    // gesture recognizer attached to it will not get triggered
    // so we need to override point to return true in case it matches the location in coordinate of closeImageView
    
    override func point(inside point: CGPoint, with event: UIEvent?) -> Bool
    {
        if super.point(inside: point, with: event) {return true}
        
        for subview in subviews {
            let subviewPoint = subview.convert(point, from: self)
            if subview.point(inside: subviewPoint, with: event) {
                return true
            }
        }
        return false
    }
}
