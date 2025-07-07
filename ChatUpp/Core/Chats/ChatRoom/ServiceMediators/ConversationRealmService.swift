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
        
        RealmDataBase.shared.update(object: conversation) { chat in
            guard let realm = chat.realm else { return }

            let existingMessageIDs = Set(chat.conversationMessages.map { $0.id })
            let newMessages = messages.filter { !existingMessageIDs.contains($0.id) }

            var messagesToAppend: [Message] = []

            for message in newMessages {
                if message.realm == nil {
                    realm.add(message, update: .all)
                }

                messagesToAppend.append(message)
            }

            chat.conversationMessages.append(objectsIn: messagesToAppend)
        }
        
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
        guard let conversation = conversation,
              let userID = authenticatedUserID
        else { return 0 }
        
        let filter = conversation.isGroup ?
        NSPredicate(format: "NONE seenBy == %@ AND senderId != %@", userID, userID) : NSPredicate(format: "messageSeen == false AND senderId != %@", authenticatedUserID ?? "")

        let count = conversation.conversationMessages.filter(filter).count
        return count
    }
    
    func removeMessageFromRealm(message: Message)
    {
        guard let realmMessage = retrieveMessageFromRealm(message) else {return}
        RealmDataBase.shared.delete(object: realmMessage)
    }
}
