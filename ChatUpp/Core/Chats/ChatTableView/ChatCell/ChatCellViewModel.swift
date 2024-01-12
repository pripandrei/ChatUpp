//
//  ChatCellViewModel.swift
//  ChatUpp
//
//  Created by Andrei Pripa on 10/6/23.
//

import Foundation
import Firebase

class ChatCellViewModel {
    let user: DBUser
    var recentMessages: Message
    var otherUserProfileImage: ObservableObject<Data?> = ObservableObject(nil)
    
    init(user: DBUser, recentMessages: Message) {
        self.user = user
        self.recentMessages = recentMessages
//        fetchImageData()
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

//    func fetchImageData() {
//        UserManager.shared.getProfileImageData(urlPath: user.photoUrl) { [weak self] data in
//            if let data = data {
//                self?.otherUserProfileImage.value = data
//            }
//        }
//    }
    
    func fetchImageData() {
        Task {
            self.otherUserProfileImage.value = try await StorageManager.shared.getUserImage(userID: user.userId, path: user.photoUrl!)
        }
    }
}

