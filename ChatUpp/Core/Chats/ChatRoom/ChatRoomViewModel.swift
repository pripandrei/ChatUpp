
//
//  ConversationViewModel.swift
//  ChatUpp
//
//  Created by Andrei Pripa on 10/3/23.
//

import Foundation
import Combine
import UIKit
import SwiftUI

enum GroupMembershipStatus
{
    case isMember
    case notAMember
    case pendingInvite
}

class ChatRoomViewModel : SwiftUI.ObservableObject
{
    private var setupConversationTask: Task<Void, Never>?
    
    private(set) var realmService: ConversationRealmService?
    //    private(set) var messageFetcher : ConversationMessageFetcher
    private(set) var firestoreService: ConversationFirestoreService?
    private(set) var userListenerService : ConversationUsersListinerService?
    private(set) var messageListenerService : ConversationMessageListenerService?
    
    private(set) var conversation        : Chat?
    private(set) var participant         : User?
    private(set) var messageClusters     : [MessageCluster] = []
    private(set) var authUser            : AuthDataResultModel = (try! AuthenticationManager.shared.getAuthenticatedUser())
    private var cancellables             = Set<AnyCancellable>()
    
    @Published private(set) var unseenMessagesCount              : Int
    @Published private(set) var messageChangedTypes              : [MessageChangeType] = []
    @Published private(set) var conversationInitializationStatus : ConversationInitializationStatus?
    
    var shouldEditMessage: ((String) -> Void)?
    var currentlyReplyToMessageID: String?
    
    private var lastMessageItem: MessageItem? {
        return messageClusters.first?.items.first
    }
    
    var conversationExists: Bool {
        return self.conversation != nil
    }
    
    var authParticipantUnreadMessagesCount: Int {
        conversation?.participants.first(where: { $0.userID == authUser.uid })?.unseenMessagesCount ?? 0
    }
    
    var isAuthUserGroupMember: Bool
    {
        guard let conversation = conversation else {return false}
        let groupExists = RealmDataBase.shared.retrieveSingleObject(ofType: Chat.self, primaryKey: conversation.id) != nil
        if conversation.isGroup && groupExists { return true }
        else { return false }
    }
    
    var shouldHideJoinGroupOption: Bool
    {
        if conversation?.isGroup == false { return true }
        guard let conversation = conversation else { return true }
        return RealmDataBase.shared.retrieveSingleObject(ofType: Chat.self, primaryKey: conversation.id) != nil
    }
    
    
    private var isChatFetchedFirstTime: Bool {
        conversation?.isFirstTimeOpened ?? true
    }
    
    private var shouldDisplayLastMessage: Bool {
        authParticipantUnreadMessagesCount == realmService?.getUnreadMessagesCountFromRealm()
    }
    
    private var firstMessage: Message? {
        conversation?.getFirstMessage()
    }
    
    var shouldFetchNewMessages: Bool
    {
        if conversation?.realm == nil {
            return true
        }
        
        guard let localMessagesCount = conversation?.conversationMessages.count, localMessagesCount > 0 else {
            return false
        }
        
        let unreadMessagesCount = realmService?.getUnreadMessagesCountFromRealm()
        return ( authParticipantUnreadMessagesCount != unreadMessagesCount ) || isChatFetchedFirstTime || conversation?.realm == nil
    }
    
    private func setupServices(using conversation: Chat)
    {
        self.realmService = ConversationRealmService(conversation: conversation)
        self.firestoreService = ConversationFirestoreService(conversation: conversation)
        self.messageListenerService = ConversationMessageListenerService(conversation: conversation)
        if conversation.isGroup {
            self.userListenerService = ConversationUsersListinerService(chatUsers: Array(conversation.participants))
        }
    }
    
    /// - Life cycle
    
    init(conversation: Chat)
    {
        self.conversation = conversation
        self.unseenMessagesCount = conversation.getParticipant(byID: authUser.uid)?.unseenMessagesCount ?? 0
        self.setupServices(using: conversation)

        if conversationExists {
            bindToMessages()
            initiateConversation()
        }
    }
    
