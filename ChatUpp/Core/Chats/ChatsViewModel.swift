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
    😇
    init() {
        print(RealmDataBase.realmFilePath ?? "unknown realm file path")
        Task {
            do {
                try await FirebaseChatService.shared.addEmptyReactionsToAllMessagesBatched()
            } catch {
                print("could not add reactions empty field to messages: ", error)
            }
        }
        setupCellViewModels()
        observeChats()
        setChatJoinNotification()
    }
    deinit {
        print("deinit chats view model")
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
        let filter = NSPredicate(format: "ANY \(Chat.CodingKeys.participants.rawValue).userID == %@", authUser.uid)
        return RealmDataBase.shared.retrieveObjects(ofType: Chat.self, filter: filter)?.toArray() ?? []
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
    
    private func updateRealmChat(_ chat: Chat)
    {
        RealmDataBase.shared.update(objectWithKey: chat.id, type: Chat.self) { dbChat in
            dbChat.recentMessageID = chat.recentMessageID
            dbChat.name = chat.name
            dbChat.thumbnailURL = chat.thumbnailURL
            dbChat.admins = chat.admins
            
            chat.participants.forEach { participant in
                if let existingParticipant = dbChat.participants.first(where: { $0.userID == participant.userID})
                {
                    existingParticipant.userID = participant.userID
                    existingParticipant.isDeleted = participant.isDeleted
                    existingParticipant.unseenMessagesCount = participant.unseenMessagesCount
                }
                else {
                    dbChat.participants.append(participant)
                }
            }
        }
    }
}

//MARK: - Listeners

extension ChatsViewModel
{
    private func observeChats()
    {
        FirebaseChatService.shared.chatsPublisher(containingParticipantUserID: authUser.uid)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] update in
                self?.handleChatUpdate(update)
            }.store(in: &cancellables)
    }
}

//MARK: - Notofication on auth user chat join
extension ChatsViewModel
{
    private func setChatJoinNotification()
    {
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(notifyOnJoinNewChat(_:)),
                                               name: .didJoinNewChat,
                                               object: nil)
    }
//
    @objc private func notifyOnJoinNewChat(_ notification: Notification)
    {
        guard let chatID = notification.userInfo?["chatID"] as? String else { return }
        
        if let chat = RealmDataBase.shared.retrieveSingleObject(ofType: Chat.self, primaryKey: chatID)
        {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.7, execute: {
                self.addChatToRealm(chat)
                self.addCellViewModel(using: chat)
                self.chatModificationType = .added
            })
        }
    }
    
}

//MARK: - Chat updates

extension ChatsViewModel {
    
    private func handleChatUpdate(_ update: DatabaseChangedObject<Chat>)
    {
        switch update.changeType
        {
            case .added: handleAddedChat(update.data)
            case .modified: handleModifiedChat(update.data)
            case .removed: handleRemovedChat(update.data)
        }
    }
    
    @objc private func handleAddedChat(_ chat: Chat)
    {
        guard let _ = retrieveChatFromRealm(chat) else {
            addChatToRealm(chat)
            addCellViewModel(using: chat)
            chatModificationType = .added
            return
        }
        updateRealmChat(chat)
    }
    
    private func handleModifiedChat(_ chat: Chat)
    {
        updateRealmChat(chat)
        
        guard let cellVM = findCellViewModel(containing: chat),
              let viewModelIndex = findIndex(of: cellVM) else { return }
        
        cellViewModels.move(element: cellVM, toIndex: 0)
        chatModificationType = .updated(position: viewModelIndex)
    }
    
    private func handleRemovedChat(_ chat: Chat) 
    {
        guard let chat = retrieveChatFromRealm(chat) else {return}
        
        guard let cellVM = findCellViewModel(containing: chat),
              let viewModelIndex = findIndex(of: cellVM) else { return }
        
        cellViewModels.remove(at: viewModelIndex)
        chatModificationType = .removed(position: viewModelIndex)
        
//        deleteRealmChat(chat)
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


extension Notification.Name {
    static let didJoinNewChat = Notification.Name("didJoinNewChat")
}
