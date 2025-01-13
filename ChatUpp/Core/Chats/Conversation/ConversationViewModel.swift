
//
//  ConversationViewModel.swift
//  ChatUpp
//
//  Created by Andrei Pripa on 10/3/23.
//

import Foundation
import Combine
import UIKit

enum MessageValueModification 
{
    case text
    case seenStatus
    
    var animationType: UITableView.RowAnimation {
        switch self {
        case .text: return .left
        case .seenStatus: return .none
        }
    }
}

enum MessageChangeType {
    case modified(IndexPath, MessageValueModification)
    case added
    case removed(IndexPath)
}

enum MessageFetchStrategy 
{
    case ascending(startAtMessage: Message?, included: Bool)
    case descending(startAtMessage: Message?, included: Bool)
    case hybrit(startAtMessage: Message)
    case none
}

enum MessagesFetchDirection {
    case ascending
    case descending
    case both
}

enum ConversationInitializationStatus {
    case inProgress
    case finished
}

enum MessagesListenerRange
{
    case forExisting(startAtMessage: Message, endAtMessage: Message)
    case forPaged(startAtMessage: Message, endAtMessage: Message)
}


//MARK: - Model representing section of messages
extension ConversationViewModel
{
    typealias MessageItem = MessageCellViewModel
    
    struct MessageCluster
    {
        let date: Date
        var items: [MessageItem]
    }
}

class ConversationViewModel
{
    private(set) var realmService: ConversationRealmService
    private(set) var firestoreService: ConversationFirestoreService
    private(set) var userListenerService : ConversationUserListinerService
    private(set) var messageListenerService : ConversationMessageListenerService
    
    private(set) var conversation        : Chat?
//    private(set) var userObserver      : RealtimeObservable?
    private(set) var messageClusters     : [MessageCluster] = []
    private(set) var memberProfileImage  : Data?
    private(set) var authenticatedUserID : String = (try! AuthenticationManager.shared.getAuthenticatedUser()).uid
//    private      var listeners           : [Listener] = []
    private var cancellables             = Set<AnyCancellable>()
    
    @Published private(set) var unseenMessagesCount              : Int 
    @Published private(set) var chatUser                         : User
    @Published private(set) var messageChangedTypes              : [MessageChangeType] = []
    
    @Published private(set) var conversationInitializationStatus : ConversationInitializationStatus?
    
    var shouldEditMessage: ((String) -> Void)?
    var currentlyReplyToMessageID: String?
    
    private var lastMessageItem: MessageItem? {
        return messageClusters.first?.items.first
    }
    
    private var conversationExists: Bool {
        return self.conversation != nil
    }
    
    var authParticipantUnreadMessagesCount: Int {
        conversation?.participants.first(where: { $0.userID == authenticatedUserID })?.unseenMessagesCount ?? 0
    }
    
    private var isChatFetchedFirstTime: Bool {
        conversation?.isFirstTimeOpened ?? true
    }
    
    private var shouldDisplayLastMessage: Bool {
        authParticipantUnreadMessagesCount == realmService.getUnreadMessagesCountFromRealm()
    }
    
    private var firstMessage: Message? {
        conversation?.getFirstMessage()
    }
    
    var shouldFetchNewMessages: Bool {
        guard let localMessagesCount = conversation?.conversationMessages.count, localMessagesCount > 0 else {
            return false
        }
        return ( authParticipantUnreadMessagesCount != realmService.getUnreadMessagesCountFromRealm() ) || isChatFetchedFirstTime
    }
    
    /// - Life cycle
    
    init(conversationUser: User, conversation: Chat? = nil, imageData: Data?) {
        self.chatUser = conversationUser
        self.conversation = conversation
        self.memberProfileImage = imageData
        self.unseenMessagesCount = conversation?.getParticipant(byID: authenticatedUserID)?.unseenMessagesCount ?? 0
        
        self.realmService = ConversationRealmService(conversation: conversation)
        self.firestoreService = ConversationFirestoreService(conversation: conversation)
        self.userListenerService = ConversationUserListinerService(chatUser: conversationUser)
        self.messageListenerService = ConversationMessageListenerService(conversation: conversation)
        
        if conversationExists {
            bindToMessages()
            initiateConversation()
        }
    }
    
