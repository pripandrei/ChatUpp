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
        let authResult = try! AuthenticationManager.shared.getAuthenticatedUser()
        let dbUser = DBUser(auth: authResult)
        UserManager.shared.getUserFromDB(userID: dbUser.userId) { [weak self] user in
            DispatchQueue.main.async {
                self?.setProfileName?(user.userId)
            }
        }
    }
    
    func createDocID() {
        let uid = UUID()
        let chat = Chat(id: uid.uuidString, members: ["eh34h34","iu3583j22"], lastMessage: nil, messages: nil)
        
        ChatsManager.shared.createNewDocument(chat: chat) { created in
            print("doc was created")
        }
//        print(doc)
    }
}
