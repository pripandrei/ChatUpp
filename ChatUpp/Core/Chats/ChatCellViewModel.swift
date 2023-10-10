//
//  ChatCellViewModel.swift
//  ChatUpp
//
//  Created by Andrei Pripa on 10/6/23.
//

import Foundation

class ChatCellViewModel {
    var user: DBUser
    var recentMessages: Message
    
    init(user: DBUser, recentMessages: Message) {
        self.user = user
        self.recentMessages = recentMessages
    }
    
    var message: String {
        return recentMessages.messageBody
    }
    
    var timestamp: String {
        return recentMessages.timestamp
    }
    
    var userMame: String {
        user.name != nil ? user.name! : "name is missing"
    }
    
    var imageData: Data?
    {
        get async {
            return await UserManager.shared.getProfileImageData(urlPath: user.photoUrl)
        }
    }
}
