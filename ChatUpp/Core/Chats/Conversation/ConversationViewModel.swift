
//
//  ConversationViewModel.swift
//  ChatUpp
//
//  Created by Andrei Pripa on 10/3/23.
//

import Foundation
import Combine

enum MessageValueModification {
    case text
    case seenStatus
}

enum MessageChangeType {
    case modified(IndexPath, MessageValueModification)
    case added
    case removed
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

struct ConversationMessageGroup {
    let date: Date
    var cellViewModels: [ConversationCellViewModel]
}

//MARK: - Conversation initialization

enum ConversationInitializationStatus {
    case notInitialized
    case inProgress
    case finished
    case error
}

extension ConversationViewModel
{
    private func setupConversationMessageGroups() 
    {
        guard var messages = conversation?.getMessages(),
                !messages.isEmpty else { return }
        
        if displayLastMessage == false
        {
            messages.removeFirst()
        }
        manageMessageGroupsCreation(messages)
    }

    func initiateConversation() 
    {
//        guard !shouldFetchNewMessages else {
//            conversationInitializationStatus = .inProgress
//            initiateConversationWithRemoteData()
//            return
//        }
        initiateConversationUsingLocalData()
    }
    
    private func initiateConversationWithRemoteData() {
        Task { @MainActor in
            let messages = try await fetchConversationMessages()
            addMessagesToConversationInRealm(messages)
            initiateConversationUsingLocalData()
        }
    }
    
    private func initiateConversationUsingLocalData() {
        setupConversationMessageGroups()
        conversationInitializationStatus = .finished
    }
}

final class ConversationViewModel 
{
    
    var additionalMessageFetchLimit = 10
    var listeners: [Listener] = []
    
    var unreadMessagesCount: Int = 22
    var isChatFetchedFirstTime: Bool = false
    @Published var conversationInitializationStatus: ConversationInitializationStatus = .notInitialized
    
    private(set) var conversation: Chat?
    private(set) var memberProfileImage: Data?
    var messageGroups: [ConversationMessageGroup] = []
    private(set) var (userListener,messageListener): (Listener?, Listener?)
    private(set) var userObserver: RealtimeDBObserver?
    private(set) var authenticatedUserID: String = (try! AuthenticationManager.shared.getAuthenticatedUser()).uid
    
    @Published private(set) var participant: DBUser
    @Published var messageChangedType: MessageChangeType?
    
    var shouldEditMessage: ((String) -> Void)?
    var updateUnreadMessagesCount: (() async throws -> Void)?
    var currentlyReplyToMessageID: String?
    
    var conversationIsInitiated: Bool {
        return self.conversation != nil
    }
    
    private var firstMessage: Message? {
        conversation?.getFirstMessage()
    }
    
    var shouldFetchNewMessages: Bool 
    {
        guard let localMessagesCount = conversation?.conversationMessages.count else {return true}
        let isLocalUnreadMessageCountNotEquelToRemoteCount = unreadMessagesCount != getUnreadMessagesCountFromRealm()
        return isLocalUnreadMessageCountNotEquelToRemoteCount || isChatFetchedFirstTime
    }
    
    private var displayLastMessage: Bool {
        unreadMessagesCount == getUnreadMessagesCountFromRealm()
    }
    
    init(participant: DBUser, conversation: Chat? = nil, imageData: Data?) {
        self.participant = participant
        self.conversation = conversation
        self.memberProfileImage = imageData
        
        initiateConversation()
    }
    
//    func addListeners() {
////        addListenerToMessages()
//        addUsersListener()
//        addUserObserver()
//    }
    func addListeners() {
        addUsersListener()
        addUserObserver()
        
        guard let startMessage = messageGroups.last?.cellViewModels.last?.cellMessage,
//              let endMessage = messageGroups.first?.cellViewModels.first?.cellMessage,
              let limit = conversation?.conversationMessages.count else {return}
        
        addListenerToUpcomingMessages()
//        addListenerToExistingMessages(startAtTimestamp: startMessage.timestamp, endAtTimeStamp: endMessage.timestamp)
        addListenerToExistingMessages(startAtTimestamp: startMessage.timestamp, ascending: true, limit: limit)
    }
    
