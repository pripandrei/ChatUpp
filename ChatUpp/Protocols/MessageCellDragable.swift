//
//  MessageCellDragable.swift
//  ChatUpp
//
//  Created by Andrei Pripa on 8/12/25.
//

import Foundation
import UIKit

protocol MessageCellDragable: AnyObject
{
    var center: CGPoint { get set }
    var messageID: String? { get }
    var messageText: String? { get }
    var messageImage: UIImage? { get }
    var messageSenderName: String? { get }
}

extension MessageCellDragable
{
    var messageText: String? {
        return nil
    }
    
    var messageImage: UIImage?
    {
        return nil
    }
    
    var messageSenderName: String?
    {
        return nil
    }
    
    var messageID: String?
    {
        return nil
    }
}


protocol MessageCellSeenable: AnyObject {
    var frame: CGRect { get set }
}