    init(participant: User?)
    {
        self.participant = participant
        self.unseenMessagesCount = 0
    }
    
    init() {
        self.unseenMessagesCount = 0
    }
    
    private func observeParticipantChanges()
    {
        guard let chat = conversation else {return}
        guard let participant = chat.getParticipant(byID: authUser.uid) else {return}
        
        RealmDataBase.shared.observeChanges(for: participant)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] change in
                guard let self = self, change.name == "unseenMessagesCount" else { return }
                self.unseenMessagesCount = change.newValue as? Int ?? self.unseenMessagesCount
            }.store(in: &cancellables)
    }

    /// - listeners
    
    func addListeners()
    {
        userListenerService?.addUsersListener()
        userListenerService?.addUserObserver()
        observeParticipantChanges()
        
        guard let startMessage = messageClusters.last?.items.last?.message,
              let limit = conversation?.conversationMessages.count else {return}
        
        messageListenerService?.addListenerToUpcomingMessages()
        messageListenerService?.addListenerToExistingMessages(startAtMesssageWithID: startMessage.id, ascending: true, limit: limit)
    }
    
    func removeAllListeners() 
    {
        messageListenerService?.removeAllListeners()
        cancellables.forEach { subscriber in
            subscriber.cancel()
        }
        cancellables.removeAll()
    }
 
    func resetCurrentReplyMessageIfNeeded() {
        if currentlyReplyToMessageID != nil {
            currentlyReplyToMessageID = nil
        }
    }
    
    func resetInitializationStatus() {
        conversationInitializationStatus = nil
    }
    
    @MainActor
    func joinGroup() async throws
    {
        guard let conversation = conversation else { return }
        
        let participant = ChatParticipant(userID: authUser.uid, unseenMessageCount: 0)
        conversation.participants.append(participant)
        try await FirebaseChatService.shared.addParticipant(participant: participant, toChat: conversation.id)
        RealmDataBase.shared.add(object: conversation)
    }
    
    /// - chat components creation
    
    private func createChat() -> Chat?
    {
        guard let participant = self.participant else {return nil}
        
        let chatId = UUID().uuidString
        let participants = [
            ChatParticipant(userID: authUser.uid, unseenMessageCount: 0),
            ChatParticipant(userID: participant.id, unseenMessageCount: 0)
        ]
        let recentMessageID = lastMessageItem?.message?.id
        let messagesCount = messageClusters.first?.items.count
        
        return Chat(
            id: chatId,
            participants: participants,
            recentMessageID: recentMessageID,
            messagesCount: messagesCount,
            isFirstTimeOpened: false
        )
    }

    var chatParticipants: [ChatParticipant] = []
    
    func setupConversation()
    {
        guard let chat = createChat() else {return}
        
        self.conversation = chat
        
        setupServices(using: chat)
        
        realmService?.addChatToRealm(chat)
        
        let freezedChat = chat.freeze()
        
        self.setupConversationTask = Task(priority: .high) { @MainActor in
            await firestoreService?.addChatToFirestore(freezedChat)
            setupMessageListenerOnChatCreation()
        }
    }
    
    private func createNewMessage(_ messageBody: String) -> Message
    {
        let isGroupChat = conversation?.isGroup == true
        
        return Message(
            id: UUID().uuidString,
            messageBody: messageBody,
            senderId: authUser.uid,
            timestamp: Date(),
            messageSeen: isGroupChat ? nil : false,
            seenBy: isGroupChat ? [] : nil,
            isEdited: false,
            imagePath: nil,
            imageSize: nil,
            repliedTo: currentlyReplyToMessageID
        )
    }
    
    func manageMessageCreation(_ messageText: String = "")
    {
        let message = createNewMessage(messageText)
        
        // Local updates
        realmService?.addMessageToRealmChat(message)
        createMessageClustersWith([message], ascending: true)
        
        // Remote updates
        Task { @MainActor in
            await setupConversationTask?.value /// await for chat to be remotely created before proceeding, if any
            updateUnseenMessageCounter(shouldIncrement: true)
            await firestoreService?.addMessageToFirestoreDataBase(message)
            await firestoreService?.updateRecentMessageFromFirestoreChat(messageID: message.id)
        }
        
        resetCurrentReplyMessageIfNeeded()
    }
    
    private func setupMessageListenerOnChatCreation()
    {
        guard let timestamp = conversation?.getLastMessage()?.timestamp,
              let limit = conversation?.conversationMessages.count else { return }
        
        messageListenerService?.addListenerToExistingMessages(
            startAtTimestamp: timestamp,
            ascending: true,
            limit: limit
        )
    }
    
    /// - update messages components
    
    func updateUnseenMessageCounter(shouldIncrement: Bool)
    {
        updateUnseenMessageCounterLocal(shouldIncrement: shouldIncrement)
        updateUnseenMessageCounterRemote(shouldIncrement: shouldIncrement)
    }
    
    private func updateUnseenMessageCounterLocal(shouldIncrement: Bool)
    {
        guard let conversation = conversation else { return }

        RealmDataBase.shared.update(object: conversation) { dbChat in
            if shouldIncrement {
                for participant in dbChat.participants where participant.userID != self.authUser.uid {
                    participant.unseenMessagesCount += 1
                }
            }
            else {
                if let participant = dbChat.getParticipant(byID: self.authUser.uid)
                {
                    participant.unseenMessagesCount = max(0, participant.unseenMessagesCount - 1)
                }
            }
        }
    }
    
    private func updateUnseenMessageCounterRemote(shouldIncrement: Bool)
    {
        guard let conversation = conversation else { return }

        Task { @MainActor in
            let targetIDs = shouldIncrement
            ? conversation.participants.filter { $0.userID != self.authUser.uid }.map { $0.userID }
            : [authUser.uid]
            do {
                try await FirebaseChatService.shared.updateUnreadMessageCount(
                    for: targetIDs,
                    inChatWithID: conversation.id,
                    increment: shouldIncrement
                )
            } catch {
                print("Failed to update Firebase unread message count: \(error)")
            }
        }
    }

    @MainActor
    func updateMessageSeenStatus(from cellViewModel: ConversationCellViewModel) async
    {
        guard let chatID = conversation?.id else { return }
        
        let isGroup = conversation?.isGroup ?? false
        await cellViewModel.updateFirestoreMessageSeenStatus(by: isGroup ? authUser.uid : nil, from: chatID)
    }
    
    func clearMessageChanges() {
        messageChangedTypes.removeAll()
    }
    
    /// - unseen message check
    
    /// @MainActor
    func findFirstUnseenMessageIndex() -> IndexPath?
    {
        guard conversation?.realm != nil else { return nil }
        guard let unseenMessage = conversation?.conversationMessages
            .filter("messageSeen == false AND senderId != %@", authUser.uid)
            .sorted(byKeyPath: Message.CodingKeys.timestamp.rawValue, ascending: true)
            .first else { return nil }
    
        for (groupIndex, messageGroup) in messageClusters.enumerated()
        {
            if let viewModelIndex = messageGroup.items.firstIndex(where: { $0.message?.id == unseenMessage.id }) {
                return IndexPath(item: viewModelIndex, section: groupIndex)
            }
        }
        return nil
    }
    
    func insertUnseenMessagesTitle() 
    {
        guard let indexPath = findFirstUnseenMessageIndex() else {return}
//        let indexPath = IndexPath(row: 13, section: 3)
        let conversationCellVM = ConversationCellViewModel(isUnseenCell: true)
        messageClusters[indexPath.section].items.insert(conversationCellVM, at: indexPath.row + 1)
    }
    
    /// - save image from message
    
    func handleImageDrop(imageData: Data, size: MessageImageSize)
    {
        if let message = lastMessageItem?.message {
            RealmDataBase.shared.update(object: message) { message in
                message.imageSize = size
            }
        }
        self.saveImage(data: imageData, size: size)
    }
    
    func saveImage(data: Data, size: MessageImageSize)
    {
        guard let conversation = conversation else {return}
        guard let message = lastMessageItem?.message else {return}
        Task { @MainActor in
            //TODO: - Image resolve
            // create image path an pass to saveImage
            // or consider creating firstly image and from returned path create than message 
            let imageMetaData = try await FirebaseStorageManager
                .shared
                .saveImage(data: data, to: .message(message.id))
            
            try await FirebaseChatService
                .shared
                .updateMessageImagePath(messageID: message.id,
                                        chatDocumentPath: conversation.id,
                                        path: imageMetaData.name)
            
            try await FirebaseChatService
                .shared
                .updateMessageImageSize(messageID: message.id,
                                        chatDocumentPath: conversation.id,
                                        imageSize: size)
            print("Success saving image: \(imageMetaData.path) \(imageMetaData.name)")
            
            CacheManager.shared.saveImageData(data, toPath: imageMetaData.name)
            
            await MainActor.run {
                realmService?.addMessageToRealmChat(message)
            }
        }
    }
}

