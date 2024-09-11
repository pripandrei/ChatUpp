//
//  ChatCellViewModel.swift
//  ChatUpp
//
//  Created by Andrei Pripa on 10/6/23.
//

import Foundation

class ChatCellViewModel: Equatable {
    
    @Published private(set) var member: DBUser?
    @Published private(set) var recentMessage: Message?
    @Published private(set) var memberProfileImage: Data?
    @Published private(set) var unreadMessageCount: Int?
    private var usersListener: Listener?
    private var userObserver: RealtimeDBObserver?
    private var authUser = try! AuthenticationManager.shared.getAuthenticatedUser()
    
    var chat: Chat?

    var isRecentMessagePresent: Bool? 
    {
        guard member != nil else { return nil }
        if let _ = chat?.recentMessageID { return true }
        return false
    }
    
    var isAuthUserOwnerOfRecentMessage: Bool {
        authUser.uid == recentMessage?.senderId
    }
    
    init(chat: Chat) {
        self.chat = chat

        initiateChatDataLoad()
    }
    
    private func initiateChatDataLoad() {
        try? retrieveDataFromRealm()
        Task {
            await fetchDataFromFirestore()
            await self.addObserverToUser()
            await self.addListenerToUser()
            self.addDataToRealm()
        }
    }
    
    private func addDataToRealm() {
        guard let member = member else {return}
        
        
        Task { @MainActor in
            RealmDBManager.shared.add(object: member)
            
            if let recentMessage = recentMessage,
                let chat = chat,
                !chat.conversationMessages.contains(where: {$0.id == recentMessage.id}) 
            {
                RealmDBManager.shared.update(object: chat) { chat in
                    chat.conversationMessages.append(recentMessage)
                }
            }
        }
    }
    
    private func findMemberID() -> String? {
        return chat?.members.first(where: { $0 != authUser.uid} )
    }
}


//MARK: - Update cell data

extension ChatCellViewModel {

    func updateChat(_ modifiedChat: Chat) {
//        self.chat = modifiedChat
    }

    func updateRecentMessage(_ message: Message?, count: Int?) {
        self.recentMessage = message
        self.unreadMessageCount = count
    }
    func updateMember(_ member: DBUser?) {
        self.member = member
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
              let member = RealmDBManager.shared.retrieveSingleObject(ofType: DBUser.self, primaryKey: memberID) else {
            throw
            RealmRetrieveError.memberNotPresent }
        return member
    }
    
    func retrieveRecentMessage() throws -> Message {
        guard let messageID = chat?.recentMessageID,
        let message = RealmDBManager.shared.retrieveSingleObject(ofType: Message.self, primaryKey: messageID) else {
            throw RealmRetrieveError.messageNotPresent }
        return message
    }
    
    func retrieveMemberImageData() throws {
        guard let member = self.member,
              let userProfilePhotoURL = member.photoUrl,
              let imageURL = RealmDBManager.shared.retrieveSingleObject(ofType: DBUser.self, primaryKey: member.userId)?.photoUrl else {
            print("image not")
            throw RealmRetrieveError.imageNotPresent}
        
        //TODO: Retrieve image from FileManager cach with imageURL
    }
}

//MARK: - Fetch Firestore data

extension ChatCellViewModel 
{
    private func fetchDataFromFirestore() async
    {
        do {
            self.member                = try await loadOtherMemberOfChat()
            async let loadMessage      = loadRecentMessage()
            async let loadImage        = fetchImageData()
            async let loadMessageCount = fetchUnreadMessagesCount()
            
            (recentMessage, memberProfileImage, unreadMessageCount) = await (loadMessage, try loadImage, try loadMessageCount)
        } catch {
            print("Could not fetch ChatCellVM data from Firestore: ", error.localizedDescription)
        }
    }
    @MainActor
    func loadOtherMemberOfChat() async throws -> DBUser? {
        guard let memberID = findMemberID() else {
            return nil
        }
        let member = try await UserManager.shared.getUserFromDB(userID: memberID)
        return member
    }
    
    @MainActor
    func loadRecentMessage() async -> Message?  {
        guard let chat = chat,
        let message = try? await ChatsManager.shared.getRecentMessage(from: chat)
        else { return nil }
        return message
    }
    
    @MainActor
    func fetchUnreadMessagesCount() async throws -> Int? {
        guard let chatID = chat?.id else {return nil}
        let unreadMessageCount = try await ChatsManager.shared.getUnreadMessagesCount(for: chatID)
        self.unreadMessageCount = unreadMessageCount
        return unreadMessageCount
    }
    
    func fetchImageData() async throws -> Data? {
        guard let user = self.member,
              let userProfilePhotoURL = user.photoUrl else {
            return nil
        }
        let photoData = try await StorageManager.shared.getUserImage(userID: user.userId, path: userProfilePhotoURL)
        return photoData
    }
}

//MARK: - Listeners

extension ChatCellViewModel {
   
    /// Observe user from Realtime db (Temporary fix while firebase functions are deactivated)
    @MainActor
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
    @MainActor
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
