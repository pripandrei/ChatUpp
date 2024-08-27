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
    
    @Published var initialChatsDoneFetching: Bool = false
    @Published var shouldReloadCell: Bool = false
    
    init() {
        tryCreateCellVM()
//        print(FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!.path(percentEncoded: true))
    }
    
    private func tryCreateCellVM() {
        if let chats = RealmDBManager.shared.retrieveObjectsFromRealmDB(ofType: Chat.self) {
            self.chats = chats
            cellViewModels = createCellViewModel(with: chats)
            initialChatsDoneFetching = true
        }
    }
    
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
            addChatsToRealmDB(self.chats)
            initialChatsDoneFetching = true
        }
    }
    
    func activateOnDisconnect() {
        Task {
            try await UserManagerRealtimeDB.shared.setupOnDisconnect()
        }
    }
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
    
    private func addChatsToRealmDB(_ chats: [Chat]) {
        Task { @MainActor in
            for chat in chats {
                RealmDBManager.shared.createRealmDBObject(object: chat)
            }
        }
    }
    
    private func addChatsListener()
    {
        self.chatsListener = ChatsManager.shared.addListenerForChats(containingUserID: authUser.uid, complition: { [weak self] chats, docTypes in
            guard let self = self else {return}
            
//            self.addChatsToRealmDB(chats)
            if self.chats.isEmpty {
                handleInitialChatsFetch(chats)
                return
            }
            docTypes.enumerated().forEach { index, type in
                switch type {
                case .added: print("RealmDBManager.shared.createRealmDBObject(object: chats[index])")
                case .removed: self.handleRemovedChat(chats[index])
                case .modified: self.handleModifiedChat(chats[index])
                }
            }
//            self.addChatsToRealmDB(chats)
        })
    }
}

//MARK: - User updates

extension ChatsViewModel {
    private func handleModifiedUser(_ user: DBUser) {
        guard let oldCellVM = cellViewModels.first(where: {$0.member?.userId == user.userId} ) else {return}
        
        oldCellVM.updateUserMember(user)
    }
    
    private func handleDeletedUserUpdate(from chatCellVM: ChatCellViewModel, using chat: Chat) {
        let deletedUserID = UserManager.mainDeletedUserID
        if chat.members.contains(where: {$0 == deletedUserID}) {
            Task {
                await chatCellVM.updateUserAfterDeletion(deletedUserID)
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
            shouldReloadCell = true
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
        if chatCellVM.recentMessage?.id != chat.recentMessageID {
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
