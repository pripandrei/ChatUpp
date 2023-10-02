//
//  ChatsManager.swift
//  ChatUpp
//
//  Created by Andrei Pripa on 10/2/23.
//

import Foundation
import FirebaseFirestore
import FirebaseFirestoreSwift

struct Chat: Codable {
    let id: String
    let members: [String]
    let lastMessage: String?
    
    let messages: [Message]?
}

struct Message: Codable {
    let id: String
    let message_body: String
    let sender_id: String
    let image_url: String?
    let timestamp: Date
}

final class ChatsManager {
    
    let shared = ChatsManager()
    
    private init() {}
    
    let chatsCollection = Firestore.firestore().collection("chats")
    
    private func chatDocument(chatID: String) -> DocumentReference {
        return chatsCollection.document(chatID)
    }
    
    //MARK: - CREATE NEW DOC
    
    func createNewDocument(chat: Chat, complition: @escaping (Bool) -> Void) {
        
        chatDocument(chatID: chat.id).getDocument { [weak self] docSnapshot, error in
            
            guard error == nil else { print(error!.localizedDescription) ; return }
            
            guard let docSnapshot = docSnapshot, docSnapshot.exists else {
                complition(true)
                return
            }
            
            try? self?.chatDocument(chatID: chat.id).setData(from: chat, merge: false) { error in
                guard error == nil else {
                    print(error!.localizedDescription)
                    return
                }
                complition(true)
            }
            
        }
    }
    
}
