//
//  ChatCellViewModel.swift
//  ChatUpp
//
//  Created by Andrei Pripa on 10/6/23.
//

import Foundation

struct ChatCellViewModel {
    var user: DBUser
    var recentMessages: Message
    
    var message: String {
        return recentMessages.messageBody
    }
    
    var timestamp: String {
        return recentMessages.timestamp
    }
    
    var userMame: String {
        user.name != nil ? user.name! : "name is missing"
    }
    var profileImageUrl: String? {
        return user.photoUrl
    }
}