//MARK: - Conversation initialization

extension ChatRoomViewModel
{
    private func initiateConversation()
    {
        if shouldFetchNewMessages
        {
            conversationInitializationStatus = .inProgress
            Task { await initializeWithRemoteData() }
        }
        else { initializeWithLocalData() }
    }
    
    @MainActor
    private func initializeWithRemoteData() async
    {
        do {
            let messages = try await fetchConversationMessages()
            
            if conversation?.isGroup == true
            {
                try await syncGroupUsers(for: messages)
                
                if !isAuthUserGroupMember
                {
                    initializeWithMessages(messages)
                    return
                }
            }
            realmService?.addMessagesToConversationInRealm(messages)
            initializeWithLocalData()
        } catch {
            print("Error while initiating conversation: - \(error)")
        }
    }
    
    private func initializeWithLocalData()
    {
        defer { conversationInitializationStatus = .finished }
        
        guard conversation?.realm != nil,
              var messages = conversation?.getMessages(),
              !messages.isEmpty else { return }
        
        if !shouldDisplayLastMessage {
            messages.removeFirst()
        }
        createMessageClustersWith(messages)
    }
    
    private func initializeWithMessages(_ messages: [Message])
    {
        if !messages.isEmpty
        {
            createMessageClustersWith(messages)
        }
        conversationInitializationStatus = .finished
    }
    
    
    // MARK: - Group Chat Handling
    
