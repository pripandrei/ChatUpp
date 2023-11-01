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
//
//    func getChatDocumentFromDB(chatID: String) async throws -> Chat {
//        return try await chatDocument(documentPath: chatID).getDocument(as: Chat.self)
//    }
//
    //MARK: - GET MESSAGE DOCUMENT (currently not in use)
    
//    func getMessageDocumentFromDB(_ document: DocumentReference) async throws -> Message {
//        return try await document.getDocument(as: Message.self)
//    }
    
    //MARK: - GET USER RELATED CHATS DOCUMENT
    
    func getUserChatsFromDB(_ userID: String) async throws -> [Chat] {
        let chatsQuery = chatsCollection.whereField(FirestoreCollection.members.rawValue, arrayContainsAny: [userID])
        return try await chatsQuery.getDocuments(as: Chat.self)
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
    
    func getOtherMembersFromChats(_ chats: [Chat],_ authUserId: String) -> [String] {
        return chats.map { chat in
            guard let memberId = chat.members.first(where: { $0 != authUserId} ) else {fatalError("member is missing")}
            return memberId
        }
    }
    
    //MARK: - GET ALL MESSAGES FROM CHAT
    
    func getAllMessages(fromChatDocumentPath documentID: String) async throws -> [Message] {
        let messagesReference = chatDocument(documentPath: documentID).collection(FirestoreCollection.messages.rawValue)
        return try await messagesReference.order(by: "timestamp", descending: true).getDocuments(as: Message.self)
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

//extension Sequence {
//    func asyncMap<T>(_ transform: (Element) async throws -> T) async rethrows -> [T] {
//        var values = [T]()
//        
//        for element in self {
//            try await values.append(transform(element))
//        }
//
//        return values
//    }
//}