    private func observeParticipantChanges()
    {
        guard let chat = conversation else {return}
        guard let participant = chat.getParticipant(byID: authenticatedUserID) else {return}
        
        RealmDataBase.shared.observeChanges(for: participant)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] change in
                guard let self = self, change.name == "unseenMessagesCount" else { return }
                self.unseenMessagesCount = change.newValue as? Int ?? self.unseenMessagesCount
            }.store(in: &cancellables)
    }

    /// - listeners
    
    func addListeners() {
        userListenerService.addUsersListener()
        userListenerService.addUserObserver()
        observeParticipantChanges()
        
        guard let startMessage = messageClusters.last?.items.last?.message,
              let limit = conversation?.conversationMessages.count else {return}
        
        messageListenerService.addListenerToUpcomingMessages()
        messageListenerService.addListenerToExistingMessages(startAtTimestamp: startMessage.timestamp, ascending: true, limit: limit)
    }
    
    func removeAllListeners() 
    {
        messageListenerService.removeAllListeners()
        userListenerService.removeAllListeners()
    }
//    
    func resetCurrentReplyMessageIfNeeded() {
        if currentlyReplyToMessageID != nil {
            currentlyReplyToMessageID = nil
        }
    }
    
    func resetInitializationStatus() {
        conversationInitializationStatus = nil
    }
    
    /// - chat components creation
    
    private func createChat() -> Chat
    {
        let chatId = UUID().uuidString
        let participants = createParticipants()
        let recentMessageID = lastMessageItem?.message?.id
        let messagesCount = messageClusters.first?.items.count
        return Chat(id: chatId, participants: participants, recentMessageID: recentMessageID, messagesCount: messagesCount, isFirstTimeOpened: false)
    }
    
    private func createParticipants() -> [ChatParticipant]
    {
        let firstParticipant = ChatParticipant(userID: authenticatedUserID, unseenMessageCount: 0)
        let secondParticipant = ChatParticipant(userID: chatUser.id, unseenMessageCount: 0)
        return [firstParticipant,secondParticipant]
    }
    
    private func createNewMessage(_ messageBody: String) -> Message {
        let messageID = UUID().uuidString
        
        return Message(id: messageID,
                       messageBody: messageBody,
                       senderId: authenticatedUserID,
                       timestamp: Date(),
                       messageSeen: false,
                       isEdited: false,
                       imagePath: nil,
                       imageSize: nil,
                       repliedTo: currentlyReplyToMessageID)
    }
    
    func manageMessageCreation(_ messageText: String)
    {
        let message = createNewMessage(messageText)
        
        resetCurrentReplyMessageIfNeeded()
        realmService.addMessageToRealmChat(message)
        createMessageClustersWith([message], ascending: true)
        
        updateUnseenMessageCounter(shouldIncrement: true)
        
        Task { @MainActor in
            await firestoreService.addMessageToFirestoreDataBase(message)
            await firestoreService.updateRecentMessageFromFirestoreChat(messageID: message.id)
        }
    }
    
    func createConversationIfNeeded()
    {
        if !conversationExists
        {
            let chat = createChat()
            conversation = chat
            realmService.addChatToRealm(chat)
            
            let freezedChat = chat.freeze()
            
            Task(priority: .high, operation: { @MainActor in
                await firestoreService.addChatToFirestore(freezedChat)
                
                guard let timestamp = self.conversation?.getLastMessage()?.timestamp,
                      let limit = conversation?.conversationMessages.count else {return}
                
                messageListenerService.addListenerToExistingMessages(startAtTimestamp: timestamp, ascending: true, limit: limit)
            })
        }
    }
    
    /// - update messages components
    
    func updateUnseenMessageCounter(shouldIncrement: Bool) 
    {
        let participantUserID = shouldIncrement ? chatUser.id : authenticatedUserID
 
        guard let conversation = conversation else { return }

        RealmDataBase.shared.update(object: conversation) { dbChat in
            
            if let participant = dbChat.getParticipant(byID: participantUserID) 
            {
                participant.unseenMessagesCount += shouldIncrement ? 1 : -1
            } 
            else {
                print("Participant not found for ID: \(participantUserID)")
            }
        }

        Task { @MainActor in
            do {
                try await FirebaseChatService.shared.updateUnreadMessageCount(
                    for: participantUserID,
                    inChatWithID: conversation.id,
                    increment: shouldIncrement
                )
            } catch {
                print("Failed to update Firebase unread message count: \(error)")
            }
        }
    }

    @MainActor
    func updateMessageSeenStatus(from cellViewModel: MessageCellViewModel) async
    {
        guard let chatID = conversation?.id else { return }
        await cellViewModel.updateFirestoreMessageSeenStatus(from: chatID)
    }
    
    func clearMessageChanges() {
        messageChangedTypes.removeAll()
    }
    
    /// - unseen message check
    
    /// @MainActor
    func findFirstUnseenMessageIndex() -> IndexPath?
    {
        guard let unseenMessage = RealmDataBase.shared.retrieveObjects(ofType: Message.self)?
            .filter("messageSeen == false AND senderId != %@", authenticatedUserID)
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
        let conversationCellVM = MessageCellViewModel(isUnseenCell: true)
        messageClusters[indexPath.section].items.insert(conversationCellVM, at: indexPath.row + 1)
    }
    
    func getRepliedToMessage(messageID: String) -> Message? 
    {
        var repliedMessage: Message?
        
        messageClusters.forEach { conversationGroups in
            conversationGroups.items.forEach { conversationCellViewModel in
                if conversationCellViewModel.message?.id == messageID {
                    repliedMessage = conversationCellViewModel.message
                    return
                }
            }
        }
        return repliedMessage
    }
    
    func setReplyMessageData(fromReplyMessageID id: String, toViewModel viewModel: MessageCellViewModel) {
        if let messageToBeReplied = getRepliedToMessage(messageID: id) 
        {
            let senderNameOfMessageToBeReplied = getMessageSenderName(usingSenderID: messageToBeReplied.senderId)
            (viewModel.senderNameOfMessageToBeReplied, viewModel.textOfMessageToBeReplied) = (senderNameOfMessageToBeReplied, messageToBeReplied.messageBody)
        }
    }
    
    func getMessageSenderName(usingSenderID id: String) -> String?
    {
        guard let user = try? AuthenticationManager.shared.getAuthenticatedUser() else { return nil }
        if id == user.uid {
            return user.name
        } else {
            return chatUser.name
        }
    }
    
    /// - save image from message
    
    func handleImageDrop(imageData: Data, size: MessageImageSize)
    {
        self.lastMessageItem?.imageData = imageData
        self.lastMessageItem?.message?.imageSize = size
        self.saveImage(data: imageData, size: size)
    }
    
    func saveImage(data: Data, size: MessageImageSize)
    {
        guard let conversation = conversation else {return}
        guard let message = lastMessageItem?.message else {return}
        
        Task {
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
                realmService.addMessageToRealmChat(message)
            }
        }
    }
}

