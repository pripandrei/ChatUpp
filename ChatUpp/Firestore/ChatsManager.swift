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
        return chatDocument(documentPath: documentPath).collection("messages").document(messagePath)
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
    
    //MARK: - GET USER RELATED CHATS DOCUMENT
    
    func getUserChatsFromDB(_ userID: String) async throws -> [Chat] {
        var chats = [Chat]()
        //        do {
        let querySnapshot = try await chatsCollection.whereField("members", arrayContainsAny: [userID]).getDocuments()
        
        for documentSnapshot in  querySnapshot.documents {
            let document = try documentSnapshot.data(as: Chat.self)
            chats.append(document)
            //                otherUsersFromChat.append(document.members.first { $0 != userID }!)
        }
        return chats
    }
    
    //MARK: - GET RECENT MESSAGE FROM CHATS
    
    func getRecentMessageFromChats(_ chats: [Chat]) async throws -> [Message] {
        var messages = [Message]()
        for chat in chats {
            let message = try await getMessageReference(messagePath: chat.recentMessage, fromChatDocumentPath: chat.id).getDocument(as: Message.self)
            messages.append(message)
        }
        return messages
    }
    
    func getOtherMembersFromChats(_ chats: [Chat],_ authUserId: String) async throws -> [String] {
        var otherMebmers = [String]()
        for chat in chats {
            if let otherUser = chat.members.first(where: { $0 != authUserId }) {
                otherMebmers.append(otherUser)
            }
        }
        return otherMebmers
    }
    
//    func getOtherMembersFromChats(withUser userID: String) async throws -> [String] {
   //        var otherMebmers = [String]()
   //        let querySnapshot = try await chatsCollection.whereField("members", arrayContainsAny: [userID]).getDocuments()
   //        for documentSnapshot in  querySnapshot.documents {
   //            let document = try documentSnapshot.data(as: Chat.self)
   //            otherMebmers.append(document.members.first { $0 != userID }!)
   //        }
   //        return otherMebmers
   //    }
}
