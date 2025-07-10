//
//  ChatsManager.swift
//  ChatUpp
//
//  Created by Andrei Pripa on 10/2/23.
//

import Foundation
import FirebaseFirestore
import FirebaseFirestoreSwift
import Combine



typealias Listener = ListenerRegistration

struct DatabaseChangedObject<T>
{
    let data: T
    let changeType: DocumentChangeType
}

final class FirebaseChatService {

    static let shared = FirebaseChatService()
    
    private init() {}
    
    private let firestoreEncoder = Firestore.Encoder()
    private let firestoreDecoder = Firestore.Decoder()
    
    private let db = Firestore.firestore()
    
    private lazy var chatsCollection = db.collection(FirestoreCollection.chats.rawValue)
    
    private func chatDocument(documentPath: String) -> DocumentReference {
        return chatsCollection.document(documentPath)
    }
    
    @MainActor
    func createNewChat(chat: Chat) async throws {
        try chatDocument(documentPath: chat.id).setData(from: chat, merge: false)
    }

    //TODO: - modify function to adjusts current participants map strucutre
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
extension FirebaseChatService
{
    func fetchChats(containingUserID userID: String) async throws -> [Chat] {
        return try await chatsCollection.whereField(Chat.CodingKeys.participants.rawValue, arrayContainsAny: [userID]).getDocuments(as: Chat.self)
    }
    
    func fetchChat(withID id: String) async throws -> Chat {
        return try await chatDocument(documentPath: id).getDocument(as: Chat.self)
    }
}

//MARK: - update chat
extension FirebaseChatService
{
    @MainActor
    func updateChat(_ chat: Chat) throws
    {
        try chatsCollection.document(chat.id).setData(from: chat, merge: true)
    }
}


//MARK: - remove chat
extension FirebaseChatService 
{
    func removeChat(chatID: String) async throws {
//        try await removeSubcollection(inChatWithID: chatID)
        try await deleteSubcollection(fromChatWithID: chatID)
        try await chatsCollection.document(chatID).delete()
    }
    
    func deleteSubcollection(fromChatWithID chatID: String) async throws
    {
        var batch: WriteBatch
        var documents: [QueryDocumentSnapshot]
        
        repeat {
            documents = try await chatDocument(documentPath: chatID)
                .collection(FirestoreCollection.messages.rawValue)
                .getDocuments()
                .documents
            
            batch = Firestore.firestore().batch()
            
            for document in documents {
                batch.deleteDocument(document.reference)
            }
            
            try await batch.commit()
        } while !documents.isEmpty
    }

}

//MARK: - Create and remove message

extension FirebaseChatService
{
    @MainActor
    func createMessage(message: Message, atChatPath path: String) async throws {
        try getMessageDocument(messagePath: message.id, fromChatDocumentPath: path).setData(from: message.self, merge: false)
    }
    func removeMessage(messageID: String, conversationID: String) async throws {
        try await getMessageDocument(messagePath: messageID,
                                     fromChatDocumentPath: conversationID).delete()
    }
}


//MARK: - Fetch messages

extension FirebaseChatService
{
    func getMessagesCount(fromChatDocumentPath documentPath: String) async throws -> Int  {
        let countQuery = chatDocument(documentPath: documentPath).collection(FirestoreCollection.messages.rawValue).count
        let count = try await countQuery.getAggregation(source: .server).count
        return count.intValue
    }
    