    private func createChat() -> Chat
    {
        let chatId = UUID().uuidString
        let participants = [authenticatedUserID, participant.userId]
        let recentMessageID = messageGroups.first?.cellViewModels.first?.cellMessage.id
        let messagesCount = messageGroups.first?.cellViewModels.count
        return Chat(id: chatId, participants: participants, recentMessageID: recentMessageID, messagesCount: messagesCount)
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
    
    func createConversationIfNeeded() {
        if !conversationIsInitiated 
        {
            let chat = createChat()
            conversation = chat
            addChatToRealm(chat)
            
            let freezedChat = chat.freeze()
            
            Task(priority: .high, operation: { @MainActor in
                await addChatToFirestore(freezedChat)
                
                guard let timestamp = self.conversation?.getLastMessage()?.timestamp,
                      let limit = conversation?.conversationMessages.count else {return}
                
                addListenerToExistingMessages(startAtTimestamp: timestamp, ascending: true, limit: limit)
            })
        }
    }
    
    func manageMessageCreation(_ messageText: String) 
    {
        guard let chat = conversation else {return}
        
        let message = createNewMessage(messageText)
        
        resetCurrentReplyMessageIfNeeded()
        addMessageToRealmChat(message)
        chat.incrementMessageCount()
        manageMessageGroupsCreation([message], ascending: true)
        
        Task { @MainActor in
            await addMessageToFirestoreDataBase(message)
            await updateRecentMessageFromFirestoreChat(messageID: message.id)
            try await ChatsManager.shared.updateMessagesCount(in: chat)
        }
        
    }
    
    func resetCurrentReplyMessageIfNeeded() {
        if currentlyReplyToMessageID != nil { 
            currentlyReplyToMessageID = nil
        }
    }
    
//    @MainActor
    //TODO: Make this function to query realm db for smaller code
    func findFirstUnseenMessageIndex() -> IndexPath? 
    {
        var indexOfNotSeenMessageToScrollTo: IndexPath?
        
        for (groupIndex, messageGroup) in messageGroups.enumerated()
        {
            for (viewModelIndex,conversationVM) in messageGroup.cellViewModels.enumerated()
            {
                if isUnseenMessagePresent(in: conversationVM) {
                    indexOfNotSeenMessageToScrollTo = IndexPath(item: viewModelIndex, section: groupIndex)
                } else {
                    return indexOfNotSeenMessageToScrollTo
                }
            }
        }
        return indexOfNotSeenMessageToScrollTo
    }

    private func isUnseenMessagePresent(in conversationVM: ConversationCellViewModel) -> Bool {
        let messageIsUnseen = !conversationVM.cellMessage.messageSeen
        let authUserIsNotOwnerOfMessage = conversationVM.cellMessage.senderId != authenticatedUserID
        
        if messageIsUnseen && authUserIsNotOwnerOfMessage { return true }
        else { return false }
    }
    
    func handleImageDrop(imageData: Data, size: MessageImageSize) {
        self.messageGroups.first?.cellViewModels.first?.imageData = imageData
        self.messageGroups.first?.cellViewModels.first?.cellMessage.imageSize = size
        self.saveImage(data: imageData, size: CGSize(width: size.width, height: size.height))
    }
    
    func saveImage(data: Data, size: CGSize) {
        guard let conversation = conversation else {return}
        guard let messageID = messageGroups.first?.cellViewModels.first?.cellMessage.id else {return}
        Task {
            let (path,name) = try await StorageManager
                .shared
                .saveMessageImage(data: data, messageID: messageID)
            try await ChatsManager
                .shared
                .updateMessageImagePath(messageID: messageID,
                                        chatDocumentPath: conversation.id,
                                        path: name)
            
            let imageSize = MessageImageSize(width: Int(size.width), height: Int(size.height))
            try await ChatsManager
                .shared
                .updateMessageImageSize(messageID: messageID,
                                        chatDocumentPath: conversation.id,
                                        imageSize: imageSize)
            print("Success saving image: \(path) \(name)")
        }
    }
    
    func getRepliedToMessage(messageID: String) -> Message? 
    {
        var repliedMessage: Message?
        
        messageGroups.forEach { conversationGroups in
            conversationGroups.cellViewModels.forEach { conversationCellViewModel in
                if conversationCellViewModel.cellMessage.id == messageID {
                    repliedMessage = conversationCellViewModel.cellMessage
                    return
                }
            }
        }
        return repliedMessage
    }
    
    func setReplyMessageData(fromReplyMessageID id: String, toViewModel viewModel: ConversationCellViewModel) {
        if let messageToBeReplied = getRepliedToMessage(messageID: id) 
        {
            let senderNameOfMessageToBeReplied = getMessageSenderName(usingSenderID: messageToBeReplied.senderId)
            (viewModel.senderNameOfMessageToBeReplied, viewModel.textOfMessageToBeReplied) = (senderNameOfMessageToBeReplied, messageToBeReplied.messageBody)
        }
    }
}

//MARK: - Realm functions
extension ConversationViewModel
{
    private func addMessagesToConversationInRealm(_ messages: [Message]) 
    {
        guard let conversation = conversation else { return }
        RealmDBManager.shared.update(object: conversation) { chat in
            let existingMessageIDs = Set(chat.conversationMessages.map { $0.id })
            let newMessages = messages.filter { !existingMessageIDs.contains($0.id) }
            
            chat.conversationMessages.append(objectsIn: newMessages)
        }
    }
    
