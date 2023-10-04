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
    
//    var authenticatedUser: AuthDataResultModel?  {
//        return try? AuthenticationManager.shared.getAuthenticatedUser()
//    }
    
    func validateUserAuthentication() {
        let authUser = try? AuthenticationManager.shared.getAuthenticatedUser()
        isUserSignedOut.value = authUser == nil
    }
    
    func getChats() async throws -> [Chat] {
        let id = try AuthenticationManager.shared.getAuthenticatedUser().uid
        return try await ChatsManager.shared.getUserChatsFromDB(id)
    }
    
    func getMessages() async {
        do {
            let chats = try await getChats()
            let messages = try await ChatsManager.shared.getRecentMessageFromChats(chats)
            for message in messages {
                print(message.messageBody)
            }
        } catch {
            print(error.localizedDescription)
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