    func getMessageDocument(messagePath: String,
                            fromChatDocumentPath documentPath: String) -> DocumentReference
    {
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
    
    func getUnreadMessagesCountTest(from chatID: String, whereMessageSenderID senderID: String) async throws -> Int
    {
        let messagesRef = chatDocument(documentPath: chatID)
            .collection(FirestoreCollection.messages.rawValue)
            .whereField(Message.CodingKeys.messageSeen.rawValue, isEqualTo: false)
            .whereField(Message.CodingKeys.senderId.rawValue, isEqualTo: senderID)

        let snapshot = try await messagesRef.count.getAggregation(source: .server)
        return Int(truncating: snapshot.count)
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
    
    @MainActor
    func getRecentMessage(from chat: Chat) async throws -> Message?
    {
        guard let recentMessageID = chat.recentMessageID else {return nil}
        do {
            let message = try await getMessageDocument(messagePath: recentMessageID, fromChatDocumentPath: chat.id).getDocument(as: Message.self)
            return message
        } catch {
            print("Error fetching recent message: ", error.localizedDescription)
            return nil
        }
    }
    
    func getLatestMessages(fromChatWithID chatID: String, limit: Int) async throws -> [Message]
    {
        let messagesReference = chatDocument(documentPath: chatID).collection(FirestoreCollection.messages.rawValue)
        return try await messagesReference
            .order(by: Message.CodingKeys.timestamp.rawValue, descending: true)
            .limit(to: limit)
            .getDocuments(as: Message.self)
    }
}

//MARK: - Update messages

extension FirebaseChatService
{
    func updateMessageText(_ messageText: String, messageID: String, chatID: String) async throws {
        let data: [String: Any] = [
            Message.CodingKeys.messageBody.rawValue : messageText,
            Message.CodingKeys.isEdited.rawValue : true
        ]
        try await getMessageDocument(messagePath: messageID, fromChatDocumentPath: chatID).updateData(data)
    }
    
    func updateMessageSeenStatusTest(messageID: String , chatID: String) async throws {
        let data: [String: Any] = [
            Message.CodingKeys.messageSeen.rawValue : false
        ]
        try await getMessageDocument(messagePath: messageID, fromChatDocumentPath: chatID).updateData(data)
    }
    
    func updateMessagesSeenStatus(seenByUser userID: String? = nil,
                                  _ messageIDs: [String],
                                  chatID: String) async throws
    {
        var currentBatch = db.batch()
        var batches = [WriteBatch]()
        var writeCount = 0
        
        for id in messageIDs
        {
            let messageRef = getMessageDocument(
                messagePath: id,
                fromChatDocumentPath: chatID
            )
            
            /// if chat is group, append user that saw the message
            if let userID {
                currentBatch.updateData(["seenBy": FieldValue.arrayUnion([userID])], forDocument: messageRef)
            } else {
                currentBatch.updateData(["message_seen": true], forDocument: messageRef)
            }
            
            writeCount += 1
            
            if writeCount >= 500
            {
                batches.append(currentBatch)
                currentBatch = db.batch()
                writeCount = 0
            }
        }
        
        if writeCount > 0 {
            batches.append(currentBatch)
        }
        
        for batch in batches {
            try await batch.commit()
        }
    }
    
    func updateMessageSeenStatus(messageID: String , chatID: String) async throws {
        let data: [String: Any] = [
            Message.CodingKeys.messageSeen.rawValue : true
        ]
        try await getMessageDocument(messagePath: messageID, fromChatDocumentPath: chatID).updateData(data)
    }
    
    func updateMessageSeenStatus(by userID: String,
                                 messageID: String,
                                 chatID: String) async throws
    {
        let data: [String: Any] = [
            Message.CodingKeys.seenBy.rawValue: FieldValue.arrayUnion([userID])
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

    func updateMessageImageSize(messageID: String,
                                chatDocumentPath: String,
                                imageSize: MessageImageSize) async throws
    {
        let encodedImageSize = try firestoreEncoder.encode(imageSize)
        
        let data: [String: Any] = [
            Message.CodingKeys.imageSize.rawValue: encodedImageSize
        ]
        try await getMessageDocument(messagePath: messageID, fromChatDocumentPath: chatDocumentPath).updateData(data)
    }
    
    func updateMessageReactions(_ reactions: [String : [String]],
                                messageID: String,
                                chatID: String) async throws
    {
        let data: [String: Any] = [
            Message.CodingKeys.reactions.rawValue: reactions
        ]
        try await getMessageDocument(messagePath: messageID, fromChatDocumentPath: chatID).updateData(data)
    }
}

//MARK: - update chat participants

extension FirebaseChatService
{
//    func updateUnreadMessageCount(for participantID: String, inChatWithID chatID: String, increment: Bool) async throws
//    {
//        let fieldPath = "participants.\(participantID).\(ChatParticipant.CodingKeys.unseenMessagesCount.rawValue)"
//        
//        let counterValue = increment ? +1 : -1
//        let data = [fieldPath : FieldValue.increment(Int64(counterValue))]
//        
//        try await chatDocument(documentPath: chatID).updateData(data)
//    }
    
    func updateUnreadMessageCount(for participantsID: [String],
                                  inChatWithID chatID: String,
                                  increment: Bool,
                                  counter: Int? = nil) async throws
    {
        var data: [String: FieldValue] = [:]
        
        var counterValue = 0
        
        if let counter = counter {
            counterValue = increment ? counter : -counter
        } else {
            counterValue = increment ? +1 : -1
        }
        
        for id in participantsID
        {
            let fieldPath = "participants.\(id).\(ChatParticipant.CodingKeys.unseenMessagesCount.rawValue)"
            data[fieldPath] = FieldValue.increment(Int64(counterValue))
        }
        
        let chat = try await chatDocument(documentPath: chatID).getDocument(as: Chat.self)
        
        if let participant = chat.participants.first(where: { $0.userID == participantsID.first })
        {
            if participant.unseenMessagesCount <= 0 {
                print("stop this shit")
            }
        }
    
        try await chatDocument(documentPath: chatID).updateData(data)
    }
    
    func removeParticipant(participantID: String, inChatWithID chatID: String) async throws
    {
        let isDeletedField = "participants.\(participantID).is_deleted"
//        try await chatsCollection.document(chatID).updateData( [isDeletedField: true] )
        try await chatDocument(documentPath: chatID).updateData( [isDeletedField: true] )
    }
    
    func removeParticipant(participantID: String, fromChatWithID chatID: String) async throws
    {
        let participant = "participants.\(participantID)"
//        try await chatsCollection.document(chatID).updateData( [isDeletedField: true] )
        try await chatDocument(documentPath: chatID).updateData( [participant: FieldValue.delete()] )
    }
    
    @MainActor   
    func addParticipant(participant: ChatParticipant, toChat chatID: String) async throws
    {
        let newParticipant = [participant.userID : participant]
        try chatDocument(documentPath: chatID).setData(from: ["participants": newParticipant], merge: true)
    }
}


//MARK: - Listeners

extension FirebaseChatService 
{
    
    func singleChatPublisher(for chatID: String) -> AnyPublisher<DatabaseChangedObject<Chat>, Never>
    {
        let subject = PassthroughSubject<DatabaseChangedObject<Chat>, Never>()
        
        let listener = chatsCollection
            .whereField("id", isEqualTo: chatID)
            .addSnapshotListener { snapshot, error in
                guard error == nil else { print(error!); return }
                
                if let change = snapshot?.documentChanges.first
                {
                    if let chat = try? change.document.data(as: Chat.self)
                    {
                        let update = DatabaseChangedObject(data: chat, changeType: change.type)
                        subject.send(update)
                    }
                }
            }
        return subject
            .handleEvents(receiveCancel: { listener.remove() })
            .eraseToAnyPublisher()
    }
    
    func chatsPublisher(containingParticipantUserID participantUserID: String) -> AnyPublisher<DatabaseChangedObject<Chat>, Never>
    {
        let subject = PassthroughSubject<DatabaseChangedObject<Chat>, Never>()
        
        let listener = chatsCollection
            .whereField("participants.\(participantUserID).is_deleted", isEqualTo: false)
            .addSnapshotListener { snapshot, error in
                guard error == nil else { print(error!); return }
                
                snapshot?.documentChanges.forEach { change in

                    if let chat = try? change.document.data(as: Chat.self) {
                        let update = DatabaseChangedObject(data: chat, changeType: change.type)
                        subject.send(update)
                    }
                }
            }
        return subject
            .handleEvents(receiveCancel: { listener.remove() })
            .eraseToAnyPublisher()
    }
    
    // messages listners
    func addListenerForUpcomingMessages(inChat chatID: String,
                                        startingAfterMessage messageID: String,
                                        onNewMessageReceived:  @escaping (DatabaseChangedObject<Message>) -> Void) async throws -> Listener
    {
        let document = try await chatsCollection.document(chatID)
            .collection(FirestoreCollection.messages.rawValue)
            .document(messageID)
            .getDocument()
        
        guard document.exists else {
            throw FirestoreErrorCode(.notFound)
        }
        
        return chatDocument(documentPath: chatID)
            .collection(FirestoreCollection.messages.rawValue)
            .order(by: Message.CodingKeys.timestamp.rawValue, descending: false)
            .start(afterDocument: document)
            .addSnapshotListener { snapshot, error in
                guard error == nil else { print(error!.localizedDescription); return }
                guard let documents = snapshot?.documentChanges else { print("No Message Documents to listen"); return }
                
                for document in documents {
                    guard let message = try? document.document.data(as: Message.self) else { continue }
                    onNewMessageReceived(DatabaseChangedObject(data: message, changeType: document.type))
                }
                
            }
    }
    
    func addListenerForExistingMessages(inChat chatID: String,
                                        startAtMessageWithID messageID: String,
                                        ascending: Bool,
                                        limit: Int) async throws -> AnyPublisher<DatabaseChangedObject<Message>, Never>
    {
        let subject = PassthroughSubject<DatabaseChangedObject<Message>, Never>()
        
        let document = try await chatsCollection.document(chatID)
            .collection(FirestoreCollection.messages.rawValue)
            .document(messageID)
            .getDocument()
        
        guard document.exists else {
            throw FirestoreErrorCode(.notFound)
        }
        
        let listener = chatDocument(documentPath: chatID)
            .collection(FirestoreCollection.messages.rawValue)
            .order(by: Message.CodingKeys.timestamp.rawValue, descending: !ascending)
            .start(atDocument: document)
            .limit(to: limit)
            .addSnapshotListener { snapshot, error in
                guard error == nil else { print(error!.localizedDescription); return }
                guard let documents = snapshot?.documentChanges else { print("No Message Documents to listen"); return }
                
                for document in documents
                {
                    guard let message = try? document.document.data(as: Message.self) else { continue }
                    let object = DatabaseChangedObject(data: message, changeType: document.type)
                    subject.send(object)
                }
            }
        
        return subject
            .handleEvents(receiveCancel: {
                listener.remove()
            })
            .eraseToAnyPublisher()
    }
    
    // TODO:
    // Refactore code to fit async version of function above
    // and remove this function
//    func addListenerForExistingMessages(inChat chatID: String,
//                                        startAtTimestamp startTimestamp: Date,
//                                        ascending: Bool,
//                                        limit: Int,
//                                        onMessageUpdated: @escaping (DatabaseChangedObject<Message>) -> Void) -> Listener
//    {
//        
//        return chatDocument(documentPath: chatID)
//            .collection(FirestoreCollection.messages.rawValue)
//            .order(by: Message.CodingKeys.timestamp.rawValue, descending: !ascending)
//            .start(at: [startTimestamp])
//            .limit(to: limit)
//            .addSnapshotListener { snapshot, error in
//                guard error == nil else { print(error!.localizedDescription); return }
//                guard let documents = snapshot?.documentChanges else { print("No Message Documents to listen"); return }
//                
//                for document in documents {
//                    guard let message = try? document.document.data(as: Message.self) else { continue }
//                    onMessageUpdated(DatabaseChangedObject(data: message, changeType: document.type))
//                }
//            }
//    }
}

//MARK: - Pagination fetch

extension FirebaseChatService 
{
    func fetchMessagesFromChat(chatID: String,
                               startingFrom messageID: String?,
                               inclusive: Bool,
                               fetchDirection: MessagesFetchDirection,
                               limit: Int = ObjectsFetchingLimit.messages) async throws -> [Message]
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
extension FirebaseChatService
{
    func addEmptyReactionsToAllMessagesBatched() async throws
    {
        let chatsRef = chatsCollection
        
        var currentBatch = db.batch()
        var writeCount = 0
        var batches: [WriteBatch] = []
        
        let chatsSnapshot = try await chatsRef.getDocuments()
        
        for chatDoc in chatsSnapshot.documents
        {
            let chat = try chatDoc.data(as: Chat.self)
            
            // Messages
            let messagesRef = chatDoc.reference.collection("messages")
            let messagesSnapshot = try await messagesRef.getDocuments()
            
            for messageDoc in messagesSnapshot.documents
            {
                currentBatch.updateData(["reactions": [String: [String]]()], forDocument: messageDoc.reference)
                writeCount += 1
                
                if writeCount >= 500
                {
                    batches.append(currentBatch)
                    currentBatch = self.db.batch()
                    writeCount = 0
                }
            }
        }
        
        
        
//        chatsRef.getDocuments { chatSnapshot, error in
//            guard let chatSnapshot = chatSnapshot, error == nil else {
//                print("Failed to fetch chats: \(error?.localizedDescription ?? "unknown error")")
//                return
//            }
//            
//            for chatDoc in chatSnapshot.documents {
//                let messagesRef = chatDoc.reference.collection("messages")
//                
//                messagesRef.getDocuments { messageSnapshot, error in
//                    guard let messageSnapshot = messageSnapshot, error == nil else {
//                        print("Failed to fetch messages for chat \(chatDoc.documentID): \(error?.localizedDescription ?? "unknown error")")
//                        return
//                    }
//
//                    for messageDoc in messageSnapshot.documents {
//                        currentBatch.updateData(["reactions": [String: [String]]()], forDocument: messageDoc.reference)
//                        writeCount += 1
//                        
//                        if writeCount >= 500
//                        {
//                            batches.append(currentBatch)
//                            currentBatch = self.db.batch()
//                            writeCount = 0
//                        }
//                    }
//                }
//            }
//        }
        if writeCount > 0 {
            batches.append(currentBatch)
        }
        
        // Commit all batches sequentially
        for batch in batches {
            try await batch.commit()
        }
    }
    // update messages seenBy field with authUserID

    func markAllGroupMessagesAsSeen(by userID: String) async throws
    {
        let chatsRef = chatsCollection
        
        // 1. Query group chats (those with "name" field)
        let groupChatsSnapshot = try await chatsRef.whereField("name", isGreaterThan: "").getDocuments()
        
        var currentBatch = db.batch()
        var writeCount = 0
        var batches: [WriteBatch] = []
        
        for chatDoc in groupChatsSnapshot.documents
        {
            //Chat participants
            let chat = try chatDoc.data(as: Chat.self)
            let participantsID: [String] = chat.participants.map { $0.userID }
            
            // Messages
            let messagesRef = chatDoc.reference.collection("messages")
            let messagesSnapshot = try await messagesRef.getDocuments()
            
            for messageDoc in messagesSnapshot.documents
            {
                let seenBy = messageDoc.get("seen_by") as? [String] ?? []
//                let seenStatus = messageDoc.get("message_seen") as? Bool ?? nil
//                let senderID = messageDoc.get("sent_by") as? String ?? ""
                
//                currentBatch.updateData(["message_seen": FieldValue.delete()], forDocument: messageDoc.reference)
                for participantID in participantsID {
                    // Only add to batch if user hasn't already seen it
                    if !seenBy.contains(participantID) {
                        currentBatch.updateData(["seen_by": FieldValue.arrayUnion([participantID])], forDocument: messageDoc.reference)
                        //                currentBatch.updateData(["seen_by": FieldValue.arrayRemove([userID])], forDocument: messageDoc.reference)
                        writeCount += 1
                        
                        if writeCount >= 500 {
                            batches.append(currentBatch)
                            currentBatch = db.batch()
                            writeCount = 0
                        }
                    }
                }
            }
        }
        
        // Append the last batch if it has any writes
        if writeCount > 0 {
            batches.append(currentBatch)
        }
        
        // Commit all batches sequentially
        for batch in batches {
            try await batch.commit()
        }
    }
    
    func observeUserChats(userId: String) async -> AnyPublisher<[Chat], Never>
    {
        let subject = PassthroughSubject<[Chat], Never>()
        
        let listener = db.collectionGroup("participants_info")
            .whereField("user_id", isEqualTo: "DESg2qjjJPP20KQDWfKpJJnozv53")
            .addSnapshotListener { snapshot, error in
                guard let snapshot = snapshot else {
                    print("Error fetching chats: \(error?.localizedDescription ?? "")")
                    return
                }
                
                // Process chat documents
                Task {
                    var chats: [Chat] = []
                    for participantDoc in snapshot.documentChanges {
//                        participantDoc.document.reference
                        if let chatRef = participantDoc.document.reference.parent.parent {
                            do {
                                let chatDoc = try await chatRef.getDocument()
                                if let chat = try? chatDoc.data(as: Chat.self) {
                                    chats.append(chat)
                                }
                            } catch {
                                print("Error fetching chat: \(error)")
                            }
                        }
                    }
                    subject.send(chats)
                }
            }
        return subject
            .handleEvents(receiveCancel: { listener.remove() })
            .eraseToAnyPublisher()
    }
    func fetchChatsForUser(userId: String) async throws -> [Chat]
    {
        
        let userID = "DESg2qjjJPP20KQDWfKpJJnozv53"
        // This gets all 'participants' subcollections across all chat documents
        let participantsRef = db.collectionGroup("participants_info")
            .whereField("user_id", isEqualTo: userID)
        
        let snapshot = try await participantsRef.getDocuments()
        
        // Get parent documents (chats)
        var chats: [Chat] = []
        for participantDoc in snapshot.documents {
            // Get the reference to the parent chat document
            let chatRef = participantDoc.reference.parent.parent
            if let chatRef = chatRef {
                let chatDoc = try await chatRef.getDocument()
                if let chat = try? chatDoc.data(as: Chat.self) {
                    chats.append(chat)
                }
            }
        }
        
        return chats
    }
    
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
    
    func migrateParticipantsField() 
    {
        chatsCollection.getDocuments { snapshot, error in
            if let error = error {
                print("Error fetching chat documents: \(error)")
                return
            }
            
            guard let documents = snapshot?.documents else { return }
            
            let batch = self.db.batch()
            
            for document in documents {
                let chatId = document.documentID
                print(chatId)
//                if chatId == "543CFF01-4AA8-47FB-9965-9D1B0F75D460" {
                    // Fetch current participants array
                    if let oldParticipants = document.data()["participants"] as? [String: [String: Any]] {
                        // Prepare the new participants map
                        var newParticipantsMap: [String: [String: Any]] = [:]
                        
                        for participant in oldParticipants.values {
                            guard let userID = participant["user_id"] as? String else {
                                print("could not create participant")
                                continue
                            }
//                            values["user_id"]
                            newParticipantsMap[userID] = [
                                "user_id": userID,
                                "unseen_messages_count": 0,
                                "is_deleted": false
                            ]
                        }
                        
                        // Update chat document with new schema
                        let chatRef = self.chatsCollection.document(chatId)
                        
                        batch.updateData([
                            "participants": newParticipantsMap,
                            "participants_user_ids": FieldValue.delete() // Remove the field
                        ], forDocument: chatRef)
                    } else {
                        print("No participants array found for chat \(chatId)")
                    }
                    
//                    self.updateMessageSeenStatusToTrue(fromChatWithID: chatId)
//                }
            }
            
            // Commit the batch updates
            batch.commit { error in
                if let error = error {
                    print("Error updating chats: \(error)")
                } else {
                    print("Successfully updated chats")
                }
            }
        }
    }

    
    func updateMessageSeenStatusToTrue(fromChatWithID chatID: String) {
        let messagesCollection = self.chatsCollection.document(chatID).collection(FirestoreCollection.messages.rawValue)

        messagesCollection.whereField("message_seen", isEqualTo: false).getDocuments { snapshot, error in
            if let error = error {
                print("Error fetching messages: \(error)")
                return
            }
            
            guard let documents = snapshot?.documents else {
                print("No messages found.")
                return
            }
            
            let batch = self.db.batch()
            
            for document in documents {
                let documentRef = messagesCollection.document(document.documentID)
                batch.updateData(["message_seen": true], forDocument: documentRef)
            }
            
            // Commit the batch
            batch.commit { error in
                if let error = error {
                    print("Error updating messages: \(error)")
                } else {
                    print("Successfully updated all unseen messages to seen.")
                }
            }
        }
    }
}