    private func addMessageToRealmChat(_ message: Message)
    {
        guard let conversation = conversation else { return }
        RealmDBManager.shared.update(object: conversation) { chat in
            chat.conversationMessages.append(message)
        }
    }
    
    private func retrieveMessageFromRealm(_ message: Message) -> Message? {
        return RealmDBManager.shared.retrieveSingleObject(ofType: Message.self, primaryKey: message.id)
    }
    
    private func addChatToRealm(_ chat: Chat) {
        RealmDBManager.shared.add(object: chat)
    }
    
    
    private func updateMessage(_ message: Message) {
        RealmDBManager.shared.add(object: message)
    }
    
    private func getUnreadMessagesCountFromRealm() -> Int
    {
        guard let conversation = conversation else { return 0 }
        
        let filter = NSPredicate(format: "messageSeen == false AND senderId != %@", authenticatedUserID)
        let count = conversation.conversationMessages.filter(filter).count
        
        return count
    }
    
    
    private func removeMessageFromRealm(message: Message) {
        guard let realmMessage = retrieveMessageFromRealm(message) else {return}
        RealmDBManager.shared.delete(object: realmMessage)
    }
}


//MARK: - Users listener
extension ConversationViewModel
{
    /// - Temporary fix while firebase functions are deactivated
    func addUserObserver() {
        userObserver = UserManagerRealtimeDB
            .shared
            .addObserverToUsers(participant.userId) { [weak self] realtimeDBUser in
                
            guard let self = self else {return}
            
            if realtimeDBUser.isActive != self.participant.isActive
            {
                if let date = realtimeDBUser.lastSeen,
                    let isActive = realtimeDBUser.isActive
                {
                    self.participant = self.participant.updateActiveStatus(lastSeenDate: date,isActive: isActive)
                }
            }
        }
    }
    
    func addUsersListener()
    {
        self.userListener = UserManager
            .shared
            .addListenerToUsers([participant.userId]) { [weak self] users, documentsTypes in
            guard let self = self else {return}
            // since we are listening only for one user, we can just get the first user and docType
            guard let docType = documentsTypes.first, let user = users.first, docType == .modified else {return}
            self.participant = user
        }
    }
}

//MARK: - Messages listener
extension ConversationViewModel
{
    
//    func addListenerToMessages()
//    {
//        guard let conversation = conversation else {return}
//        self.messageListener = ChatsManager.shared.addListenerToChatMessages(conversation.id) { [weak self] message, type in
//            guard let self = self else {return}
//
//            switch type {
//            case .added: self.handleAddedMessage(message)
//            case .removed: self.handleRemovedMessage(message)
//            case .modified: self.handleModifiedMessage(message)
//                print("==== modified", message)
//            }
//        }
//    }
    
    func addListenerToUpcomingMessages()
    {
        guard let conversationID = conversation?.id,
              let startMessageID = conversation?.getLastMessage()?.id else { return }
        
        Task { @MainActor in
            
            let listener = try await ChatsManager.shared.addListenerForUpcomingMessages(
                inChat: conversationID,
                startingAfterMessage: startMessageID) { [weak self] message, changeType in
                    
                    guard let self = self else {return}
                    
                    switch changeType {
                    case .added: print("added")
                        //                    self.handleAddedMessage(message)
                    case .removed: self.handleRemovedMessage(message)
                    case .modified: self.handleModifiedMessage(message)
                        print("==== modified", message)
                    }
                }
            self.listeners.append(listener)
        }
    }
    