    private func syncGroupUsers(for messages: [Message]) async throws
    {
        let missingUserIDs = await findMissingUserIDs(from: messages)
        
        guard !missingUserIDs.isEmpty else { return }
        
        let users = try await FirestoreUserService.shared.fetchUsers(with: missingUserIDs)
        RealmDataBase.shared.add(objects: users)
        await fetchAvatars(for: users)
    }

    @MainActor
    private func findMissingUserIDs(from messages: [Message]) -> [String] {
        let senderIDs = Set(messages.map(\.senderId))
        let existingUsers = getRealmUsers(with: senderIDs)
        let existingUserIds = Set(existingUsers.map(\.id))
        
        return Array(senderIDs.subtracting(existingUserIds))
    }
    
    private func getRealmUsers(with userIDs: Set<String>) -> [User] {
        let filter = NSPredicate(format: "id IN %@", Array(userIDs))
        return RealmDataBase.shared.retrieveObjects(ofType: User.self, filter: filter)?.toArray() ?? []
    }
    
    
    private func fetchAvatars(for users: [User]) async
    {
        await withTaskGroup(of: Void.self) { group in
            for user in users
            {
                guard let avatarURL = user.photoUrl else { continue }
                
                group.addTask {
                    do {
                        let optimizedURL = avatarURL.replacingOccurrences(of: ".jpg", with: "_small.jpg")
                        let imageData = try await FirebaseStorageManager.shared.getImage(from: .user(user.id), imagePath: optimizedURL)
                        CacheManager.shared.saveImageData(imageData, toPath: optimizedURL)
                    } catch {
                        print("Error fetching avatar image data for user: \(user.id); Error: \(error)")
                    }
                }
            }
            await group.waitForAll()
        }
    }
}


