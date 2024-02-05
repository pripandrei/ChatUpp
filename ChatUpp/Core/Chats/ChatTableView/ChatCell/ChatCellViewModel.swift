//
//  ChatCellViewModel.swift
//  ChatUpp
//
//  Created by Andrei Pripa on 10/6/23.
//

import Foundation
import Firebase

class ChatCellViewModel {
    
    private(set) var user: DBUser?
//    {didSet { onUserFetch?() ; fetchImageData()}}
    var otherUserProfileImage: ObservableObject<Data?> = ObservableObject(nil)
    var recentMessage: ObservableObject<Message?> = ObservableObject(nil)
    
    var authUser = try! AuthenticationManager.shared.getAuthenticatedUser()
    
    var onUserModified: (() -> Void)?
    private(set) var chat: Chat
    
    init(chat: Chat) {
        self.chat = chat
//        Task {
//            let user = try await loadOtherMembersOfChats()
//            print(chat,user)
//            self.user = user
//            self.recentMessage.value = try await loadRecentMessages([chat]).first!
//        }
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
    
    func updateChat(_ modifiedChat: Chat) {
        self.chat = modifiedChat
        Task { try await loadRecentMessage() }
    }

    func updateRecentMessage(_ message: Message?) {
        self.recentMessage.value = message
    }
    
    func updateUser(_ modifiedUserID: String) async {
        do {
            let updatedUser = try await UserManager.shared.getUserFromDB(userID: modifiedUserID)
            self.user = updatedUser
            self.otherUserProfileImage.value = try await self.fetchImageData()
            self.onUserModified?()
        } catch {
            print("Error updating user while listening: ", error.localizedDescription)
        }
    }
    
    @discardableResult
    func loadOtherMemberOfChat() async throws -> DBUser? {
        guard let memberID = chat.members.first(where: { $0 != authUser.uid} ) else {return nil}
        let member = try await UserManager.shared.getUserFromDB(userID: memberID)
        self.user = member
        return member
    }
    @discardableResult
    func loadRecentMessage() async throws -> Message?  {
        guard let message = try await ChatsManager.shared.getRecentMessageFromChats([chat]).first else {return nil}
        self.recentMessage.value = message
        return message
    }
    @discardableResult
    func fetchImageData() async throws -> Data? {
        guard let user = self.user else {return nil}
        let photoData = try await StorageManager.shared.getUserImage(userID: user.userId, path: userProfilePhotoURL)
        self.otherUserProfileImage.value = photoData
        return photoData
    }
    
    func fetchUserData() async throws -> (DBUser?, Message?, Data?) {
        
//        async let loadMembers = loadOtherMemberOfChat()
//        async let loadMessage = loadRecentMessage()
//    
//        
//        let (mem, mesage) = try await (loadMembers, loadMessage)
//        
//        let loadImageData = try await fetchImageData()
//        
//        return (mem, mesage, loadImageData)
        
        let member = try await loadOtherMemberOfChat()
        self.user = member
        let recentMessage = try await loadRecentMessage()
        self.recentMessage.value = recentMessage
        let imageData = try await fetchImageData()

        self.otherUserProfileImage.value = imageData

        return (member,recentMessage,imageData)
    }

    
    //    func fetchImageData() {
    //        UserManager.shared.getProfileImageData(urlPath: user.photoUrl) { [weak self] data in
    //            if let data = data {
    //                self?.otherUserProfileImage.value = data
    //            }
    //        }
    //    }
        
}