    func addListenerToExistingMessages(startAtTimestamp: Date, ascending: Bool, limit: Int) {
        guard let conversationID = conversation?.id
                /*let startMessage = messageGroups.first?.cellViewModels.first?.cellMessage */else { return }
        
        let listener = ChatsManager.shared.addListenerForExistingMessages(
            inChat: conversationID,
            startAtTimestamp: startAtTimestamp,
            ascending: ascending,
            limit: limit) { [weak self] message, changeType in
                
                guard let self = self else {return}
                
                switch changeType {
                    //            case .added: print("added")
                    //                    self.handleAddedMessage(message)
                case .removed: print("removed")
                    self.handleRemovedMessage(message)
                case .modified: self.handleModifiedMessage(message)
                    print("==== modified", message)
                default: break
                }
                
            }
        listeners.append(listener)
    }
    
    
//    func addListenerToExistingMessages(startAtTimestamp: Date, endAtTimeStamp: Date) {
//        guard let conversationID = conversation?.id
//              /*let startMessage = messageGroups.first?.cellViewModels.first?.cellMessage */else { return }
//        
//        let listener = ChatsManager.shared.addListenerForExistingMessages(inChat: conversationID,
//                                                           startAtTimestamp: startAtTimestamp,
//                                                           endAtTimeStamp: endAtTimeStamp) { message, updateType in
//            
//            
//        }
//        listeners.append(listener)
//    }
    
//    func addListenerToExistingMessages() {
//        guard let conversationID = conversation?.id,
//              let startMessage = messageGroups.first?.cellViewModels.first?.cellMessage else { return }
//        
//        ChatsManager.shared.addListenerForExistingMessages(inChat: conversationID,
//                                                           startAfterTimestamp: startMessage.timestamp,
//                                                           descending: <#T##Bool#>,
//                                                           onMessageUpdated: <#T##(Message, DocumentChangeType) -> Void#>)
//    }

}


enum MessagesListenerRange
{
    case forExisting(startAtMessage: Message, endAtMessage: Message)
    case forPaged(startAtMessage: Message, endAtMessage: Message)
}

//MARK: - Message listener helper functions
extension ConversationViewModel
{
    private func handleAddedMessage(_ message: Message)
    {
        guard let _ = retrieveMessageFromRealm(message) else {
            addMessageToRealmChat(message)
            // TODO: - if chat unseen message counter is heigher than local unseen count,
            // dont create messageGroup with this new message
            manageMessageGroupsCreation([message], ascending: true)
            messageChangedType = .added
            return
        }
        Task { @MainActor in
//            if message.id == "----" { print("stop") }
            updateMessage(message)
        }
    }
    
    private func handleModifiedMessage(_ message: Message) 
    {
        guard let indexPath = indexPath(of: message) else { return }
        let cellVM = messageGroups.getCellViewModel(at: indexPath)
        
        guard let modificationValue = cellVM.getModifiedValueOfMessage(message) else { return }
        
        updateMessage(message)
        if message.senderId == authenticatedUserID {
            messageChangedType = .modified(indexPath, modificationValue)
        }
    }
    
    private func handleRemovedMessage(_ message: Message) {
        
        guard let indexPath = indexPath(of: message) else { return }
        
        messageGroups.removeCellViewModel(at: indexPath)
        removeMessageGroup(at: indexPath)
        removeMessageFromRealm(message: message)
        
        if isLastMessage(indexPath) { updateLastMessageFromFirestoreChat() }
        messageChangedType = .removed
    }
    
    private func removeMessageGroup(at indexPath: IndexPath) {
        if messageGroups[indexPath.section].cellViewModels.isEmpty {
            messageGroups.remove(at: indexPath.section)
        }
    }

