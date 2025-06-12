//
//  Untitled.swift
//  ChatUpp
//
//  Created by Andrei Pripa on 6/12/25.
//

import Foundation

enum GroupEventMessage: String
{
    case created
    case userLeft
    case userJoined
    case photoUpdated
    case nameUpdated
    
    var eventMessage: String
    {
        switch self
        {
        case .created: return "created a new group"
        case .userLeft: return "has left the group"
        case .userJoined: return "has joined the group"
        case .photoUpdated: return "Group photo updated"
        case .nameUpdated: return "updated name of group"
        }
    }
}
