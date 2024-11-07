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
        let chatsQuery = try await chatsCollection.whereField(FirestoreField.participants.rawValue, arrayContainsAny: [id]).getDocuments()
        
        for document in chatsQuery.documents {
            try await document.reference.updateData([Chat.CodingKeys.participants.rawValue: FieldValue.arrayRemove([id])])
            try await document.reference.updateData([Chat.CodingKeys.participants.rawValue: FieldValue.arrayUnion([deletedId])])
        }
    }
}

//MARK: - fetch chats
extension ChatsManager {
    func fetchChats(containingUserID userID: String) async throws -> [Chat] {
        return try await chatsCollection.whereField(Chat.CodingKeys.participants.rawValue, arrayContainsAny: [userID]).getDocuments(as: Chat.self)
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
        return try await messagesReference.order(by: Message.CodingKeys.timestamp.rawValue, descending: false).getDocuments(as: Message.self)
    }
    
    func getUnreadMessagesCount(from chatID: String, whereMessageSenderID senderID: String) async throws -> Int {
        let messagesReference = chatDocument(documentPath: chatID).collection(FirestoreCollection.messages.rawValue)
        return try await messagesReference.whereField(Message.CodingKeys.messageSeen.rawValue, isEqualTo: false).whereField(Message.CodingKeys.senderId.rawValue, isEqualTo: senderID).getDocuments().count
    }
    
    func getFirstUnseenMessage(fromChatDocumentPath documentID: String, whereSenderIDNotEqualTo senderID: String) async throws -> Message?
    {
        let messagesReference = chatDocument(documentPath: documentID).collection(FirestoreCollection.messages.rawValue)
        return try await messagesReference
            .whereField(Message.CodingKeys.messageSeen.rawValue, isEqualTo: false)
            .whereField(Message.CodingKeys.senderId.rawValue, isNotEqualTo: senderID)
            .order(by: Message.CodingKeys.timestamp.rawValue, descending: false)
            .limit(to: 1)
            .getDocuments(as: Message.self)
            .first
    }
    
