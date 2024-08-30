//
//  ConversationsViewModel.swift
//  ChatUpp
//
//  Created by Andrei Pripa on 9/26/23.
//

import Foundation
import Combine

final class ChatsViewModel {
    
    private(set) var chats: [Chat] = [] {
        didSet {
//            chatsWereUpdated(oldValue)
        }
    }
    var reloadCell: ((Bool) -> Void)?
    
//    private func chatsWereUpdated(_ chats: [Chat]) {
//        self.chats.difference(from: chats).forEach { change in
//            switch change {
//            case .insert(_, let chat, _): createCellViewModel(from: chat)
//            case .remove(_, let chat, _): removeCellViewModel(containing: chat)
//            }
//            //                shouldReloadCell = true
//        }
//        
//        self.initialChatsDoneFetching = true
//    }
    
    private func removeCellViewModel(containing chat: Chat) {
        cellViewModels.removeAll(where: {$0.chat.id == chat.id})
    }
    
    private func createCellViewModel(from chat: Chat)
    {
        let cellVM = ChatCellViewModel(chat: chat)
        self.cellViewModels.insert(cellVM, at: 0)
    }
    
    private func addChat(_ chat: Chat) {
        self.chats.insert(chat, at: 0)
    }
        
    private func removeChat(_ chat: Chat) {
        self.chats.removeAll(where: {$0.id == chat.id})
    }
    
    private(set) var cellViewModels = [ChatCellViewModel]()
    private(set) var usersListener: Listener?
    private(set) var chatsListener: Listener?
    
    private let authUser = try! AuthenticationManager.shared.getAuthenticatedUser()
    
    @Published var initialChatsDoneFetching: Bool = false
    @Published var shouldReloadCell: Bool = false
    
    init() {
        //        loadDataFromRealm()
        addChatsListener()
        //        print(FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!.path(percentEncoded: true))
    }

    
    private func loadDataFromRealm() {
        let chats = retrieveChatsFromRealm()
        
        if !chats.isEmpty {
            self.chats = chats
            self.cellViewModels = createCellViewModels(with: chats)
            self.initialChatsDoneFetching = true
        }
    }
    
    private func retrieveChatsFromRealm() -> [Chat] {
        return RealmDBManager.shared.retrieveObjects(ofType: Chat.self)
    }
    
    private func createCellViewModels(with chats: [Chat]) -> [ChatCellViewModel] {
        return chats.map { chat in
            return ChatCellViewModel(chat: chat)
        }
    }
    
    func handleInitialChatsFetch(_ chats: [Chat]) 
    {
        self.chats = chats
//        self.cellViewModels = createCellViewModels(with: chats)
//        addChatsToRealmDB(chats)
        self.initialChatsDoneFetching = true
    }
    
    func activateOnDisconnect() {
        Task {
            try await UserManagerRealtimeDB.shared.setupOnDisconnect()
        }
    }
    
}


//MARK: - Listeners

extension ChatsViewModel {
    
    private func addChatsToRealmDB(_ chats: [Chat]) {
        for chat in chats {
            RealmDBManager.shared.add(object: chat)
        }
    }
    
    private func addChatsListener()
    {
        self.chatsListener = ChatsManager.shared.addListenerForChats(containingUserID: authUser.uid, complition: { [weak self] chats, docTypes in
            guard let self = self else {return}
            
//            self.addChatsToRealmDB(chats)
//            if self.chats.isEmpty {
//                handleInitialChatsFetch(chats)
//                return
//            }
            docTypes.enumerated().forEach { index, type in
                switch type {
                case .added: 
                    self.addChat(chats[index])
                    self.createCellViewModel(from: chats[index])
//                    self.shouldReloadCell.send(true)
//                    self.reloadCell?(true)
//                    print("RealmDBManager.shared.createRealmDBObject(object: chats[index])")
                case .removed: self.removeChat(chats[index])
                case .modified: self.handleModifiedChat(chats[index])
                }
            }
            self.initialChatsDoneFetching = true
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
                chatCellVM.recentMessage = try await chatCellVM.loadRecentMessage()
                chatCellVM.unreadMessageCount = try await chatCellVM.fetchUnreadMessagesCount()
            }
        }
    }
    
    //... new =>>
    
    
}
