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
    
    private func chatDocument(chatID: String) -> DocumentReference {
        return chatsCollection.document(chatID)
    }
//
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
    
    func getMessage(messageID: String, fromChatDocumentPath documentPath: String) -> DocumentReference {
        chatDocument(chatID: documentPath).collection("messages").document(messageID)
    }

    
    //MARK: - CREATE NEW DOC
    
    func createNewDocument(chat: Chat, complition: @escaping (Bool) -> Void) {
            try? chatDocument(chatID: chat.id).setData(from: chat, merge: false) { error in
                if let error = error {
                    print(error.localizedDescription)
                    complition(false)
                    return
                }
                complition(true)
            }
    }
    
    //MARK: - GET CHAT DOCUMENT
    
    func getChatFromDB(chatID: String, complition: @escaping (Chat) -> Void) {
        chatDocument(chatID: chatID).getDocument(as: Chat.self) { (result) in
            do {
                let chat = try result.get()
                complition(chat)
            } catch let e {
                print("error getting chat document: \(e)")
            }
        }
    }
    
    func getMessagesFromDB(messagesID: String, fromCollectionRef collectionReference: CollectionReference) -> DocumentReference {
        return collectionReference.document(messagesID)
    }
    
    //MARK: - GET MESSAGE DOCUMENT
    
    func getMessageDocument(_ document: DocumentReference, complition: @escaping (Message?) -> Void) {
        document.getDocument(as: Message.self) { result in
            do {
               let message = try result.get()
                complition(message)
            } catch let e {
                print("error getting message from doc: \(e)")
                complition(nil)
            }
        }
    }
    
}











//    func createNewDocument(chat: Chat, complition: @escaping (Bool) -> Void) {
//
//        chatDocument(chatID: chat.id).getDocument { [weak self] docSnapshot, error in
//
//            guard error == nil else { print(error!.localizedDescription) ; return }
//
//            guard let docSnapshot = docSnapshot, docSnapshot.exists else {
//                complition(true)
//                return
//            }
//
//            try? self?.chatDocument(chatID: chat.id).setData(from: chat, merge: false) { error in
//                guard error == nil else {
//                    print(error!.localizedDescription)
//                    return
//                }
//                complition(true)
//            }
//        }
//    }



struct Chast: Codable {
    let id: String
    let lastMessage: String?
    let members: [String]
    
    // Custom Codable property to represent the subcollection path
    let messagesSubcollectionPath: String

    // Computed property to get a reference to the subcollection
    var messagesCollectionRef: CollectionReference {
        return Firestore.firestore().collection(messagesSubcollectionPath)
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
         messages: [Message]?) {
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
}
