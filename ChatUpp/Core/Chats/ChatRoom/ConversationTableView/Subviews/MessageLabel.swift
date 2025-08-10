//
//  MessageLabel.swift
//  ChatUpp
//
//  Created by Andrei Pripa on 8/10/25.
//

import UIKit
import YYText

//MARK: - Message Label
class MessageLabel: YYLabel
{
    enum MessageUpdateType {
        case edited
        case replyRemoved
    }
    
    var messageUpdateType: MessageUpdateType?
    
    /// Override to prevent message label text streching or shrinking
    /// when label size changes
    
    override func action(for layer: CALayer, forKey event: String) -> CAAction?
    {
        if messageUpdateType == .edited
        {
            if event == "bounds" || event == "position" {
                return NSNull() // Disables implicit animations for these keys
            }
        }
        return super.action(for: layer, forKey: event)
    }
}
