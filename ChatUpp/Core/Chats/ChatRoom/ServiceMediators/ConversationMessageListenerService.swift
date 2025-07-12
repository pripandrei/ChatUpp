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
    @Published var updatedMessages: [DatabaseChangedObject<Message>] = []

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
//                    self.updatedMessages.send([messageUpdate])
                    self.updatedMessages.append(messageUpdate)
                }
            self.listeners.append(listener)
        }
    }
    
    func addListenerToExistingMessagesTest(startAtMesssageWithID messageID: String,
                                           ascending: Bool,
                                           limit: Int = ObjectsFetchingLimit.messages)
    {
        guard let conversationID = conversation?.id, limit > 0 else { return }
        
        Task {
            try await FirebaseChatService.shared.addListenerForExistingMessagesTest(
                inChat: conversationID,
                startAtMessageWithID: messageID,
                ascending: ascending,
                limit: limit)
            .sink { [weak self] messagesUpdate in
                guard let self = self else {return}
                self.updatedMessages.append(contentsOf: messagesUpdate)
//                self.updatedMessage.send(messageUpdate)
            }.store(in: &cancellables)
        }
    }
    
    func addListenerToExistingMessages(startAtMesssageWithID messageID: String,
                                       ascending: Bool,
                                       limit: Int = ObjectsFetchingLimit.messages)
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
}
