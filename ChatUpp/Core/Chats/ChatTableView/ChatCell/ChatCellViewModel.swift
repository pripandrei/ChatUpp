//
//  ChatCellViewModel.swift
//  ChatUpp
//
//  Created by Andrei Pripa on 10/6/23.
//

import Foundation
import Firebase

class ChatCellViewModel {
    
    private(set) var user: DBUser? {didSet { onUserFetch?() ; fetchImageData()}}
    var otherUserProfileImage: ObservableObject<Data?> = ObservableObject(nil)
    var recentMessage: ObservableObject<Message?> = ObservableObject(nil)
    
    var onUserFetch: (() -> Void)?
    var chat: Chat
    
    init(chat: Chat) {
        self.chat = chat
        Task {
            let user = try await loadOtherMembersOfChats([chat])
            print(chat,user)
            self.user = user.first!
            self.recentMessage.value = try await loadRecentMessages([chat]).first!
        }
    }
    
    var message: String? {
        return recentMessage.value?.messageBody != nil ? recentMessage.value!.messageBody : nil
    }
    
    var timestamp: String? {
        guard let hoursAndMinutes = recentMessage.value?.timestamp.formatToHoursAndMinutes() else {return nil}
        return hoursAndMinutes
    }
    
    var userName: String {
        user?.name != nil ? user!.name! : "name is missing"
    }

    var userProfilePhotoURL: String {
        user?.photoUrl ?? ""
    }
    
    var listener: ListenerRegistration?
    
//    func addListenerToRecentMessage() {
////        if listener != nil {
////            listener?.remove()
////        }
//        self.listener = ChatsManager.shared.addListenerForLastMessage(chatID: chatId) { chat in
//            Task {
//                let message = try await ChatsManager.shared.getRecentMessageFromChats([chat])
////                print(self.userName)
////                print(message)
//                if let message = message.first {
//                    self.recentMessage.value = message
//                }
//            }
//        }
//    }
//    
    func updateRecentMessage(_ message: Message?) {
        self.recentMessage.value = message
    }
    
    func fetchImageData() {
        guard let user = self.user else {return}
        Task {
            self.otherUserProfileImage.value = try await StorageManager.shared.getUserImage(userID: user.userId, path: userProfilePhotoURL)
        }
    }
    
    deinit {
        print("CHATCELLViewMOdel DeINITED")
//        listener?.remove()
    }
    
    
    
    
    private func loadRecentMessages(_ chats: [Chat]) async throws -> [Message?]  {
        try await ChatsManager.shared.getRecentMessageFromChats(chats)
    }
    
    private func loadOtherMembersOfChats(_ chats: [Chat]) async throws -> [DBUser] {
        let memberIDs = getOtherMembersFromChats(chats)
        var otherMembers = [DBUser]()

        for id in memberIDs {
            let dbUser = try await UserManager.shared.getUserFromDB(userID: id)
            otherMembers.append(dbUser)
        }
        return otherMembers
    }
    
    var authUser = try! AuthenticationManager.shared.getAuthenticatedUser()
    
    private func getOtherMembersFromChats(_ chats: [Chat]) -> [String] {
        return chats.compactMap { chat in
            return chat.members.first(where: { $0 != authUser.uid} )
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

