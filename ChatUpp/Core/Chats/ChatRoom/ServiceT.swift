//
//  ServiceT.swift
//  ChatUpp
//
//  Created by Andrei Pripa on 1/11/25.
//

import Foundation
import Combine


//MARK: - realm service

final class ConversationRealmService
{
    private let conversation: Chat?
    
    private var authenticatedUserID: String?
    {
        return try? AuthenticationManager.shared.getAuthenticatedUser().uid
    }
    
    init(conversation: Chat?) {
        self.conversation = conversation
    }
    
    func addMessagesToConversationInRealm(_ messages: [Message])
    {
        guard let conversation = conversation else { return }
        
        RealmDataBase.shared.update(object: conversation) { chat in
            
            let existingMessageIDs = Set(chat.conversationMessages.map { $0.id })
            let newMessages = messages.filter { !existingMessageIDs.contains($0.id) }
            
            chat.conversationMessages.append(objectsIn: newMessages)
        }
    }
    
    func updateChatOpenStatusIfNeeded()
    {
        guard let conversation = conversation else { return }
        
        if conversation.isFirstTimeOpened != false {
            RealmDataBase.shared.update(object: conversation) { $0.isFirstTimeOpened = false }
        }
    }
    
    func addMessageToRealmChat(_ message: Message)
    {
        guard let conversation = conversation else { return }
        
        RealmDataBase.shared.update(object: conversation) { chat in
            chat.conversationMessages.append(message)
        }
    }
    
    func retrieveMessageFromRealm(_ message: Message) -> Message? {
        return RealmDataBase.shared.retrieveSingleObject(ofType: Message.self, primaryKey: message.id)
    }
    
    func addChatToRealm(_ chat: Chat) {
        RealmDataBase.shared.add(object: chat)
    }
    
    func updateMessage(_ message: Message) {
        RealmDataBase.shared.add(object: message)
    }
    
    func getUnreadMessagesCountFromRealm() -> Int
    {
        guard let conversation = conversation else { return 0 }
        
        let filter = NSPredicate(format: "messageSeen == false AND senderId != %@", authenticatedUserID ?? "")
        let count = conversation.conversationMessages.filter(filter).count
        
        return count
    }
    
    func removeMessageFromRealm(message: Message)
    {
        guard let realmMessage = retrieveMessageFromRealm(message) else {return}
        RealmDataBase.shared.delete(object: realmMessage)
    }
}


//MARK: - firebase service

final class ConversationFirestoreService
{
    private let conversation: Chat?
    
    private var authenticatedUserID: String?
    {
        return try? AuthenticationManager.shared.getAuthenticatedUser().uid
    }
    
    init(conversation: Chat?) {
        self.conversation = conversation
    }
    
    func getFirstUnseenMessageFromFirestore(from chatID: String) async throws -> Message?
    {
        return try await FirebaseChatService.shared.getFirstUnseenMessage(fromChatDocumentPath: chatID,
                                                                   whereSenderIDNotEqualTo: authenticatedUserID ?? "")
    }

    func addChatToFirestore(_ chat: Chat) async {
        do {
            try await FirebaseChatService.shared.createNewChat(chat: chat)
        } catch {
            print("Error creating conversation", error.localizedDescription)
        }
    }
    
    @MainActor
    func addMessageToFirestoreDataBase(_ message: Message) async
    {
        guard let conversation = conversation else {return}
        do {
            try await FirebaseChatService.shared.createMessage(message: message, atChatPath: conversation.id)
        } catch {
            print("error occur while trying to create message in DB: ", error.localizedDescription)
        }
    }
    
    @MainActor
    func updateRecentMessageFromFirestoreChat(messageID: String) async
    {
        guard let chatID = conversation?.id else { print("chatID is nil") ; return}
        do {
            try await FirebaseChatService.shared.updateChatRecentMessage(recentMessageID: messageID, chatID: chatID)
        } catch {
            print("Error updating chat last message:", error.localizedDescription)
        }
    }
    
    func deleteMessageFromFirestore(messageID: String) {
        Task { @MainActor in
            do {
                try await FirebaseChatService.shared.removeMessage(messageID: messageID, conversationID: conversation!.id)
            } catch {
                print("Error deleting message: ",error.localizedDescription)
            }
        }
    }
    
    @MainActor
    func editMessageTextFromFirestore(_ messageText: String, messageID: String) {
        Task {
            try await FirebaseChatService.shared.updateMessageText(messageText, messageID: messageID, chatID: conversation!.id)
        }
    }
    
    func updateLastMessageFromFirestoreChat(_ lastMessageID: String) {
        Task { @MainActor in
//            guard let messageID = messageGroups[0].cellViewModels[0].cellMessage?.id else {return}
            await updateRecentMessageFromFirestoreChat(messageID: lastMessageID)
        }
    }
}


//MARK: - Users listener

final class ConversationUserListinerService
{
    private var cancellables = Set<AnyCancellable>()
    
