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
    var imgData: ObservableObject<Data?> = ObservableObject(nil)
    
    init(user: DBUser, recentMessages: Message) {
        self.user = user
        self.recentMessages = recentMessages
//        getImageData()
//        Task { await fetchImageData() }
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

    func fetchImageData() {
        UserManager.shared.getProfileImageData(urlPath: user.photoUrl) { data in
            if let data = data {
                self.imgData.value = data
            }
        }
    }
    
    //    var imageData: Data?
    //    {
    //        get async {
    //            return await UserManager.shared.getProfileImageData(urlPath: user.photoUrl)
    //        }
    //    }
}

extension Date {
    func formatToHoursAndMinutes() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat  = "hh:m"
        let time = formatter.string(from: self)
        return time
    }
}
