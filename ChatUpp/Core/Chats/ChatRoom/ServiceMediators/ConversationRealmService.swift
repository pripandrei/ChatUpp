//
//  Untitled.swift
//  ChatUpp
//
//  Created by Andrei Pripa on 4/13/25.
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
    
    
//    func addMessagesToConversationInRealmBackground(_ messages: [Message])
//    {
//        guard let conversationFreezed = conversation?.freeze() else { return }
//        RealmDataBase.shared.add(objects: messages)
//        
//        let messagesFreezed = messages.map { $0.freeze() }
//        
//        Task.detached(priority: .background)
//        {
//            RealmDataBase.shared.updateBackground(object: conversationFreezed) { chat in
//                messagesFreezed.forEach { message in
//                    if !chat.conversationMessages.contains(where: { $0.id == message.id} ) {
//                        if let message = RealmDataBase.shared.retrieveSingleObjectTest(ofType: Message.self, primaryKey: message.id)
//                        {
//                            chat.conversationMessages.append(message)
//                        }
//                    }
//                }
//            }
//        }
//    }
    
    func addMessagesToConversationInRealm(_ messages: [Message])
    {
        guard let conversation = conversation else { return }
        
        let existingIDs = Set(conversation.conversationMessages.map(\.id))
        
        RealmDataBase.shared.add(objects: messages)
        
        RealmDataBase.shared.update(object: conversation) { chat in
            for message in messages
            {
                if !existingIDs.contains(message.id) {
                    chat.conversationMessages.append(message)
                }
                
//                if !chat.conversationMessages.contains(where: { $0.id == message.id }) {
//                    chat.conversationMessages.append(message)
//                }
            }
        }
    
        // DO NOT REMOVE !
        
//        RealmDataBase.shared.update(object: conversation) { chat in
//            guard let realm = chat.realm else { return }
//
//            let existingMessageIDs = Set(chat.conversationMessages.map { $0.id })
//            let newMessages = messages.filter { !existingMessageIDs.contains($0.id) }
//
//            var messagesToAppend: [Message] = []
//
//            for message in newMessages {
//                if message.realm == nil {
//                    realm.add(message, update: .all)
//                }
//
//                messagesToAppend.append(message)
//            }
//
//            chat.conversationMessages.append(objectsIn: messagesToAppend)
//        }
        
        /// See Footnote.swift [2]
        messages.forEach { message in
            if message.realm == nil {
                RealmDataBase.shared.add(object: message)
            }
        }
    }
    
    func updateChatOpenStatusIfNeeded()
    {
        guard let conversation = conversation else { return }
        
        if conversation.isFirstTimeOpened != false {
            RealmDataBase.shared.update(object: conversation) { $0.isFirstTimeOpened = false }
        }
    }
    
    func addMessagesToRealmChat(_ messages: [Message])
    {
        guard let conversation = conversation else { return }
        
        RealmDataBase.shared.update(object: conversation) { chat in
            chat.conversationMessages.append(objectsIn: messages)
        }
    }
    
    func retrieveMessageFromRealm(_ message: Message) -> Message? {
        return RealmDataBase.shared.retrieveSingleObject(ofType: Message.self, primaryKey: message.id)
    }
    
    func retrieveMessagesFromRealm(_ messages: [Message]) -> [Message]
    {
        let ids = messages.map(\.id)
        let predicate = NSPredicate(format: "id IN %@", ids as NSArray)
        guard let messages = RealmDataBase.shared
            .retrieveObjects(ofType: Message.self)?
            .filter(predicate) else { return [] }
        return Array(messages)
    }
    
    func addChatToRealm(_ chat: Chat) {
        RealmDataBase.shared.add(object: chat)
    }
    
    func updateMessage(_ message: Message) {
        RealmDataBase.shared.add(object: message)
    }
    
    func getUnreadMessagesCountFromRealm() -> Int
    {
        guard let conversation = conversation,
              let userID = authenticatedUserID
        else { return 0 }
        
        let filter = conversation.isGroup ?
        NSPredicate(format: "NONE seenBy == %@ AND senderId != %@", userID, userID) : NSPredicate(format: "messageSeen == false AND senderId != %@", authenticatedUserID ?? "")

        let count = conversation.conversationMessages.filter(filter).count
        return count
    }
    
    ///// test
    func getUnreadMessagesCountFromRealmTestish() -> Int
    {
        guard let conversation = conversation,
              let userID = authenticatedUserID
        else { return 0 }
        guard let senderID = conversation.participants
            .first(where: { $0.userID != userID })?.userID else {return 0}
        let filter = conversation.isGroup ?
        NSPredicate(format: "NONE seenBy == %@ AND senderId != %@", senderID, senderID) : NSPredicate(format: "messageSeen == false AND senderId != %@", senderID ?? "")

        let count = conversation.conversationMessages.filter(filter).count
        return count
    }
    
    func removeMessageFromRealm(message: Message)
    {
        guard let realmMessage = retrieveMessageFromRealm(message) else {return}
        RealmDataBase.shared.delete(object: realmMessage)
    }
    
    func removeMessagesFromRealm(messages: [Message])
    {
        let realmMessages = retrieveMessagesFromRealm(messages)
        RealmDataBase.shared.delete(objects: realmMessages)
    }
    
    func updateRecentMessageFromRealmChat(withID messageID: String)
    {
        guard let chat = conversation else {return}
        RealmDataBase.shared.update(object: chat) { dbChat in
            dbChat.recentMessageID = messageID
        }
    }
}
