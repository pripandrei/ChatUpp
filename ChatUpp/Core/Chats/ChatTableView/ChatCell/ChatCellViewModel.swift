//
//  ChatCellViewModel.swift
//  ChatUpp
//
//  Created by Andrei Pripa on 10/6/23.
//

import Foundation
import Combine

class ChatCellViewModel: Equatable {
    
    private(set) var chat: Chat
    private var usersListener: Listener?
    private var userObserver: RealtimeDBObserver?
    private var authUser = try! AuthenticationManager.shared.getAuthenticatedUser()
    
    @Published private(set) var chatUser: User?
    @Published private(set) var recentMessage: Message?
    @Published private(set) var memberProfileImage: Data?
    @Published private(set) var unreadMessageCount: Int?
    
    init(chat: Chat) {
        self.chat = chat

        initiateChatDataLoad()
    }
    
    private func initiateChatDataLoad() {
        try? retrieveDataFromRealm()
        Task 
        {
            await fetchDataFromFirestore()
            await self.addObserverToUser()
            await self.addListenerToUser()
            self.addDataToRealm()
        }
    }
    
    private func addDataToRealm() {
        guard let member = chatUser else {return}
        
        Task { @MainActor in
            RealmDBManager.shared.add(object: member)
            
            addMessageToRealm()
            saveImageToCache()
        }
    }
    
    private func saveImageToCache() {
        if let imageData = memberProfileImage, let path = chatUser?.photoUrl {
            CacheManager.shared.saveImageData(imageData, toPath: path)
        }
    }
    
    private func addMessageToRealm() {
        if let recentMessage = recentMessage,
            !chat.conversationMessages.contains(where: { $0.id == recentMessage.id} )
        {
            RealmDBManager.shared.update(object: chat) { chat in
                chat.conversationMessages.append(recentMessage)
            }
        }
    }
    
    private func findMemberID() -> String? {
        return chat.participants.first(where: { $0.userID != authUser.uid } )?.userID
    }
    
    var isRecentMessagePresent: Bool?
    {
        guard chatUser != nil else { return nil }
        if let _ = chat.recentMessageID { return true }
        return false
    }
}


//MARK: - Update cell data

extension ChatCellViewModel {
    
    func updateChatParameters() {
        
        /// chat was update in realm, so we check if it's properties match local one (member & recentMessage)
//        if findMemberID() != member?.userId {
//            Task { await updateUserAfterDeletion() }
//        }
        if chat.recentMessageID != recentMessage?.id {
            Task {
                recentMessage = await loadRecentMessage()
                unreadMessageCount = try await fetchUnreadMessagesCount()
                await MainActor.run { addMessageToRealm() }
            }
        }
    }

    /// - updated user after deletion
    func updateUserAfterDeletion() async {
        let deletedUserID = UserManager.mainDeletedUserID
        do {
            self.chatUser = try await UserManager.shared.getUserFromDB(userID: deletedUserID)
            self.memberProfileImage = try await self.fetchImageData()
        } catch {
            print("Error updating user while listening: ", error.localizedDescription)
        }
    }
}

//MARK: - Retrieve Realm db data

extension ChatCellViewModel {
    
    func retrieveDataFromRealm() throws {
        self.chatUser = try retrieveMember()
        self.recentMessage = try retrieveRecentMessage()
        try retrieveMemberImageData()
    }
    
    func retrieveMember() throws -> User {
        guard let memberID = findMemberID(),
              let member = RealmDBManager.shared.retrieveSingleObject(ofType: User.self, primaryKey: memberID) else {
            throw
            RealmRetrieveError.memberNotPresent }
        return member
    }
    
    func retrieveRecentMessage() throws -> Message {
        guard let messageID = chat.recentMessageID,
        let message = RealmDBManager.shared.retrieveSingleObject(ofType: Message.self, primaryKey: messageID) else {
            throw RealmRetrieveError.messageNotPresent }
        return message
    }
    
    func retrieveMemberImageData() throws {
        guard let userProfilePhotoURL = chatUser?.photoUrl else {
//            print("image not")
            throw RealmRetrieveError.imageNotPresent }
        memberProfileImage = CacheManager.shared.retrieveImageData(from: userProfilePhotoURL)
    }
}

//MARK: - Fetch Firestore data

extension ChatCellViewModel 
{
    @MainActor
    private func fetchDataFromFirestore() async
    {
        do {
            self.chatUser                = try await loadOtherMemberOfChat()
            async let loadMessage      = loadRecentMessage()
            async let loadImage        = fetchImageData()
            async let loadUnreadMessageCount = fetchUnreadMessagesCount()
            
            (recentMessage, memberProfileImage, unreadMessageCount) = await (loadMessage, try loadImage, try loadUnreadMessageCount)
        } catch {
            print("Could not fetch ChatCellVM data from Firestore: ", error.localizedDescription)
        }
    }
    @MainActor
    func loadOtherMemberOfChat() async throws -> User? {
        guard let memberID = findMemberID() else {
            return nil
        }
        let member = try await UserManager.shared.getUserFromDB(userID: memberID)
        return member
    }
    
    @MainActor
    func loadRecentMessage() async -> Message?  {
        guard let message = try? await ChatsManager.shared.getRecentMessage(from: chat)
        else { return nil }
        return message
    }
    
    @discardableResult
    @MainActor
    func fetchUnreadMessagesCount() async throws -> Int? {
        let unreadMessageCount = try await ChatsManager
            .shared
            .getUnreadMessagesCount(from: chat.id, whereMessageSenderID: chatUser!.id)
        
        self.unreadMessageCount = unreadMessageCount
        return unreadMessageCount
    }
    
    func fetchImageData() async throws -> Data? {
        guard let user = self.chatUser,
              let userProfilePhotoURL = user.photoUrl else {
            return nil
        }
        let photoData = try await StorageManager.shared.getUserImage(userID: user.id, path: userProfilePhotoURL)
        return photoData
    }
    
//    @MainActor
//    func getMessagesCount() async throws -> Int {
//        let count = try await ChatsManager.shared.getMessagesCount(fromChatDocumentPath: chat.id)
//        return count
//    }
}

//MARK: - Listeners

extension ChatCellViewModel {
   
    /// Observe user from Realtime db (Temporary fix while firebase functions are deactivated)
    @MainActor
    private func addObserverToUser() {
        guard let member = chatUser else {return}
        
        self.userObserver = UserManagerRealtimeDB.shared.addObserverToUsers(member.id) { [weak self] realtimeDBUser in
            if realtimeDBUser.isActive != self?.chatUser?.isActive
            {
                if let date = realtimeDBUser.lastSeen, let isActive = realtimeDBUser.isActive 
                {
                    self?.chatUser = self?.chatUser?.updateActiveStatus(lastSeenDate: date,isActive: isActive)
                }
            }
        }
    }
    
    /// Listen to user from Firestore db
    @MainActor
    private func addListenerToUser()
    {
        guard let memberID = chatUser?.id else {return}
        
        self.usersListener = UserManager.shared.addListenerToUsers([memberID]) { [weak self] users, documentsTypes in
            guard let self = self else {return}
            // since we are listening only for one user here
            // we can just get the first user and docType
            guard let docType = documentsTypes.first, let user = users.first, docType == .modified else {return}
            self.chatUser = user
        }
    }
}

//MARK: - Equatable protocol subs

extension ChatCellViewModel {
    static func == (lhs: ChatCellViewModel, rhs: ChatCellViewModel) -> Bool {
        lhs.chat == rhs.chat
    }
}