//MARK: - Message listener bindings
extension ChatRoomViewModel
{
    private func bindToMessages()
    {
        messageListenerService?.updatedMessage
            .receive(on: DispatchQueue.main)
            .sink { messageType in
                let message = messageType.data

                switch messageType.changeType {
                case .added: Task { await self.handleAddedMessage(message) }
                case .modified: self.handleModifiedMessage(message)
                case .removed: self.handleRemovedMessage(message)
                }
            }.store(in: &cancellables)
    }
}

// MARK: - Message listener helper functions

extension ChatRoomViewModel
{
    @MainActor
    private func handleAddedMessage(_ message: Message) async
    {
        guard realmService?.retrieveMessageFromRealm(message) == nil else { return }

        realmService?.addMessageToRealmChat(message)
        
        if message.type == .title
//            &&
//            RealmDataBase.shared.retrieveSingleObject(ofType: User.self, primaryKey: message.senderId) == nil
        {
            do {
                try await syncGroupUsers(for: [message])
            } catch {
                print("Error in synchronizing user from message title: ", error)
            }
        }
        
        // TODO: - if chat unseen message counter is heigher than local unseen count,
        // dont create messageGroup with this new message
        createMessageClustersWith([message], ascending: true)
        messageChangedTypes.append(.added)
    }
    
    private func handleModifiedMessage(_ message: Message)
    {
        guard let indexPath = indexPath(of: message),
              let cellVM = messageClusters.getCellViewModel(at: indexPath),
              let modificationValue = cellVM.getModifiedValueOfMessage(message)
        else { return }
        
        realmService?.updateMessage(message)
        messageChangedTypes.append(.modified(indexPath, modificationValue))
    }
    
    private func handleRemovedMessage(_ message: Message)
    {
        guard let indexPath = indexPath(of: message) else { return }
        
        messageClusters.removeClusterItem(at: indexPath)
        if messageClusters[indexPath.section].items.isEmpty {
            messageClusters.remove(at: indexPath.section)
        }
        
        realmService?.removeMessageFromRealm(message: message)
        
        if indexPath.isFirst(), let lastMessageID = lastMessageItem?.message?.id
        {
            firestoreService?.updateLastMessageFromFirestoreChat(lastMessageID)
        }
        messageChangedTypes.append(.removed(indexPath))
    }
    
    private func indexPath(of message: Message) -> IndexPath?
    {
        guard let date = message.timestamp.formatToYearMonthDay() else { return nil }
        
        for (groupIndex, group) in messageClusters.enumerated() {
            if group.date == date,
               let messageIndex = group.items.firstIndex(where: { $0.message?.id == message.id }) {
                return IndexPath(row: messageIndex, section: groupIndex)
            }
        }
        return nil
    }
}

// MARK: - messages fetch

