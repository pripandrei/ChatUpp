//
//  ConversationsViewModel.swift
//  ChatUpp
//
//  Created by Andrei Pripa on 9/26/23.
//

import Foundation


final class ChatsViewModel {
    
    var isUserSignedOut: ObservableObject<Bool> = ObservableObject(false)
    var chats = [Chat]()
    var dbUsers = [DBUser]()
    var recentMessages = [Message]()

    init() {
        Task {
            do {
                try await reloadChatsCellData()
            } catch {
                print(error.localizedDescription)
            }
        }
    }

    var onCellUpdate: (() -> Void)?
    
    func validateUserAuthentication() {
        let authUser = try? AuthenticationManager.shared.getAuthenticatedUser()
        isUserSignedOut.value = authUser == nil
    }
    
    func getChats() async throws -> [Chat] {
        let authUser = try AuthenticationManager.shared.getAuthenticatedUser()
        self.chats = try await ChatsManager.shared.getUserChatsFromDB(authUser.uid)
        return try await ChatsManager.shared.getUserChatsFromDB(authUser.uid)
    }
    
    func getRecentMessages() async throws -> [Message] {
        var recentMessages = [Message]()
        let chats = try await getChats()
        let messages = try await ChatsManager.shared.getRecentMessageFromChats(chats)
        for message in messages {
            recentMessages.append(message)
        }
        return recentMessages
    }
    
//    func getOtherMembersID() async throws -> [String] {
//        let authUser = try AuthenticationManager.shared.getAuthenticatedUser()
//        let chats = try await getChats()
//        return try await ChatsManager.shared.getOtherMembersFromChatss(chats, authUser.uid)
//    }
//
    func getOtherMembersOfChats() async throws -> [DBUser] {
        let authUser = try AuthenticationManager.shared.getAuthenticatedUser()
        let chats = try await getChats()
        let memberIDs = try await ChatsManager.shared.getOtherMembersFromChatss(chats, authUser.uid)
        var dbUsers = [DBUser]()
        for id in memberIDs {
            let dbUser = try await UserManager.shared.getUserFromDB(userID: id)
            dbUsers.append(dbUser)
        }
        return dbUsers
    }
    
    func reloadChatsCellData() async throws {
        self.dbUsers = try await getOtherMembersOfChats()
        self.recentMessages = try await getRecentMessages()
        onCellUpdate?()
    }
    
//    func createCellModel() async throws {
//        let messages = await getRecentMessages()
//        let otherMembers = try await getOtherMembersID()
//        let cellModel = [CellModel]()
//        for (message,member) in zip(messages, otherMembers) {
//            let dbUser = try await UserManager.shared.getUserFromDB(userID: member)
//            let cell = CellModel(name: dbUser.name!, message: message.messageBody, timestamp: message.timestamp, image_url: dbUser.photoUrl!)
//        }
//    }
}



struct CellModel {
    let name: String
    let message: String
    let timestamp: String
    let image_url: String
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