    @Published private(set) var chatUser: User
    
    init(chatUser: User) {
        self.chatUser = chatUser
    }
    
    /// - Temporary fix while firebase functions are deactivated
    /// 
    func addUserObserver()
    {
        RealtimeUserService
            .shared
            .addObserverToUsers(chatUser.id)
            .sink(receiveValue: { [weak self] updatedUser in
                guard let self = self else {return}
                
                if updatedUser.isActive != self.chatUser.isActive
                {
                    if let date = updatedUser.lastSeen,
                       let isActive = updatedUser.isActive
                    {
                        self.chatUser = self.chatUser.updateActiveStatus(lastSeenDate: date,isActive: isActive)
                    }
                }
            }).store(in: &cancellables)
    }
    
    func addUsersListener()
    {
        FirestoreUserService
            .shared
            .addListenerToUsers([chatUser.id])
            .sink(receiveValue: { [weak self] userUpdatedObject in
                if userUpdatedObject.changeType == .modified {
                    self?.chatUser = userUpdatedObject.data
                }
            }).store(in: &cancellables)
    }
}

final class ConversationMessageListenerService
{
    private let conversation: Chat?
    private var listeners: [Listener] = []

    private(set) var updatedMessage = PassthroughSubject<DatabaseChangedObject<Message>,Never>()

    init(conversation: Chat?) {
        self.conversation = conversation
    }
    
    func removeAllListeners()
    {
        listeners.forEach{ $0.remove() }
    }
    
    func addListenerToUpcomingMessages()
    {
        guard let conversationID = conversation?.id,
              let startMessageID = conversation?.getLastMessage()?.id else { return }
 
        Task { @MainActor in
            
            let listener = try await FirebaseChatService.shared.addListenerForUpcomingMessages(
                inChat: conversationID,
                startingAfterMessage: startMessageID) { [weak self] messageUpdate in
                    guard let self = self else {return}
                    self.updatedMessage.send(messageUpdate)
                }
            self.listeners.append(listener)
        }
    }
    
    func addListenerToExistingMessages(startAtTimestamp: Date, ascending: Bool, limit: Int = 100)
    {
        guard let conversationID = conversation?.id else { return }
        
        let listener = FirebaseChatService.shared.addListenerForExistingMessages(
            inChat: conversationID,
            startAtTimestamp: startAtTimestamp,
            ascending: ascending,
            limit: limit) { [weak self] messageUpdate in
                guard let self = self else {return}
                self.updatedMessage.send(messageUpdate)

            }
        listeners.append(listener)
    }
}


//enum MessageUpdateType {
//    case added(_ message: Message)
//    case removed(_ message: Message)
//    case modified(_ message: Message)
//}


//class ConversationMessageFetcher
//{
//    private var conversation: Chat
//    private let firestoreService: ConversationFirestoreService
////    private var messageClusters: [ChatRoomViewModel.MessageCluster]
//    
//    private var isChatFetchedFirstTime: Bool {
//        conversation.isFirstTimeOpened ?? true
//    }
//    
//    init(conversation: Chat,
//         firestoreService: ConversationFirestoreService
//    )
////         messageClusterers: [ChatRoomViewModel.MessageCluster])
//    {
//        self.conversation = conversation
//        self.firestoreService = firestoreService
////        self.messageClusters = messageClusterers
//    }
//    
//    @MainActor
//    func fetchConversationMessages(using strategy: MessageFetchStrategy? = nil) async throws -> [Message]
//    {
//        let fetchStrategy = (strategy == nil) ? try await determineFetchStrategy() : strategy
//        
//        switch fetchStrategy
//        {
//        case .ascending(let startAtMessage, let included):
//            return try await FirebaseChatService.shared.fetchMessagesFromChat(
//                chatID: conversation.id,
//                startingFrom: startAtMessage?.id,
//                inclusive: included,
//                fetchDirection: .ascending
//            )
//        case .descending(let startAtMessage, let included):
//            return try await FirebaseChatService.shared.fetchMessagesFromChat(
//                chatID: conversation.id,
//                startingFrom: startAtMessage?.id,
//                inclusive: included,
//                fetchDirection: .descending
//            )
//        case .hybrit(let startAtMessage):
//            let descendingMessages = try await FirebaseChatService.shared.fetchMessagesFromChat(
//                chatID: conversation.id,
//                startingFrom: startAtMessage.id,
//                inclusive: true,
//                fetchDirection: .descending
//            )
//            let ascendingMessages = try await FirebaseChatService.shared.fetchMessagesFromChat(
//                chatID: conversation.id,
//                startingFrom: startAtMessage.id,
//                inclusive: false,
//                fetchDirection: .ascending
//            )
//            return descendingMessages + ascendingMessages
//        default: return []
//        }
//    }
//    
//    func loadAdditionalMessages(inAscendingOrder ascendingOrder: Bool,
//                                        startMessage: Message) async throws -> [Message]
//    {
//        switch ascendingOrder {
//        case true: return try await fetchConversationMessages(using: .ascending(startAtMessage: startMessage, included: false))
//        case false: return try await fetchConversationMessages(using: .descending(startAtMessage: startMessage, included: false))
//        }
//    }
//    
//    @MainActor
//    private func determineFetchStrategy() async throws -> MessageFetchStrategy
//    {
//        if let firstUnseenMessage = try await firestoreService.getFirstUnseenMessageFromFirestore(from: conversation.id)
//        {
//            return isChatFetchedFirstTime ? .hybrit(startAtMessage: firstUnseenMessage) : .ascending(startAtMessage: firstUnseenMessage, included: true)
//        }
//        
//        if let lastSeenMessage = conversation.getLastMessage()
//        {
//            return .descending(startAtMessage: lastSeenMessage, included: true)
//        }
//
//        return .none // would trigger only if isChatFetchedFirstTime and chat is empty
//    }
//}

