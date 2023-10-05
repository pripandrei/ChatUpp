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
    
    var dbUser: DBUser?
    
    var chats = [Chat]()
//    var recentMessages = [Message]()
    var recentMessages: ObservableObject<[Message]?> = ObservableObject(nil)
    
    func validateUserAuthentication() {
        let authUser = try? AuthenticationManager.shared.getAuthenticatedUser()
        isUserSignedOut.value = authUser == nil
    }
    
//    func getDBUser() async throws -> DBUser {
//        let authUser = try AuthenticationManager.shared.getAuthenticatedUser()
//        dbUser = try await UserManager.shared.getUserFromDB(userID: authUser.uid)
//        return try await UserManager.shared.getUserFromDB(userID: authUser.uid)
//    }
    
    func getChats() async throws -> [Chat] {
        let authUser = try AuthenticationManager.shared.getAuthenticatedUser()
        self.chats = try await ChatsManager.shared.getUserChatsFromDB(authUser.uid)
        return try await ChatsManager.shared.getUserChatsFromDB(authUser.uid)
    }
    
    func getRecentMessages() async {
        do {
            let chats = try await getChats()
            let messages = try await ChatsManager.shared.getRecentMessageFromChats(chats)
            self.recentMessages.value = messages
            for message in messages {
                print(message.messageBody)
            }
        } catch {
            print(error.localizedDescription)
        }
    }
    
    func getOtherMembers() async throws -> [String] {
        let authUser = try AuthenticationManager.shared.getAuthenticatedUser()
        let chats = try await getChats()
        return try await ChatsManager.shared.getOtherMembersFromChatss(chats, authUser.uid)
    }
}







//var dbUser: DBUser?
//    var chats: [Chat]?
//    var recentMessages: [Message]?
//    var otherMembers: [String]?
//
//    func validateUserAuthentication() {
//        let authUser = try? AuthenticationManager.shared.getAuthenticatedUser()
//        isUserSignedOut.value = authUser == nil
//    }
//
//    func loadDBUser() async throws {
//        let authUser = try AuthenticationManager.shared.getAuthenticatedUser()
//        dbUser = try await UserManager.shared.getUserFromDB(userID: authUser.uid)
//    }
//
//    func loadChats() async throws  {
//        guard let dbUser = dbUser else {throw AuthenticationStatus.userIsNotAuthenticated }
//        chats = try await ChatsManager.shared.getUserChatsFromDB(dbUser.userId)
//    }
//
//    func loadOtherMembers() async throws {
//        guard let dbUser = dbUser else {throw AuthenticationStatus.userIsNotAuthenticated }
//        guard let chats = chats else { throw URLError(.cannotOpenFile) }
//        otherMembers = try await ChatsManager.shared.getOtherMembersFromChatss(chats, dbUser.userId)
//    }
//
//    func loadMessages() async {
//        do {
////            let chats = try await loadChats()
//            guard let chats = chats else { throw URLError(.cannotOpenFile) }
//            let messages = try await ChatsManager.shared.getRecentMessageFromChats(chats)
//            for message in messages {
//                print(message.messageBody)
//            }
//        } catch {
//            print(error.localizedDescription)
//        }
//    }
