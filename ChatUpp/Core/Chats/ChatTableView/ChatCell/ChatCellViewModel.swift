//
//  ChatCellViewModel.swift
//  ChatUpp
//
//  Created by Andrei Pripa on 10/6/23.
//

import Foundation
import Firebase
import RealmSwift

enum RealmRetrieveError: Error, LocalizedError {
    case objectNotPresent
    case chatNotPresent
    case memberNotPresent
    case messageNotPresent
    case imageNotPresent
    
    var errorDescription: String? {
        switch self {
        case .objectNotPresent: return "object not present"
        case .chatNotPresent: return "chat not present"
        case .memberNotPresent: return "member not present"
        case .messageNotPresent: return "message not present"
        case .imageNotPresent: return "image not present"
        }
    }
}

class ChatCellViewModel: Equatable {
    
//    private(set) var chat: Chat
    private(set) var chatID: String
    
//    private var freezedChat: Chat
    var freezedChat: Chat? {
        return RealmDBManager.shared.retrieveSingleObject(ofType: Chat.self, primaryKey: chatID)
    }
    
    @Published private(set) var member: DBUser?
//     var onMemberSet: ((DBUser?) -> Void)?
//     var onMessageSet: ((Message?) -> Void)?
//    
    private(set) var freezedMember: DBUser? {
        get {
            guard let memberID = findMemberID() else {
                return nil
            }
            return RealmDBManager.shared.retrieveSingleObject(ofType: DBUser.self, primaryKey: memberID)
        } set {
            guard let member = newValue else {return}
            RealmDBManager.shared.add(object: member)
            guard let asd = freezedMember?.freeze() else {return}
            Task { @MainActor in
            self.member = RealmDBManager.shared.retrieveSingleObject(ofType: DBUser.self, primaryKey: asd.userId)
//            onMemberSet?(freezedMember?.freeze())
//            self.member = freezedMember?.freeze()
            }
            //            self.member = nil
        }
    }
    
    @Published var memberProfileImage: Data?
    @Published var unreadMessageCount: Int?
    
    @Published var recentMessage: Message?
    
    private(set) var freezedMessage: Message?
    {
        get {
            guard let message = freezedChat?.recentMessageID else {
                return nil
            }
            return RealmDBManager.shared.retrieveSingleObject(ofType: Message.self, primaryKey: message)
        } set {
            guard let message = newValue else {return}
            RealmDBManager.shared.add(object: message)
            Task { @MainActor in
            self.recentMessage = RealmDBManager.shared.retrieveSingleObject(ofType: Message.self, primaryKey: freezedMessage!.id)
//            onMemberSet?(freezedMember?.freeze())
//            self.member = freezedMember?.freeze()
            }
//            Task { @MainActor in
//                self.recentMessage = message
//            onMessageSet?(freezedMessage?.freeze())
//            self.recentMessage = freezedMessage?.freeze()
//            }
//            self.member = nil
        }
    }
    
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
    
    private var usersListener: Listener?
    private(set) var userObserver: RealtimeDBObserver?
    
    var authUser = try! AuthenticationManager.shared.getAuthenticatedUser()
    
    init(chat: Chat) {
//        self.chat = chat
        chatID = chat.id
//        self.freezedChat = chat.freeze()
        initiateChatDataLoad()
    }


    var isRecentMessagePresent: Bool? 
    {
        guard freezedMember != nil else { return nil }
        if let _ = freezedChat?.recentMessageID { return true }
        return false
    }
    
    var isAuthUserOwnerOfRecentMessage: Bool {
        authUser.uid == freezedMessage?.senderId
    }
    
    private func initiateChatDataLoad() {
        do {
            Task {
                try? retrieveDataFromRealmSecondOption()
//                await fetchDataFromFirestore()
//                self.addObserverToUser()
//                self.addListenerToUser()
//                self.addDataToRealm()
            }
        } catch {
            print("Could not retrieve data from Realm: ", error.localizedDescription)
//            Task {
//                await fetchDataFromFirestore()
//                self.addObserverToUser()
//                self.addListenerToUser()
//                self.addDataToRealm()
//            }
        }
    }
    
