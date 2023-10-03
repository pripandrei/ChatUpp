//
//  SettingsViewModel.swift
//  ChatUpp
//
//  Created by Andrei Pripa on 9/26/23.
//

import Foundation

final class SettingsViewModel {

    var userIsSignedOut: ObservableObject<Bool> = ObservableObject(false)
    
    @objc func signOut() {
        do {
            try AuthenticationManager.shared.signOut()
            userIsSignedOut.value = true
        } catch {
            print("Error signing out")
        }
    }
    
    var setProfileName: ((String) -> Void)?
    
    func integrateName() {
//        let authResult = try! AuthenticationManager.shared.getAuthenticatedUser()
//        let dbUser = DBUser(auth: authResult)
//        UserManager.shared.getUserFromDB(userID: dbUser.userId) { [weak self] user in
//            DispatchQueue.main.async {
////                self?.setProfileName?(user.userId)
//            }
//        }
        
        let messageDoc2 = ChatsManager.shared.getMessage(messagePath: "BucXHvVBzgPDax5BYOyE", fromChatDocumentPath: "KmAGbYwUTrwWAqfbbGo9")
        let messag = Message(id: "£424", messageBody: "IEW98980R", senderId: "WER", imageUrl: "WER", timestamp: "WER")
//        let messageDocument = ChatsManager.shared.getMessage(messageID: "BucXHvVBzgPDax5BYOyE", fromChatDocumentPath: "KmAGbYwUTrwWAqfbbGo9")
//        let messagesCollection = ChatsManager.shared.getMessagesCollection(fromChatDocumentPath: "KmAGbYwUTrwWAqfbbGo9")
//        let messageDoc = ChatsManager.shared.getMessagePath("BucXHvVBzgPDax5BYOyE", from: messagesCollection)
        ChatsManager.shared.createNewMessage(message: messag, onChatPath: "KmAGbYwUTrwWAqfbbGo9") { created in
            
        }
        ChatsManager.shared.getMessageDocumentFromDB(messageDoc2) { [weak self] message in
            if let message = message {
                DispatchQueue.main.async {
                    self?.setProfileName?(message.messageBody)
                }
            }
        }
    }
    
    func createDocID() {
        let uid = UUID()
        let chat = Chat(id: uid.uuidString, members: ["eh34h34","iu3583j22"], lastMessage: nil, messages: nil)
        
        ChatsManager.shared.createNewChat(chat: chat) { created in
            print("doc was created")
        }
    }
}
