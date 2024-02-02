//
//  ConversationsViewModel.swift
//  ChatUpp
//
//  Created by Andrei Pripa on 9/26/23.
//

import Foundation


final class ChatsViewModel {

    private(set) var chats: [Chat] = []
    private(set) var otherMembers: [DBUser] = []
    private(set) var recentMessages: [Message?] = []
    private(set) var cellViewModels = [ChatCellViewModel]()
    
    var onDataFetched: (() -> Void)?
    
    private let authUser = try! AuthenticationManager.shared.getAuthenticatedUser()

    private func createCellViewModel() -> [ChatCellViewModel] {
        return chats.enumerated().map { index, element in
            let member = otherMembers[index]
            let message = recentMessages[index]
            return ChatCellViewModel(user: member, chatID: element.id, recentMessage: message)
        }
        //        return zip(otherMembers, recentMessages).map { ChatCellViewModel(user: $0, recentMessage: $1) }
    }
    
    func setupChatListener() {
        addChatsListener {
//            Task {
//                await self.fetchChatData()
//////                for cell in self.cellViewModels {
//////                    cell.listener?.remove()
//////                }
//                self.cellViewModels = self.createCellViewModel()
//                self.onDataFetched?()
//            }
        }
    }
    
    private func fetchChatData() async {
        do {
            self.recentMessages = try await loadRecentMessages(chats)
            self.otherMembers = try await loadOtherMembersOfChats(chats)
        } catch {
            print("Could not fetch ChatsViewModel Data: ", error.localizedDescription)
        }
    }
    
    private func addChatsListener(complition: @escaping () -> Void)  {
        
        ChatsManager.shared.addListenerForChats(containingUserID: authUser.uid, complition: { [weak self] chats, docTypes in
            guard let self = self else {return}
//            print("Times listener called")
            if self.chats.isEmpty {
                self.chats = chats
                Task {
                    await self.fetchChatData()

                    self.cellViewModels = self.createCellViewModel()
                    self.onDataFetched?()
                }
                return
            }
            docTypes.enumerated().forEach { index, type in
                switch type {
                case .added: self.handleAddedChat(chats[index])
                case .removed: self.handleRemovedChat(chats[index])
                case .modified: self.handleModifiedChat(chats[index])
                }
            }
//            self.chats = chats
//            complition()
        })
    }
    
    private func handleAddedChat(_ chat: Chat) {
        self.chats.insert(chat, at: 0)
        Task {
            guard let recentMessage = try await self.loadRecentMessages([chat]).first else {return}
            guard let otherMembers = try await self.loadOtherMembersOfChats([chat]).first else {return}
            self.recentMessages.insert(recentMessage, at: 0)
            self.otherMembers.insert(otherMembers, at: 0)
            let cellVM = ChatCellViewModel(user: otherMembers, chatID: chat.id, recentMessage: recentMessage)
            self.cellViewModels.insert(cellVM, at: 0)
            
            self.reloadCell?()
        }
        print("added!!")
    }

    var reloadCell: (() -> Void)?
    
    private func handleModifiedChat(_ chat: Chat) {
        guard let oldChat = self.chats.first(where: {$0.id == chat.id}) else {return}
        
        if oldChat.recentMessageID != chat.recentMessageID {
            Task {
                guard let message = try await loadRecentMessages([chat]).first else {return}
                cellViewModels.forEach { cell in
                    if cell.chatId == oldChat.id {
                        cell.updateRecentMessage(message)
                    }
                }
            }
            return
        }
        
        let deletedUserID = UserManager.mainDeletedUserID
        if chat.members.contains(where: {$0 == deletedUserID}) {
            
        }
    }
    
    private func handleRemovedChat(_ chat: Chat) {
        self.chats.removeAll(where: {$0.id == chat.id})
    }
    
    private func loadRecentMessages(_ chats: [Chat]) async throws -> [Message?]  {
        try await ChatsManager.shared.getRecentMessageFromChats(chats)
    }
    
    private func loadOtherMembersOfChats(_ chats: [Chat]) async throws -> [DBUser] {
        let memberIDs = getOtherMembersFromChats(chats)
        var otherMembers = [DBUser]()

        for id in memberIDs {
            let dbUser = try await UserManager.shared.getUserFromDB(userID: id)
            otherMembers.append(dbUser)
        }
        return otherMembers
    }
    
    private func getOtherMembersFromChats(_ chats: [Chat]) -> [String] {
        return chats.compactMap { chat in
            return chat.members.first(where: { $0 != authUser.uid} )
        }
    }
}



//
//  ConversationsViewModel.swift
//  ChatUpp
//
//  Created by Andrei Pripa on 9/26/23.
//
//
//import Foundation
//
//
//final class ChatsViewModel {
//
//    private(set) var chats: [Chat] = []
//    private(set) var otherMembers: [DBUser]!
//    private(set) var recentMessages: [Message]!
//    private(set) var cellViewModels = [ChatCellViewModel]()
//    
//    var onDataFetched: (() -> Void)?
//    
//    private let authUser = try! AuthenticationManager.shared.getAuthenticatedUser()
//
//    private func createCellViewModel() -> [ChatCellViewModel] {
//        return zip(otherMembers, recentMessages).map { ChatCellViewModel(user: $0, recentMessage: $1) }
//    }
//    
//    func setupChatListener() {
//        Task {
//            await self.fetchChatData()
//            self.cellViewModels = self.createCellViewModel()
//            addChatsListener {
//                self.onDataFetched?()
//            }
//        }
////        addChatsListener {
////            Task {
////                self.onDataFetched?()
////            }
////        }
//    }
//    
//    private func fetchChatData() async {
//        do {
//            self.chats = try await loadChats()
//            self.recentMessages = try await loadRecentMessages()
//            self.otherMembers = try await loadOtherMembersOfChats()
//        } catch {
//            print("Could not fetch ChatsViewModel Data: ", error.localizedDescription)
//        }
//    }
//    
//    func loadChats() async throws -> [Chat] {
//        try await ChatsManager.shared.getUserChatsFromDB(authUser.uid)
//    }
//    
//    private func addChatsListener(complition: @escaping () -> Void)  {
//        ChatsManager.shared.addListenerForChats(containingUserID: authUser.uid, complition: { [weak self] chats in
//            guard let self = self else {return}
//            
//            if self.chats.isEmpty {
//                self.chats = chats
//            } else if self.chats.contains(where: {$0.id == chats.first!.id}) {
//                self.chats.removeAll(where: {$0.id == chats.first!.id})
//                self.cellViewModels.removeAll(where: { cell in
//                    chats.first!.members.contains(where: {$0 == cell.userID})
//                })
//            } else {
//                self.chats.insert(chats.first!, at: 0)
//            }
////            self?.chats = chats
//            complition()
//        })
//    }
//    
//    private func loadRecentMessages() async throws -> [Message]  {
//        try await ChatsManager.shared.getRecentMessageFromChats(chats)
//    }
//    
//    private func loadOtherMembersOfChats() async throws -> [DBUser] {
//        let memberIDs = getOtherMembersFromChats()
//        var otherMembers = [DBUser]()
//
//        for id in memberIDs {
//            let dbUser = try await UserManager.shared.getUserFromDB(userID: id)
//            otherMembers.append(dbUser)
//        }
//        return otherMembers
//    }
//    
//    private func getOtherMembersFromChats() -> [String] {
//        return chats.compactMap { chat in
//            chat.members.first(where: { $0 != authUser.uid} )
//        }
//    }
//}
//
//
//