//MARK: - Conversation initialization

extension ConversationViewModel
{
    private func initiateConversation()
    {
        guard !shouldFetchNewMessages else {
            conversationInitializationStatus = .inProgress
            initiateConversationWithRemoteData()
            return
        }
        initiateConversationUsingLocalData()
    }
    
    private func initiateConversationWithRemoteData()
    {
        Task { @MainActor in
            do {
                let messages = try await fetchConversationMessages()
                realmService.addMessagesToConversationInRealm(messages)
                initiateConversationUsingLocalData()
            } catch {
                print("Error while initiating conversation: - \(error)")
            }
        }
    }
    
    private func initiateConversationUsingLocalData() 
    {
        setupConversationMessageGroups()
        conversationInitializationStatus = .finished
    }
    
    private func setupConversationMessageGroups()
    {
        guard var messages = conversation?.getMessages(),
                !messages.isEmpty else { return }
        
        if shouldDisplayLastMessage == false {
            messages.removeFirst()
        }
        createMessageClustersWith(messages)
    }
}

// MARK: - Realm functions

//extension ConversationViewModel
//{
//    func addMessagesToConversationInRealm(_ messages: [Message]) 
//    {
//        guard let conversation = conversation else { return }
//        
//        RealmDataBase.shared.update(object: conversation) { chat in
//            
//            let existingMessageIDs = Set(chat.conversationMessages.map { $0.id })
//            let newMessages = messages.filter { !existingMessageIDs.contains($0.id) }
//            
//            chat.conversationMessages.append(objectsIn: newMessages)
//        }
//    }
//    
//    func updateChatOpenStatusIfNeeded()
//    {
//        guard let conversation = conversation else { return }
//        
//        if conversation.isFirstTimeOpened != false {
//            RealmDataBase.shared.update(object: conversation) { $0.isFirstTimeOpened = false }
//        }
//    }
//    
//    private func addMessageToRealmChat(_ message: Message)
//    {
//        guard let conversation = conversation else { return }
//        
//        RealmDataBase.shared.update(object: conversation) { chat in
//            chat.conversationMessages.append(message)
//        }
//    }
//    
//    private func retrieveMessageFromRealm(_ message: Message) -> Message? {
//        return RealmDataBase.shared.retrieveSingleObject(ofType: Message.self, primaryKey: message.id)
//    }
//    
//    private func addChatToRealm(_ chat: Chat) {
//        RealmDataBase.shared.add(object: chat)
//    }
//    
//    private func updateMessage(_ message: Message) {
//        RealmDataBase.shared.add(object: message)
//    }
//    
//    private func getUnreadMessagesCountFromRealm() -> Int
//    {
//        guard let conversation = conversation else { return 0 }
//        
//        let filter = NSPredicate(format: "messageSeen == false AND senderId != %@", authenticatedUserID)
//        let count = conversation.conversationMessages.filter(filter).count
//        
//        return count
//    }
//    
//    private func removeMessageFromRealm(message: Message)
//    {
//        guard let realmMessage = retrieveMessageFromRealm(message) else {return}
//        RealmDataBase.shared.delete(object: realmMessage)
//    }
//}