    private func addDataToRealm() {
        guard let member = freezedMember, let recentMessage = freezedMessage else {return}
        Task { @MainActor in
//            guard let chat = RealmDBManager.shared.retrieveSingleObject(ofType: Chat.self, primaryKey: chat.id) else {
//                return
//            }
            guard let chat = freezedChat else {return }
            RealmDBManager.shared.add(object: member)
            RealmDBManager.shared.add(object: chat)
//            RealmDBManager.shared.update(object: chat) { chat in
//                chat.conversationMessages.append(recentMessage)
//            }
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
        self.freezedMessage = message
    }
    
    /// - updated user after deletion
    func updateUserAfterDeletion(_ modifiedUserID: String) async {
        do {
            self.freezedMember = try await UserManager.shared.getUserFromDB(userID: modifiedUserID)
            self.memberProfileImage = try await self.fetchImageData()
        } catch {
            print("Error updating user while listening: ", error.localizedDescription)
        }
    }
}

//MARK: - Retrieve Realm db data

extension ChatCellViewModel {
    
    func retrieveDataFromRealmSecondOption() throws {
        guard let member = freezedMember else {throw RealmRetrieveError.memberNotPresent}
        self.freezedMember = member
        guard let recentMessage = freezedMessage else {throw RealmRetrieveError.messageNotPresent}
        self.freezedMessage = recentMessage
//        self.recentMessage = try retrieveRecentMessage()
        try retrieveMemberImageData()
    }
    
//    func retrieveDataFromRealm() throws {
//        self.freezedMember = try retrieveMember()
//        self.recentMessage = try retrieveRecentMessage()
//        try retrieveMemberImageData()
//    }
    
    func retrieveMember() throws -> DBUser {
        guard let memberID = findMemberID(),
              let member = RealmDBManager.shared.retrieveSingleObject(ofType: DBUser.self, primaryKey: memberID) else {
            print("member not ID", findMemberID())
            throw
            RealmRetrieveError.memberNotPresent }
        return member
    }
    
    func retrieveRecentMessage() throws -> Message {
        guard let messageID = freezedChat?.recentMessageID,
              let message = RealmDBManager.shared.retrieveSingleObject(ofType: Message.self, primaryKey: messageID) else {
            print("message  not")
            throw RealmRetrieveError.messageNotPresent }
        return message
    }
    
    func retrieveMemberImageData() throws {
        guard let member = self.freezedMember,
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
            self.freezedMember      = try await loadOtherMemberOfChat()
            self.freezedMessage     =     await loadRecentMessage()
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
        guard let user = self.freezedMember,
              let userProfilePhotoURL = user.photoUrl else {
            return nil
        }
        let photoData = try await StorageManager.shared.getUserImage(userID: user.userId, path: userProfilePhotoURL)
        return photoData
    }

    func fetchUnreadMessagesCount() async throws -> Int? {
        guard let chat = freezedChat else {return nil}
        let unreadMessageCount = try await ChatsManager.shared.getUnreadMessagesCount(for: chat.id)
        self.unreadMessageCount = unreadMessageCount
        return unreadMessageCount
    }
}

//MARK: - Listeners

extension ChatCellViewModel {
   
    /// Observe user from Realtime db (Temporary fix while firebase functions are deactivated)
    private func addObserverToUser() {
        guard let member = freezedMember else {return}
        
        self.userObserver = UserManagerRealtimeDB.shared.addObserverToUsers(member.userId) { [weak self] realtimeDBUser in
            if realtimeDBUser.isActive != self?.freezedMember?.isActive
            {
                if let date = realtimeDBUser.lastSeen, let isActive = realtimeDBUser.isActive 
                {
                    self?.freezedMember = self?.freezedMember?.updateActiveStatus(lastSeenDate: date,isActive: isActive)
                }
            }
        }
    }
    
    /// Listen to user from Firestore db
    private func addListenerToUser()
    {
        guard let memberID = freezedMember?.userId else {return}
        
        self.usersListener = UserManager.shared.addListenerToUsers([memberID]) { [weak self] users, documentsTypes in
            guard let self = self else {return}
            // since we are listening only for one user here
            // we can just get the first user and docType
            guard let docType = documentsTypes.first, let user = users.first, docType == .modified else {return}
            self.freezedMember = user
        }
    }
}

//MARK: - Equatable protocol subs

extension ChatCellViewModel {
    static func == (lhs: ChatCellViewModel, rhs: ChatCellViewModel) -> Bool {
        lhs.freezedChat == rhs.freezedChat
    }
}
