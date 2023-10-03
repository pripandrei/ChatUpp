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

//    func messagesCollection(chatDocRef: DocumentReference) -> CollectionReference {
//        return chatDocRef.collection("message")
//    }
    
//    func getMessagesCollection(fromChatDocumentPath documentPath: String) -> CollectionReference {
//        chatDocument(chatID: documentPath).collection("messages")
//    }
//
//    func getMessagePath(_ messagePath: String, from messageCollection: CollectionReference) -> DocumentReference {
//        return messageCollection.document(messagePath)
//    }
    
    func getMessageReference(messagePath: String, fromChatDocumentPath documentPath: String) -> DocumentReference {
        chatDocument(documentPath: documentPath).collection("messages").document(messagePath)
    }
    
//    func getMessage2(messageID :String, fromChatID chatID :String) -> DocumentReference {
//        return chatsCollection.document("chats/\(fromChatID)/messages/\(messageID))")
//    }

    
    //MARK: - CREATE NEW DOC
    
//    func createNewChat(chat: Chat, complition: @escaping (Bool) -> Void) {
//            try? chatDocument(documentPath: chat.id).setData(from: chat, merge: false) { error in
//                if let error = error {
//                    print(error.localizedDescription)
//                    complition(false)
//                    return
//                }
//                complition(true)
//            }
//    }
    
    func createNewChat(chat: Chat) async throws {
        try chatDocument(documentPath: chat.id).setData(from: chat, merge: false)
    }
    
    //MARK: - CREATE NEW MESSAGE
    
//    func createNewMessage(message: Message, atChatPath path: String, complition: @escaping (Bool) -> Void) {
//        try? getMessageReference(messagePath: message.id, fromChatDocumentPath: path).setData(from: message.self, merge: false) { error in
//            if let error = error {
//                print("error creating new message: ",error.localizedDescription)
//                complition(false)
//                return
//            }
//            complition(true)
//        }
//    }
    
    func createNewMessage(message: Message, atChatPath path: String) async throws {
        try getMessageReference(messagePath: message.id, fromChatDocumentPath: path).setData(from: message.self, merge: false)
    }
    
    
    //MARK: - GET CHAT DOCUMENT
    
//    func getChatDocumentFromDB(chatID: String, complition: @escaping (Chat) -> Void) {
//        chatDocument(documentPath: chatID).getDocument(as: Chat.self) { (result) in
//            do {
//                let chat = try result.get()
//                complition(chat)
//            } catch let e {
//                print("error getting chat document: \(e)")
//            }
//        }
//    }
    
    func getChatDocumentFromDB(chatID: String) async throws -> Chat {
        return try await chatDocument(documentPath: chatID).getDocument(as: Chat.self)
    }
    
    //MARK: - GET MESSAGE DOCUMENT
    
//    func getMessageDocumentFromDB(_ document: DocumentReference, complition: @escaping (Message?) -> Void) {
//        document.getDocument(as: Message.self) { result in
//            do {
//               let message = try result.get()
//                complition(message)
//            } catch let e {
//                print("error getting message from doc: \(e)")
//                complition(nil)
//            }
//        }
//    }
    
    func getMessageDocumentFromDB(_ document: DocumentReference) async throws -> Message {
            return try await document.getDocument(as: Message.self)
    }
}


struct Chat: Codable {
    let id: String
    let members: [String]
    let lastMessage: String?
    
    let messages: [Message]?
    
    enum CodingKeys: String, CodingKey {
        case id = "id"
        case members = "members"
        case lastMessage = "last_message"
        case messages = "message"
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try container.decode(String.self, forKey: .id)
        self.members = try container.decode([String].self, forKey: .members)
        self.lastMessage = try container.decodeIfPresent(String.self, forKey: .lastMessage)
        self.messages = try container.decodeIfPresent([Message].self, forKey: .messages)
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(self.id, forKey: .id)
        try container.encode(self.members, forKey: .members)
        try container.encodeIfPresent(self.lastMessage, forKey: .lastMessage)
        try container.encodeIfPresent(self.messages, forKey: .messages)
    }
    
    init(id: String,
         members: [String],
         lastMessage: String?,
         messages: [Message]?)
    {
        self.id = id
        self.members = members
        self.lastMessage = lastMessage
        self.messages = messages
    }
}

struct Message: Codable {
    let id: String
    let messageBody: String
    let senderId: String
    let imageUrl: String?
    let timestamp: String
    
    enum CodingKeys: String, CodingKey {
        case id = "id"
        case messageBody = "message_body"
        case senderId = "sender_id"
        case imageUrl = "image_url"
        case timestamp = "timestamp"
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try container.decode(String.self, forKey: .id)
        self.messageBody = try container.decode(String.self, forKey: .messageBody)
        self.senderId = try container.decode(String.self, forKey: .senderId)
        self.imageUrl = try container.decodeIfPresent(String.self, forKey: .imageUrl)
        self.timestamp = try container.decode(String.self, forKey: .timestamp)
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(self.id, forKey: .id)
        try container.encode(self.messageBody, forKey: .messageBody)
        try container.encode(self.senderId, forKey: .senderId)
        try container.encodeIfPresent(self.imageUrl, forKey: .imageUrl)
        try container.encode(self.timestamp, forKey: .timestamp)
    }
    
    init(id: String,
         messageBody: String,
         senderId: String,
         imageUrl: String?,
         timestamp: String)
    {
        self.id = id
        self.messageBody = messageBody
        self.senderId = senderId
        self.imageUrl = imageUrl
        self.timestamp = timestamp
    }
}



//private var chatDocument: DocumentReference!
//private var messageDocument: DocumentReference!
//
//var chatPath: String = "" {
//    didSet {
//        chatDocument = chatsCollection.document(chatPath)
//    }
//}
//
//var messagePath: String? {
//    didSet {
//        messageDocument = chatDocument.collection("messages").document(messagePath!)
//        messagePath = nil
//    }
//}

//    func getMessageFromDB(complition: @escaping (Message?) -> Void) {
//        messageDocument.getDocument(as: Message.self) { result in
//            do {
//               let message = try result.get()
//                complition(message)
//            } catch let e {
//                print("error getting message from doc: \(e)")
//                complition(nil)
//            }
//        }
//    }
