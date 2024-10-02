//
//  ChatsManager.swift
//  ChatUpp
//
//  Created by Andrei Pripa on 10/2/23.
//

import Foundation
import FirebaseFirestore
import FirebaseFirestoreSwift


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

    func createNewChat(chat: Chat) async throws {
        try chatDocument(documentPath: chat.id).setData(from: chat, merge: false)
    }

    /// - Replace deleted user id in chats
    func replaceUserId(_ id: String, with deletedId: String) async throws {
        let chatsQuery = try await chatsCollection.whereField(FirestoreField.members.rawValue, arrayContainsAny: [id]).getDocuments()
        
        for document in chatsQuery.documents {
            try await document.reference.updateData(["members": FieldValue.arrayRemove([id])])
            try await document.reference.updateData(["members": FieldValue.arrayUnion([deletedId])])
        }
    }
}

//MARK: - Create and remove message

extension ChatsManager
{
    @MainActor
    func createMessage(message: Message, atChatPath path: String) async throws {
        try getMessageDocument(messagePath: message.id, fromChatDocumentPath: path).setData(from: message.self, merge: false)
    }
    func removeMessage(messageID: String, conversationID: String) async throws {
        try await getMessageDocument(messagePath: messageID, fromChatDocumentPath: conversationID).delete()
    }
}


//MARK: - Fetch messages

extension ChatsManager 
{
    
    func getMessagesCount(fromChatDocumentPath documentPath: String) async throws -> Int  {
        let countQuery = chatDocument(documentPath: documentPath).collection(FirestoreCollection.messages.rawValue).count
        let count = try await countQuery.getAggregation(source: .server).count
        return count.intValue
    }
    
    func getMessageDocument(messagePath: String, fromChatDocumentPath documentPath: String) -> DocumentReference {
        return chatDocument(documentPath: documentPath).collection(FirestoreCollection.messages.rawValue).document(messagePath)
    }
    
    func getAllMessages(fromChatDocumentPath documentID: String) async throws -> [Message] {
        let messagesReference = chatDocument(documentPath: documentID).collection(FirestoreCollection.messages.rawValue)
        return try await messagesReference.order(by: "timestamp", descending: false).getDocuments(as: Message.self)
    }
    
    func getUnreadMessagesCount(from chatID: String, whereMessageSenderID senderID: String) async throws -> Int {
        let messagesReference = chatDocument(documentPath: chatID).collection(FirestoreCollection.messages.rawValue)
        return try await messagesReference.whereField(Message.CodingKeys.messageSeen.rawValue, isEqualTo: false).whereField(Message.CodingKeys.senderId.rawValue, isEqualTo: senderID).getDocuments().count
    }
    
//    func getRecentMessageFromChats(_ chats: [Chat]) async throws -> [Message?] {
//        var messages = [Message?]()
//        
//        for chat in chats {
//            guard let recentMessageID = chat.recentMessageID else { messages.append(nil) ; continue }
//            let message = try await getMessageDocument(messagePath: recentMessageID, fromChatDocumentPath: chat.id).getDocument(as: Message.self)
//            messages.append(message)
//        }
//        return messages
//    }
    @MainActor
    func getRecentMessage(from chat: Chat) async throws -> Message? {
        guard let recentMessage = chat.recentMessageID else {return nil}
        let message = try await getMessageDocument(messagePath: recentMessage, fromChatDocumentPath: chat.id).getDocument(as: Message.self)
        return message
    }
}

//MARK: - Update messages

extension ChatsManager
{
    func updateMessageText(_ messageText: String, messageID: String, chatID: String) async throws {
        let data: [String: Any] = [
            Message.CodingKeys.messageBody.rawValue : messageText,
            Message.CodingKeys.isEdited.rawValue : true
        ]
        try await getMessageDocument(messagePath: messageID, fromChatDocumentPath: chatID).updateData(data)
    }
    
    func updateMessageSeenStatus(messageID: String , chatID: String) async throws {
        let data: [String: Any] = [
            Message.CodingKeys.messageSeen.rawValue : true
        ]
        try await getMessageDocument(messagePath: messageID, fromChatDocumentPath: chatID).updateData(data)
    }
    
    func updateChatRecentMessage(recentMessageID: String ,chatID: String) async throws {
        let data: [String: Any] = [
            Chat.CodingKeys.recentMessageID.rawValue : recentMessageID
        ]
        try await chatDocument(documentPath: chatID).updateData(data)
    }

    func updateMessageImagePath(messageID: String, chatDocumentPath: String, path: String) async throws {
        let data: [String: Any] = [
            Message.CodingKeys.imagePath.rawValue: path
        ]
        try await getMessageDocument(messagePath: messageID, fromChatDocumentPath: chatDocumentPath).updateData(data)
    }

    func updateMessageImageSize(messageID: String, chatDocumentPath: String, imageSize: MessageImageSize) async throws {
        let encodedImageSize = try firestoreEncoder.encode(imageSize)
        
        let data: [String: Any] = [
            Message.CodingKeys.imageSize.rawValue: encodedImageSize
        ]
        try await getMessageDocument(messagePath: messageID, fromChatDocumentPath: chatDocumentPath).updateData(data)
    }
    
}

//MARK: - Listeners

extension ChatsManager 
{
    func addListenerForChats(containingUserID userID: String, complition: @escaping ([Chat],[DocumentChangeType]) -> Void) -> Listener
    {
        // get only the added or removed doc with diff option.
        // use compliciton to get the doc and find if the doc is in array of chats remove it, if not add it
        
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
    }
    
    func addListenerToChatMessages(_ chatId: String,
                                   onReceivedMessage: @escaping (Message, DocumentChangeType) -> Void,
                                   onReceiveMessagesComplition: @escaping () -> Void) -> Listener
    {
        return chatDocument(documentPath: chatId).collection(FirestoreCollection.messages.rawValue).addSnapshotListener { querySnapshot, error in
            guard error == nil else { print(error!.localizedDescription); return}
            guard let documents = querySnapshot?.documentChanges else { print("No Message Documents to listen"); return}

            for document in documents {
                guard let message = try? document.document.data(as: Message.self) else {continue}
                onReceivedMessage(message, document.type)
            }
            onReceiveMessagesComplition()
        }
    }
}

//MARK: Testing functions
extension ChatsManager {
    
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
}
