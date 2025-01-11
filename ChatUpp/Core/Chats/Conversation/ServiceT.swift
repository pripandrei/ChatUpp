//
//  ServiceT.swift
//  ChatUpp
//
//  Created by Andrei Pripa on 1/11/25.
//

import Foundation


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