extension ChatRoomViewModel
{
    @MainActor
    func fetchConversationMessages(using strategy: MessageFetchStrategy? = nil) async throws -> [Message] 
    {
        guard let conversation = conversation else { return [] }

        let fetchStrategy = (strategy == nil) ? try await determineFetchStrategy() : strategy
        
        switch fetchStrategy
        {
        case .ascending(let startAtMessage, let included):
            return try await FirebaseChatService.shared.fetchMessagesFromChat(
                chatID: conversation.id,
                startingFrom: startAtMessage?.id,
                inclusive: included,
                fetchDirection: .ascending
            )
        case .descending(let startAtMessage, let included):
            return try await FirebaseChatService.shared.fetchMessagesFromChat(
                chatID: conversation.id,
                startingFrom: startAtMessage?.id,
                inclusive: included,
                fetchDirection: .descending
            )
        case .hybrit(let startAtMessage):
            let descendingMessages = try await FirebaseChatService.shared.fetchMessagesFromChat(
                chatID: conversation.id,
                startingFrom: startAtMessage.id,
                inclusive: true,
                fetchDirection: .descending
            )
            let ascendingMessages = try await FirebaseChatService.shared.fetchMessagesFromChat(
                chatID: conversation.id,
                startingFrom: startAtMessage.id,
                inclusive: false,
                fetchDirection: .ascending
            )
            return descendingMessages + ascendingMessages
        default: return []
        }
    }
    
    private func loadAdditionalMessages(inAscendingOrder ascendingOrder: Bool) async throws -> [Message]
    {
        guard let startMessage = ascendingOrder
                ? lastMessageItem?.message
                : messageClusters.last?.items.last?.message else {return []}
        
        switch ascendingOrder {
        case true: return try await fetchConversationMessages(using: .ascending(startAtMessage: startMessage, included: false))
        case false: return try await fetchConversationMessages(using: .descending(startAtMessage: startMessage, included: false))
        }
    }
    
    @MainActor
    private func determineFetchStrategy() async throws -> MessageFetchStrategy 
    {
        guard let conversation = conversation else { return .none }
        
        if !isAuthUserGroupMember {
            if let recentMessage = try await FirebaseChatService.shared.getRecentMessage(from: conversation) {
                return .descending(startAtMessage: recentMessage, included: true)
            }
        }

        if let firstUnseenMessage = try await firestoreService?.getFirstUnseenMessageFromFirestore(from: conversation.id)
        {
            return isChatFetchedFirstTime ? .hybrit(startAtMessage: firstUnseenMessage) : .ascending(startAtMessage: firstUnseenMessage, included: true)
        }
        
        if let lastSeenMessage = conversation.getLastMessage()
        {
            return .descending(startAtMessage: lastSeenMessage, included: true)
        }

        return .none // would trigger only if isChatFetchedFirstTime and chat is empty
    }
}

// MARK: - messageCluster functions
extension ChatRoomViewModel
{
    private func createMessageClustersWith(_ messages: [Message], ascending: Bool? = nil)
    {
        var dateToIndex = Dictionary(uniqueKeysWithValues: self.messageClusters.enumerated().map { ($0.element.date, $0.offset) })
        var tempMessageClusters = self.messageClusters

        messages.forEach { message in
            guard let date = message.timestamp.formatToYearMonthDay() else { return }
            let messageItem = MessageItem(message: message)

            if let index = dateToIndex[date] {
                ascending == true
                    ? tempMessageClusters[index].items.insert(messageItem, at: 0)
                    : tempMessageClusters[index].items.append(messageItem)
            } else {
                let newCluster = MessageCluster(date: date, items: [messageItem])
                if ascending == true {
                    tempMessageClusters.insert(newCluster, at: 0)
                    dateToIndex[date] = 0
                } else {
                    tempMessageClusters.append(newCluster)
                    dateToIndex[date] = tempMessageClusters.count - 1
                }
            }
        }
        self.messageClusters = tempMessageClusters
    }

    @MainActor
    private func prepareMessageClustersUpdate(withMessages messages: [Message],
                                              inAscendingOrder: Bool) async throws -> ([IndexPath], IndexSet?)
    {
        let messageClustersBeforeUpdate = messageClusters
        let startSectionCount = inAscendingOrder ? 0 : messageClusters.count
        
        createMessageClustersWith(messages, ascending: inAscendingOrder)
        
        let endSectionCount = inAscendingOrder ? (messageClusters.count - messageClustersBeforeUpdate.count) : messageClusters.count
        
        let newRows = findNewRowIndexPaths(inMessageClusters: messageClustersBeforeUpdate, ascending: inAscendingOrder)
        let newSections = findNewSectionIndexSet(startSectionCount: startSectionCount, endSectionCount: endSectionCount)
        
        return (newRows, newSections)
    }
    
