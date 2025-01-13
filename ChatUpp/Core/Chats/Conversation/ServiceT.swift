//
//  ServiceT.swift
//  ChatUpp
//
//  Created by Andrei Pripa on 1/11/25.
//

import Foundation
import Combine

//MARK: - realm service

final class ConversationRealmService
{
    private let conversation: Chat?
    
    private var authenticatedUserID: String?
    {
        return try? AuthenticationManager.shared.getAuthenticatedUser().uid
    }
    
    init(conversation: Chat?) {
        self.conversation = conversation
    }
    
    func addMessagesToConversationInRealm(_ messages: [Message])
    {
        guard let conversation = conversation else { return }
        
        RealmDataBase.shared.update(object: conversation) { chat in
            
            let existingMessageIDs = Set(chat.conversationMessages.map { $0.id })
            let newMessages = messages.filter { !existingMessageIDs.contains($0.id) }
            
            chat.conversationMessages.append(objectsIn: newMessages)
        }
    }
    
    func updateChatOpenStatusIfNeeded()
    {
        guard let conversation = conversation else { return }
        
        if conversation.isFirstTimeOpened != false {
            RealmDataBase.shared.update(object: conversation) { $0.isFirstTimeOpened = false }
        }
    }
    
    func addMessageToRealmChat(_ message: Message)
    {
        guard let conversation = conversation else { return }
        
        RealmDataBase.shared.update(object: conversation) { chat in
            chat.conversationMessages.append(message)
        }
    }
    
    func retrieveMessageFromRealm(_ message: Message) -> Message? {
        return RealmDataBase.shared.retrieveSingleObject(ofType: Message.self, primaryKey: message.id)
    }
    
    func addChatToRealm(_ chat: Chat) {
        RealmDataBase.shared.add(object: chat)
    }
    
    func updateMessage(_ message: Message) {
        RealmDataBase.shared.add(object: message)
    }
    
    func getUnreadMessagesCountFromRealm() -> Int
    {
        guard let conversation = conversation else { return 0 }
        
        let filter = NSPredicate(format: "messageSeen == false AND senderId != %@", authenticatedUserID ?? "")
        let count = conversation.conversationMessages.filter(filter).count
        
        return count
    }
    
    func removeMessageFromRealm(message: Message)
    {
        guard let realmMessage = retrieveMessageFromRealm(message) else {return}
        RealmDataBase.shared.delete(object: realmMessage)
    }
}


//MARK: - firebase service

final class ConversationFirestoreService
{
    private let conversation: Chat?
    
    private var authenticatedUserID: String?
    {
        return try? AuthenticationManager.shared.getAuthenticatedUser().uid
    }
    
    init(conversation: Chat?) {
        self.conversation = conversation
    }
    
    func getFirstUnseenMessageFromFirestore(from chatID: String) async throws -> Message?
    {
        return try await FirebaseChatService.shared.getFirstUnseenMessage(fromChatDocumentPath: chatID,
                                                                   whereSenderIDNotEqualTo: authenticatedUserID ?? "")
    }

    func addChatToFirestore(_ chat: Chat) async {
        do {
            try await FirebaseChatService.shared.createNewChat(chat: chat)
        } catch {
            print("Error creating conversation", error.localizedDescription)
        }
    }
    
    @MainActor
    func addMessageToFirestoreDataBase(_ message: Message) async
    {
        guard let conversation = conversation else {return}
        do {
            try await FirebaseChatService.shared.createMessage(message: message, atChatPath: conversation.id)
        } catch {
            print("error occur while trying to create message in DB: ", error.localizedDescription)
        }
    }
    
    @MainActor
    func updateRecentMessageFromFirestoreChat(messageID: String) async
    {
        guard let chatID = conversation?.id else { print("chatID is nil") ; return}
        do {
            try await FirebaseChatService.shared.updateChatRecentMessage(recentMessageID: messageID, chatID: chatID)
        } catch {
            print("Error updating chat last message:", error.localizedDescription)
        }
    }
    
