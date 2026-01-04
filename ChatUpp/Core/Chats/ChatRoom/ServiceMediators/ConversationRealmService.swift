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
    
    func addMessagesToConversationInRealm(_ messages: [Message])
    {
        guard let conversation = conversation else { return }
        
        let existingIDs = Set(conversation.conversationMessages.map(\.id))
        
        RealmDatabase.shared.add(objects: messages)
        
        RealmDatabase.shared.update(object: conversation) { chat in
            for message in messages
            {
                if !existingIDs.contains(message.id) {
                    chat.conversationMessages.append(message)
                }
            }
        }
        
        /// See Footnote.swift [2]
        messages.forEach { message in
            if message.realm == nil {
                RealmDatabase.shared.add(object: message)
            }
        }
    }
    
    func updateChatOpenStatusIfNeeded()
    {
        guard let conversation = conversation else { return }
        
        if conversation.isFirstTimeOpened != false {
            RealmDatabase.shared.update(object: conversation) { $0.isFirstTimeOpened = false }
        }
    }
    
    func addMessagesToRealmChat(_ messages: [Message])
    {
        guard let conversation = conversation else { return }
        
        RealmDatabase.shared.update(object: conversation) { chat in
            chat.conversationMessages.append(objectsIn: messages)
        }
    }
    
    func retrieveMessageFromRealm(_ message: Message) -> Message? {
        return RealmDatabase.shared.retrieveSingleObject(ofType: Message.self, primaryKey: message.id)
    }
    
    func retrieveMessagesFromRealm(_ messages: [Message]) -> [Message]
    {
        let ids = messages.map(\.id)
        let predicate = NSPredicate(format: "id IN %@", ids as NSArray)
        guard let messages = RealmDatabase.shared
            .retrieveObjects(ofType: Message.self)?
            .filter(predicate) else { return [] }
        return Array(messages)
    }
    
    func addChatToRealm(_ chat: Chat) {
        RealmDatabase.shared.add(object: chat)
    }
    
    func updateMessage(_ message: Message) {
        RealmDatabase.shared.add(object: message)
    }
    
    func getUnreadMessagesCountFromRealm() -> Int
    {
        guard let conversation = conversation,
              let userID = authenticatedUserID
        else { return 0 }
        
        let filter = conversation.isGroup ?
//        NSPredicate(format: "NONE seenBy == %@ AND senderId != %@", userID, userID)
        NSPredicate(format: "NONE seenBy CONTAINS %@ AND senderId != %@", userID, userID)
        :
        NSPredicate(format: "messageSeen == false AND senderId != %@", authenticatedUserID ?? "")

        let count = conversation.conversationMessages.filter(filter).count
        return count
    }
    
    func removeMessageFromRealm(message: Message)
    {
        guard let realmMessage = retrieveMessageFromRealm(message) else {return}
        RealmDatabase.shared.delete(objects: [realmMessage])
    }
    
    func removeMessagesFromRealm(messages: [Message])
    {
        let realmMessages = retrieveMessagesFromRealm(messages)
        RealmDatabase.shared.delete(objects: realmMessages)
    }
    
    func updateRecentMessageFromRealmChat(withID messageID: String)
    {
        guard let chat = conversation else {return}
        RealmDatabase.shared.update(object: chat) { dbChat in
            dbChat.recentMessageID = messageID
        }
    }
}