    @MainActor
    func handleAdditionalMessageClusterUpdate(inAscendingOrder order: Bool) async throws -> ([IndexPath], IndexSet?)?
    {
        let newMessages = try await loadAdditionalMessages(inAscendingOrder: order)
        guard !newMessages.isEmpty else { return nil }

        if conversation?.isGroup == true {
            try await syncGroupUsers(for: newMessages)
        }
        
        let (newRows, newSections) = try await prepareMessageClustersUpdate(withMessages: newMessages, inAscendingOrder: order)
        
        if let timestamp = newMessages.first?.timestamp 
        {
            messageListenerService?.addListenerToExistingMessages(startAtTimestamp: timestamp, ascending: order)
        }
        
        if conversation?.realm != nil {
            realmService?.addMessagesToConversationInRealm(newMessages)
        }
        
        return (newRows, newSections)
    }
    
    private func findNewRowIndexPaths(inMessageClusters messageClusters: [MessageCluster],
                                      ascending: Bool) -> [IndexPath]
    {
        guard let sectionBeforeUpdate = ascending ?
                messageClusters.first?.items : messageClusters.last?.items else {return []}
        
        let sectionIndex = ascending ? 0 : messageClusters.count - 1
        
        return self.messageClusters[sectionIndex].items
            .enumerated()
            .compactMap { index, viewModel in
                return sectionBeforeUpdate.contains { $0.message == viewModel.message }
                ? nil
                : IndexPath(row: index, section: sectionIndex)
            }
    }
    
    private func findNewSectionIndexSet(startSectionCount: Int, endSectionCount: Int) -> IndexSet? 
    {
        return (startSectionCount < endSectionCount)
        ? IndexSet(integersIn: startSectionCount..<endSectionCount)
        : nil
    }
}





//MARK: - not in use


//extension ChatRoomViewModel {
//    var members: [User]
//    {
//        guard let conversation = conversation else { return [] }
//        
//        let participantsID = Array( conversation.participants.map { $0.userID } )
//        let filter = NSPredicate(format: "id IN %@ AND id != %@", participantsID, authUser.uid)
//        let users = RealmDataBase.shared.retrieveObjects(ofType: User.self, filter: filter)?.toArray()
//        
//        return users ?? []
//    }

///= ==== = =
//    func getRepliedToMessage(messageID: String) -> Message?
//    {
//        var repliedMessage: Message?
//
//        messageClusters.forEach { conversationGroups in
//            conversationGroups.items.forEach { conversationCellViewModel in
//                if conversationCellViewModel.message?.id == messageID {
//                    repliedMessage = conversationCellViewModel.message
//                    return
//                }
//            }
//        }
//        return repliedMessage
//    }
    
//    func setReplyMessageData(fromReplyMessageID id: String,
//                             toViewModel viewModel: ConversationCellViewModel)
//    {
////        let messageToBeReplied = getRepliedToMessage(messageID: id)
////        viewModel.updateReferenceMessage(messageToBeReplied)
////        viewModel.setReferenceMessage(messageToBeReplied)
////        if let messageToBeReplied = getRepliedToMessage(messageID: id)
////        {
////            let senderNameOfMessageToBeReplied = getMessageSenderName(usingSenderID: messageToBeReplied.senderId)
////            (viewModel.senderNameOfMessageToBeReplied, viewModel.textOfMessageToBeReplied) =
////            (senderNameOfMessageToBeReplied, messageToBeReplied.messageBody)
////        }
//    }
    
//    func getMessageSenderName(usingSenderID id: String) -> String?
//    {
//        let user = RealmDataBase.shared.retrieveSingleObject(ofType: User.self, primaryKey: id)
//        return user?.name
//    }

//}

