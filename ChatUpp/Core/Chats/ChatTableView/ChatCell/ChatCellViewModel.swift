//
//  ChatCellViewModel.swift
//  ChatUpp
//
//  Created by Andrei Pripa on 10/6/23.
//

import Foundation
import Firebase

class ChatCellViewModel {
    
    private(set) var user: DBUser
//    private(set) var recentMessage: Message
    var otherUserProfileImage: ObservableObject<Data?> = ObservableObject(nil)
    var chatId: String
    
    var recentMessage: ObservableObject<Message?> = ObservableObject(nil)
    
    init(user: DBUser, chatID: String, recentMessage: Message?) {
        self.user = user
        self.recentMessage.value = recentMessage
        self.chatId = chatID
        //        fetchImageData()
    }
    
    var message: String? {
        return recentMessage.value?.messageBody != nil ? recentMessage.value!.messageBody : nil
    }
    
    var timestamp: String? {
        guard let hoursAndMinutes = recentMessage.value?.timestamp.formatToHoursAndMinutes() else {return nil}
        return hoursAndMinutes
    }
    
    var userName: String {
        user.name != nil ? user.name! : "name is missing"
    }

    var userProfilePhotoURL: String {
        user.photoUrl ?? ""
    }
    
    func addListenerToRecentMessage() {
        ChatsManager.shared.addListenerForLastMessage(chatID: chatId) { chat in
            Task {
                let message = try await ChatsManager.shared.getRecentMessageFromChats([chat])
                if let message = message.first {
                    self.recentMessage.value = message
                }
            }
        }
    }
    
    func fetchImageData() {
        Task {
            self.otherUserProfileImage.value = try await StorageManager.shared.getUserImage(userID: user.userId, path: userProfilePhotoURL)
        }
    }
    
    

    //    func fetchImageData() {
    //        UserManager.shared.getProfileImageData(urlPath: user.photoUrl) { [weak self] data in
    //            if let data = data {
    //                self?.otherUserProfileImage.value = data
    //            }
    //        }
    //    }
        
}

