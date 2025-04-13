//
//  ConversationFirestoreService.swift
//  ChatUpp
//
//  Created by Andrei Pripa on 4/13/25.
//

import Foundation
import Combine



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
            await updateRecentMessageFromFirestoreChat(messageID: lastMessageID)
        }
    }
}
