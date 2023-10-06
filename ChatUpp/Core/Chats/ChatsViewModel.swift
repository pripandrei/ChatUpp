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
    var cellViewModels = [ChatCellViewModel]()
    
    var onDataFetched: (() -> Void)?

    init() {
//        fetchChatData()
        validateUserAuthentication()
    }
    
    private func fetchChatData() async  {
            do {
                try await loadChats()
                try await loadRecentMessages()
                try await loadOtherMembersOfChats()
            } catch {
                print(error.localizedDescription)
            }
    }
    
    func reloadChatsCellData() {
        Task {
            await fetchChatData()
            cellViewModels = createCellViewModelFromData()
            onDataFetched?()
        }
    }
    
    private func createCellViewModelFromData() -> [ChatCellViewModel] {
        var cellsViewModel = [ChatCellViewModel]()
        
        for (user,message) in zip(dbUsers, recentMessages) {
            let cellViewModel = ChatCellViewModel(user: user, recentMessages: message)
            cellsViewModel.append(cellViewModel)
        }
        return cellsViewModel
    }
    
    func validateUserAuthentication() {
        let authUser = try? AuthenticationManager.shared.getAuthenticatedUser()
        isUserSignedOut.value = authUser == nil
    }
    
    private func loadChats() async throws {
        let authUser = try AuthenticationManager.shared.getAuthenticatedUser()
        self.chats = try await ChatsManager.shared.getUserChatsFromDB(authUser.uid)
    }
    
    private func loadRecentMessages() async throws  {
        try await loadChats()
        self.recentMessages = try await ChatsManager.shared.getRecentMessageFromChats(chats)
    }
    
    private func loadOtherMembersOfChats() async throws {
        let authUser = try AuthenticationManager.shared.getAuthenticatedUser()
        let memberIDs = try await ChatsManager.shared.getOtherMembersFromChatss(chats, authUser.uid)

        for id in memberIDs {
            let dbUser = try await UserManager.shared.getUserFromDB(userID: id)
            dbUsers.append(dbUser)
        }
    }
}



