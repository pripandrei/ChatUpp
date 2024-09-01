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

class ChatCellViewModel: Equatable {
    
    private(set) var chat: Chat
    
    @Published private(set) var member: DBUser?
    @Published var memberProfileImage: Data?
    @Published var unreadMessageCount: Int? 
    @Published var recentMessage: Message? {
        didSet {
            guard let message = recentMessage else {return}
            chat.conversationMessages.append(message)
        }
    }
    
    
    private var usersListener: Listener?
    private(set) var userObserver: RealtimeDBObserver?
    
    var authUser = try! AuthenticationManager.shared.getAuthenticatedUser()
    
    init(chat: Chat) {
        self.chat = chat
        initiateChatDataLoad()
    }

    var isRecentMessagePresent: Bool? 
    {
        guard member != nil else { return nil }
        if let _ = chat.recentMessageID { return true }
        return false
    }
    
    var isAuthUserOwnerOfRecentMessage: Bool {
        authUser.uid == recentMessage?.senderId
    }
    
    private func initiateChatDataLoad() {
        do {
            try retrieveDataFromRealm()
        } catch {
//            print("Could not retrieve data from Realm: ", error.localizedDescription)
            Task { 
                await fetchDataFromFirestore()
                self.addObserverToUser()
                self.addListenerToUser()
                self.addDataToRealm()
            }
        }
    }
    
    private func addDataToRealm() {
        guard let member = member, let recentMessage = recentMessage else {return}
        Task { @MainActor in
            guard let chat = RealmDBManager.shared.retrieveSingleObject(ofType: Chat.self, primaryKey: chat.id) else {
                return
            }
            RealmDBManager.shared.add(object: member)
            RealmDBManager.shared.add(object: chat)
//            RealmDBManager.shared.update(object: chat) { chat in
//                chat.conversationMessages.append(recentMessage)
//            }
        }
    }
    
    private func findMemberID() -> String? {
        return chat.members.first(where: { $0 != authUser.uid} )
    }
}


//MARK: - Update cell data

extension ChatCellViewModel {

    func updateChat(_ modifiedChat: Chat) {
        self.chat = modifiedChat
    }

    func updateRecentMessage(_ message: Message?) {
        self.recentMessage = message
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

//MARK: - Retrieve Realm db data

extension ChatCellViewModel {
    
    func retrieveDataFromRealm() throws {
        self.member = try retrieveMember()
        self.recentMessage = try retrieveRecentMessage()
        try retrieveMemberImageData()
    }
    
    func retrieveMember() throws -> DBUser {
        guard let memberID = findMemberID(),
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

//MARK: - Fetch Firestore data

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
        guard let memberID = findMemberID() else { return nil }
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

//MARK: - Listeners

extension ChatCellViewModel {
   
    /// Observe user from Realtime db (Temporary fix while firebase functions are deactivated)
    private func addObserverToUser() {
        guard let member = member else {return}
        
        self.userObserver = UserManagerRealtimeDB.shared.addObserverToUsers(member.userId) { [weak self] realtimeDBUser in
            if realtimeDBUser.isActive != self?.member?.isActive
            {
                if let date = realtimeDBUser.lastSeen, let isActive = realtimeDBUser.isActive 
                {
                    self?.member = self?.member?.updateActiveStatus(lastSeenDate: date,isActive: isActive)
                }
            }
        }
    }
    
    /// Listen to user from Firestore db
    private func addListenerToUser()
    {
        guard let memberID = member?.userId else {return}
        
        self.usersListener = UserManager.shared.addListenerToUsers([memberID]) { [weak self] users, documentsTypes in
            guard let self = self else {return}
            // since we are listening only for one user here
            // we can just get the first user and docType
            guard let docType = documentsTypes.first, let user = users.first, docType == .modified else {return}
            self.member = user
        }
    }
}

//MARK: - Equatable protocol subs

extension ChatCellViewModel {
    static func == (lhs: ChatCellViewModel, rhs: ChatCellViewModel) -> Bool {
        lhs.chat == rhs.chat
    }
}
