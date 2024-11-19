//
//  ChatsViewModel.swift
//  ChatUpp
//
//  Created by Andrei Pripa on 9/26/23.
//

import Foundation
import Combine
import RealmSwift


enum ChatDeletionOption
{
    case forMe
    case forBoth
}

enum ChatModificationType 
{
    case added
    case updated(position: Int)
    case removed(position: Int)
}

final class ChatsViewModel {
    
    @Published private(set) var chatModificationType: ChatModificationType?

    //TODO: - remove listeners
    private var cancellables = Set<AnyCancellable>()
    
    private(set) var cellViewModels = [ChatCellViewModel]()
    private(set) var usersListener: Listener?
    private(set) var chatsListener: Listener?
    private let authUser = try! AuthenticationManager.shared.getAuthenticatedUser()
    
    @Published var initialChatsDoneFetching: Bool = false
    //    @Published var modifiedChatIndex: Int = 0
    
//    var onNewChatAdded: ((Bool) -> Void)?
    
    init() {
        print(RealmDataBase.realmFilePath)
        setupCellViewModels()
        observeChats()
    }

    func activateOnDisconnect() {
        Task {
            try await RealtimeUserService.shared.setupOnDisconnect()
        }
    }
}


//MARK: - CellViewModel functions

extension ChatsViewModel {
    
    /// initial setup on initialization
    private func setupCellViewModels() {
        let chats = retrieveChatsFromRealm()
        
        guard !chats.isEmpty else { return }
        self.cellViewModels = chats.map { ChatCellViewModel(chat: $0) }
    }
    
    private func addCellViewModel(using chat: Chat)
    {
        let cellVM = ChatCellViewModel(chat: chat)
        self.cellViewModels.insert(cellVM, at: 0)
    }
    
    private func removeCellViewModel(containing chatID: String) {
        cellViewModels.removeAll(where: {$0.chat.id == chatID})
    }
    
    private func removeCellViewModel(at position: Int) {
        cellViewModels.remove(at: position)
    }
    
    private func findCellViewModel(containing chat: Chat) -> ChatCellViewModel? {
        return cellViewModels.first(where: {$0.chat.id == chat.id})
    }
    
    private func findIndex(of element: ChatCellViewModel) -> Int? {
        return cellViewModels.firstIndex(of: element)
    }
}

//MARK: - Realm functions

extension ChatsViewModel 
{
    private func retrieveChatsFromRealm() -> [Chat] {
        //TODO: - adjust by participants retrieve after update
        let filter = NSPredicate(format: "ANY \(Chat.CodingKeys.participants.rawValue).userID == %@", authUser.uid)
        return RealmDataBase.shared.retrieveObjects(ofType: Chat.self, filter: filter)
    }
    
    private func retrieveChatFromRealm(_ chat: Chat) -> Chat? {
        return RealmDataBase.shared.retrieveSingleObject(ofType: Chat.self, primaryKey: chat.id)
    }
    
    private func addChatToRealm(_ chat: Chat) {
        RealmDataBase.shared.add(object: chat)
    }
    
    private func deleteRealmChat(_ chat: Chat) {
        RealmDataBase.shared.delete(object: chat)
    }
    
    private func updateRealmChat(_ chat: Chat) {
        
//        // preserve messages before update, because updated chat from firestore doesn't have messages
//        guard let messages = RealmDataBase.shared.retrieveSingleObject(ofType: Chat.self, primaryKey: chat.id)?.conversationMessages else {return}
//        
//        RealmDataBase.shared.add(object: chat)
//        
//        RealmDataBase.shared.update(objectWithKey: chat.id, type: Chat.self) { dbChat in
//            dbChat.conversationMessages = messages
//            
//            dbChat.participants.removeAll()
//            dbChat.participants.append(objectsIn: chat.participants)
//        }
        
        RealmDataBase.shared.update(objectWithKey: chat.id, type: Chat.self) { dbChat in
            dbChat.recentMessageID = chat.recentMessageID
            
            dbChat.participants.removeAll()
            dbChat.participants.append(objectsIn: chat.participants)
        }
    }
//    
//    private func updateRealmChat(_ chat: Chat) {
//        RealmDataBase.shared.update(objectWithKey: chat.id, type: Chat.self) { DBChat in
//            
//            DBChat.recentMessageID = chat.recentMessageID
//            
//            // Update existing participants or add new ones
//            chat.participants.forEach { participant in
//                if let existingParticipant = DBChat.participants.first(where: { $0.userID == participant.userID }) {
//                    existingParticipant.userID = participant.userID
//                    existingParticipant.isDeleted = participant.isDeleted
//                    existingParticipant.unseenMessagesCount = participant.unseenMessagesCount
//                } else {
//                    DBChat.participants.append(participant)
//                }
//            }
//            
//            // Remove participants not in the updated chat
//            let updatedParticipantIDs = Set(chat.participants.map { $0.userID })
//            let pariticipantsToRemove = DBChat.participants.filter { !updatedParticipantIDs.contains($0.userID) }
//            
//            pariticipantsToRemove.forEach { participant in
//                if let index = DBChat.participants.firstIndex(of: participant) {
//                    DBChat.participants.remove(at: index)
//                }
//            }
//        }
//    }

}

//MARK: - Listeners

extension ChatsViewModel {
    
    private func observeChats()
    {
        FirebaseChatService.shared.chatsPublisher(containingParticipantUserID: authUser.uid)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] update in
                self?.handleChatUpdate(update)
            }.store(in: &cancellables)
    }
}

//MARK: - Chat updates

extension ChatsViewModel {
    
