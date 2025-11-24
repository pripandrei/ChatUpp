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

//    private(set) var updatedMessage = PassthroughSubject<DatabaseChangedObject<Message>,Never>()
    @Published var updatedMessages: [DatabaseChangedObject<Message>] = []

    init(conversation: Chat?) {
        self.conversation = conversation
    }
    
    func removeAllListeners()
    {
        listeners.forEach { $0.remove() }
        listeners.removeAll()
        cancellables.forEach { subscriber in
            subscriber.cancel()
        }
        cancellables.removeAll()
    }
    
    func addListenerToUpcomingMessages()
    {
        guard let conversationID = conversation?.id,
              let startMessage = conversation?.getLastMessage() else { return }
        let messageID = startMessage.id
        let messageTimestamp = startMessage.timestamp
 
        Task
        {
            let listener = try await FirebaseChatService.shared.addListenerForUpcomingMessages(
                inChat: conversationID,
                startingAfterMessage: messageID,
                messageTimestamp: messageTimestamp) { [weak self] messageUpdate in
                    guard let self = self else {return}
                    self.updatedMessages.append(messageUpdate)
                }
            self.listeners.append(listener)
        }
    }
    
    func addListenerToExistingMessagesTest(startAtMesssage message: Message,
                                           ascending: Bool,
                                           limit: Int = ObjectsPaginationLimit.remoteMessages)
    {
        guard let conversationID = conversation?.id, limit > 0 else { return }
        let messageID = message.id
        let messageTimestamp = message.timestamp
        
        Task { [weak self] in
            guard let self else { return }

            try await FirebaseChatService.shared
                .addListenerForExistingMessagesTest(
                    inChat: conversationID,
                    startAtMessageWithID: messageID,
                    messageTimestamp: messageTimestamp,
                    ascending: ascending,
                    limit: limit
                )
                .sink { [weak self] messagesUpdate in
                    guard let self else { return }
                    self.updatedMessages.append(contentsOf: messagesUpdate)
                }.store(in: &cancellables)
        }
    }
}