    func deleteMessageFromFirestore(messageID: String) {
        Task { @MainActor in
            do {
                try await FirebaseChatService.shared.removeMessage(messageID: messageID, conversationID: conversation!.id)
            } catch {
                print("Error deleting message: ",error.localizedDescription)
            }
        }
    }
    
    @MainActor
    func editMessageTextFromFirestore(_ messageText: String, messageID: String) {
        Task {
            try await FirebaseChatService.shared.updateMessageText(messageText, messageID: messageID, chatID: conversation!.id)
        }
    }
    
    func updateLastMessageFromFirestoreChat(_ lastMessageID: String) {
        Task { @MainActor in
//            guard let messageID = messageGroups[0].cellViewModels[0].cellMessage?.id else {return}
            await updateRecentMessageFromFirestoreChat(messageID: lastMessageID)
        }
    }
}


//MARK: - Users listener

final class ConversationUserListinerService
{
    private(set) var userObserver: RealtimeObservable?
    private var listeners: [Listener] = []
    
    private var chatUser: User
    
    init(chatUser: User) {
        self.chatUser = chatUser
    }
    
    func removeAllListeners()
    {
        listeners.forEach{ $0.remove() }
        userObserver?.removeAllObservers()
    }
    
    /// - Temporary fix while firebase functions are deactivated
    func addUserObserver()
    {
        userObserver = RealtimeUserService
            .shared
            .addObserverToUsers(chatUser.id) { [weak self] realtimeDBUser in
                
            guard let self = self else {return}
            
            if realtimeDBUser.isActive != self.chatUser.isActive
            {
                if let date = realtimeDBUser.lastSeen,
                    let isActive = realtimeDBUser.isActive
                {
                    self.chatUser = self.chatUser.updateActiveStatus(lastSeenDate: date,isActive: isActive)
                }
            }
        }
    }
    
    func addUsersListener()
    {
        let userListener = FirestoreUserService
            .shared
            .addListenerToUsers([chatUser.id]) { [weak self] users, documentsTypes in
            guard let self = self else {return}
            // since we are listening only for one user, we can just get the first user and docType
            guard let docType = documentsTypes.first, let user = users.first, docType == .modified else {return}
            self.chatUser = user
        }
        self.listeners.append(userListener)
    }
}

final class ConversationMessageListenerService
{
    private let conversation: Chat?
    private var listeners: [Listener] = []
    
    private(set) var addedMessage = PassthroughSubject<Message,Never>()
    private(set) var removedMessage = PassthroughSubject<Message,Never>()
    private(set) var modifiedMessage = PassthroughSubject<Message,Never>()
    
    init(conversation: Chat?) {
        self.conversation = conversation
    }
    
    func removeAllListeners()
    {
        listeners.forEach{ $0.remove() }
    }
    
    func addListenerToUpcomingMessages()
    {
        guard let conversationID = conversation?.id,
              let startMessageID = conversation?.getLastMessage()?.id else { return }
 
        Task { @MainActor in
            
            let listener = try await FirebaseChatService.shared.addListenerForUpcomingMessages(
                inChat: conversationID,
                startingAfterMessage: startMessageID) { [weak self] message, changeType in
                    
                    guard let self = self else {return}
                    
                    switch changeType {
                    case .added: self.addedMessage.send(message)
                    case .removed: self.removedMessage.send(message)
                    case .modified: self.modifiedMessage.send(message)
                    }
                }
            self.listeners.append(listener)
        }
    }
    
    func addListenerToExistingMessages(startAtTimestamp: Date, ascending: Bool, limit: Int = 100)
    {
        guard let conversationID = conversation?.id else { return }
        
        let listener = FirebaseChatService.shared.addListenerForExistingMessages(
            inChat: conversationID,
            startAtTimestamp: startAtTimestamp,
            ascending: ascending,
            limit: limit) { [weak self] message, changeType in
                
                guard let self = self else {return}
                
                switch changeType {
                case .removed: self.removedMessage.send(message)
                case .modified: self.modifiedMessage.send(message)
                default: break
                }
            }
        listeners.append(listener)
    }
}