    private func handleChatUpdate(_ update: ChatUpdate<Chat>)
    {
        switch update.changeType
        {
            case .added: handleAddedChat(update.data)
            print("Handle Added chat")
            case .modified: handleModifiedChat(update.data)
            print("Handle Updated chat")
            case .removed: print("Handle Removed chat")
                           handleRemovedChat(update.data)
        }
    }
    
    private func handleAddedChat(_ chat: Chat)
    {
        guard let _ = retrieveChatFromRealm(chat) else {
            addChatToRealm(chat)
            addCellViewModel(using: chat)
//            onNewChatAdded?(true)
            chatModificationType = .added
            return
        }
        updateRealmChat(chat)
    }
    
    private func handleModifiedChat(_ chat: Chat) {
        updateRealmChat(chat)
        
        guard let cellVM = findCellViewModel(containing: chat),
              let viewModelIndex = findIndex(of: cellVM) else { return }
        
        cellVM.updateChatParameters()
        
        cellViewModels.move(element: cellVM, toIndex: 0)
        chatModificationType = .updated(position: viewModelIndex)
//        modifiedChatIndex = viewModelIndex
    }
    
    private func handleRemovedChat(_ chat: Chat) 
    {
        guard let chat = retrieveChatFromRealm(chat) else {return}
        
        guard let cellVM = findCellViewModel(containing: chat),
              let viewModelIndex = findIndex(of: cellVM) else { return }
        
        cellViewModels.remove(at: viewModelIndex)
        chatModificationType = .removed(position: viewModelIndex)
        
        deleteRealmChat(chat)
    }
}

//MARK: - Chats deletion

extension ChatsViewModel
{
    func initiateChatDeletion(for deletionOption: ChatDeletionOption, at indexPath: IndexPath)
    {
        let chat = cellViewModels[indexPath.row].chat
        
        switch deletionOption {
        case .forMe: deleteChatForCurrentUser(chat)
        case .forBoth: deleteChatForBothUsers(chat)
        }
//        RealmDataBase.shared.retrieveSingleObject(ofType: Chat.self, primaryKey: chat.id)
        deleteRealmChat(chat)
        removeCellViewModel(at: indexPath.row)
    }
    
    private func deleteChatForCurrentUser(_ chat: Chat) {
        
        let chatID = chat.id
        
        Task {
            do {
                try await FirebaseChatService.shared.removeParticipant(participantID: authUser.uid, inChatWithID: chatID)
            } catch {
                print("Error removing participant: ", error.localizedDescription)
            }
        }
    }
    
    private func deleteChatForBothUsers(_ chat: Chat) {
        
        let chatID = chat.id

        Task {
            do {
                try await FirebaseChatService.shared.removeChat(chatID: chatID)
            } catch {
                print("Error removing chat: ", error.localizedDescription)
            }
        }
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


//MARK: - User updates
//
//extension ChatsViewModel {
//    private func c(from chatCellVM: ChatCellViewModel, using chat: Chat) {
//        let deletedUserID = UserManager.mainDeletedUserID
//        if chat.members.contains(where: {$0 == deletedUserID}) {
//            Task {
//                await chatCellVM.updateUserAfterDeletion(deletedUserID)
//            }
//        }
//    }
//}

//
//extension ChatsViewModel {
//    
//    private func addChatsParticipantsListener()
//    {
//        self.chatsListener = ChatsManager.shared.addListenerForChatsParticipants(withUserID: authUser.uid, complition: { [weak self] participants, docTypes in
//            
//            guard let self = self else {return}
// 
//            docTypes.enumerated().forEach { index, type in
//                switch type {
//                case .added:  self.participants.append(participants[index])
//                case .removed: self.handleRemovedParticipant(participants[index])
//                case .modified: self.handleModifiedParticipant(participants[index])
//                }
//            }
//        })
//    }
//    
//    private func addListenerForChats(containingParticipantsID participantsID: [String]) {
//        
//        self.chatsListener = ChatsManager.shared.addListenerForChats(containingParticipantID: participantsID, complition: { [weak self] chats, docTypes in
//            
//            guard let self = self else {return}
//            
//            docTypes.enumerated().forEach { index, type in
//                switch type {
//                case .added: self.handleAddedChat(chats[index])
//                case .removed: print("remove cellVM")
//                    //                    self.removeChat(chats[index])
//                case .modified: self.handleModifiedChat(chats[index])
//                }
//            }
//        })
//    }
//}


//MARK: - Participants
extension ChatsViewModel
{
//    private func participantBinding() {
//        self.$participants
//            .scan([] as [ChatParticipant]) { previous, current in
//                let newItems = current.filter { !previous.contains($0) }
//                return newItems
//            }
//            .filter { !$0.isEmpty }
//            .receive(on: DispatchQueue.main)
//            .sink { newParticipants in
//                print("New participants:", newParticipants)
//                let participantsIDs = newParticipants.compactMap({ $0.id })
//                self.addListenerForChats(containingParticipantsID: participantsIDs)
//
//            }
//            .store(in: &subscribers)
//    }
//
//    private func pa2rticipantBinding() {
//        self.$participants
//            .scan(([], [])) { (old, new) -> ([ChatParticipant], [ChatParticipant]) in
//                // Returns tuple of (previous array, current array)
//                return (new, old.1)
//            }
//            .map { prev, current in
//
//                return current.filter { newParticipant in
//                    !prev.contains(where: { $0.id == newParticipant.id })
//                }
//            }
//            .receive(on: DispatchQueue.main)
//            .sink { newParticipants in
//                // Handle only the newly added participants here
//                print("New participants:", newParticipants)
//            }
//            .store(in: &subscribers)
//    }
}
