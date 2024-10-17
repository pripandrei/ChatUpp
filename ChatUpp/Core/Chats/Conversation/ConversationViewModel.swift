
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

enum MessageFetchStrategy {
    case ascending(startAtMessage: Message?)
    case descending(startAtMessage: Message?)
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

//MARK: -

extension ConversationViewModel
{
    private func setupConversationMessageGroups() {
        guard let messages = conversation?.getMessages(), !messages.isEmpty else { return }
        manageMessageGroupsCreation(messages)
    }
    
    func initiateConversation()
    {
        if shouldFetchNewMessages
        {
            skeletonAnimationState = .initiated
//            print("Should fetch?: ", shouldFetchNewMessages)
            Task { @MainActor in
                let messages = try await fetchConversationMessages()
                
                addMessagesToConversationInRealm(messages)
                setupConversationMessageGroups()
                skeletonAnimationState = .terminated
                firstUnseenMessageIndex = self.findFirstUnseenMessageIndex()
                
                conversationListenersInitiationSubject.send()
            }
        } else {
            setupConversationMessageGroups()
            firstUnseenMessageIndex = self.findFirstUnseenMessageIndex()
            
            conversationListenersInitiationSubject.send()
        }
    }
}

final class ConversationViewModel 
{
    var unreadMessagesCount: Int = 0
    
    private(set) var conversation: Chat?
    private(set) var memberProfileImage: Data?
    var messageGroups: [ConversationMessageGroup] = []
    private(set) var (userListener,messageListener): (Listener?, Listener?)
    private(set) var userObserver: RealtimeDBObserver?
    private(set) var authenticatedUserID: String = (try! AuthenticationManager.shared.getAuthenticatedUser()).uid
    
    @Published private(set) var participant: DBUser
    @Published var messageChangedType: MessageChangeType?
    @Published var firstUnseenMessageIndex: IndexPath?
    @Published var skeletonAnimationState: SkeletonAnimationState = .none
    
    private(set) var conversationListenersInitiationSubject = PassthroughSubject<Void,Never>()
    
    var shouldEditMessage: ((String) -> Void)?
    var updateUnreadMessagesCount: (() async throws -> Void)?
    var currentlyReplyToMessageID: String?
    
    var conversationIsInitiated: Bool {
        return self.conversation != nil
    }
    
    var isChatFetchedFirstTime: Bool = false
    
    private var firstMessage: Message? {
        conversation?.getFirstMessage()
    }
    
    private var shouldFetchNewMessages: Bool {
//        return conversation?.conversationMessages.count != conversation?.messagesCount
        guard let localMessagesCount = conversation?.conversationMessages.count else {return true}
//        guard let remoteMessagesCount = conversation?.messagesCount else {return true}
        
//        let isFirstChatFetch = localMessagesCount < 50 && remoteMessagesCount >= 50
        let isLocalUnreadMessageCountNotEquelToRemoteCount = unreadMessagesCount != getUnreadMessagesCountFromRealm()
        return isLocalUnreadMessageCountNotEquelToRemoteCount || isChatFetchedFirstTime
    }
    
    init(participant: DBUser, conversation: Chat? = nil, imageData: Data?) {
        self.participant = participant
        self.conversation = conversation
        self.memberProfileImage = imageData
        
//        initiateConversation()
//        addListeners()
    }
    
