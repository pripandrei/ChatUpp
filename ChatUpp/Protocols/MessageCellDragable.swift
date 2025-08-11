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
    var messageText: String? { get }
    var messageImage: UIImage? { get }
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
}
