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
    
    @Published private(set) var member: DBUser? { didSet {self.addObserverToUser()} }
    @Published var memberProfileImage: Data?
    @Published var recentMessage: Message?
    @Published  var unreadMessageCount: Int?
    
    private(set) var userObserver: RealtimeDBObserver?
    
    private(set) var chat: Chat
    var authUser = try! AuthenticationManager.shared.getAuthenticatedUser()
    
    init(chat: Chat) {
        self.chat = chat
        initiateChatDataLoad()
    }
    
    
    var isAuthUserOwnerOfRecentMessage: Bool {
        authUser.uid != recentMessage?.senderId
    }
    
    private func initiateChatDataLoad() {
        do {
            try retrieveDataFromRealm()
        } catch {
            //               print("Could not retrieve data from Realm: ", error.localizedDescription)
            //               try await fetchChatDataFromFirestoreDB()
            Task { await fetchDataFromFirestore() }
        }
    }
    
    private func addDataToRealm() {
        Task { @MainActor in
            RealmDBManager.shared.add(object: member!)
            RealmDBManager.shared.add(object: recentMessage!)
        }
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
    
    func retrieveDataFromRealm() throws {
        self.member = try retrieveMember()
        self.recentMessage = try retrieveRecentMessage()
        try retrieveMemberImageData()
    }
    
    func retrieveMember() throws -> DBUser {
        guard let memberID = chat.members.first(where: { $0 != authUser.uid} ),
              let member = RealmDBManager.shared.retrieveSingleObject(ofType: DBUser.self, primaryKey: memberID) else { throw RealmRetrieveError.objectNotPresent }
        return member
    }
    
    func retrieveRecentMessage() throws -> Message {
        guard let messageID = chat.recentMessageID,
              let message = RealmDBManager.shared.retrieveSingleObject(ofType: Message.self, primaryKey: messageID) else { throw RealmRetrieveError.objectNotPresent }
        return message
    }
    
    func retrieveMemberImageData() throws {
        guard let member = self.member,
              let userProfilePhotoURL = member.photoUrl,
              let imageURL = RealmDBManager.shared.retrieveSingleObject(ofType: DBUser.self, primaryKey: member.userId)?.photoUrl else {throw RealmRetrieveError.objectNotPresent}
        
        //TODO: Retrieve image from FileManager cach with imageURL
    }
}

//MARK: - Fetch cell data

extension ChatCellViewModel 
{
    private func fetchDataFromFirestore() async
    {
        do {
            self.member             = try await loadOtherMemberOfChat()
            self.recentMessage      =     await loadRecentMessage()
            self.memberProfileImage = try await fetchImageData()
            self.unreadMessageCount = try await fetchUnreadMessagesCount()
        } catch {
            print("Could not fetch ChatCellVM data from Firestore: ", error.localizedDescription)
        }
    }
    
    func loadOtherMemberOfChat() async throws -> DBUser? {
        guard let memberID = chat.members.first(where: { $0 != authUser.uid} ) else { return nil }
        let member = try await UserManager.shared.getUserFromDB(userID: memberID)
        return member
    }
    
    func loadRecentMessage() async -> Message?  {
        guard let message = try? await ChatsManager.shared.getRecentMessageFromChats([chat]).first,
              let message = message else { return nil }
        return message
    }
    
    func fetchImageData() async throws -> Data? {
        guard let user = self.member,
              let userProfilePhotoURL = user.photoUrl else {
//            print("Could not get User image url. Local image will be used")
            return nil
        }
        let photoData = try await StorageManager.shared.getUserImage(userID: user.userId, path: userProfilePhotoURL)
        return photoData
    }
    
    func fetchUnreadMessagesCount() async throws -> Int {
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
