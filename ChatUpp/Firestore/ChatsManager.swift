//
//  ChatsManager.swift
//  ChatUpp
//
//  Created by Andrei Pripa on 10/2/23.
//

import Foundation
import FirebaseFirestore
import FirebaseFirestoreSwift


//typealias ListenerIdentifier = String
typealias Listener = ListenerRegistration

final class ChatsManager {
    
    static let shared = ChatsManager()
    
    private init() {}
    
    let firestoreEncoder = Firestore.Encoder()
    let firestoreDecoder = Firestore.Decoder()
    
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
    
    func createNewMessageInDataBase(message: Message, atChatPath path: String) async throws {
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
        let chatsQuery = chatsCollection.whereField(FirestoreField.members.rawValue, arrayContainsAny: [userID])
        return try await chatsQuery.getDocuments(as: Chat.self)
    }
    
    //MARK: - DELETE MESSAGES BY TIMESTAMP
    
    func testDeleteLastDocuments(documentPath: String) {
        chatDocument(documentPath: documentPath).collection(FirestoreCollection.messages.rawValue).order(by: "timestamp", descending: true)
            .limit(to: 1) // Limit the query to retrieve the last 10 documents
            .getDocuments { (querySnapshot, error) in
                if let error = error {
                    print("Error fetching documents: \(error)")
                } else {
                    // Iterate through the documents and delete them
                    for document in querySnapshot!.documents {
                        document.reference.delete { error in
                            if error == nil {
                                print("Document \(document.documentID) successfully deleted")
                            }
                        }
                    }
                }
            }
    }
    
