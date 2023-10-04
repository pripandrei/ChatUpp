//
//  ConversationsViewModel.swift
//  ChatUpp
//
//  Created by Andrei Pripa on 9/26/23.
//

import Foundation

final class ChatsViewModel {
    
    //    var userProfile: authDataResultModel?
    
    var isUserSignedOut: ObservableObject<Bool> = ObservableObject(false)
    
    var authenticatedUser: AuthDataResultModel?  {
        return try? AuthenticationManager.shared.getAuthenticatedUser()
    }
    
    func validateUserAuthentication() {
//        let authUser = try? AuthenticationManager.shared.getAuthenticatedUser()
        isUserSignedOut.value = authenticatedUser == nil
    }
    
    func getMessages() async {
        guard let id = authenticatedUser?.uid else { return }
        do {
            let chats = try await ChatsManager.shared.getUserChats(id)
            print(chats.count)
            let messages = try await ChatsManager.shared.getRecentMessageFromChats(chats)
            for message in messages {
                print(message.messageBody)
            }
        } catch {
            
        }
    }
    
//    func getMessages() async {
//        guard let user = authenticatedUser else {
//            return
//        }
//        do {
//            let chat = try await ChatsManager.shared.getChatDocumentFromDB(chatID: "KmAGbYwUTrwWAqfbbGo9")
//            let messages = chat.recentMessage
//            print("Recent Messages: \(messages)")
//        } catch let e {
//            print("error getting messages: ", e.localizedDescription)
//        }
//    }
    
}