    private func indexPath(of message: Message) -> IndexPath? {
        guard let date = message.timestamp.formatToYearMonthDay() else { return nil }
        
        for groupIndex in 0..<messageGroups.count {
            let group = messageGroups[groupIndex]
            
            if group.date == date {
                if let messageIndex = group.cellViewModels.firstIndex(where: { $0.cellMessage.id == message.id }) {
                    return IndexPath(row: messageIndex, section: groupIndex)
                }
            }
        }
        return nil
    }
    
    @MainActor
    func updateMessageSeenStatus(from cellViewModel: ConversationCellViewModel) async
    {
        guard let chatID = conversation?.id else { return }
        await cellViewModel.updateFirestoreMessageSeenStatus(from: chatID)
    }
    
    private func isLastMessage(_ indexPath: IndexPath) -> Bool {
        return indexPath.row == 0 && indexPath.section == 0
    }
    
    func contains(_ message: Message) -> Bool {
        let existingMessageIDs: Set<String> = Set(messageGroups.flatMap { $0.cellViewModels.map { $0.cellMessage.id } })
        return existingMessageIDs.contains(message.id)
    }
}


//MARK: - messages fetch

extension ConversationViewModel
{
    @MainActor
    func fetchConversationMessages(using strategy: MessageFetchStrategy? = nil) async throws -> [Message] {
        guard let conversation = conversation else { return [] }

        let fetchStrategy = (strategy == nil) ? try await determineFetchStrategy() : strategy
        
        switch fetchStrategy
        {
        case .ascending(let startAtMessage, let included):
            return try await ChatsManager.shared.fetchMessagesFromChat(
                chatID: conversation.id,
                startingFrom: startAtMessage?.id,
                inclusive: included,
                fetchDirection: .ascending
            )
        case .descending(let startAtMessage, let included):
            return try await ChatsManager.shared.fetchMessagesFromChat(
                chatID: conversation.id,
                startingFrom: startAtMessage?.id,
                inclusive: included,
                fetchDirection: .descending
            )
        case .hybrit(let startAtMessage):
            let descendingMessages = try await ChatsManager.shared.fetchMessagesFromChat(
                chatID: conversation.id,
                startingFrom: startAtMessage.id,
                inclusive: true,
                fetchDirection: .descending
            )
            let ascendingMessages = try await ChatsManager.shared.fetchMessagesFromChat(
                chatID: conversation.id,
                startingFrom: startAtMessage.id,
                inclusive: false,
                fetchDirection: .ascending
            )
            return descendingMessages + ascendingMessages
        default: return []
        }
    }
    
    
    @MainActor
    private func determineFetchStrategy() async throws -> MessageFetchStrategy 
    {
        guard let conversation = conversation else { return .none }

        if let firstUnseenMessage = try await getFirstUnseenMessageFromFirestore(from: conversation.id)
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


//MARK: - Firestore functions
extension ConversationViewModel 
{
    private func getFirstUnseenMessageFromFirestore(from chatID: String) async throws -> Message? 
    {
        return try await ChatsManager.shared.getFirstUnseenMessage(fromChatDocumentPath: chatID,
                                                                   whereSenderIDNotEqualTo: authenticatedUserID)
    }
    
//    private func getLastSeenMessageFromFirestore(from chatID: String) async throws -> Message? {
//        return try await ChatsManager.shared.getLastSeenMessage(fromChatDocumentPath: chatID)
//    }
    
    private func addChatToFirestore(_ chat: Chat) async {
        do {
            try await ChatsManager.shared.createNewChat(chat: chat)
        } catch {
            print("Error creating conversation", error.localizedDescription)
        }
    }
    
    @MainActor
    private func addMessageToFirestoreDataBase(_ message: Message) async  {
        guard let conversation = conversation else {return}
        do {
            try await ChatsManager.shared.createMessage(message: message, atChatPath: conversation.id)
        } catch {
            print("error occur while trying to create message in DB: ", error.localizedDescription)
        }
    }
    
    @MainActor
    func updateRecentMessageFromFirestoreChat(messageID: String ) async {
        guard let chatID = conversation?.id else { print("chatID is nil") ; return}
        do {
            try await ChatsManager.shared.updateChatRecentMessage(recentMessageID: messageID, chatID: chatID)
        } catch {
            print("Error updating chat last message:", error.localizedDescription)
        }
    }
    
    func deleteMessageFromFirestore(messageID: String) {
        Task { @MainActor in
            do {
                try await ChatsManager.shared.removeMessage(messageID: messageID, conversationID: conversation!.id)
            } catch {
                print("Error deleting message: ",error.localizedDescription)
            }
        }
    }
    
    @MainActor
    func editMessageTextFromFirestore(_ messageText: String, messageID: String) {
        Task {
            try await ChatsManager.shared.updateMessageText(messageText, messageID: messageID, chatID: conversation!.id)
        }
    }
    
    func getMessageSenderName(usingSenderID id: String) -> String?
    {
        guard let user = try? AuthenticationManager.shared.getAuthenticatedUser() else { return nil }
        if id == user.uid {
            return user.name
        } else {
            return participant.name
        }
    }
    
    private func updateLastMessageFromFirestoreChat() {
        Task { @MainActor in
            let messageID = messageGroups[0].cellViewModels[0].cellMessage.id
            await updateRecentMessageFromFirestoreChat(messageID: messageID)
        }
    }
}


extension ConversationViewModel
{
    func manageMessageGroupsCreation(_ messages: [Message], ascending: Bool? = nil)
    {
        var tempMessageGroups: [ConversationMessageGroup] = self.messageGroups
        var groupIndexDict: [Date: Int] = Dictionary(uniqueKeysWithValues: tempMessageGroups.enumerated().map { ($0.element.date, $0.offset) })
        
       messages.forEach { message in
            guard let date = message.timestamp.formatToYearMonthDay() else { return }
            let cellViewModel = ConversationCellViewModel(cellMessage: message)
            
            if let index = groupIndexDict[date] {
                if ascending == true {
                    tempMessageGroups[index].cellViewModels.insert(cellViewModel, at: 0)
                } else {
                    tempMessageGroups[index].cellViewModels.append(cellViewModel)
                }
            } else {
                if ascending == true {
                    let newMessageGroup = ConversationMessageGroup(date: date, cellViewModels: [cellViewModel])
                    tempMessageGroups.insert(newMessageGroup, at: 0)
                    groupIndexDict[date] = 0
                }
                else {
                    let newMessageGroup = ConversationMessageGroup(date: date, cellViewModels: [cellViewModel])
                    tempMessageGroups.append(newMessageGroup)
                    groupIndexDict[date] = tempMessageGroups.count - 1
                }
            }
        }
        self.messageGroups = tempMessageGroups
    }
    
    @MainActor
    func manageAdditionalMessageGroupsCreation(inAscendingOrder: Bool) async throws -> ([IndexPath], IndexSet?)
    {
        let messageGroupsBeforeUpdate = messageGroups
        var startSectionCount: Int
        
        switch inAscendingOrder {
        case true: startSectionCount = 0
        case false: startSectionCount = messageGroups.count
        }
        
        let newMessages = try await loadAdditionalMessages(inAscendingOrder: inAscendingOrder)
        guard !newMessages.isEmpty else { return ([], nil) }

        addListenerToExistingMessages(startAtTimestamp: newMessages.first!.timestamp, ascending: inAscendingOrder, limit: additionalMessageFetchLimit)
        
        addMessagesToConversationInRealm(newMessages)
        
        manageMessageGroupsCreation(newMessages, ascending: inAscendingOrder)
        
        let endSectionCount = inAscendingOrder ? (messageGroups.count - messageGroupsBeforeUpdate.count) : messageGroups.count
        
        let newRows = findNewRowIndexPaths(inMessageGroups: messageGroupsBeforeUpdate, ascending: inAscendingOrder)
        let newSections = findNewSectionIndexSet(startSectionCount: startSectionCount, endSectionCount: endSectionCount)
        
        return (newRows, newSections)
    }
    
    private func findNewRowIndexPaths(inMessageGroups messageGroups: [ConversationMessageGroup], ascending: Bool) -> [IndexPath]
    {
        guard let sectionBeforeUpdate = ascending ? messageGroups.first?.cellViewModels : messageGroups.last?.cellViewModels else {return []}
        
        let sectionIndex = ascending ? 0 : messageGroups.count - 1
        
        return self.messageGroups[sectionIndex].cellViewModels
            .enumerated()
            .compactMap { index, viewModel in
                return sectionBeforeUpdate.contains { $0.cellMessage == viewModel.cellMessage }
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
    
    private func loadAdditionalMessages(inAscendingOrder ascendingOrder: Bool) async throws -> [Message]
    {
        guard let startMessage = ascendingOrder
                ? messageGroups.first?.cellViewModels.first?.cellMessage
                : messageGroups.last?.cellViewModels.last?.cellMessage else {return []}
        
        switch ascendingOrder {
        case true: return try await fetchConversationMessages(using: .ascending(startAtMessage: startMessage, included: false))
        case false: return try await fetchConversationMessages(using: .descending(startAtMessage: startMessage, included: false))
        }
    }

}

//MARK: - Not in use

extension ConversationViewModel {
    
    //    @Published var firstUnseenMessageIndex: IndexPath?
    //    @Published var skeletonAnimationState: SkeletonAnimationState = .none
    //    private(set) var conversationListenersInitiationSubject = PassthroughSubject<Void,Never>()
    
    
    
    //    private func sortCellViewModels() {
    //        if var lastMessageGroup = messageGroups.first {
    //            lastMessageGroup.cellViewModels.sort(by: { $0.cellMessage.timestamp > $1.cellMessage.timestamp })
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
}



//@MainActor
//func manageAdditionalMessageGroupsCreation() async throws {
//    let newMessages = try await loadAdditionalMessages()
//    manageMessageGroupsCreation(newMessages)
//}
//
//func findNewRowIndexPaths(usingPreviousMessageGroups previousMessageGroups: [ConversationMessageGroup]) -> [IndexPath] {
//    guard let lastSectionBeforeUpdate = previousMessageGroups.last?.cellViewModels else { return [] }
//    let lastSectionIndex = previousMessageGroups.count - 1
//    
//    return messageGroups[lastSectionIndex].cellViewModels.enumerated().compactMap { index, viewModel in
//        return lastSectionBeforeUpdate.contains { $0.cellMessage == viewModel.cellMessage }
//            ? nil
//            : IndexPath(row: index, section: lastSectionIndex)
//    }
//}
//
//func findNewSectionIndexSet(startSectionCount: Int, endSectionCount: Int) -> IndexSet? {
//    return (startSectionCount < endSectionCount)
//    ? IndexSet(integersIn: startSectionCount..<endSectionCount)
//    : nil
//}
//
//private func loadAdditionalMessages() async throws -> [Message] {
//    guard let lastMessage = messageGroups.last?.cellViewModels.last?.cellMessage
//    else { return [] }
//    
//    var newMessages = try await fetchConversationMessages(using: .descending(startAtMessage: lastMessage))
//    newMessages.removeFirst()
//    return newMessages
//}

/// ==== = = ===
//    @MainActor
//    private func determineFetchStrategy() async throws -> MessageFetchStrategy
//    {
//        guard let conversation = conversation else { return .none }
//
//        if let message = conversation.getLastSeenMessage()
//        {
//            if isChatFetchedFirstTime
//            {
//                return .ascending(startAtMessage: message)
//            } else {
//                return .descending(startAtMessage: message)
//            }
//        }
//        else if let message = try await getLastSeenMessageFromFirestore(from: conversation.id)
//        {
//            return .hybrit(startAtMessage: message)
//        }
//        else if let message = conversation.getPenultimateMessage()
//        {
//            return .ascending(startAtMessage: message) // all messages are unssen but not all are in local data base
//        }
//        else {
//            return .ascending(startAtMessage: nil) // all messages are unseen and we just fetch them from the vey first one
//        }
//    }


//    @MainActor
//    private func determineFetchStrategy() async throws -> MessageFetchStrategy {
//        guard let conversation = conversation else { return .none }
//
//        // Case 1: Fetch starting from the last seen message in local storage
//        if let lastSeenMessage = conversation.getLastSeenMessage() {
//            return isChatFetchedFirstTime ? .ascending(startAtMessage: lastSeenMessage) : .descending(startAtMessage: lastSeenMessage)
//        }
//
//        // Case 2: Fetch starting from the last seen message in Firestore if not available locally
//        if let firestoreLastSeenMessage = try await getLastSeenMessageFromFirestore(from: conversation.id) {
//            return .hybrit(startAtMessage: firestoreLastSeenMessage)
//        }
//
//        // Case 3: No seen messages, fetch all from the beginning
//        return .ascending(startAtMessage: nil)
//    }