//MARK: - Firestore functions
//extension ConversationViewModel
//{
//    private func getFirstUnseenMessageFromFirestore(from chatID: String) async throws -> Message?
//    {
//        return try await FirebaseChatService.shared.getFirstUnseenMessage(fromChatDocumentPath: chatID,
//                                                                   whereSenderIDNotEqualTo: authenticatedUserID)
//    }
//
//    private func addChatToFirestore(_ chat: Chat) async {
//        do {
//            try await FirebaseChatService.shared.createNewChat(chat: chat)
//        } catch {
//            print("Error creating conversation", error.localizedDescription)
//        }
//    }
//    
//    @MainActor
//    private func addMessageToFirestoreDataBase(_ message: Message) async
//    {
//        guard let conversation = conversation else {return}
//        do {
//            try await FirebaseChatService.shared.createMessage(message: message, atChatPath: conversation.id)
//        } catch {
//            print("error occur while trying to create message in DB: ", error.localizedDescription)
//        }
//    }
//    
//    @MainActor
//    func updateRecentMessageFromFirestoreChat(messageID: String) async 
//    {
//        guard let chatID = conversation?.id else { print("chatID is nil") ; return}
//        do {
//            try await FirebaseChatService.shared.updateChatRecentMessage(recentMessageID: messageID, chatID: chatID)
//        } catch {
//            print("Error updating chat last message:", error.localizedDescription)
//        }
//    }
//    
//    func deleteMessageFromFirestore(messageID: String) {
//        Task { @MainActor in
//            do {
//                try await FirebaseChatService.shared.removeMessage(messageID: messageID, conversationID: conversation!.id)
//            } catch {
//                print("Error deleting message: ",error.localizedDescription)
//            }
//        }
//    }
//    
//    @MainActor
//    func editMessageTextFromFirestore(_ messageText: String, messageID: String) {
//        Task {
//            try await FirebaseChatService.shared.updateMessageText(messageText, messageID: messageID, chatID: conversation!.id)
//        }
//    }
//    
//    private func updateLastMessageFromFirestoreChat() {
//        Task { @MainActor in
//            guard let messageID = messageGroups[0].cellViewModels[0].message?.id else {return}
//            await updateRecentMessageFromFirestoreChat(messageID: messageID)
//        }
//    }
//}

// MARK: - Users listener

