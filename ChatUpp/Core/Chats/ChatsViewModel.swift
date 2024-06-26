//
//  ConversationsViewModel.swift
//  ChatUpp
//
//  Created by Andrei Pripa on 9/26/23.
//

import Foundation


final class ChatsViewModel {

    private(set) var chats: [Chat] = []
//    private(set) var otherMembers: [DBUser] = []
//    private(set) var recentMessages: [Message?] = []
    private(set) var cellViewModels = [ChatCellViewModel]()
    
    var onInitialChatsFetched: (() -> Void)?
    var reloadCell: (() -> Void)?
    
    private let authUser = try! AuthenticationManager.shared.getAuthenticatedUser()
    
    private func createCellViewModel(with chats: [Chat]) -> [ChatCellViewModel] {
        return chats.map { chat in
            return ChatCellViewModel(chat: chat)
        }
    }
    
    func setupChatListener() {
        addChatsListener()
    }
    
    // Fetch all data at once
    func fetchCellVMData(_ cellViewModels: [ChatCellViewModel]) async throws {
        return await withThrowingTaskGroup(of: (DBUser?, Data?, Message?, Int?)?.self) { group in
            for cellViewModel in cellViewModels {
                group.addTask {
                    try? await (cellViewModel.loadOtherMemberOfChat(), cellViewModel.fetchImageData(), cellViewModel.loadRecentMessage(), cellViewModel.fetchUnreadMessagesCount())
                }
            }
        }
    }
    
    private func addChatsListener()  {
        ChatsManager.shared.addListenerForChats(containingUserID: authUser.uid, complition: { [weak self] chats, docTypes in
            guard let self = self else {return}

            if self.chats.isEmpty {
                handleInitialChatsFetch(chats)
                return
            }
            docTypes.enumerated().forEach { index, type in
                switch type {
                case .added: self.handleAddedChat(chats[index])
                case .removed: self.handleRemovedChat(chats[index])
                case .modified: self.handleModifiedChat(chats[index])
                }
            }
        })
    }
    
    func handleInitialChatsFetch(_ chats: [Chat]) {
        self.chats = chats
        self.cellViewModels = createCellViewModel(with: chats)
        Task {
            try await self.fetchCellVMData(self.cellViewModels)
            self.onInitialChatsFetched?()
        }
    }
    
    private func handleAddedChat(_ chat: Chat)
    {
        self.chats.insert(chat, at: 0)
        let cellVM = ChatCellViewModel(chat: chat)
        self.cellViewModels.insert(cellVM, at: 0)
        
        Task {
            try await cellVM.loadOtherMemberOfChat()
            try await cellVM.loadRecentMessage()
            try await cellVM.fetchImageData()
            try await cellVM.fetchUnreadMessagesCount()
            reloadCell?()
        }
    }
    
    private func handleModifiedChat(_ chat: Chat) {
        guard let oldViewModel = self.cellViewModels.first(where: {$0.chat.id == chat.id}) else {return}
        
        // If recent message modified
        if oldViewModel.recentMessage.value?.id != chat.recentMessageID {
            oldViewModel.updateChat(chat)
            Task {
                try await oldViewModel.loadRecentMessage()
                try await oldViewModel.fetchUnreadMessagesCount()
            }
        }
        // If other User was deleted
        let deletedUserID = UserManager.mainDeletedUserID
        if chat.members.contains(where: {$0 == deletedUserID}) {
            Task {
                await oldViewModel.updateUser(deletedUserID)
            }
        }
        // User swiped to delete the Chat cell
        
    }
    
    private func handleRemovedChat(_ chat: Chat) {
        self.chats.removeAll(where: {$0.id == chat.id})
    }
    
//    private func loadRecentMessages(_ chats: [Chat]) async throws -> [Message?]  {
//        try await ChatsManager.shared.getRecentMessageFromChats(chats)
//    }
}