//
//class MessageClusterManager {
//    
//    @Published var messageClusters: [MessageCluster]
//    
//    init(messageCluster: MessageCluster) {
//        self.messageClusters = messageCluster
//    }
//
//        private func createMessageClustersWith(_ messages: [Message], ascending: Bool? = nil)
//        {
//            var dateToIndex = Dictionary(uniqueKeysWithValues: self.messageClusters.enumerated().map { ($0.element.date, $0.offset) })
//            var tempMessageClusters = self.messageClusters
//
//            messages.forEach { message in
//                guard let date = message.timestamp.formatToYearMonthDay() else { return }
//                let messageItem = MessageItem(message: message)
//
//                if let index = dateToIndex[date] {
//                    ascending == true
//                        ? tempMessageClusters[index].items.insert(messageItem, at: 0)
//                        : tempMessageClusters[index].items.append(messageItem)
//                } else {
//                    let newCluster = MessageCluster(date: date, items: [messageItem])
//                    if ascending == true {
//                        tempMessageClusters.insert(newCluster, at: 0)
//                        dateToIndex[date] = 0
//                    } else {
//                        tempMessageClusters.append(newCluster)
//                        dateToIndex[date] = tempMessageClusters.count - 1
//                    }
//                }
//            }
//            self.messageClusters = tempMessageClusters
//        }
//
//        @MainActor
//        private func prepareMessageClustersUpdate(withMessages messages: [Message], inAscendingOrder: Bool) async throws -> ([IndexPath], IndexSet?)
//        {
//            let messageClustersBeforeUpdate = messageClusters
//            let startSectionCount = inAscendingOrder ? 0 : messageClusters.count
//            
//            createMessageClustersWith(messages, ascending: inAscendingOrder)
//            
//            let endSectionCount = inAscendingOrder ? (messageClusters.count - messageClustersBeforeUpdate.count) : messageClusters.count
//            
//            let newRows = findNewRowIndexPaths(inMessageClusters: messageClustersBeforeUpdate, ascending: inAscendingOrder)
//            let newSections = findNewSectionIndexSet(startSectionCount: startSectionCount, endSectionCount: endSectionCount)
//            
//            return (newRows, newSections)
//        }
//        
//        @MainActor
//        func handleAdditionalMessageClusterUpdate(inAscendingOrder order: Bool) async throws -> ([IndexPath], IndexSet?)? {
//            
//            let newMessages = try await loadAdditionalMessages(inAscendingOrder: order)
//            guard !newMessages.isEmpty else { return nil }
//            
//            let (newRows, newSections) = try await prepareMessageClustersUpdate(withMessages: newMessages, inAscendingOrder: order)
//            
//            if let timestamp = newMessages.first?.timestamp
//            {
//                messageListenerService.addListenerToExistingMessages(startAtTimestamp: timestamp, ascending: order)
//            }
//            realmService.addMessagesToConversationInRealm(newMessages)
//            
//            return (newRows, newSections)
//        }
//        
//        private func findNewRowIndexPaths(inMessageClusters messageClusters: [MessageCluster], ascending: Bool) -> [IndexPath]
//        {
//            guard let sectionBeforeUpdate = ascending ? messageClusters.first?.items : messageClusters.last?.items else {return []}
//            
//            let sectionIndex = ascending ? 0 : messageClusters.count - 1
//            
//            return self.messageClusters[sectionIndex].items
//                .enumerated()
//                .compactMap { index, viewModel in
//                    return sectionBeforeUpdate.contains { $0.message == viewModel.message }
//                    ? nil
//                    : IndexPath(row: index, section: sectionIndex)
//                }
//        }
//        
//        private func findNewSectionIndexSet(startSectionCount: Int, endSectionCount: Int) -> IndexSet?
//        {
//            return (startSectionCount < endSectionCount)
//            ? IndexSet(integersIn: startSectionCount..<endSectionCount)
//            : nil
//        }
//}
