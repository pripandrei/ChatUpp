//
//  ChatsViewModel.swift
//  ChatUpp
//
//  Created by Andrei Pripa on 9/26/23.
//

import Foundation
import Combine

final class ChatsViewModel {
    
    private(set) var chats: [Chat] = []
    private(set) var cellViewModels = [ChatCellViewModel]()
    private(set) var usersListener: Listener?
    private(set) var chatsListener: Listener?
    private let authUser = try! AuthenticationManager.shared.getAuthenticatedUser()
    
    @Published var modifiedChatIndex: Int = 0
    @Published var initialChatsDoneFetching: Bool = false
    
    var onNewChatAdded: ((Bool) -> Void)?
    
    init() {
//        print(FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!.path(percentEncoded: true))
        loadDataFromRealm()
        addChatsListener()
    }
    
    private func createCellViewModel(from chat: Chat)
    {
        let cellVM = ChatCellViewModel(chat: chat)
        self.cellViewModels.insert(cellVM, at: 0)
    }
    
    private func removeCellViewModel(containing chat: Chat) {
        cellViewModels.removeAll(where: {$0.member?.userId == chat.id})
    }
    
    private func addChat(_ chat: Chat) {
        self.chats.insert(chat, at: 0)
    }
        
    private func removeChat(_ chat: Chat) {
        self.chats.removeAll(where: {$0.id == chat.id})
    }

    private func loadDataFromRealm() {
        let chats = retrieveChatsFromRealm()
        
        if !chats.isEmpty {
            self.chats = chats
            self.cellViewModels = chats.map { ChatCellViewModel(chat: $0) }
            self.initialChatsDoneFetching = true
        }
    }
    
    func activateOnDisconnect() {
        Task {
            try await UserManagerRealtimeDB.shared.setupOnDisconnect()
        }
    }
}

//MARK: - Realm functions

extension ChatsViewModel {
    private func retrieveChatsFromRealm() -> [Chat] {
        return RealmDBManager.shared.retrieveObjects(ofType: Chat.self)
    }
    
    private func addChatToRealm(_ chat: Chat) {
        RealmDBManager.shared.add(object: chat)
    }
}


//MARK: - Listeners

extension ChatsViewModel {
    
//    private func addChatsToRealmDB(_ chats: [Chat]) {
//        for chat in chats {
//            RealmDBManager.shared.add(object: chat)
//        }
//    }
    
    private func addChatsListener()
    {
        self.chatsListener = ChatsManager.shared.addListenerForChats(containingUserID: authUser.uid, complition: { [weak self] chats, docTypes in
                
            guard let self = self else {return}
        
            docTypes.enumerated().forEach { index, type in
                switch type {
                case .added: self.handleAddedChat(chats[index])
                case .removed: self.removeChat(chats[index])
                case .modified: self.handleModifiedChat(chats[index])
                }
            }
        })
    }
}

//MARK: - User updates

extension ChatsViewModel {
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
    
    private func retrieveChatFromRealm(_ chat: Chat) -> Chat? {
//        guard let chat = RealmDBManager.shared.retrieveSingleObject(ofType: Chat.self, primaryKey: chat.id) else {return nil}
//        return Chat(value: chat)
        return RealmDBManager.shared.retrieveSingleObject(ofType: Chat.self, primaryKey: chat.id)
    }
    
    private func handleAddedChat(_ chat: Chat) {
//        Task { @MainActor in
//            addChatToRealm(chat)
//            addChat2(chat)            
//        }

//        Task { @MainActor in
//            addChatToRealm(chat)
            addChat(chat)
            createCellViewModel(from: chat)
            onNewChatAdded?(true)            
//        }
    }

    private func handleModifiedChat(_ chat: Chat) {
        guard let oldViewModel = findCellViewModel(containing: chat),
              let viewModelIndex = findIndex(of: oldViewModel) else {return}
        
        modifiedChatIndex = viewModelIndex
        
        cellViewModels.move(element: oldViewModel, toIndex: 0)
        
        // check if recent message modified
        handleRecentMessageUpdate(from: oldViewModel, using: chat)
        
        // check If other User was deleted
        handleDeletedUserUpdate(from: oldViewModel, using: chat)

        // User swiped to delete the Chat cell
    }
    
    private func handleRecentMessageUpdate(from chatCellVM: ChatCellViewModel, using chat: Chat) {
        if chatCellVM.member?.userId != chat.recentMessageID {
            chatCellVM.updateChat(chat)
            Task {
//                chatCellVM.freezedMessage = try await chatCellVM.loadRecentMessage()
//                chatCellVM.unreadMessageCount = try await chatCellVM.fetchUnreadMessagesCount()
            }
        }
    }
    
    private func findCellViewModel(containing chat: Chat) -> ChatCellViewModel? {
        return cellViewModels.first(where: {$0.member?.userId == chat.id})
    }
    
    private func findIndex(of element: ChatCellViewModel) -> Int? {
        return cellViewModels.firstIndex(of: element)
    }
}

extension Array where Element: Equatable 
{
    mutating func move(element: Element, toIndex destinationIndex: Int) {
        guard let elementIndex = self.firstIndex(of: element) else {return}
        let removedElement = self.remove(at: elementIndex)
        insert(removedElement, at: destinationIndex)
    }
}


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
