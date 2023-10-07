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
    
    func integrateName() async {
//        let authResult = try! AuthenticationManager.shared.getAuthenticatedUser()
//        let dbUser = DBUser(auth: authResult)
//        UserManager.shared.getUserFromDB(userID: dbUser.userId) { [weak self] user in
//            DispatchQueue.main.async {
////                self?.setProfileName?(user.userId)
//            }
//        }
        
        let messageReference = ChatsManager.shared.getMessageReference(messagePath: "BucXHvVBzgPDax5BYOyE", fromChatDocumentPath: "KmAGbYwUTrwWAqfbbGo9")
        let messageData = Message(id: "£424", messageBody: "IEW98980R", senderId: "WER", imageUrl: "WER", timestamp: "WER", messageSeen: false, receivedBy: "wueiyriuwr3")

        do {
            try await ChatsManager.shared.createNewMessage(message: messageData, atChatPath: "KmAGbYwUTrwWAqfbbGo9")
            let message = try await ChatsManager.shared.getMessageDocumentFromDB(messageReference)
            DispatchQueue.main.async {
                self.setProfileName?(message.messageBody)
            }
        } catch let e {
            print(e.localizedDescription)
        }
    }
    
//    func createDocID() async {
//        let uid = UUID()
//        let chat = Chat(id: uid.uuidString, members: ["eh34h34","iu3583j22"], lastMessage: nil)
//        
//        do {
//            try await ChatsManager.shared.createNewChat(chat: chat)
//        } catch let e {
//            print(e)
//        }
//    }
}
