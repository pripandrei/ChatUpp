//
//  ChatCellViewModel.swift
//  ChatUpp
//
//  Created by Andrei Pripa on 10/6/23.
//

import Foundation
import Firebase

enum RealmRetrieveError: Error {
    case objectNotPresent
}

class ChatCellViewModel {
    
    @Published private(set) var member: DBUser?
    @Published var memberProfileImage: Data?
    @Published var recentMessage: Message?
    @Published private(set) var unreadMessageCount: Int?
    
    private(set) var userObserver: RealtimeDBObserver?
    
    private(set) var chat: Chat
    var authUser = try! AuthenticationManager.shared.getAuthenticatedUser()
    
    init(chat: Chat) {
        self.chat = chat
        tryRetrieveChatDataFromRealmDB()
    }
    
    /// - updated user after deletion
    func updateUserAfterDeletion(_ modifiedUserID: String) async {
        do {
            self.member = try await UserManager.shared.getUserFromDB(userID: modifiedUserID)
            self.memberProfileImage = try await self.fetchImageData()
        } catch {
            print("Error updating user while listening: ", error.localizedDescription)
        }
    }

}

//MARK: - Update cell data

extension ChatCellViewModel {
    
    func updateUserMember(_ member: DBUser) {
        self.member = member
    }
    
    func updateUnreadMessagesCount(_ count: Int) {
        unreadMessageCount = count
    }
    
    func updateChat(_ modifiedChat: Chat) {
        self.chat = modifiedChat
    }

    func updateRecentMessage(_ message: Message?) {
        self.recentMessage = message
    }
}

//MARK: - Retrieve Realm db data

extension ChatCellViewModel {
    
    func tryRetrieveChatDataFromRealmDB() {
        do {
            try retrieveMember()
            try retrieveRecentMessage()
            try retrieveMemberImageData()
        } catch {
            print("Could not retrieve realm object: ",error.localizedDescription)
        }
    }
    
    func retrieveMember() throws {
        guard let memberID = chat.members.first(where: { $0 != authUser.uid} ),
              let member = RealmDBManager.shared.retrieveSingleObjectFromRealmDB(ofType: DBUser.self, primaryKey: memberID) else { throw RealmRetrieveError.objectNotPresent }
        self.member = member
        self.addObserverToUser()
    }
    
    func retrieveRecentMessage() throws {
        guard let messageID = chat.recentMessageID,
              let message = RealmDBManager.shared.retrieveSingleObjectFromRealmDB(ofType: Message.self, primaryKey: messageID) else { throw RealmRetrieveError.objectNotPresent }
        self.recentMessage = message
    }
    
    func retrieveMemberImageData() throws {
        guard let member = self.member,
              let userProfilePhotoURL = member.photoUrl,
              let imageURL = RealmDBManager.shared.retrieveSingleObjectFromRealmDB(ofType: DBUser.self, primaryKey: member.userId)?.photoUrl else {throw RealmRetrieveError.objectNotPresent}
        
        //TODO: Retrieve image from FileManager cach with imageURL
    }
}

//MARK: - Fetch cell data

extension ChatCellViewModel {
    @discardableResult
    func loadOtherMemberOfChat() async throws -> DBUser? {
        guard let memberID = chat.members.first(where: { $0 != authUser.uid} ) else { return nil }
        let member = try await UserManager.shared.getUserFromDB(userID: memberID)
        self.member = member
        Task { @MainActor in RealmDBManager.shared.createRealmDBObject(object: member)}
        self.addObserverToUser()
        return member
    }
    
    @discardableResult
    func loadRecentMessage() async throws -> Message?  {
        guard let message = try await ChatsManager.shared.getRecentMessageFromChats([chat]).first,
              let message = message else { return nil }
        self.recentMessage = message
        Task { @MainActor in RealmDBManager.shared.createRealmDBObject(object: message)}
        return message
    }
    
    @discardableResult
    func fetchImageData() async throws -> Data? {
        guard let user = self.member,
              let userProfilePhotoURL = self.member?.photoUrl else { print("Could not get User data to fetch imageData") ; return nil }
        let photoData = try await StorageManager.shared.getUserImage(userID: user.userId, path: userProfilePhotoURL)
        self.memberProfileImage = photoData
        return photoData
    }
    
    @discardableResult
    func fetchUnreadMessagesCount() async throws -> Int? {
        let unreadMessageCount = try await ChatsManager.shared.getUnreadMessagesCount(for: chat.id)
        self.unreadMessageCount = unreadMessageCount
        return unreadMessageCount
    }
}

//MARK: - Temporary fix while firebase functions are deactivated

extension ChatCellViewModel {
   
    private func addObserverToUser() {
        guard let member = member else {return}
        
        self.userObserver = UserManagerRealtimeDB.shared.addObserverToUsers(member.userId) { [weak self] realtimeDBUser in
            if realtimeDBUser.isActive != self?.member?.isActive
            {
                let date = Date(timeIntervalSince1970: realtimeDBUser.lastSeen)
                self?.member = self?.member?.updateActiveStatus(lastSeenDate: date,isActive: realtimeDBUser.isActive)
            }
        }
    }
}
