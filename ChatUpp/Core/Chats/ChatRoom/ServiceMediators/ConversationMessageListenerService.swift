//
//  Untitled.swift
//  ChatUpp
//
//  Created by Andrei Pripa on 4/13/25.
//

import Foundation
import Combine


//MARK: conversation message listener
final class ConversationMessageListenerService
{
    private let conversation: Chat?
    private var listeners: [Listener] = []
    
    private var cancellables: Set<AnyCancellable> = []

    private(set) var updatedMessage = PassthroughSubject<DatabaseChangedObject<Message>,Never>()

    init(conversation: Chat?) {
        self.conversation = conversation
    }
    
    func removeAllListeners()
    {
        listeners.forEach{ $0.remove() }
        listeners.removeAll()
        cancellables.forEach { subscriber in
            subscriber.cancel()
        }
        cancellables.removeAll()
    }
    
    func addListenerToUpcomingMessages()
    {
        guard let conversationID = conversation?.id,
              let startMessageID = conversation?.getLastMessage()?.id else { return }
 
        Task { @MainActor in
            
            let listener = try await FirebaseChatService.shared.addListenerForUpcomingMessages(
                inChat: conversationID,
                startingAfterMessage: startMessageID) { [weak self] messageUpdate in
                    guard let self = self else {return}
                    self.updatedMessage.send(messageUpdate)
                }
            self.listeners.append(listener)
        }
    }
    
    func addListenerToExistingMessages(startAtMesssageWithID messageID: String, ascending: Bool, limit: Int = ObjectsFetchingLimit.messages)
    {
        guard let conversationID = conversation?.id, limit > 0 else { return }
        
        Task {
            try await FirebaseChatService.shared.addListenerForExistingMessages(
                inChat: conversationID,
                startAtMessageWithID: messageID,
                ascending: ascending,
                limit: limit)
            .sink { [weak self] messageUpdate in
                guard let self = self else {return}
                self.updatedMessage.send(messageUpdate)
            }.store(in: &cancellables)
        }
    }
    
    // TODO:
    // Refactore code to fit version of function above
    // and remove this function
    func addListenerToExistingMessages(startAtTimestamp: Date, ascending: Bool, limit: Int = ObjectsFetchingLimit.messages)
    {
        guard let conversationID = conversation?.id else { return }
        
        let listener = FirebaseChatService.shared.addListenerForExistingMessages(
            inChat: conversationID,
            startAtTimestamp: startAtTimestamp,
            ascending: ascending,
            limit: limit) { [weak self] messageUpdate in
                guard let self = self else {return}
                self.updatedMessage.send(messageUpdate)
            }
        listeners.append(listener)
    }
}
