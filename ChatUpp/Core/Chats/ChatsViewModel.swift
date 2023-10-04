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
    
    func DBUser() async throws -> DBUser {
        let authenticatedUser = AuthenticationManager.shared.getAuthenticatedUser()
        guard let authUser = authenticatedUser else { throw URLError(.cannotOpenFile) }
        
        return try await UserManager.shared.getUserFromDB(userID: authUser.uid)
    }
    
    func validateUserAuthentication() {
        let authUser = AuthenticationManager.shared.getAuthenticatedUser()
        isUserSignedOut.value = authUser == nil
    }
    
    func getChats() async throws -> [Chat] {
//        if let authUser = AuthenticationManager.shared.getAuthenticatedUser() {
//            let user = try await DBUser().userId
            return try await ChatsManager.shared.getUserChatsFromDB(DBUser().userId)
//        }
//        throw URLError(.badServerResponse)
//        let id = AuthenticationManager.shared.getAuthenticatedUser().uid
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
