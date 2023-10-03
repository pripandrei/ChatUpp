//
//  ChatsManager.swift
//  ChatUpp
//
//  Created by Andrei Pripa on 10/2/23.
//

import Foundation
import FirebaseFirestore
import FirebaseFirestoreSwift


final class ChatsManager {
    
    static let shared = ChatsManager()
    
    private init() {}
    
    let chatsCollection = Firestore.firestore().collection("chats")
    
    private func chatDocument(documentPath: String) -> DocumentReference {
        return chatsCollection.document(documentPath)
    }
    
    func getMessageReference(messagePath: String, fromChatDocumentPath documentPath: String) -> DocumentReference {
        chatDocument(documentPath: documentPath).collection("messages").document(messagePath)
    }
    
    //MARK: - CREATE NEW DOC
    
    func createNewChat(chat: Chat) async throws {
        try chatDocument(documentPath: chat.id).setData(from: chat, merge: false)
    }
    
    //MARK: - CREATE NEW MESSAGE
    
    func createNewMessage(message: Message, atChatPath path: String) async throws {
        try getMessageReference(messagePath: message.id, fromChatDocumentPath: path).setData(from: message.self, merge: false)
    }
    
    //MARK: - GET RECENT MESSAGE
    
//    func getRecentMessages(chatID: String) async throws {
//        let message = try await chatDocument(documentPath: chatID).getDocument(as: Message.self)
//    }
    
    //MARK: - GET CHAT DOCUMENT
    
    func getChatDocumentFromDB(chatID: String) async throws -> Chat {
        return try await chatDocument(documentPath: chatID).getDocument(as: Chat.self)
    }
    
    //MARK: - GET MESSAGE DOCUMENT
    
    func getMessageDocumentFromDB(_ document: DocumentReference) async throws -> Message {
            return try await document.getDocument(as: Message.self)
    }
}