//extension ConversationViewModel
//{
//    /// - Temporary fix while firebase functions are deactivated
//    func addUserObserver() 
//    {
//        userObserver = RealtimeUserService
//            .shared
//            .addObserverToUsers(chatUser.id) { [weak self] realtimeDBUser in
//                
//            guard let self = self else {return}
//            
//            if realtimeDBUser.isActive != self.chatUser.isActive
//            {
//                if let date = realtimeDBUser.lastSeen,
//                    let isActive = realtimeDBUser.isActive
//                {
//                    self.chatUser = self.chatUser.updateActiveStatus(lastSeenDate: date,isActive: isActive)
//                }
//            }
//        }
//    }
//    
//    func addUsersListener()
//    {
//        let userListener = FirestoreUserService
//            .shared
//            .addListenerToUsers([chatUser.id]) { [weak self] users, documentsTypes in
//            guard let self = self else {return}
//            // since we are listening only for one user, we can just get the first user and docType
//            guard let docType = documentsTypes.first, let user = users.first, docType == .modified else {return}
//            self.chatUser = user
//        }
//        self.listeners.append(userListener)
//    }
//}

// MARK: - Messages listener
//extension ConversationViewModel
//{
//    private func addListenerToUpcomingMessages()
//    {
//        guard let conversationID = conversation?.id,
//              let startMessageID = conversation?.getLastMessage()?.id else { return }
// 
//        Task { @MainActor in
//            
//            let listener = try await FirebaseChatService.shared.addListenerForUpcomingMessages(
//                inChat: conversationID,
//                startingAfterMessage: startMessageID) { [weak self] message, changeType in
//                    
//                    guard let self = self else {return}
//                    
//                    switch changeType {
//                    case .added: self.handleAddedMessage(message)
//                    case .removed: self.handleRemovedMessage(message)
//                    case .modified: self.handleModifiedMessage(message)
//                    }
//                }
//            self.listeners.append(listener)
//        }
//    }
//    
//    private func addListenerToExistingMessages(startAtTimestamp: Date, ascending: Bool, limit: Int = 100)
//    {
//        guard let conversationID = conversation?.id else { return }
//        
//        let listener = FirebaseChatService.shared.addListenerForExistingMessages(
//            inChat: conversationID,
//            startAtTimestamp: startAtTimestamp,
//            ascending: ascending,
//            limit: limit) { [weak self] message, changeType in
//                
//                guard let self = self else {return}
//                
//                switch changeType {
//                case .removed: self.handleRemovedMessage(message)
//                case .modified: self.handleModifiedMessage(message)
//                default: break
//                }
//            }
//        listeners.append(listener)
//    }
//}

extension ConversationViewModel
{
    private func bindToMessages()
    {
        messageListenerService.addedMessage
            .sink { addedMessage in
                self.handleAddedMessage(addedMessage)
            }.store(in: &cancellables)
        
        messageListenerService.modifiedMessage
            .sink { modifiedMessage in
                self.handleModifiedMessage(modifiedMessage)
            }.store(in: &cancellables)
        
        messageListenerService.removedMessage
            .sink { removedMessage in
                self.handleRemovedMessage(removedMessage)
            }.store(in: &cancellables)
    }
}

// MARK: - Message listener helper functions

extension ConversationViewModel
{
    private func handleAddedMessage(_ message: Message)
    {
        guard let _ = realmService.retrieveMessageFromRealm(message) else {
            realmService.addMessageToRealmChat(message)
            // TODO: - if chat unseen message counter is heigher than local unseen count,
            // dont create messageGroup with this new message
            createMessageClustersWith([message], ascending: true)
//            messageChangedType = .added
            messageChangedTypes.append(.added)
//            unseenMessagesCount = conversation?.getParticipant(byID: authenticatedUserID)?.unseenMessagesCount ?? unseenMessagesCount
            return
        }
        Task { @MainActor in
            realmService.updateMessage(message)
        }
    }
    
    private func handleModifiedMessage(_ message: Message) 
    {
        guard let indexPath = indexPath(of: message) else { return }
        
        let cellVM = messageClusters.getCellViewModel(at: indexPath)
        
        guard let modificationValue = cellVM.getModifiedValueOfMessage(message) else { return }
        
        realmService.updateMessage(message)
        if message.senderId == authenticatedUserID {
            messageChangedTypes.append(.modified(indexPath, modificationValue))
        }
    }
    
