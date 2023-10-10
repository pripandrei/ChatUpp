//
//  ChatCellViewModel.swift
//  ChatUpp
//
//  Created by Andrei Pripa on 10/6/23.
//

import Foundation
import Firebase

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
        let hoursAndMinutes = recentMessages.timestamp.formatToHoursAndMinutes()
        return hoursAndMinutes
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


extension Date {
    func formatToHoursAndMinutes() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat  = "hh:m"
        let time = formatter.string(from: self)
        return time
    }
}