    func addListeners() {
        addListenerToMessages()
        addUsersListener()
        addUserObserver()
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
                addListenerToMessages()
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
        manageMessageGroupsCreation([message])
        
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
    private func findFirstUnseenMessageIndex() -> IndexPath? {
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
    
    func getRepliedToMessage(messageID: String) -> Message? {
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
        if let messageToBeReplied = getRepliedToMessage(messageID: id) {
            let senderNameOfMessageToBeReplied = getMessageSenderName(usingSenderID: messageToBeReplied.senderId)
            
            (viewModel.senderNameOfMessageToBeReplied, viewModel.textOfMessageToBeReplied) = (senderNameOfMessageToBeReplied, messageToBeReplied.messageBody)
        }
    }
}

//MARK: - Users listener
extension ConversationViewModel 
{
    /// - Temporary fix while firebase functions are deactivated
    func addUserObserver() {
        userObserver = UserManagerRealtimeDB.shared.addObserverToUsers(participant.userId) { [weak self] realtimeDBUser in
            guard let self = self else {return}
            if realtimeDBUser.isActive != self.participant.isActive
            {
                if let date = realtimeDBUser.lastSeen, let isActive = realtimeDBUser.isActive {
                    self.participant = self.participant.updateActiveStatus(lastSeenDate: date,isActive: isActive)
                    
                }
            }
        }
    }
    
    func addUsersListener() 
    {
        self.userListener = UserManager.shared.addListenerToUsers([participant.userId]) { [weak self] users, documentsTypes in
            guard let self = self else {return}
            // since we are listening only for one user, we can just get the first user and docType
            guard let docType = documentsTypes.first, let user = users.first, docType == .modified else {return}
            self.participant = user
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
    
    private func getUnreadMessagesCountFromRealm() -> Int {
        let filter = NSPredicate(format: "messageSeen == false")
        let count = conversation?.conversationMessages.filter(filter).count
        
        guard let count = count else {return 0}
        return count
    }
}

//MARK: - Messages listener
extension ConversationViewModel
{
    
    func addListenerToMessages()
    {
        guard let conversation = conversation else {return}
        self.messageListener = ChatsManager.shared.addListenerToChatMessages(conversation.id) { [weak self] message, type in
            guard let self = self else {return}

            switch type {
            case .added: self.handleAddedMessage(message)
            case .removed: self.handleRemovedMessage(message)
            case .modified: self.handleModifiedMessage(message)
                print("==== modified", message)
            }
        }
    }
}

//MARK: - Message listener helper functions
extension ConversationViewModel
{
    private func handleAddedMessage(_ message: Message)
    {
        guard let _ = retrieveMessageFromRealm(message) else {
            addMessageToRealmChat(message)
            manageMessageGroupsCreation([message])
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
        
        var fetchStrategy = strategy
        
        if fetchStrategy == nil {
            fetchStrategy = try await determineFetchStrategy()
        }
        
        switch fetchStrategy {
        case .ascending(let startAtMessage): 
            return try await fetchMessages(from: conversation.id, startTimeStamp: startAtMessage?.timestamp, direction: .ascending)
        case .descending(let startAtMessage):
            return try await fetchMessages(from: conversation.id, startTimeStamp: startAtMessage?.timestamp, direction: .descending)
        case .hybrit(let startAtMessage):
            let descendingMessages = try await fetchMessages(from: conversation.id, startTimeStamp: startAtMessage.timestamp, direction: .descending)
            let ascendingMessages = try await fetchMessages(from: conversation.id, startTimeStamp: startAtMessage.timestamp, direction: .ascending)
            return descendingMessages + ascendingMessages
        default: return []
        }
    }
    
    @MainActor
    private func determineFetchStrategy(strategy: MessageFetchStrategy? = nil) async throws -> MessageFetchStrategy 
    {
        guard let conversation = conversation else { return .none }
        
        if let message = conversation.getLastSeenMessage() {
            if conversation.conversationMessages.count > 1 {
                return .ascending(startAtMessage: message)
            } else {
                return .descending(startAtMessage: message)
            }
        } else if let message = try await getLastSeenMessageFromFirestore(from: conversation.id) {
            return .hybrit(startAtMessage: message)
        } else if let message = conversation.getPenultimateMessage() {
            return .ascending(startAtMessage: message)
        } else {
            return .ascending(startAtMessage: nil)
        }
    }

    private func fetchMessages(from chatID: String, startTimeStamp timestamp: Date? = nil, direction: MessagesFetchDirection) async throws -> [Message] {
        try await ChatsManager.shared.fetchMessages(
            from: chatID,
            messagesQueryLimit: 30,
            startAtTimestamp: timestamp,
            direction: direction
        )
    }
}


//MARK: - Firestore functions
extension ConversationViewModel 
{
    private func getLastSeenMessageFromFirestore(from chatID: String) async throws -> Message? {
        return try await ChatsManager.shared.getLastSeenMessage(fromChatDocumentPath: chatID)
    }
    
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
        Task {
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
        Task {
            let messageID = messageGroups[0].cellViewModels[0].cellMessage.id
            await updateRecentMessageFromFirestoreChat(messageID: messageID)
        }
    }
}


extension ConversationViewModel
{
    func manageMessageGroupsCreation(_ messages: [Message])
    {
        var tempMessageGroups: [ConversationMessageGroup] = self.messageGroups
        var groupIndexDict: [Date: Int] = Dictionary(uniqueKeysWithValues: tempMessageGroups.enumerated().map { ($0.element.date, $0.offset) })
        
       messages.forEach { message in
            guard let date = message.timestamp.formatToYearMonthDay() else { return }
            let cellViewModel = ConversationCellViewModel(cellMessage: message)
            
            if let index = groupIndexDict[date] {
                tempMessageGroups[index].cellViewModels.append(cellViewModel)
            } else {
                let newMessageGroup = ConversationMessageGroup(date: date, cellViewModels: [cellViewModel])
                tempMessageGroups.append(newMessageGroup)
                groupIndexDict[date] = tempMessageGroups.count - 1
            }
        }
        self.messageGroups = tempMessageGroups
    }
    
//    @MainActor
//    func loadAdditionalMessageGroups() async throws -> ([IndexPath], IndexSet?) {
//        let startSection = messageGroups.count
//        
//        guard let lastMessage = messageGroups.last?.cellViewModels.last?.cellMessage else {return ([], nil)}
//        guard let lastSectionMessagesBeforeUpdate = messageGroups.last?.cellViewModels else {return ([], nil)}
//        
//        let lastSectionIndexBeforeUpdate = messageGroups.count - 1
//        
//        var newMessages = try await fetchConversationMessages(using: .descending(startAtMessage: lastMessage))
//        newMessages.removeFirst()
//        
//        manageMessageGroupsCreation(newMessages)
//        
//        /// check if new cells in last section were added
//        let newRowsIndexes = messageGroups[lastSectionIndexBeforeUpdate].cellViewModels.enumerated().compactMap { index, element in
//            return lastSectionMessagesBeforeUpdate.contains(where: { $0.cellMessage == element.cellMessage }) ? nil : IndexPath(row: index, section: lastSectionIndexBeforeUpdate)
//        }
//
//        let endSection = messageGroups.count
//        let indexSet = startSection < endSection ? IndexSet(integersIn: startSection...endSection - 1) : nil
//        return (newRowsIndexes, indexSet)
//    }
    
//    @MainActor
//    func loadAdditionalMessageGroups() async throws -> ([IndexPath], IndexSet?) {
//        guard let lastGroup = messageGroups.last,
//              let lastMessage = lastGroup.cellViewModels.last?.cellMessage
//        else { return ([], nil) }
//        
//        let startSectionCount = messageGroups.count
//        let lastSectionMessagesBeforeUpdate = lastGroup.cellViewModels
//        let lastSectionIndex = messageGroups.count - 1
//        
//        // Fetch new messages and remove the duplicate first message
//        var newMessages = try await fetchConversationMessages(using: .descending(startAtMessage: lastMessage))
//        newMessages.removeFirst()
//
//        manageMessageGroupsCreation(newMessages)
//        
//        // Compute index paths for newly added messages in the last section
//        let newIndexPaths = messageGroups[lastSectionIndex].cellViewModels.enumerated().compactMap { index, viewModel in
//            return lastSectionMessagesBeforeUpdate.contains { $0.cellMessage == viewModel.cellMessage }
//                ? nil
//                : IndexPath(row: index, section: lastSectionIndex)
//        }
//
//        // Check if new sections were added
//        let endSectionCount = messageGroups.count
//        let newSections: IndexSet? = (startSectionCount < endSectionCount)
//            ? IndexSet(integersIn: startSectionCount..<endSectionCount)
//            : nil
//
//        return (newIndexPaths, newSections)
//    }
    
    @MainActor
    func manageAdditionalMessageGroupsCreation() async throws -> ([IndexPath], IndexSet?) {
        let messageGroupSnapshot = messageGroups
        let startSectionCount = messageGroups.count
        
        // Fetch new messages and remove the duplicate first message
        let newMessages = try await loadAdditionalMessages()
        manageMessageGroupsCreation(newMessages)

        let newRows = findNewRowIndexPaths(usingPreviousMessageGroups: messageGroupSnapshot)
        let newSections = findNewSectionIndexSet(startSectionCount: startSectionCount, endSectionCount: messageGroups.count)
        
        return (newRows, newSections)
    }
    
//    private func findNewRowIndexPaths(inLastSectionBeforeUpdate lastSectionMessagesBeforeUpdate: [ConversationCellViewModel], lastSectionIndex: Int) -> [IndexPath] {
//        return messageGroups[lastSectionIndex].cellViewModels.enumerated().compactMap { index, viewModel in
//            return lastSectionMessagesBeforeUpdate.contains { $0.cellMessage == viewModel.cellMessage }
//            ? nil
//            : IndexPath(row: index, section: lastSectionIndex)
//        }
//    }
//    
    private func findNewRowIndexPaths(usingPreviousMessageGroups previousMessageGroups: [ConversationMessageGroup]) -> [IndexPath] {
        guard let lastSectionBeforeUpdate = previousMessageGroups.last?.cellViewModels else { return [] }
        let lastSectionIndex = previousMessageGroups.count - 1
    
        return messageGroups[lastSectionIndex].cellViewModels.enumerated().compactMap { index, viewModel in
            return lastSectionBeforeUpdate.contains { $0.cellMessage == viewModel.cellMessage }
                ? nil
                : IndexPath(row: index, section: lastSectionIndex)
        }
    }
    
    private func findNewSectionIndexSet(startSectionCount: Int, endSectionCount: Int) -> IndexSet? {
        return (startSectionCount < endSectionCount)
        ? IndexSet(integersIn: startSectionCount..<endSectionCount)
        : nil
    }
    
    private func loadAdditionalMessages() async throws -> [Message] {
        guard let lastMessage = messageGroups.last?.cellViewModels.last?.cellMessage
        else { return [] }
        
        var newMessages = try await fetchConversationMessages(using: .descending(startAtMessage: lastMessage))
        newMessages.removeFirst()
        return newMessages
    }

}

//MARK: - Not in use

extension ConversationViewModel {
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
