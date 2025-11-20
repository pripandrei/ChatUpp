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
    case leaveGroup
}

enum ChatModificationType 
{
    case added
    case updated(position: Int)
    case removed(position: Int)
}

final class ChatsViewModel
{
    private var userTimestampUpdateTimer: Timer?
    
    @Published private(set) var chatModificationType: ChatModificationType?
    @Published private(set) var chatDeletionIsInitiated: Bool = false

    //TODO: - remove listeners
    private var cancellables = Set<AnyCancellable>()
    
    private(set) var cellViewModels = [ChatCellViewModel]()
    private let authUser = try! AuthenticationManager.shared.getAuthenticatedUser()
    
    @Published var initialChatsDoneFetching: Bool = false
    
    init() {
        print(RealmDataBase.realmFilePath ?? "unknown realm file path")
        setupCellViewModels()
        observeChats()
        updateUserTimestamp() // while firestore functions is deactivated
    }
    
    deinit {
//        print("deinit chats view model")
    }

    func activateOnDisconnect() {
        Task {
            try await RealtimeUserService.shared.setupOnDisconnect()
        }
    }
}


//MARK: - CellViewModel functions

extension ChatsViewModel
{
    /// initial setup on initialization
    private func setupCellViewModels()
    {
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
    
    private func updateUserTimestamp()
    {
        self.userTimestampUpdateTimer?.invalidate()
        
        self.userTimestampUpdateTimer = Timer.scheduledTimer(
            withTimeInterval: 60,
            repeats: true)
        { [weak self] _ in
            guard let self else {return}
            Task {
                do {
                    try await FirestoreUserService.shared.updateUser(
                        with: self.authUser.uid,
                        timestamp: Date()
                    )
                } catch {
                    print("Error while updating user timestamp: \(error)")
                }
            }
        }
    }
    
    func stopUserUpdateTimer()
    {
        userTimestampUpdateTimer?.invalidate()
        userTimestampUpdateTimer = nil
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
            if dbChat.recentMessageID != chat.recentMessageID {
                dbChat.recentMessageID = chat.recentMessageID
            }
            dbChat.name = chat.name
            if dbChat.thumbnailURL != chat.thumbnailURL {
                dbChat.thumbnailURL = chat.thumbnailURL
            }
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
        
        ChatManager.shared.$newCreatedChat
            .receive(on: DispatchQueue.main)
            .sink { [weak self] chat in
                guard let chat = chat else { return }
                executeAfter(seconds: 0.3) {
                    self?.addCellViewModel(using: chat)
                    self?.chatModificationType = .added
                }
            }.store(in: &cancellables)
        
        ChatManager.shared.$joinedGroupChat
            .receive(on: DispatchQueue.main)
            .sink { [weak self] chat in
                guard let chat = chat else { return }
                executeAfter(seconds: 0.7) {
                    self?.addCellViewModel(using: chat)
                    self?.chatModificationType = .added
                }
            }.store(in: &cancellables)
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
            self.chatModificationType = .added
            return
        }
        updateRealmChat(chat)
    }
    
    private func handleModifiedChat(_ chat: Chat)
    {
//        guard let _ = retrieveChatFromRealm(chat) else {return}
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
           
           if let unreadMessagesCount = cellVM.unreadMessageCount,
              unreadMessagesCount > 0
           {
               ChatManager.shared.decrementUnseenMessageCount(by: unreadMessagesCount)
           }
           
           cellVM.invalidateSelf()
           self.cellViewModels.remove(at: viewModelIndex)
           self.chatModificationType = .removed(position: viewModelIndex)
           self.deleteRealmChat(chat)
       }
}

//MARK: - Chats deletion

extension ChatsViewModel
{
    func initiateChatDeletion(for deletionOption: ChatDeletionOption,
                              at indexPath: IndexPath)
    {
        let cellVM = cellViewModels[indexPath.row]
        let chat = cellVM.chat
        
        if let unreadMessagesCount = cellVM.unreadMessageCount,
           unreadMessagesCount > 0
        {
            ChatManager.shared.decrementUnseenMessageCount(by: unreadMessagesCount)
        }
        
        cellVM.removeObservers()
        
        switch deletionOption {
        case .forMe: deleteChatForCurrentUser(chat)
        case .forBoth: deleteChatForBothUsers(chat)
        case .leaveGroup: leaveTheGroup(chat)
        }
        deleteRealmChat(chat)
        removeCellViewModel(at: indexPath.row)
    }
    
    private func deleteChatForCurrentUser(_ chat: Chat) {
        
        let chatID = chat.id
        
        Task {
            do {
                try await FirebaseChatService.shared.removeParticipant(
                    participantID: authUser.uid,
                    inChatWithID: chatID
                )
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
    
    private func leaveTheGroup(_ chat: Chat)
    {
//        let chatID = chat.id
        let chat = chat.freeze()
 
        Task {
            do {
                try await FirebaseChatService.shared.removeParticipant(
                    participantID: authUser.uid,
                    fromChatWithID: chat.id
                )
                let text = GroupEventMessage.userLeft.eventMessage
                let message = try await createMessage(messageText: text, for: chat.id)
                
                try await FirebaseChatService.shared.createMessage(
                    message: message,
                    atChatPath: chat.id
                )
                try await updateUnseenMessageCounterRemote(for: chat)
                try await FirebaseChatService.shared.updateChatRecentMessage(
                    recentMessageID: message.id,
                    chatID: chat.id
                )
            } catch {
                print("Error removing participant: ", error.localizedDescription)
            }
        }
    }
    
    @MainActor
    private func updateUnseenMessageCounterRemote(for chat: Chat) async throws
    {
        let currentUserID = AuthenticationManager.shared.authenticatedUser!.uid
        let otherUserIDs = Array(chat.participants
            .map(\.userID)
            .filter { $0 != currentUserID })

        try await FirebaseChatService.shared.updateUnreadMessageCount(
            for: otherUserIDs,
            inChatWithID: chat.id,
            increment: true
        )
    }
    
    @MainActor
    private func createMessage(messageText text: String,
                               for chatID: String) async throws -> Message
    {
        let authUserID = AuthenticationManager.shared.authenticatedUser!.uid
        let message = Message(
            id: UUID().uuidString,
            messageBody: text,
            senderId: authUserID,
            timestamp: Date(),
            messageSeen: nil,
            seenBy: nil,
            isEdited: false,
            imagePath: nil,
            imageSize: nil,
            repliedTo: nil,
            type: .title
        )
        
        try await FirebaseChatService.shared.createMessage(
            message: message,
            atChatPath: chatID
        )
        
        return message
    }
}
