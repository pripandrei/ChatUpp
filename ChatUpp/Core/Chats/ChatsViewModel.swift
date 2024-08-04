//
//  ConversationsViewModel.swift
//  ChatUpp
//
//  Created by Andrei Pripa on 9/26/23.
//

import Foundation

final class ChatsViewModel {

    private(set) var chats: [Chat] = []
    private(set) var cellViewModels = [ChatCellViewModel]()
    private(set) var usersListener: Listener?
    private(set) var chatsListener: Listener?
    
    private let authUser = try! AuthenticationManager.shared.getAuthenticatedUser()
    
    var onInitialChatsFetched: (() -> Void)?
    var reloadCell: (() -> Void)?
    
    private func createCellViewModel(with chats: [Chat]) -> [ChatCellViewModel] {
        return chats.map { chat in
            return ChatCellViewModel(chat: chat)
        }
    }
    
    // Fetch all data at once
    func fetchCellVMData(_ cellViewModels: [ChatCellViewModel]) async throws 
    {
        return await withThrowingTaskGroup(of: (DBUser?, Data?, Message?, Int?)?.self) { group in
            for cellViewModel in cellViewModels {
                group.addTask {
                    try? await (cellViewModel.loadOtherMemberOfChat(), cellViewModel.fetchImageData(), cellViewModel.loadRecentMessage(), cellViewModel.fetchUnreadMessagesCount())
                }
            }
        }
    }

    func handleInitialChatsFetch(_ chats: [Chat]) 
    {
        self.chats = chats
        self.cellViewModels = createCellViewModel(with: chats)
        Task {
            try await self.fetchCellVMData(self.cellViewModels)
            self.onInitialChatsFetched?()
        }
    }
    
    func activateOnDisconnect() {
        Task {
            try await UserManagerRealtimeDB.shared.setupOnDisconnect()
        }
    }
//    func updateUserOnlineStatus(_ activeStatus: Bool) async throws {
//        try await UserManager.shared.updateUser(with: authUser.uid, usingName: nil, onlineStatus: activeStatus)
//    }
}


//MARK: - Listeners

extension ChatsViewModel {
    
    func setupChatListener() {
        addChatsListener()
    }
    
    func addUsersListiner() 
    {
        let usersID = cellViewModels.compactMap { chatCellVM in
            chatCellVM.member?.userId
        }
        guard !usersID.isEmpty else { return }
        
        self.usersListener = UserManager.shared.addListenerToUsers(usersID) { [weak self] users, documentsTypes in
            documentsTypes.enumerated().forEach { [weak self] index, docChangeType in
                if docChangeType == .modified {
                    self?.handleModifiedUser(users[index])
                }
            }
        }
    }
    
    private func addChatsListener()
    {
        self.chatsListener = ChatsManager.shared.addListenerForChats(containingUserID: authUser.uid, complition: { [weak self] chats, docTypes in
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
}

//MARK: - User updates

extension ChatsViewModel {
    private func handleModifiedUser(_ user: DBUser) {
        guard let oldCellVM = cellViewModels.first(where: {$0.member?.userId == user.userId} ) else {return}
        
        /// if active status changes
        if oldCellVM.member?.isActive != user.isActive {
            oldCellVM.updateUserMember(user)
            oldCellVM.updateUserActiveStatus(isActive: user.isActive)
        }
    }
    
    private func handleDeletedUserUpdate(from chatCellVM: ChatCellViewModel, using chat: Chat) {
        let deletedUserID = UserManager.mainDeletedUserID
        if chat.members.contains(where: {$0 == deletedUserID}) {
            Task {
                await chatCellVM.updateUser(deletedUserID)
            }
        }
    }
}

//MARK: - Chat updates

extension ChatsViewModel {
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
        
        // check if recent message modified
        handleRecentMessageUpdate(from: oldViewModel, using: chat)
        
        // check If other User was deleted
        handleDeletedUserUpdate(from: oldViewModel, using: chat)

        // User swiped to delete the Chat cell
    }
    
    private func handleRecentMessageUpdate(from chatCellVM: ChatCellViewModel, using chat: Chat) {
        if chatCellVM.recentMessage.value?.id != chat.recentMessageID {
            chatCellVM.updateChat(chat)
            Task {
                try await chatCellVM.loadRecentMessage()
                try await chatCellVM.fetchUnreadMessagesCount()
            }
        }
    }
    
    private func handleRemovedChat(_ chat: Chat) {
        self.chats.removeAll(where: {$0.id == chat.id})
    }
}