    /// For testing purposes only
    func updateAllMessagesFields() {
        
        // Query the "Chats" collection
        chatsCollection.getDocuments { (querySnapshot, error) in
            if let error = error {
                print("Error getting documents: \(error)")
            } else {
                guard let querySnapshot = querySnapshot else { return }
                
                for document in querySnapshot.documents {
                    let chatID = document.documentID
                    
                    // Reference to the "Messages" subcollection within the current chat
                    let messagesCollectionRef = self.chatsCollection.document(chatID).collection("messages")
                    
                    // Update the "is_edited" field for each document in the "Messages" subcollection
                    messagesCollectionRef.getDocuments { (messageQuerySnapshot, error) in
                        if let error = error {
                            print("Error getting documents: \(error)")
                        } else {
                            guard let messageQuerySnapshot = messageQuerySnapshot else { return }
                            
                            for messageDocument in messageQuerySnapshot.documents {
                                let messageID = messageDocument.documentID
                                
                                // Update the "is_edited" field for each message document
                                let messageDocRef = messagesCollectionRef.document(messageID)
                                messageDocRef.updateData(["is_edited": false]) { error in
                                    if let error = error {
                                        print("Error updating document: \(error)")
                                    } else {
                                        print("Document \(messageID) updated successfully")
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
    
    func testUpdateEditedFiled() {
        let data: [String: Any] = [
            Message.CodingKeys.isEdited.rawValue : false
        ]
        chatDocument(documentPath: "06067529-2DA4-48E0-9D8A-03305FF1AC8C").collection(FirestoreCollection.messages.rawValue).getDocuments { (querySnapshot, error) in
                if let error = error {
                    print("Error fetching documents: \(error)")
                } else {
                    // Iterate through the documents and delete them
                    for document in querySnapshot!.documents {
                        document.reference.updateData(data)
                    }
                }
            }
    }
    
    //MARK: - GET RECENT MESSAGE FROM CHATS
    
    func getRecentMessageFromChats(_ chats: [Chat]) async throws -> [Message?] {
        var messages = [Message?]()
        
        for chat in chats {
            guard let recentMessageID = chat.recentMessageID else {messages.append(nil) ; continue}
            let message = try await getMessageDocument(messagePath: recentMessageID, fromChatDocumentPath: chat.id).getDocument(as: Message.self)
            messages.append(message)
        }
        return messages
    }
    
    //MARK: - GET OTHER MEMBERS FROM CHATS
//
//    func getOtherMembersFromChats(_ chats: [Chat],_ authUserId: String) -> [String] {
//        return chats.map { chat in
//            guard let memberId = chat.members.first(where: { $0 != authUserId} ) else {fatalError("member is missing")}
//            return memberId
//        }
//    }
    
    //MARK: - GET ALL MESSAGES FROM CHAT
    
    func getAllMessages(fromChatDocumentPath documentID: String) async throws -> [Message] {
        let messagesReference = chatDocument(documentPath: documentID).collection(FirestoreCollection.messages.rawValue)
        return try await messagesReference.order(by: "timestamp", descending: false).getDocuments(as: Message.self)
    }
    
    //MARK: - UPDATE RECENT MESSAGE OF CHAT
    
    func updateChatRecentMessage(recentMessageID: String ,chatID: String) async throws {
        let data: [String: Any] = [
            Chat.CodingKeys.recentMessageID.rawValue : recentMessageID
        ]
        try await chatDocument(documentPath: chatID).updateData(data)
    }
    
    //MARK: - UPDATE MESSAGE SEEN STATUS
    
    func updateMessageSeenStatus(messageID: String , chatID: String) async throws {
        let data: [String: Any] = [
            Message.CodingKeys.messageSeen.rawValue : true
        ]
        try await getMessageDocument(messagePath: messageID, fromChatDocumentPath: chatID).updateData(data)
    }
    
    //MARK: - UPDATE MESSAGE TEXT
    
    func updateMessageFromDB(_ messageText: String, messageID: String, chatID: String) async throws {
        let data: [String: Any] = [
            Message.CodingKeys.messageBody.rawValue : messageText,
            Message.CodingKeys.isEdited.rawValue : true
        ]
        try await getMessageDocument(messagePath: messageID, fromChatDocumentPath: chatID).updateData(data)
    }
    
//    func updateMessageTest(messageID: String, chatID: String) async throws {
//        let data: [String: Any] = [
//            Message.CodingKeys.isEdited.rawValue : false
//        ]
//        try await getMessageDocument(messagePath: messageID, fromChatDocumentPath: chatID).updateData(data)
//    }
    
    //MARK: - GET ALL UNREAD CHAT MESSAGES COUNT
    
    func getUnreadMessagesCount(for chatID: String) async throws -> Int {
        let messagesReference = chatDocument(documentPath: chatID).collection(FirestoreCollection.messages.rawValue)
        return try await messagesReference.whereField(Message.CodingKeys.messageSeen.rawValue, isEqualTo: false).getDocuments().count
    }
    
    //MARK: - UPDATE MESSAGE IMAGE PATH
    
    func updateMessageImagePath(messageID: String, chatDocumentPath: String, path: String) async throws {
        let data: [String: Any] = [
            Message.CodingKeys.imagePath.rawValue: path
        ]
        try await getMessageDocument(messagePath: messageID, fromChatDocumentPath: chatDocumentPath).updateData(data)
    }
    
    //MARK: - UPDATE MESSAGE IMAGE SIZE
    
    func updateMessageImageSize(messageID: String, chatDocumentPath: String, imageSize: MessageImageSize) async throws {
        let encodedImageSize = try firestoreEncoder.encode(imageSize)
        
        let data: [String: Any] = [
            Message.CodingKeys.imageSize.rawValue: encodedImageSize
        ]
        try await getMessageDocument(messagePath: messageID, fromChatDocumentPath: chatDocumentPath).updateData(data)
    }
    
    //MARK: - REPLACE DELETED USER ID IN CHATS
    
    func replaceUserId(_ id: String, with deletedId: String) async throws {
        let chatsQuery = try await chatsCollection.whereField(FirestoreField.members.rawValue, arrayContainsAny: [id]).getDocuments()
        
        for document in chatsQuery.documents {
            try await document.reference.updateData(["members": FieldValue.arrayRemove([id])])
            try await document.reference.updateData(["members": FieldValue.arrayUnion([deletedId])])
        }
    }
    
    //MARK: - LISTENERS
    
    func addListenerForChats(containingUserID userID: String, complition: @escaping ([Chat],[DocumentChangeType]) -> Void) -> Listener
    {
        // get only the added or removed doc with diff option.
        // use compliciton to get the doc and find if the doc is in array of chats remove it, if not add it
        let listenerIdentifire = UUID().uuidString
        
       return chatsCollection.whereField(FirestoreField.members.rawValue, arrayContainsAny: [userID]).addSnapshotListener { querySnapshot, error in
            guard error == nil else { print(error!.localizedDescription); return}
            guard let documents = querySnapshot?.documentChanges else { print("No Chat Documents to listen"); return}

            var docChangeType: [DocumentChangeType] = []
            
            let chats = documents.compactMap { docChange in
                docChangeType.append(docChange.type)
                return try? docChange.document.data(as: Chat.self)
            }
            complition(chats,docChangeType)
        }
//        return listenerIdentifire
    }
    
    func addListenerToChatMessages(_ chatId: String, complition: @escaping ([Message], [DocumentChangeType]) -> Void) -> Listener
    {
        return chatDocument(documentPath: chatId).collection(FirestoreCollection.messages.rawValue).addSnapshotListener { querySnapshot, error in
            guard error == nil else { print(error!.localizedDescription); return}
            guard let documents = querySnapshot?.documentChanges else { print("No Message Documents to listen"); return}
            
            var docChangeType: [DocumentChangeType] = []
            
            let messages = documents.compactMap { documentMessage in
                docChangeType.append(documentMessage.type)
                return try? documentMessage.document.data(as: Message.self)
            }
            complition(messages,docChangeType)
        }
    }
    
    /// One message listener
    
    func addListenerToMessage(messageID: String, fromChatWithID chatID: String, complition: @escaping (Message?) -> Void) -> Listener {
        return chatDocument(documentPath: chatID)
            .collection(FirestoreCollection.messages.rawValue)
            .document(messageID)
            .addSnapshotListener { querySnapshot, error in
                guard error == nil else { print(error!.localizedDescription); return}
                guard let document = querySnapshot else { print("No Message Documents to listen"); return}
                
                if document.exists {
                    do {
                        let message = try document.data(as: Message.self)
                        complition(message)
                    } catch {
                        print("Error while decoding message from listener: ", error.localizedDescription)
                    }
                } else { complition(nil) }
            }
    }
    
    //MARK: - REMOVE MESSAGE FROM DB
    
    func removeMessageFromDB(messageID: String, conversationID: String) async throws {
        try await getMessageDocument(messagePath: messageID, fromChatDocumentPath: conversationID).delete()
    }

//    func addListenerForLastMessage(chatID: String, complition: @escaping (Chat) -> Void) -> ListenerRegistration {
//        let listener = chatDocument(documentPath: chatID).addSnapshotListener { docSnapshot, error in
//            guard error == nil else { print(error!.localizedDescription); return}
//            guard let document = docSnapshot else { print("No Documents to listen"); return}
//
//            guard let chat = try? document.data(as: Chat.self) else {print("Could not decode Chat data!") ; return}
//            complition(chat)
//        }
//        return listener
//    }
}

extension Query {
    func getDocuments<T>(as type: T.Type) async throws -> [T] where T: Decodable  {
        let referenceType = try await self.getDocuments()
        return try referenceType.documents.map { document in
            try document.data(as: type.self)
        }
    }
}

class GenericViewController<T: UIView>: UIViewController { }


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