        // Aggregation query to not fetch all messages but only get count 
//    func getUnreadMessagesCount(from chatID: String, whereMessageSenderID senderID: String) async throws -> Int
//    {
//        let messagesReference = chatDocument(documentPath: chatID)
//            .collection(FirestoreCollection.messages.rawValue)
//        
//        let countQuery = messagesReference
//            .whereField(Message.CodingKeys.messageSeen.rawValue, isEqualTo: false)
//            .whereField(Message.CodingKeys.senderId.rawValue, isEqualTo: senderID)
//            .count
//        
//        return try await countQuery
//            .getAggregation(source: .server)
//            .count
//            .intValue
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
    
//    @MainActor
//    func updateMessagesCount(inChat chatID: String) async throws
//    {
////        guard let count = chat.messagesCount else {return}
//        let data: [String: Any] = [
////            Chat.CodingKeys.messagesCount.rawValue : count + 1
//            Chat.CodingKeys.messagesCount.rawValue : FieldValue.increment(1.0)
//        ]
//        try await chatDocument(documentPath: chatID).updateData(data)
//    }
    
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

//MARK: - update chat participants

extension ChatsManager
{
    func updateUnreadMessageCount(for participantID: String, inChatWithID chatID: String) async throws
    {
        let fieldPath = "participants.\(participantID).\(ChatParticipant.CodingKeys.unseenMessagesCount.rawValue)"
        
//        let data: [String: [String:Any]] = [
//            Chat.CodingKeys.participants.rawValue : [ Participant.CodingKeys.unseenMessagesCount.rawValue : FieldValue.increment(1.0) ]
//        ]
        
        let data = [fieldPath : FieldValue.increment(Int64(1))]
        
        try await chatDocument(documentPath: chatID).updateData(data)
    }
}

//MARK: - Listeners

extension ChatsManager 
{
    func addListenerForChats(containingUserID userID: String, complition: @escaping ([Chat],[DocumentChangeType]) -> Void) -> Listener
    {
        return chatsCollection.whereField(FirestoreField.participants.rawValue, arrayContainsAny: [userID]).addSnapshotListener { querySnapshot, error in
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
    
    // messages listners
    func addListenerForUpcomingMessages(inChat chatID: String,
                                        startingAfterMessage messageID: String,
                                        onNewMessageReceived:  @escaping (Message, DocumentChangeType) -> Void) async throws -> Listener
    {
        let document = try await chatsCollection.document(chatID)
            .collection(FirestoreCollection.messages.rawValue)
            .document(messageID)
            .getDocument()
        
        return chatDocument(documentPath: chatID)
            .collection(FirestoreCollection.messages.rawValue)
            .order(by: Message.CodingKeys.timestamp.rawValue, descending: false)
            .start(afterDocument: document)
            .addSnapshotListener { snapshot, error in
                guard error == nil else { print(error!.localizedDescription); return }
                guard let documents = snapshot?.documentChanges else { print("No Message Documents to listen"); return }
                
                for document in documents {
                    guard let message = try? document.document.data(as: Message.self) else { continue }
                    onNewMessageReceived(message, document.type)
                }
                
            }
    }
    
    func addListenerForExistingMessages(inChat chatID: String,
                                        startAtTimestamp startTimestamp: Date,
                                        ascending: Bool,
                                        limit: Int,
                                        onMessageUpdated: @escaping (Message, DocumentChangeType) -> Void) -> Listener
    {
        return chatDocument(documentPath: chatID)
            .collection(FirestoreCollection.messages.rawValue)
            .order(by: Message.CodingKeys.timestamp.rawValue, descending: !ascending)
            .start(at: [startTimestamp])
            .limit(to: limit)
            .addSnapshotListener { snapshot, error in
                guard error == nil else { print(error!.localizedDescription); return }
                guard let documents = snapshot?.documentChanges else { print("No Message Documents to listen"); return }
                
                for document in documents {
                    guard let message = try? document.document.data(as: Message.self) else { continue }
                    onMessageUpdated(message, document.type)
                }
            }
    }
}

//MARK: - Pagination fetch

extension ChatsManager 
{
    func fetchMessagesFromChat(chatID: String,
                               startingFrom messageID: String?,
                               inclusive: Bool,
                               fetchDirection: MessagesFetchDirection,
                               limit: Int = 80) async throws -> [Message]
    {
        var query: Query = chatDocument(documentPath: chatID).collection(FirestoreCollection.messages.rawValue)

        if fetchDirection == .ascending {
            query = query.order(by: Message.CodingKeys.timestamp.rawValue, descending: false) // ascending order
        }
        else if fetchDirection == .descending {
            query = query.order(by: Message.CodingKeys.timestamp.rawValue, descending: true) // descending order
        }
        
        // if message is nil, it means that DB has only unseen messages
        // and we should just fetch them starting from first one
        if let messageID = messageID
        {
            let document = try await chatDocument(documentPath: chatID)
                .collection(FirestoreCollection.messages.rawValue)
                .document(messageID)
                .getDocument()
            
            if document.exists {
                query = inclusive ? query.start(atDocument: document) : query.start(afterDocument: document)
            }
        }
        
        return try await query.limit(to: limit)
            .getDocuments(as: Message.self)
    }
}




//MARK: Testing functions
extension ChatsManager {
    
    static func cleanFirestoreCache() async throws {
        do {
            try await Firestore.firestore().clearPersistence()
            print("Firestore cache successfully cleared")
        } catch {
            print("Error clearing Firestore cache: \(error.localizedDescription)")
        }
    }
    
    //MARK: - DELETE MESSAGES BY TIMESTAMP
    func testDeleteLastDocuments(documentPath: String) {
        chatDocument(documentPath: documentPath).collection(FirestoreCollection.messages.rawValue).order(by: Message.CodingKeys.timestamp.rawValue, descending: true)
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


    func updateMembersToParticipants() {
        // Reference to your Firestore collection

        // Fetch all documents in the collection
        chatsCollection.getDocuments { (snapshot, error) in
            if let error = error {
                print("Error fetching documents: \(error)")
                return
            }
            
            // Iterate through the documents
            for document in snapshot?.documents ?? [] {
                let data = document.data()

                // Check if the `members` field exists
                if let members = data["members"] as? [String] {
                    // Set the `participants` field with the same value as `members`
                    self.chatsCollection.document(document.documentID).updateData([
                        "participants": members,
                        "members": FieldValue.delete()  // Remove the `members` field
                    ]) { error in
                        if let error = error {
                            print("Error updating document: \(error)")
                        } else {
                            print("Successfully updated document \(document.documentID)")
                        }
                    }
                }
            }
        }
    }
    
    func migrateParticipantsField() {

        // Fetch all chat documents
        chatsCollection.getDocuments { snapshot, error in
            if let error = error {
                print("Error fetching chat documents: \(error)")
                return
            }
            
            guard let documents = snapshot?.documents else { return }
            
            // Iterate over each document
            for document in documents {
                let chatId = document.documentID
                
                if chatId == "049EDFBC-1F46-465E-B0B6-FEFD8A3C3E16" {
                    // Get current participants array
                    if var oldParticipants = document.data()["participants"] as? [String] {
                        var newParticipantsMap: [String: [String: Any]] = [:]
                        
                        // Transform each participant in the array to the new map format
                        for userId in oldParticipants {
                            // Generate a new ID for each participant entry
                            let newId = UUID().uuidString
                            
                            newParticipantsMap[newId] = [
                                "id": newId,
                                "user_id": userId,
                                "unseen_messages_count": 0 // default initial value
                            ]
                        }
                        
                        // Update the document with the new participants structure
                        self.chatsCollection.document(chatId).updateData(["participants": newParticipantsMap]) { error in
                            if let error = error {
                                print("Error updating chat \(chatId): \(error)")
                            } else {
                                print("Successfully updated chat \(chatId)")
                            }
                        }
                    } else {
                        print("No participants array found for chat \(chatId)")
                    }
                }
            }
        }
    }


}
