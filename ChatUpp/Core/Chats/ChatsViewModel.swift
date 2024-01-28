//
//  ConversationsViewModel.swift
//  ChatUpp
//
//  Created by Andrei Pripa on 9/26/23.
//

import Foundation


final class ChatsViewModel {

    private(set) var chats = [Chat]()
    private(set) var otherMembers = [DBUser]()
    private(set) var recentMessages = [Message]()
    private(set) var cellViewModels = [ChatCellViewModel]()
    
    var onDataFetched: (() -> Void)?

    private func fetchChatData() async  {
        do {
//            try await loadChats()
            try await loadRecentMessages()
            try await loadOtherMembersOfChats()
        } catch {
            print("Could not fetch ChatsViewModel Data: ", error.localizedDescription)
        }
    }
    
    func reloadChatsCellData() {
        loadChats {
            Task {
                await self.fetchChatData()
                self.cellViewModels = self.createCellViewModelFromData()
                self.onDataFetched?()
                print("reload")
            }
        }
    }
    
    private func createCellViewModelFromData() -> [ChatCellViewModel] {
        var cellsViewModel = [ChatCellViewModel]()
        
        for (user,message) in zip(otherMembers, recentMessages) {
            let cellViewModel = ChatCellViewModel(user: user, recentMessage: message)
            cellsViewModel.append(cellViewModel)
        }
        return cellsViewModel
    }

    private func loadChats(complition: @escaping () -> Void)  {
       guard let authUser = try? AuthenticationManager.shared.getAuthenticatedUser() else {return}
        ChatsManager.shared.addListenerForChats(withUserId: authUser.uid, complition: { [weak self] chats in
            self?.chats = chats
            complition()
        })
//        self.chats = try await ChatsManager.shared.getUserChatsFromDB(authUser.uid)
    }
    
    private func loadRecentMessages() async throws  {
//        try await loadChats()
        self.recentMessages = try await ChatsManager.shared.getRecentMessageFromChats(chats)
    }
    
    private func loadOtherMembersOfChats() async throws {
        let authUser = try AuthenticationManager.shared.getAuthenticatedUser()
        let memberIDs = ChatsManager.shared.getOtherMembersFromChats(chats, authUser.uid)

        self.otherMembers = []
        // TODO: Can be improved
        for id in memberIDs {
            let dbUser = try await UserManager.shared.getUserFromDB(userID: id)
            otherMembers.append(dbUser)
        }
    }
}



