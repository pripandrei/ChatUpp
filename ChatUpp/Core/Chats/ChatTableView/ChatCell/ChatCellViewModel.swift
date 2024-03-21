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
    var otherUserProfileImage: ObservableObject<Data?> = ObservableObject(nil)
    var recentMessage: ObservableObject<Message?> = ObservableObject(nil)
    var authUser = try! AuthenticationManager.shared.getAuthenticatedUser()
    
    var onUserModified: (() -> Void)?
    private(set) var chat: Chat
    
    private(set) var unreadMessageCount: ObservableObject<Int?> = ObservableObject(nil)
    
    init(chat: Chat) {
        self.chat = chat
    }
    
    func updateUnreadMessagesCount(_ count: Int) {
        unreadMessageCount.value = count
//        self.chat = Chat(id: chat.id, members: chat.members, lastMessage: chat.recentMessageID, unreadMessages: count)
        print("Count after recieving from server update: ", count)
    }
    
    func updateChat(_ modifiedChat: Chat) {
        self.chat = modifiedChat
//        Task { try await loadRecentMessage() }
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
        guard let memberID = chat.members.first(where: { $0 != authUser.uid} ) else { return nil }
        let member = try await UserManager.shared.getUserFromDB(userID: memberID)
        self.user = member
        return member
    }
    
    @discardableResult
    func loadRecentMessage() async throws -> Message?  {
        guard let message = try await ChatsManager.shared.getRecentMessageFromChats([chat]).first else { return nil }
        self.recentMessage.value = message
        return message
    }
    
    @discardableResult
    func fetchImageData() async throws -> Data? {
        guard let user = self.user,
              let userProfilePhotoURL = self.user?.photoUrl else { print("Could not get User data to fetch imageData") ; return nil }
        let photoData = try await StorageManager.shared.getUserImage(userID: user.userId, path: userProfilePhotoURL)
        self.otherUserProfileImage.value = photoData
        return photoData
    }
    
    func fetchUserData() async throws -> (DBUser?, Message?, Data?) {
        let member = try await loadOtherMemberOfChat()
        self.user = member
        let recentMessage = try await loadRecentMessage()
        self.recentMessage.value = recentMessage
        let imageData = try await fetchImageData()

        self.otherUserProfileImage.value = imageData

        return (member,recentMessage,imageData)
    }
}

