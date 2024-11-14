//
//  ChatsViewModel.swift
//  ChatUpp
//
//  Created by Andrei Pripa on 9/26/23.
//

import Foundation
import Combine
import RealmSwift

final class ChatsViewModel {

    //TODO: - remove listeners
    private var cancellables = Set<AnyCancellable>()
    
    private(set) var cellViewModels = [ChatCellViewModel]()
    private(set) var usersListener: Listener?
    private(set) var chatsListener: Listener?
    private let authUser = try! AuthenticationManager.shared.getAuthenticatedUser()
    
    @Published var modifiedChatIndex: Int = 0
    @Published var initialChatsDoneFetching: Bool = false
    
    var onNewChatAdded: ((Bool) -> Void)?
    
    init() {
        print(RealmDBManager.realmFilePath)
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
    
    private func removeCellViewModel(containing chat: Chat) {
        cellViewModels.removeAll(where: {$0.chatUser?.id == chat.id})
    }
    
    private func findCellViewModel(containing chat: Chat) -> ChatCellViewModel? {
        return cellViewModels.first(where: {$0.chat.id == chat.id})
    }
    
    private func findIndex(of element: ChatCellViewModel) -> Int? {
        return cellViewModels.firstIndex(of: element)
    }
    
    private func getAuthenticatedParticipantID() -> String? {
        let filter = NSPredicate(format: "userID == %@", authUser.uid)
        return RealmDBManager.shared.retrieveObjects(ofType: ChatParticipant.self, filter: filter).first?.id
    }
}

//MARK: - Realm functions

extension ChatsViewModel {
    private func retrieveChatsFromRealm() -> [Chat] {
        //TODO: - adjust by participants retrieve after update
        let filter = NSPredicate(format: "ANY \(Chat.CodingKeys.participants.rawValue).userID == %@", authUser.uid)
        return RealmDBManager.shared.retrieveObjects(ofType: Chat.self, filter: filter)
    }
    
    private func retrieveChatFromRealm(_ chat: Chat) -> Chat? {
        return RealmDBManager.shared.retrieveSingleObject(ofType: Chat.self, primaryKey: chat.id)
    }
    
    private func addChatToRealm(_ chat: Chat) {
        RealmDBManager.shared.add(object: chat)
    }
    
    private func updateRealmChat(_ chat: Chat) 
    {
        RealmDBManager.shared.update(objectWithKey: chat.id, type: Chat.self) { DBChat in
            
            DBChat.recentMessageID = chat.recentMessageID
            
            chat.participants.forEach { participant in
                if let existingParticipant = RealmDBManager.shared.retrieveSingleObject(ofType: ChatParticipant.self, primaryKey: participant.id)
                {
                    existingParticipant.userID = participant.userID
                    existingParticipant.unseenMessagesCount = participant.unseenMessagesCount
                }
//                else {
//                    DBChat.participants.append(participant)
//                }
            }
        }
    }
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
            case .modified: handleModifiedChat(update.data)
            case .removed: print("Handle Removed chat")
        }
    }
    
    private func handleAddedChat(_ chat: Chat)
    {
        guard let _ = retrieveChatFromRealm(chat) else {
            addChatToRealm(chat)
            addCellViewModel(using: chat)
            onNewChatAdded?(true)
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
        modifiedChatIndex = viewModelIndex
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
