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
            Task {
                await self.fetchChatData()
                self.cellViewModels = self.createCellViewModel()
                self.onDataFetched?()
            }
        }
    }
    
    private func fetchChatData() async {
        do {
            self.recentMessages = try await loadRecentMessages()
            self.otherMembers = try await loadOtherMembersOfChats()
        } catch {
            print("Could not fetch ChatsViewModel Data: ", error.localizedDescription)
        }
    }
    
    private func addChatsListener(complition: @escaping () -> Void)  {
        
        ChatsManager.shared.addListenerForChats(containingUserID: authUser.uid, complition: { [weak self] chats in
            guard let self = self else {return}
            print("Times listener called")
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
            self.chats = chats
            complition()
        })
    }
    
    private func loadRecentMessages() async throws -> [Message?]  {
        try await ChatsManager.shared.getRecentMessageFromChats(chats)
    }
    
    private func loadOtherMembersOfChats() async throws -> [DBUser] {
        let memberIDs = getOtherMembersFromChats()
        var otherMembers = [DBUser]()

        for id in memberIDs {
            let dbUser = try await UserManager.shared.getUserFromDB(userID: id)
            otherMembers.append(dbUser)
        }
        return otherMembers
    }
    
    private func getOtherMembersFromChats() -> [String] {
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