    private func handleRemovedMessage(_ message: Message)
    {
        guard let indexPath = indexPath(of: message) else { return }
        
        messageClusters.removeClusterItem(at: indexPath)
        
        if messageClusters[indexPath.section].items.isEmpty {
            messageClusters.remove(at: indexPath.section)
        }
        
        realmService.removeMessageFromRealm(message: message)
        
        if indexPath.isFirst(), let lastMessageID = lastMessageItem?.message?.id
        {
            firestoreService.updateLastMessageFromFirestoreChat(lastMessageID)
        }
        messageChangedTypes.append(.removed(indexPath))
    }

    private func indexPath(of message: Message) -> IndexPath? 
    {
        guard let date = message.timestamp.formatToYearMonthDay() else { return nil }
        
        for groupIndex in 0..<messageClusters.count {
            let group = messageClusters[groupIndex]
            
            if group.date == date {
                if let messageIndex = group.items.firstIndex(where: { $0.message?.id == message.id }) {
                    return IndexPath(row: messageIndex, section: groupIndex)
                }
            }
        }
        return nil
    }
}

// MARK: - messages fetch

extension ConversationViewModel
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

        if let firstUnseenMessage = try await firestoreService.getFirstUnseenMessageFromFirestore(from: conversation.id)
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
extension ConversationViewModel
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
    private func prepareMessageClustersUpdate(withMessages messages: [Message], inAscendingOrder: Bool) async throws -> ([IndexPath], IndexSet?)
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
    func handleAdditionalMessageClusterUpdate(inAscendingOrder order: Bool) async throws -> ([IndexPath], IndexSet?)? {
        
        let newMessages = try await loadAdditionalMessages(inAscendingOrder: order)
        guard !newMessages.isEmpty else { return nil }
        
        let (newRows, newSections) = try await prepareMessageClustersUpdate(withMessages: newMessages, inAscendingOrder: order)
        
        if let timestamp = newMessages.first?.timestamp 
        {
            messageListenerService.addListenerToExistingMessages(startAtTimestamp: timestamp, ascending: order)
        }
        realmService.addMessagesToConversationInRealm(newMessages)
        
        return (newRows, newSections)
    }
    
    private func findNewRowIndexPaths(inMessageClusters messageClusters: [MessageCluster], ascending: Bool) -> [IndexPath]
    {
        guard let sectionBeforeUpdate = ascending ? messageClusters.first?.items : messageClusters.last?.items else {return []}
        
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

//MARK: - Not in use

extension ConversationViewModel {
    
//    func contains(_ message: Message) -> Bool
//    {
//        let existingMessageIDs: Set<String> = Set(messageClusters.flatMap { $0.items.compactMap { $0.message?.id } })
//        return existingMessageIDs.contains(message.id)
//    }
    
    //    @Published var firstUnseenMessageIndex: IndexPath?
    //    @Published var skeletonAnimationState: SkeletonAnimationState = .none
    //    private(set) var conversationListenersInitiationSubject = PassthroughSubject<Void,Never>()
    
    
    
    //    private func sortCellViewModels() {
    //        if var lastMessageGroup = messageClusters.first {
    //            lastMessageGroup.cellViewModels.sort(by: { $0.message.timestamp > $1.message.timestamp })
    //            if let lastIndex = messageGroups.indices.first {
    //                messageGroups[lastIndex] = lastMessageGroup
    //            }
    //        }
    //    }
    
    
    //    private func getMessagesCountFromRealm() -> Int {
    //        guard let conversationID = conversation?.id else {return 0}
    //        let chat = RealmDBManager.shared.retrieveSingleObject(ofType: Chat.self, primaryKey: conversationID)?.conversationMessages.count
    //        return RealmDBManager.shared.getObjectsCount(ofType: Message.self)
    //    }
    //
    
    //    private func getUnseenMessageCountFromRealm() -> Int {
    //        let filter = NSPredicate(format: "messageSeen == false AND senderId == %@", userMember.userId)
    //        return RealmDBManager.shared.retrieveObjects(ofType: Message.self, filter: filter).count
    //    }
    
//    guard case .message(content: let conversationCellVM) = messageGroups.last?.cellViewModels.last,
//          let startMessage = conversationCellVM.message,
//          let limit = conversation?.conversationMessages.count else {
//        return
//    }
}


class GroupViewModel: ConversationViewModel
{
        
    override func handleImageDrop(imageData: Data, size: MessageImageSize) {
        super.handleImageDrop(imageData: imageData, size: size)
    }
}
