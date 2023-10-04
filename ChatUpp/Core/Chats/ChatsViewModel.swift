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
    
    func getDBUser() async throws -> DBUser {
        let authUser = try AuthenticationManager.shared.getAuthenticatedUser()
        return try await UserManager.shared.getUserFromDB(userID: authUser.uid)
    }
    
    func getChats() async throws -> [Chat] {
        return try await ChatsManager.shared.getUserChatsFromDB(getDBUser().userId)
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
}
