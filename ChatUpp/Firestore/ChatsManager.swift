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
    
//    func createNewMessage(message: Message, atChatPath path: String, complition: () -> Void) {
//        
//    }
    
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
    
    //MARK: - GET RECENT MESSAGE FROM CHATS
    
    func getRecentMessageFromChats(_ chats: [Chat]) async throws -> [Message] {
        var messages = [Message]()
        
        for chat in chats {
            print(chat.recentMessageID, chat.id)
            let message = try await getMessageDocument(messagePath: chat.recentMessageID, fromChatDocumentPath: chat.id).getDocument(as: Message.self)
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
        return try await messagesReference.order(by: "timestamp", descending: true).getDocuments(as: Message.self)
    }
    
    //MARK: - UPDATE RECENT MESSAGE OF CHAT
    
    func updateChatRecentMessage(recentMessageID: String ,chatID: String) async throws {
        let data: [String: Any] = [
            Chat.CodingKeys.recentMessage.rawValue : recentMessageID
        ]
        try await chatDocument(documentPath: chatID).updateData(data)
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
    
    func addListenerForChats(containingUserID userID: String, complition: @escaping ([Chat]) -> Void)
    {
//        chatsCollection.addSnapshotListener { querySnapshot, error in
//            guard error == nil else { print(error!.localizedDescription); return}
//            guard let documents = querySnapshot?.documents else { print("No Documents to listen"); return}
//
//            let filteredChats = documents.compactMap { document in
//                let chat = try? document.data(as: Chat.self)
//                return chat?.members.contains { $0 == userID } == true ? chat : nil
//            }
//            complition(filteredChats)
//        }
        
        // get only the added or removed doc with diff option.
        // use compliciton to get the doc and find if the doc is in array of chats remove it, if not add it
        
        chatsCollection.whereField(FirestoreField.members.rawValue, arrayContainsAny: [userID]).addSnapshotListener { querySnapshot, error in
            guard error == nil else { print(error!.localizedDescription); return}
            guard let documents = querySnapshot?.documents else { print("No Documents to listen"); return}

            
//            let chats = documents.compactMap { diff in
//                if diff.type == .added || diff.type == .removed {
//                    return try? diff.document.data(as: Chat.self)
//                }
//                return nil
//            }
//
            let chats = documents.compactMap { diff in
//                if diff.type == .added || diff.type == .removed {
                    return try? diff.data(as: Chat.self)
//                }
//                return nil
            }
            
            complition(chats)
            
            
//            querySnapshot?.documentChanges.forEach({ diff in
//                if diff.type == .added || diff.type == .removed {
//                    let chats = documents.compactMap { documentSnapshot in
//                        try? documentSnapshot.data(as: Chat.self)
//                    }
//                    complition(chats)
//                }
//            })
//
//            let chats = documents.compactMap { documentSnapshot in
//                try? documentSnapshot.data(as: Chat.self)
////                try? documentSnapshot.document.data(as: Chat.self)
//            }
//            print("+++++Count of chats",chats.count)
//            complition(chats)
        }
    }
    
    func addListenerForLastMessage(chatID: String, complition: @escaping (Chat) -> Void) {
        chatDocument(documentPath: chatID).addSnapshotListener { docSnapshot, error in
            guard error == nil else { print(error!.localizedDescription); return}
            guard let document = docSnapshot else { print("No Documents to listen"); return}
            
            guard let chat = try? document.data(as: Chat.self) else {print("Could not decode Chat data!") ; return}
            complition(chat)
        }
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
