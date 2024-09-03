//
//  ChatCellViewModel.swift
//  ChatUpp
//
//  Created by Andrei Pripa on 10/6/23.
//

import Foundation
import Firebase
import RealmSwift



class ChatCellViewModel: Equatable {
    
    //    private(set) var freezedMember: DBUser? {
    //        get {
    //            guard let memberID = findMemberID() else {
    //                return nil
    //            }
    //            return RealmDBManager.shared.retrieveSingleObject(ofType: DBUser.self, primaryKey: memberID)
    //        } set {
    //            Task { @MainActor in
    //                guard let member = newValue else {return}
    //                RealmDBManager.shared.add(object: member)
    ////                self.member = member
    //            }
    //        }
    //    }
        
    //    private(set) var freezedMessage: Message?
    //    {
    //        get {
    //            guard let message = freezedChat?.freeze().recentMessageID else {
    //                return nil
    //            }
    //            return RealmDBManager.shared.retrieveSingleObject(ofType: Message.self, primaryKey: message)
    //        } set {
    //            Task { @MainActor in
    //                guard let message = newValue else {return}
    //                RealmDBManager.shared.add(object: message)
    ////                self.recentMessage = RealmDBManager.shared.retrieveSingleObject(ofType: Message.self, primaryKey: message.id)
    //            }
    //        }
    //    }
        
    //    {
    //        didSet {
    ////            Task { @MainActor in
    ////                guard let message = recentMessage, let chat = freezedChat else {return}
    //////                RealmDBManager.shared.update(object: chat) { chat in
    //////                    freezedChat?.conversationMessages.append(message)
    //////                }
    ////            }
    //        }
    //    }
//    var freezedChat: Chat! {
//        return RealmDBManager.shared.retrieveSingleObject(ofType: Chat.self, primaryKey: chatID)
//    }
    
    
    @Published private(set) var member: DBUser?
    @Published private(set) var recentMessage: Message?
    @Published private(set) var memberProfileImage: Data?
    @Published private(set) var unreadMessageCount: Int?
    private var usersListener: Listener?
    private var userObserver: RealtimeDBObserver?
//    private var chatID: String
    private var authUser = try! AuthenticationManager.shared.getAuthenticatedUser()
    
    var freezedChat: Chat?
    
//    var freezedChat: Chat? {
//        return RealmDBManager.shared.retrieveSingleObject(ofType: Chat.self, primaryKey: chatID)
//    }
    var computedMessage: Message? {
        get {
            return recentMessage
        }
        set {
            self.recentMessage = newValue?.freeze()
        }
    }
    
    var computedMember: DBUser? {
        get {
            return member
        }
        set {
            self.member = newValue?.freeze()
        }
    }

    var isRecentMessagePresent: Bool? 
    {
        guard member != nil else { return nil }
        if let _ = freezedChat?.recentMessageID { return true }
        return false
    }
    
    var isAuthUserOwnerOfRecentMessage: Bool {
        authUser.uid == computedMessage?.senderId
    }
    
    init(chat: Chat) {
        self.freezedChat = chat.freeze()
//        chatID = chat.id
        initiateChatDataLoad()
    }
    
    private func initiateChatDataLoad() {
        try? retrieveDataFromRealm()
        Task {
            await fetchDataFromFirestore()
//            self.addObserverToUser()
//            self.addListenerToUser()
            self.addDataToRealm()
        }
    }
    
    private func addDataToRealm() {
        guard let member = member,
              let recentMessage = recentMessage
        else {return}
        
        Task { @MainActor in
            RealmDBManager.shared.add(object: member)
            if let chat = freezedChat?.thaw(), 
                !chat.conversationMessages.contains(where: {$0.id == recentMessage.id}) {
                RealmDBManager.shared.update(object: chat) { chat in
                    chat.conversationMessages.append(recentMessage)
                }
            }
        }
    }
    
    private func findMemberID() -> String? {
        return freezedChat?.members.first(where: { $0 != authUser.uid} )
    }
}


//MARK: - Update cell data

extension ChatCellViewModel {

    func updateChat(_ modifiedChat: Chat) {
//        self.chat = modifiedChat
    }

    func updateRecentMessage(_ message: Message?) {
        self.computedMessage = message
    }
    
    /// - updated user after deletion
    func updateUserAfterDeletion(_ modifiedUserID: String) async {
        do {
            self.computedMember = try await UserManager.shared.getUserFromDB(userID: modifiedUserID)
            self.memberProfileImage = try await self.fetchImageData()
        } catch {
            print("Error updating user while listening: ", error.localizedDescription)
        }
    }
}

//MARK: - Retrieve Realm db data

extension ChatCellViewModel {
    
    func retrieveDataFromRealm() throws {
        self.computedMember = try retrieveMember()
        self.computedMessage = try retrieveRecentMessage()
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
        guard let messageID = freezedChat?.recentMessageID,
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
        guard let chat = freezedChat,
        let message = try? await ChatsManager.shared.getRecentMessage(from: chat)
        else { return nil }
        return message
    }
    
    func fetchImageData() async throws -> Data? {
        guard let user = self.computedMember,
              let userProfilePhotoURL = user.photoUrl else {
            return nil
        }
        let photoData = try await StorageManager.shared.getUserImage(userID: user.userId, path: userProfilePhotoURL)
        return photoData
    }

    func fetchUnreadMessagesCount() async throws -> Int? {
        guard let chatID = freezedChat?.id else {return nil}
        let unreadMessageCount = try await ChatsManager.shared.getUnreadMessagesCount(for: chatID)
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
        lhs.freezedChat == rhs.freezedChat
    }
}
