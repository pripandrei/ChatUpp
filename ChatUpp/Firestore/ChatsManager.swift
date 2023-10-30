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
    
    let chatsCollection = Firestore.firestore().collection(FirestoreCollection.chats.rawValue)
    
    private func chatDocument(documentPath: String) -> DocumentReference {
        return chatsCollection.document(documentPath)
    }
    
    func getMessageDocument(messagePath: String, fromChatDocumentPath documentPath: String) -> DocumentReference {
        return chatDocument(documentPath: documentPath).collection(FirestoreCollection.messages.rawValue).document(messagePath)
    }

    //MARK: - CREATE NEW DOC
    
    func createNewChat(chat: Chat) async throws {
        try chatDocument(documentPath: chat.id).setData(from: chat, merge: false)
    }
    
    //MARK: - CREATE NEW MESSAGE
    
    func createNewMessage(message: Message, atChatPath path: String) async throws {
        try getMessageDocument(messagePath: message.id, fromChatDocumentPath: path).setData(from: message.self, merge: false)
    }
    
    //MARK: - GET CHAT DOCUMENT (currently not in use)
    
    func getChatDocumentFromDB(chatID: String) async throws -> Chat {
        return try await chatDocument(documentPath: chatID).getDocument(as: Chat.self)
    }
    
    //MARK: - GET MESSAGE DOCUMENT (currently not in use)
    
    func getMessageDocumentFromDB(_ document: DocumentReference) async throws -> Message {
        return try await document.getDocument(as: Message.self)
    }
    
    //MARK: - GET USER RELATED CHATS DOCUMENT
    
    func getUserChatsFromDB(_ userID: String) async throws -> [Chat] {
        var chats = [Chat]()
        let querySnapshot = try await chatsCollection.whereField(FirestoreCollection.members.rawValue, arrayContainsAny: [userID]).getDocuments()
    
        for documentSnapshot in querySnapshot.documents {
            let document = try documentSnapshot.data(as: Chat.self)
            chats.append(document)
        }
        return chats
    }
    
    //MARK: - GET RECENT MESSAGE FROM CHATS
    
    func getRecentMessageFromChats(_ chats: [Chat]) async throws -> [Message] {
        var messages = [Message]()
        for chat in chats {
            let message = try await getMessageDocument(messagePath: chat.recentMessage, fromChatDocumentPath: chat.id).getDocument(as: Message.self)
            messages.append(message)
        }
        return messages
    }
    
    //MARK: - GET OTHER MEMBERS FROM CHATS
    
    func getOtherMembersFromChats(_ chats: [Chat],_ authUserId: String) async throws -> [String] {
        var otherMebmers = [String]()
        for chat in chats {
            if let otherUser = chat.members.first(where: { $0 != authUserId }) {
                otherMebmers.append(otherUser)
            }
        }
        return otherMebmers
    }
    
    //MARK: - GET ALL MESSAGES FROM CHAT
    
    func getAllMessages(fromChatDocumentPath documentID: String) async throws -> [Message] {
        let messagesReference = chatDocument(documentPath: documentID).collection(FirestoreCollection.messages.rawValue)
        
        return try await messagesReference.getDocuments(as: Message.self)
    }
}




extension Query {
    func getDocuments<T>(as type: T.Type) async throws -> [T] where T: Decodable  {
        let referenceType = try await self.getDocuments()
        return try referenceType.documents.map { document in
            try document.data(as: type.self)
        }
    }
    
}

