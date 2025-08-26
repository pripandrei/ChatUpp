
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
import RealmSwift

class ChatRoomViewModel : SwiftUI.ObservableObject
{
    private(set) var setupConversationTask: Task<Void, Never>?
    
    private(set) var remoteMessagePaginator = RemoteMessagePaginator()
    
    private(set) var realmService: ConversationRealmService?
    //    private(set) var messageFetcher : ConversationMessageFetcher
    private(set) var firestoreService: ConversationFirestoreService?
    private(set) var userListenerService : ConversationUsersListinerService?
    private(set) var messageListenerService : ConversationMessageListenerService?
    
    private(set) var conversation        : Chat?
    private(set) var participant         : User?
    private(set) var messageClusters     : [MessageCluster] = []
    private(set) var authUser            : AuthenticatedUserData = (try! AuthenticationManager.shared.getAuthenticatedUser())
    private(set) var lastPaginatedMessage: Message?
    private var cancellables             = Set<AnyCancellable>()
    
    @Published private(set) var unseenMessagesCount: Int
    @Published private(set) var messageChangedTypes: Set<MessageChangeType> = []
    private(set) var datasourceUpdateType = PassthroughSubject<DatasourceRowAnimation, Never>()
    @Published private(set) var schedualedMessagesForRemoval: Set<Message> = []
    @Published private(set) var conversationInitializationStatus: ConversationInitializationStatus?
    
    @MainActor
    @Published var isLocalPaginationActive: Bool = false
    @MainActor
    @Published private var deletedMessageIDs: [String] = []

    var shouldEditMessage: ((String) -> Void)?
    var currentlyReplyToMessageID: String?
    
    private var recentMessageItem: MessageItem? {
        return messageClusters.first?.items.first
    }
    
    var conversationExists: Bool {
        return self.conversation != nil
    }
    
    var authParticipantUnreadMessagesCount: Int
    {
        conversation?.participants.first(where: { $0.userID == authUser.uid })?.unseenMessagesCount ?? 0
    }
    
    var isAuthUserGroupMember: Bool
    {
        guard let conversation = conversation,
              conversation.realm != nil,
              let _ = conversation.participants.filter("userID == %@", authUser.uid).first else { return false }
        if conversation.isGroup { return true }
        else { return false }
    }

    var shouldHideJoinGroupOption: Bool
    {
        if conversation?.isGroup == true
        {
            guard conversation?.realm != nil else { return false }
            let isAuthUserChatParticipant = !conversation!.participants.filter("userID == %@", authUser.uid).isEmpty
            return isAuthUserChatParticipant
        } else {
            return true
        }
    }
    
    deinit {
        print("chat room View model deinit")
    }
    
    var shouldAttachListenerToUpcomingMessages: Bool
    {
        /// See FootNote.swift [7]
        self.shouldDisplayLastMessage
    }
        
    func getMessageSender(_ senderID: String) -> User?
    {
        return RealmDataBase.shared.retrieveSingleObject(ofType: User.self, primaryKey: senderID)
    }
    
    private lazy var authenticatedUser: User? = {
        guard let key = AuthenticationManager.shared.authenticatedUser?.uid else { return nil }
        return RealmDataBase.shared.retrieveSingleObject(ofType: User.self, primaryKey: key)
    }()
    
    private var isChatFetchedFirstTime: Bool
    {
        return conversation?.conversationMessages.count == 1
    }
    
    private var shouldDisplayLastMessage: Bool
    {
        return authParticipantUnreadMessagesCount <= (realmService?.getUnreadMessagesCountFromRealm() ?? 0)
    }
    
    private var firstMessage: Message? {
        conversation?.getFirstMessage()
    }
    
    var shouldFetchNewMessages: Bool
    {
        guard conversation?.realm != nil else {
            return true
        }
        
        let localMessageCount = conversation?.conversationMessages.count ?? 0
        
        if localMessageCount == 1 {
            return true
        } else if localMessageCount == 0 {
            return false
        }
        
        // Compare local and global/remote unread message counts
        let localUnreadMessageCount = realmService?.getUnreadMessagesCountFromRealm() ?? 0
        return (authParticipantUnreadMessagesCount != localUnreadMessageCount)
//        && localUnreadMessageCount <= 20
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
    
    private func getPrivateChatMember(from chat: Chat) -> User?
    {
        guard let memberID = chat.participants.first(where: { $0.userID != authUser.uid })?.userID,
              let user = RealmDataBase.shared.retrieveSingleObject(ofType: User.self, primaryKey: memberID) else { return nil }
        return user
    }
    
    /// - Life cycle
    
    init(conversation: Chat)
    {
        self.conversation = conversation
        self.unseenMessagesCount = conversation.getParticipant(byID: authUser.uid)?.unseenMessagesCount ?? 0
        self.setupServices(using: conversation)
        
        if !conversation.isGroup {
            self.participant = getPrivateChatMember(from: conversation)
        }
        // REVERT BACK
        bindToMessages()
//        bindToDeletedMessages()
        initiateConversation()
        ChatRoomSessionManager.activeChatID = conversation.id
//       testMessagesCountAndUnseenCount() //
    }
    
    init(participant: User?)
    {
        self.participant = participant
        self.unseenMessagesCount = 0
    }
    
    private func observeParticipantChanges()
    {
        guard let chat = conversation else {return}
        guard let participant = chat.getParticipant(byID: authUser.uid) else {return}
        
        RealmDataBase.shared.observeChanges(for: participant)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] change in
                guard let self = self, change.0.name == "unseenMessagesCount" else { return }
                
                self.unseenMessagesCount = change.0.newValue as? Int ?? self.unseenMessagesCount
            }.store(in: &cancellables)
    }

    /// - listeners
    
    func addListeners()
    {
        guard conversation?.realm != nil else {return}
        
//        userListenerService?.addUsersListener()
//        userListenerService?.addUserObserver()
        observeParticipantChanges()
         
        guard let startMessage = messageClusters.first?.items.first?.message
        else {return}

        // Attach listener to upcoming messages only if all unseen messages
        // (if any) have been fetched locally
        if self.shouldAttachListenerToUpcomingMessages
        {
            messageListenerService?.addListenerToUpcomingMessages()
        }
        
        let totalMessagesCount = messageClusters.reduce(0) { total, cluster in
            total + cluster.items.filter { $0.message != nil }.count
        }
        messageListenerService?.addListenerToExistingMessagesTest(startAtMesssage: startMessage, ascending: false, limit: totalMessagesCount)
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
        
        let text = GroupEventMessage.userJoined.eventMessage
        let newMessage = createNewMessage(ofType: .title, messageText: text)
        
        try await FirebaseChatService.shared.createMessage(message: newMessage,
                                                           atChatPath: conversation.id)
        await firestoreService?.updateRecentMessageFromFirestoreChat(messageID: newMessage.id)
        updateUnseenMessageCounterLocally()
        updateUnseenMessageCounterRemote()
        
        var messages = getCurrentMessagesFromCluster()
        messages.insert(newMessage, at: 0)
        
        realmService?.addMessagesToConversationInRealm(messages)
        
        createMessageClustersWith([newMessage])
        messageChangedTypes = [.added(IndexPath(row: 0, section: 0))]
        
        //Add new chat row
        
        ChatManager.shared.broadcastJoinedGroupChat(conversation)
//        NotificationCenter.default.post(name: .didJoinNewChat,
//                                        object: nil,
//                                        userInfo: ["chatID": conversation.id])
        addListeners()
    }
    
    private func getCurrentMessagesFromCluster() -> [Message]
    {
        let messages: [Message] = messageClusters.flatMap { cluster in
            cluster.items.compactMap { item in
                item.message
            }
        }
        return messages
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
        let recentMessageID = recentMessageItem?.message?.id
        let messagesCount = messageClusters.first?.items.count
        
        return Chat(
            id: chatId,
            participants: participants,
            recentMessageID: recentMessageID,
            messagesCount: messagesCount,
            isFirstTimeOpened: false
        )
    }

    func setupConversation()
    {
        guard let chat = createChat() else {return}
        
        self.conversation = chat
        
        setupServices(using: chat)
        
        realmService?.addChatToRealm(chat)
        
        let freezedChat = chat.freeze()
        
        self.setupConversationTask = Task(priority: .high) { @MainActor in
            await firestoreService?.addChatToFirestore(freezedChat)
//            setupMessageListenerOnChatCreation()
            bindToMessages()
            bindToDeletedMessages()
            addListeners()
        }
        ChatManager.shared.broadcastNewCreatedChat(chat)
        
        ChatRoomSessionManager.activeChatID = chat.id
    }
    
    func createNewMessage(ofType type: MessageType = .text,
                          messageText: String? = nil,
                          imagePath: String? = nil) -> Message
    {
        let isGroupChat = conversation?.isGroup == true
        let authUserID = AuthenticationManager.shared.authenticatedUser!.uid
        let seenByValue = (isGroupChat && type != .title) ? [authUserID] : nil
        let messageText = (messageText != nil) ? messageText! : ""
 
        return Message(
            id: UUID().uuidString,
            messageBody: messageText,
            senderId: authUserID,
            timestamp:  Date(),
            messageSeen: isGroupChat ? nil : false,
            seenBy: seenByValue,
            isEdited: false,
            imagePath: imagePath,
            imageSize: nil,
            repliedTo: currentlyReplyToMessageID,
            type: type
        )
    }
    
    @MainActor
    func handleLocalUpdatesOnMessageCreation(_ message: Message,
                                             imageRepository: ImageSampleRepository? = nil)
    {
        realmService?.addMessagesToRealmChat([message])
        updateUnseenMessageCounterLocally()
    }
    
    @MainActor
    func initiateRemoteUpdatesOnMessageCreation(_ message: Message,
                                                imageRepository: ImageSampleRepository? = nil) async
    {
        await self.setupConversationTask?.value /// await for chat to be remotely created before proceeding, if any
        if let imageRepository { // if message contains image add it first
            await saveImagesRemotelly(fromImageRepository: imageRepository,
                                      for: message.id)
        }
        await firestoreService?.addMessageToFirestoreDataBase(message)
//        updateUnseenMessageCounterRemote(shouldIncrement: true)
        updateUnseenMessageCounterRemote()
        await firestoreService?.updateRecentMessageFromFirestoreChat(messageID: message.id)
    }
    
    private func setupMessageListenerOnChatCreation()
    {
        guard let message = conversation?.getLastMessage(),
              let limit = conversation?.conversationMessages.count else { return }

        messageListenerService?.addListenerToExistingMessagesTest(
            startAtMesssage: message,
            ascending: true,
            limit: limit)
    }
    
    /// unseen messages counter update
    ///
    @MainActor
    func updateUnseenMessageCounterLocally()
    {
        guard let conversation = self.conversation else { return }
        RealmDataBase.shared.refresh()
        let authUserID = self.authUser.uid
        let count = realmService?.getUnreadMessagesCountFromRealm() ?? 0
        
        RealmDataBase.shared.update(object: conversation) { dbChat in
            if let participant = dbChat.getParticipant(byID: authUserID)
            {
                participant.unseenMessagesCount = count
            }
        }
    }
    
    //    @MainActor
    func updateUnseenMessageCounterRemote()
    {
        guard let conversationID = self.conversation?.id else { return }
        let authUserID = self.authUser.uid
        let count = realmService?.getUnreadMessagesCountFromRealm() ?? 0
        
        Task.detached {
            do {
                try await FirebaseChatService.shared.updateUnseenMessagesCount(
                    for: [authUserID],
                    inChatWithID: conversationID,
                    counter: count
                )
            } catch {
                print("Error updating unseen messages counter remote: ", error)
            }
        }
    }
    
    /// Message seen status update
    ///
    func updateFirebaseMessagesSeenStatus(startingFrom startMessage: Message)
    {
        guard let chatID = conversation?.id else { return }
        let authUserID = authUser.uid
        let isGroup = conversation?.isGroup ?? false
        let startMessageTimestamp = startMessage.timestamp
        
        Task.detached
        {
            do {
                try await FirebaseChatService
                    .shared
                    .updateMessagesSeenStatus(startFromTimestamp: startMessageTimestamp,
                                              seenByUser: isGroup ? authUserID : nil,
                                              chatID: chatID)
            } catch {
                print("Could not update messages seen status in firebase: ", error)
            }
        }
    }
    
    @MainActor
    func updateRealmMessagesSeenStatus(startingFromMessage message: Message) async
    {
        guard let chatID = conversation?.id else {return}
        let authUserID = authUser.uid
        let isGroup = conversation?.isGroup ?? false
        let timestamp = message.timestamp
        
        await Task.detached
        {
            guard let chat = RealmDataBase.shared.retrieveSingleObjectTest(
                ofType: Chat.self,
                primaryKey: chatID) else {
                return
            }
            
            let filter = NSPredicate(format: "timestamp <= %@ AND messageSeen == false", timestamp as NSDate)
            let messages = chat.conversationMessages
                .filter(filter)
                .sorted(byKeyPath: "timestamp", ascending: false)

            RealmDataBase.shared.update
            {
                for message in messages
                {
                    if message.messageSeen == true || message.seenBy.contains(authUserID) { break }
                    
                    if isGroup {
                        message.seenBy.append(authUserID)
                        continue
                    }
                    message.messageSeen = true
                }
            }
        }.value
    }
    
    /// - unseen message manage
    ///
    func findLastUnseenMessageIndexPath() -> IndexPath? {
        for (sectionIndex, messageGroup) in messageClusters.enumerated().reversed() {
            if let rowIndex = messageGroup.items.lastIndex(where: { $0.message?.messageSeen == false }) {
                return IndexPath(row: rowIndex, section: sectionIndex)
            }
        }
        return nil
    }
    
    func insertUnseenMessagesTitle(afterIndexPath indexPath: IndexPath)
    {
        let conversationCellVM = MessageCellViewModel(isUnseenCell: true)
        messageClusters[indexPath.section].items.insert(conversationCellVM, at: indexPath.row + 1)
    }
    
    func clearMessageChanges() {
        Task {
            await MainActor.run {
                messageChangedTypes.removeAll()
            }
        }
    }
    
    //TODO: - the whole function should be refactored along with reaction model, for better querying
    @MainActor
    func updateReactionInDataBase(_ reactionEmoji: String, from message: Message)
    {
        RealmDataBase.shared.update(object: message) { realmMessage in
            // Step 1: Check if user already reacted with any emoji
            var didRemove = false

            for reaction in realmMessage.reactions
            {
                if let index = reaction.userIDs.firstIndex(of: authUser.uid)
                {
                    // User already reacted to this message
                    reaction.userIDs.remove(at: index)
                    
                    if reaction.emoji == reactionEmoji
                    {
                        // Same emoji → toggle off (remove)
                        didRemove = true
                    }

                    // Clean up empty reaction
                    if let index = realmMessage.reactions.firstIndex(where: {  $0.userIDs.isEmpty }) {
                        realmMessage.reactions.remove(at: index)
                    }
                    break
                }
            }

            // Step 2: Add new reaction only if we didn't just toggle off the same one
            if !didRemove {
                if let existing = realmMessage.reactions.first(where: { $0.emoji == reactionEmoji }) {
                    existing.userIDs.append(authUser.uid)
                } else {
                    let newReaction = Reaction()
                    newReaction.emoji = reactionEmoji
                    newReaction.userIDs.append(authUser.uid)
                    realmMessage.reactions.append(newReaction)
                }
            }
        }

        // Step 3: Sync to Firebase
        let reactions = message.mapEncodedReactions(message.reactions)
        guard let conversation = conversation else { return }
        Task {
            do {
                try await FirebaseChatService.shared.updateMessageReactions(
                    reactions,
                    messageID: message.id,
                    chatID: conversation.id
                )
            } catch {
                print("Could not update reaction in firestore db: \(error)")
            }
        }
    }
    
    /// - save image from message

    func saveImagesLocally(fromImageRepository imageRepository: ImageSampleRepository,
                           for messageID: String) async
    {
        await withTaskGroup(of: Void.self) { group in
            for (key, imageData) in imageRepository.samples {
                let path = imageRepository.imagePath(for: key)
                group.addTask(priority: .utility) {
                    CacheManager.shared.saveImageData(imageData, toPath: path)
                    print("Cached image: \(imageData) \(path)")
                }
            }
        }
    }

    func saveImagesRemotelly(fromImageRepository imageRepository: ImageSampleRepository,
                             for messageID: String) async
    {
        await withTaskGroup(of: Void.self) { group in
            for (key, imageData) in imageRepository.samples
            {
                let path = imageRepository.imagePath(for: key)
                group.addTask {
                    do {
                        try await FirebaseStorageManager
                            .shared
                            .saveImage(data: imageData,
                                       to: .message(messageID),
                                       imagePath: path)
                        print("Saved Image with path: \(path)")
                    } catch {
                        print("Error in uploading images: \(error)")
                    }
                }
            }
            await group.waitForAll()
        }
    }
    
    // fetch image from message
    
    @MainActor
    private func downloadImageData(from message: Message) async
    {
        guard let path = message.imagePath else { return }
        let smallPath = path.addSuffix("small")
        let paths = [path, smallPath]
        
        do {
            for path in paths {
                let imageData = try await FirebaseStorageManager.shared.getImage(from: .message(message.id), imagePath: path)
                if message.senderId == "ArzzEyzTb7QRD5LhxIX3B5xqsql1"
                {
                    print("stop")
                }
                CacheManager.shared.saveImageData(imageData, toPath: path)
            }
        } catch {
            print("Could not fetch message image data: ", error)
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
            
            await self.fetchMessagesMetadata(Set(messages))
            
            if conversation?.isGroup == true
            {
                await syncGroupUsers(for: messages)
                
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
        
        var messages = prepareMessagesForConversationInitialization()
        guard !messages.isEmpty else {return}
        
        if !shouldDisplayLastMessage {
            messages.removeLast()
        }
        createMessageClustersWith(messages)
        validateMessagesForDeletion(messages)
    }
    
    private func prepareMessagesForConversationInitialization() -> [Message]
    {
        guard let conversation = conversation else { return [] }
        if let message = getFirstUnseenMessage()
        {
            let messagesAscending = conversation.getMessages(
                startingFrom: message.id,
                isMessageIncluded: true,
                ascending: true)
            
            let messagesDescending = conversation.getMessages(
                startingFrom: message.id,
                isMessageIncluded: false,
                ascending: false).reversed() /// since table view is inverted, reverse messages here
            return Array(messagesDescending + messagesAscending)
        } else {
            let limit = ObjectsPaginationLimit.localMessages * 2
            let messages = conversation.getMessagesResults().prefix(limit).reversed()
            return Array(messages)
        }
    }
    
    func paginateAdditionalLocalMessages(ascending: Bool) -> Bool
    {
        guard conversation?.realm != nil else {return false} // if group chat that we are not member of is opened
        
        var paginatedMessages = prepareAdditionalMessagesForConversation(ascending: ascending)
        let recentMessageIsPresent = paginatedMessages.contains(where: { $0.id == conversation?.recentMessageID })
        
        if recentMessageIsPresent
        {
            if paginatedMessages.count > 1 && shouldFetchNewMessages
            {
                paginatedMessages = paginatedMessages.dropLast() // drop recent message. See FootNote.swift [8]
            }
            else if shouldFetchNewMessages
            {
                return false
            }
        }
        
        if !paginatedMessages.isEmpty
        {
//            let clusterSnapshot = messageClusters
            createMessageClustersWith(paginatedMessages)
//            let (newRows, newSections) = getIndexPathsForAdditionalMessages(fromClusterSnapshot: clusterSnapshot)
            self.lastPaginatedMessage = paginatedMessages.last
            self.validateMessagesForDeletion(paginatedMessages)
//            return (newRows, newSections)
            return true
        }
        return false
    }
    
//    func paginateAdditionalLocalMessages(ascending: Bool) -> ([IndexPath], IndexSet?)?
//    {
//        guard conversation?.realm != nil else {return nil} // if group chat that we are not member of is opened
//        
//        var paginatedMessages = prepareAdditionalMessagesForConversation(ascending: ascending)
//        let recentMessageIsPresent = paginatedMessages.contains(where: { $0.id == conversation?.recentMessageID })
//        
//        if recentMessageIsPresent
//        {
//            if paginatedMessages.count > 1 && shouldFetchNewMessages
//            {
//                paginatedMessages = paginatedMessages.dropLast() // drop recent message. See FootNote.swift [8]
//            }
//            else if shouldFetchNewMessages
//            {
//                return nil
//            }
//        }
//        
//        if !paginatedMessages.isEmpty
//        {
//            let clusterSnapshot = messageClusters
//            createMessageClustersWith(paginatedMessages)
//            let (newRows, newSections) = getIndexPathsForAdditionalMessages(fromClusterSnapshot: clusterSnapshot)
//            self.lastPaginatedMessage = paginatedMessages.last
//            self.validateMessagesForDeletion(paginatedMessages)
//            return (newRows, newSections)
//        }
//        return nil
//    }
    
    private func prepareAdditionalMessagesForConversation(ascending: Bool) -> [Message]
    {
        guard let conversation = conversation else { return [] }
        
        if ascending
        {
            guard let startMessage = messageClusters[0].items.first?.message
            else {return [] }
            
            let messages = conversation.getMessages(startingFrom: startMessage.id,
                                                    isMessageIncluded: false,
                                                    ascending: ascending)
            return messages
        }
        
        let messageClustersCount = messageClusters.count
        guard let startMessage = messageClusters[messageClustersCount - 1].items.last?.message
        else {return [] }

        let messages = conversation.getMessages(startingFrom: startMessage.id,
                                                isMessageIncluded: false,
                                                ascending: ascending)
        return messages
    }
    
    private func getFirstUnseenMessage() -> Message?
    {
        let unseenMessage = conversation?.conversationMessages
            .filter("messageSeen == false AND senderId != %@", authUser.uid)
            .sorted(byKeyPath: Message.CodingKeys.timestamp.rawValue, ascending: true)
            .first
        
        return unseenMessage
    }
    
    private func initializeWithMessages(_ messages: [Message])
    {
        if !messages.isEmpty
        {
            createMessageClustersWith(messages.reversed())
        }
        conversationInitializationStatus = .finished
    }
    
    // MARK: - Messages check for deletion
    
    /// See FootNote.swift [6]
    ///
    private func bindToDeletedMessages()
    {
        $deletedMessageIDs
            .debounce(for: 2.0, scheduler: DispatchQueue.main)
            .filter { !$0.isEmpty }
            .sink { [weak self] messageIDs in
                
                guard let self else {return}
                
                Task { @MainActor in
                    await self.isPaginationInactiveStream.first(where: { true })
                    
                    guard let messagesToDelete = RealmDataBase
                        .shared
                        .retrieveObjects(ofType: Message.self,
                                         filter: NSPredicate(format: "id IN %@", messageIDs)) else {return}
                    
                    // TODO: - fix this also
//                    let modificationTypes = await self.processRemovedMessages(Set(messagesToDelete))
//                    
//                    self.deletedMessageIDs.removeAll()
//                    self.changedTypesOfRemovedMessages = modificationTypes
                }
            }.store(in: &cancellables)
    }
    
    private func validateMessagesForDeletion(_ messages: [Message])
    {
        guard let chatID = conversation?.id else {return}
        let messageIDs = messages.map { $0.id }
        
        Task { @MainActor in
            do {
                let messageIDsForDeletion = try await FirebaseChatService
                    .shared
                    .validateMessagesForDeletion(messageIDs: messageIDs,
                                                 in: chatID)
                guard !messageIDsForDeletion.isEmpty else {return}
                
                self.deletedMessageIDs.append(contentsOf: messageIDsForDeletion)
            } catch {
                print("Could not check messages for deletion: \(error)")
            }
        }
    }
    
    private var isPaginationInactiveStream: AsyncStream<Void>
    {
        AsyncStream { continuation in
            let cancelable = $isLocalPaginationActive
                .filter { !$0 }
                .sink { _ in
                    continuation.yield()
                    continuation.finish()
                }
            
            continuation.onTermination = { _ in
                cancelable.cancel()
            }
        }
    }
    
    // MARK: - Group users data fetch
    @MainActor
    private func syncGroupUsers(for messages: [Message]) async
    {
        do {
            let senderIDs = Set(messages.map(\.senderId))
           
            let missingUserIDs = findMissingUserIDs(senderIDs)
            
            if !missingUserIDs.isEmpty
            {
                let users = try await FirestoreUserService.shared.fetchUsers(with: missingUserIDs)
                RealmDataBase.shared.add(objects: users)
            }
            
            let srotedUsersForImageFetch = self.getUsersWithMissingLocalAvatars(senderIDs)
            
            await fetchAvatars(for: srotedUsersForImageFetch)
        } catch {
            print("Error in synchronizing users from messages: ", error)
        }
    }
    
    @MainActor
    private func getUsersWithMissingLocalAvatars(_ usersIDs: Set<String>) -> [User]
    {
        return getRealmUsers(with: usersIDs)
            .compactMap { user -> User? in
                guard let path = user.photoUrl else { return nil }
                if !CacheManager.shared.doesImageExist(at: path) {
                    return user
                }
                return nil
            }
    }

    @MainActor
    private func findMissingUserIDs(_ ids: Set<String>) -> [String]
    {
        let existingUsersIDs = getRealmUsers(with: ids).map(\.id)
        
        return Array(ids.subtracting(existingUsersIDs))
    }
    
    private func getRealmUsers(with userIDs: Set<String>) -> [User] {
        let filter = NSPredicate(format: "id IN %@", Array(userIDs))
        return RealmDataBase.shared.retrieveObjects(ofType: User.self, filter: filter)?.toArray() ?? []
    }
    
    @MainActor
    private func fetchAvatars(for users: [User]) async
    {
        await withTaskGroup(of: Void.self) { group in
            for user in users
            {
                let userID = user.id
                guard let avatarURL = user.photoUrl else { continue }
                
                group.addTask {
                    do {
                        let smallPath = avatarURL.addSuffix("small")
                        let paths = [avatarURL, smallPath]
                        for path in paths {
                            let imageData = try await FirebaseStorageManager.shared.getImage(
                                from: .user(userID),
                                imagePath: path)
                            CacheManager.shared.saveImageData(imageData, toPath: path)
                        }
                    } catch {
                        print("Error fetching avatar image data for user: \(userID); Error: \(error)")
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
    private func bindToMessages() {
        messageListenerService?.$updatedMessages
            .debounce(for: .seconds(0.4),
                      scheduler: DispatchQueue.global(qos: .background))
            .filter { !$0.isEmpty }
            .sink { [weak self] messagesTypes in
                guard let self = self else { return }
                Task {
                    guard self.conversation?.isInvalidated == false else {return} // See FootNote.swift [11]
                    await self.remoteMessagePaginator.perform {
                        await self.processMessageChanges(messagesTypes)
                    }
                }
            }
            .store(in: &cancellables)
    }
}

//MARK: - Messages update handlers
extension ChatRoomViewModel
{
//    private func processMessageChanges2(_ messagesTypes: [DatabaseChangedObject<Message>])
//    {
//        for type in messagesTypes
//        {
//            switch type.changeType
//            {
//            case .added:
//            case .modified:
//            case .removed:
//            }
//        }
//    }
    
    private func processMessageChanges(_ messagesTypes: [DatabaseChangedObject<Message>]) async
    {
        // Group messages by change type
        let groupedMessages = Dictionary(grouping: messagesTypes) { $0.changeType }
        
        let removedMessages = Set(groupedMessages[.removed]?.map(\.data) ?? [])
        let modifiedMessages = Set(groupedMessages[.modified]?.map(\.data) ?? [])
        let addedMessages = Set(groupedMessages[.added]?.map(\.data) ?? [])
        
        // Filter out messages that are also being removed
        let removedIDs = Set(removedMessages.map(\.id))
        let filteredModified = modifiedMessages.filter { !removedIDs.contains($0.id) }
        let filteredAdded = addedMessages.filter { !removedIDs.contains($0.id) }
        
        await fetchMessagesMetadata(filteredAdded)
      
        // wait for message pagination to finish if any
        await isPaginationInactiveStream.first(where: { true })
        
        await self.handleRemovedMessages(Array(removedMessages))
        await self.handleAddedMessages(Array(filteredAdded))
        await self.handleModifiedMessage(Array(filteredModified))
        
        // Process changes in order: remove, modify, add
//        let removedTypes = await processRemovedMessages(removedMessages)
//        let modifiedTypes = await processModifiedMessages(filteredModified)
//        let addedTypes = await processAddedMessages(filteredAdded)
        
        // Combine all changes and update
//        let allChanges: Set<MessageChangeType> = removedTypes.union(modifiedTypes.union(addedTypes))
//        
//        self.messageChangedTypes = allChanges
//        self.updatedItems = []

//         Clear processed messages
        self.messageListenerService?.updatedMessages.removeAll()
    }

//    @MainActor
//    private func processRemovedMessages(_ messages: Set<Message>) async -> Set<MessageChangeType>
//    {
//        let sortedIndexPaths = messages
//            .compactMap { self.indexPath(of: $0) }
//            .sorted(by: >)
//        let changeTypes = sortedIndexPaths.compactMap { self.handleRemovedMessage(at: $0) }
//        return Set(changeTypes)
//    }

//    @MainActor
//    private func processModifiedMessages(_ messages: Set<Message>) async -> Set<MessageChangeType>
//    {
//        return Set(messages.compactMap { message in
//            guard let indexPath = self.indexPath(of: message) else { return nil }
//            return self.handleModifiedMessage(message, at: indexPath)
//        })
//    }
//
//    @MainActor
//    private func processAddedMessages(_ messages: Set<Message>) async -> Set<MessageChangeType>
//    {
//        // Separate messages that already exist vs new ones
//        let (existingMessages, newMessages) = messages.reduce(into: ([Message](), [Message]())) { result, message in
//            if let dbMessage = RealmDataBase.shared.retrieveSingleObjectTest(ofType: Message.self, primaryKey: message.id)
//            {
//                /// See FootNote.swift [12]
//                var updatedMessage = message
//                if (dbMessage.messageSeen == true && message.messageSeen == false) ||  (dbMessage.seenBy.contains(authUser.uid) && !message.seenBy.contains(authUser.uid))
//                {
//                    updatedMessage = message.updateSeenStatus(seenStatus: true)
//                }
//                result.0.append(updatedMessage)
//            } else {
//                result.1.append(message)
//            }
//        }
//        
//        // Add existing messages to database
//        if !existingMessages.isEmpty
//        {
//            RealmDataBase.shared.add(objects: existingMessages)
//        }
//        
////        // Process new messages concurrently
//        await self.handleAddedMessage(newMessages)
//
//        // Create change types for all added messages
//        return Set(newMessages
//            .compactMap { newMessage in
//                //TODO: check if messages are paginated up to most recent one
//                self.indexPath(of: newMessage)
//            }
//            .map { MessageChangeType.added($0) })
//    }
    

    /// Use this variable before updating realm with new message
    var isMostRecentMessagePaginated: Bool
    {
        conversation?.getLastMessage()?.id == messageClusters[0].items[0].message?.id ? true : false
    }
    
    var isChatRecentMessagePaginated: Bool
    {
        guard let dataSourceFirstMessage = self.messageClusters[0].items[0].message else
        {
            return true
        }
        return dataSourceFirstMessage.id == conversation?.recentMessageID ?
        true : false
    }
    
}

// MARK: - Message listener helper functions

extension ChatRoomViewModel
{
    @MainActor
    private func handleAddedMessages(_ messages: [Message]) async
    {
        guard !messages.isEmpty else {return}
        var newMessages = [Message]()
        var updatedMessages = [Message]()
        
        for message in messages
        {
            if let dbMessage = RealmDataBase.shared.retrieveSingleObjectTest(
                ofType: Message.self,
                primaryKey: message.id)
            {
                /// See FootNote.swift [12]
                if (dbMessage.messageSeen == true && message.messageSeen == false) ||  (dbMessage.seenBy.contains(authUser.uid) && !message.seenBy.contains(authUser.uid))
                {
                    let updatedMessage = message.updateSeenStatus(seenStatus: true)
                    updatedMessages.append(updatedMessage)
                }
            } else {
                newMessages.append(message)
            }
        }
        
        RealmDataBase.shared.add(objects: updatedMessages)
        realmService?.addMessagesToRealmChat(newMessages)
        createMessageClustersWith(newMessages)
        if newMessages.count == 1 {
            datasourceUpdateType.send(DatasourceRowAnimation.none)
        } else if newMessages.count > 1 {
            datasourceUpdateType.send(DatasourceRowAnimation.top)
        }
        
        if !updatedMessages.isEmpty {
            datasourceUpdateType.send(DatasourceRowAnimation.left)
        }
//        let cellVMs = createMessageClustersWith(newMessages)
//        self.updatedItems2 = .added(cellVMs)
    }
    
    @MainActor
    private func handleRemovedMessages(_ messages: [Message])
    {
        guard !messages.isEmpty else {return}
//        var removedVMs = [MessageCellViewModel]()
        for message in messages
        {
            let day = message.timestamp.formatToYearMonthDay()
            guard let clusterIndex = messageClusters.firstIndex(where: { $0.date == day }) else {continue}
        
            guard let cellVMIndex = messageClusters[clusterIndex].items.firstIndex(where: {  $0.message?.id == message.id } ) else {continue}
            
            let _ = messageClusters[clusterIndex].items.remove(at: cellVMIndex)
//            removedVMs.append(removedVM)
            
//            messageClusters[clusterIndex].items.removeAll(where: { $0.message?.id == message.id })
            
            if messageClusters[clusterIndex].items.isEmpty {
                messageClusters.remove(at: clusterIndex)
            }
            
            if clusterIndex == 0 && cellVMIndex == 0,
               let recentMessageID = recentMessageItem?.message?.id
            {
                Task {
                    await firestoreService?.updateRecentMessageFromFirestoreChat(messageID: recentMessageID)
                }
            }
            
        }
        realmService?.removeMessagesFromRealm(messages: messages)
        
        self.datasourceUpdateType.send(.fade)
        
//        let items = MessagesUpdateType.removed(removedVMs)
//        self.updatedItems2 = items
    }
    
    @MainActor
    func handleModifiedMessage(_ messages: [Message]) /*-> MessageChangeType?*/
    {
        guard !messages.isEmpty else {return}
//        guard let cellVM = messageClusters.getCellViewModel(at: indexPath),
//              let modificationValue = cellVM.getModifiedValueOfMessage(message)
//        else { return nil }
//        var modifiedVMs = [MessageCellViewModel]()
        RealmDataBase.shared.add(objects: messages)
//        for message in messages {
//            let day = message.timestamp.formatToYearMonthDay()
//            guard let clusterIdx = messageClusters.firstIndex(where: { $0.date == day }) else { return }
//            
//            guard let itemIdx = messageClusters[clusterIdx].items.firstIndex(where: { $0.message?.id == message.id }) else { return }
//            
//            let vm = MessageCellViewModel(message: message)
////            messageClusters[clusterIdx].items[itemIdx].updateMessage(message)
//            messageClusters[clusterIdx].items[itemIdx] = vm
////            let vm = messageClusters[clusterIdx].items[itemIdx]
//            modifiedVMs.append(vm)
//        }
//        let items = MessagesUpdateType.updated(modifiedVMs)
//        self.updatedItems2 = items
//        realmService?.updateMessage(message)
//        return .modified(indexPath, modificationValue)
    }

    
    @MainActor
    private func fetchMessagesMetadata(_ messages: Set<Message>) async
    {
        await withTaskGroup(of: Void.self) { group in
            for message in messages {
                metadataTasks(for: message).forEach { task in
                    group.addTask { await task() }
                }
            }
        }
    }

    private func metadataTasks(for message: Message) -> [() async -> Void]
    {
        var tasks: [() async -> Void] = []
        
        if message.imagePath != nil {
            tasks.append { await self.downloadImageData(from: message) }
        }
        
        if conversation?.isGroup == true {
            tasks.append { await self.syncGroupUsers(for: [message]) }
        }

        if let messageToReplyID = message.repliedTo
        {
            tasks.append {
                do {
                    try await self.fetchRreferencedMessageData(messageToReplyID)
                } catch MessageFetchError.notFound {
                    await self.updateMessageReplyToID(message.id)
                } catch {
                    print("Error fetching referenced message: \(error)")
                }
            }
        }
        return tasks
    }
    
    @MainActor
    private func updateMessageReplyToID(_ messageID: String) async
    {
        do {
            try await FirebaseChatService.shared.updateMessageReplyToID(
                messageID,
                chatID: conversation!.id)
        } catch {
            print("Error while updating MessageReplyToID \(error)")
        }
    }
    
    private func fetchRreferencedMessageData(_ refMessageID: String) async throws
    {
        let realmRefMessage = RealmDataBase.shared.retrieveSingleObjectTest(
            ofType: Message.self,
            primaryKey: refMessageID
        )?.freeze()
        
        let referencedMessage = realmRefMessage == nil ? try await fetchMessage(withID: refMessageID) : realmRefMessage!
        
        if let path = referencedMessage.imagePath
        {
            let imageExists = CacheManager.shared.doesImageExist(at: path.addSuffix("small"))
            imageExists ? () : await self.downloadImageData(from: referencedMessage)
        }
        
        await syncGroupUsers(for: [referencedMessage])
        
        await MainActor.run {
            realmRefMessage == nil ?  self.realmService?.addMessagesToConversationInRealm([referencedMessage]) : ()
        }
    }
    
    
//    @MainActor
//    private func handleRemovedMessage2(at indexPath: IndexPath) -> MessageChangeType?
//    {
//        guard let message = messageClusters[indexPath.section].items[indexPath.row].message else {return nil}
//        
//        var isLastMessageInSection: Bool = false
//        
//        messageClusters.removeClusterItem(at: indexPath)
//        if messageClusters[indexPath.section].items.isEmpty
//        {
//            messageClusters.remove(at: indexPath.section)
//            isLastMessageInSection = true
//        }
//        
//        realmService?.removeMessageFromRealm(message: message) // message becomes unmanaged from here on, freeze it before accessing it further in current scope (ex. on debug with print)
//         
//        if indexPath.isFirst(), let recentMessageID = recentMessageItem?.message?.id
//        {
//            Task {
//                await firestoreService?.updateRecentMessageFromFirestoreChat(messageID: recentMessageID)
//            }
//        }
//        return .removed(indexPath, isLastItemInSection: isLastMessageInSection)
//    }

    
//    @MainActor
//    func handleModifiedMessage(_ message: Message,
//                               at indexPath: IndexPath) -> MessageChangeType?
//    {
//        guard let cellVM = messageClusters.getCellViewModel(at: indexPath),
//              let modificationValue = cellVM.getModifiedValueOfMessage(message)
//        else { return nil }
//        
//        realmService?.updateMessage(message)
//        return .modified(indexPath, modificationValue)
//    }
    
    @MainActor
    func indexPath(of message: Message) -> IndexPath?
    {
        guard let date = message.timestamp.formatToYearMonthDay() else { return nil }
        
        for (groupIndex, group) in messageClusters.enumerated() where group.date == date
        {
            if let messageIndex = group.items.firstIndex(where: { $0.message?.id == message.id })
            {
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
    private func fetchMessage(withID messageID: String) async throws -> Message
    {
        let message = try await FirebaseChatService.shared.fetchMessage(
            messageID: messageID,
            from: conversation!.id
        )
        return message
    }
    
    @MainActor
    func fetchConversationMessages(using strategy: MessageFetchStrategy? = nil) async throws -> [Message]
    {
        guard let conversation = conversation else { return [] }

        // TODO: - Remove after testing done
        var limit = 20
        
        if strategy != nil {
            limit = 25
        }
        
        let fetchStrategy = (strategy == nil) ? try await determineFetchStrategy() : strategy
        
        switch fetchStrategy
        {
        case .ascending(let startAtMessage, let included):
            return try await FirebaseChatService.shared.fetchMessagesFromChat(
                chatID: conversation.id,
                startingFrom: startAtMessage?.id,
                inclusive: included,
                fetchDirection: .ascending,
                limit: limit
            )
        case .descending(let startAtMessage, let included):
            return try await FirebaseChatService.shared.fetchMessagesFromChat(
                chatID: conversation.id,
                startingFrom: startAtMessage?.id,
                inclusive: included,
                fetchDirection: .descending,
                limit: limit
            )
        case .hybrit(let startAtMessage):
            let descendingMessages = try await FirebaseChatService.shared.fetchMessagesFromChat(
                chatID: conversation.id,
                startingFrom: startAtMessage.id,
                inclusive: false,
                fetchDirection: .descending,
                limit: limit
            )
            let ascendingMessages = try await FirebaseChatService.shared.fetchMessagesFromChat(
                chatID: conversation.id,
                startingFrom: startAtMessage.id,
                inclusive: true,
                fetchDirection: .ascending,
                limit: limit
            )
            return descendingMessages + ascendingMessages
        default: return []
        }
    }
    
    private func getStrategyForAdditionalMessagesFetch(inAscendingOrder ascendingOrder: Bool) -> MessageFetchStrategy?
    {
        let startMessage: Message?
        
        if ascendingOrder {
            startMessage = recentMessageItem?.message
        } else {
            // last message can be UnseenMessagesTitle, so we need to check and get one before last message instead
            guard let items = messageClusters.last?.items else { return nil }
                  
            if let lastItem = items.last, lastItem.displayUnseenMessagesTitle == true
            {
                startMessage = items.dropLast().last?.message
            } else {
                startMessage = items.last?.message
            }
        }
        
        switch ascendingOrder {
        case true: return .ascending(startAtMessage: startMessage, included: false)
        case false: return .descending(startAtMessage: startMessage, included: false)
        }
    }
    
    @MainActor
    private func determineFetchStrategy() async throws -> MessageFetchStrategy
    {
        guard let conversation = conversation else { return .none }
        
        if conversation.isGroup && !isAuthUserGroupMember
        {
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
    
//    func createMessageClustersWith(_ messages: [Message], ascending: Bool)
//    {
//        guard !messages.isEmpty else { return }
//        
//        var dateToClusterIndex = Dictionary(uniqueKeysWithValues: self.messageClusters.enumerated().map { ($0.element.date, $0.offset) })
//        var tempMessageClusters = self.messageClusters
//        
//        for message in messages {
//            guard let date = message.timestamp.formatToYearMonthDay() else { continue }
//            let messageItem = MessageItem(message: message)
//            
//            if let index = dateToClusterIndex[date] {
//                if ascending
//                {
//                    tempMessageClusters[index].items.insert(messageItem, at: 0)
//                    continue
//                }
//                tempMessageClusters[index].items.append(messageItem)
//            } else
//            {
//                let newCluster = MessageCluster(date: date, items: [messageItem])
//                if ascending {
//                    tempMessageClusters.insert(newCluster, at: 0)
//                } else {
//                    tempMessageClusters.append(newCluster)
//                }
//                dateToClusterIndex[date] = ascending ? 0 : tempMessageClusters.count - 1
//            }
//        }
//        self.messageClusters = tempMessageClusters
//    }
    
    @discardableResult
    func createMessageClustersWith(_ messages: [Message]) -> [MessageCellViewModel]
    {
        guard !messages.isEmpty else { return [] }
        
        var cellVMs: [MessageCellViewModel] = []
        
        var dateToClusterIndex = Dictionary(uniqueKeysWithValues: self.messageClusters.enumerated().map { ($0.element.date, $0.offset) })
        var tempMessageClusters = self.messageClusters
        
        // Determine insertion direction by comparing timestamps
        let isAscendingInsertion = {
            guard let firstCurrent = self.messageClusters.first?.items.first?.message?.timestamp,
                  let lastNew = messages.last?.timestamp else {
                return true /// since table view is inverted, return true
            }
            return lastNew > firstCurrent
        }()
        
        for message in messages {
            guard let date = message.timestamp.formatToYearMonthDay() else { continue }
            let messageItem = MessageItem(message: message)
            cellVMs.append(messageItem)
            if let index = dateToClusterIndex[date] {
                if isAscendingInsertion {
                    tempMessageClusters[index].items.insert(messageItem, at: 0)
                } else {
                    tempMessageClusters[index].items.append(messageItem)
                }
            } else {
                let newCluster = MessageCluster(date: date, items: [messageItem])
                if isAscendingInsertion {
                    tempMessageClusters.insert(newCluster, at: 0)
                    dateToClusterIndex[date] = 0
                } else {
                    tempMessageClusters.append(newCluster)
                    dateToClusterIndex[date] = tempMessageClusters.count - 1
                }
            }
        }
        
        self.messageClusters = tempMessageClusters
        return cellVMs
    }
    
//    private func getIndexPathsForAdditionalMessages(fromClusterSnapshot clusterSnapshot: [MessageCluster]) -> ([IndexPath], IndexSet?)
//    {
//        let oldDates = Set(clusterSnapshot.map { $0.date })
//        
//        var newIndexPaths: [IndexPath] = []
//        var newSections = IndexSet()
//        
//        for (sectionIndex, updatedCluster) in messageClusters.enumerated() {
//            let isNewSection = !oldDates.contains(updatedCluster.date)
//            
//            if isNewSection
//            {
//                newSections.insert(sectionIndex)
//                
//                let updatedMessagesSet = Set(updatedCluster.items.compactMap { $0.message })
//                for (index, _) in updatedMessagesSet.enumerated()
//                {
//                    newIndexPaths.append(IndexPath(row: index, section: sectionIndex))
//                }
//                continue
//            }
//            
//            // Match existing section by date
//            guard let oldSection = clusterSnapshot.first(where: { $0.date == updatedCluster.date }) else { continue }
//            let oldMessagesSet = Set(oldSection.items.compactMap { $0.message })
//
//            for (rowIndex, item) in updatedCluster.items.enumerated() {
//                if let message = item.message, !oldMessagesSet.contains(message) {
//                    newIndexPaths.append(IndexPath(row: rowIndex, section: sectionIndex))
//                }
//            }
//        }
//        
//        return (newIndexPaths, newSections.isEmpty ? nil : newSections)
//    }
    
    @MainActor
    func paginateRemoteMessages(inAscendingOrder order: Bool) async throws -> MessagesPaginationResult
    {
        guard let strategy = getStrategyForAdditionalMessagesFetch(inAscendingOrder: order) else {return .noMoreMessagesToPaginate}
        
        let newMessages = try await fetchConversationMessages(using: strategy)
        guard !newMessages.isEmpty else { return .noMoreMessagesToPaginate }
        
        await fetchMessagesMetadata(Set(newMessages))
        await isPaginationInactiveStream.first(where: { true })
        
        if conversation?.realm != nil
        {
            let startMessage = newMessages.first!
            realmService?.addMessagesToConversationInRealm(newMessages)
            messageListenerService?.addListenerToExistingMessagesTest(
                startAtMesssage: startMessage,
                ascending: order,
                limit: newMessages.count)
        }
        createMessageClustersWith(newMessages)
        return .didPaginate
    }
    
    enum MessagesPaginationResult {
        case didPaginate
        case noMoreMessagesToPaginate
    }
}


extension ChatRoomViewModel
{
    func retrieveImageDataFromCache(for path: String) -> Data?
    {
        return CacheManager.shared.retrieveImageData(from: path)
    }
}

// MARK: - Test
extension ChatRoomViewModel
{
    private func testMessagesCountAndUnseenCount()
    {
        Task { @MainActor in
            let localMessageCount = conversation?.getMessagesResults().count
            
            let remoteMessagesCount = try await FirebaseChatService.shared.getAllMessages(fromChatDocumentPath: conversation!.id).count
            
            print("local messages count", localMessageCount ?? 0)
            print("remote messages count", remoteMessagesCount)
            
        }
        
        Task { @MainActor in
            let authUserID = AuthenticationManager.shared.authenticatedUser?.uid ?? ""
            guard let senderID = conversation?.participants
                .first(where: { $0.userID != authUserID })?.userID else {return}
            let unreadCount = try await FirebaseChatService.shared.getUnreadMessagesCountTest(
                from: conversation!.id,
                whereMessageSenderID: senderID
            )
        
            let localUnseenCount = realmService?.getUnreadMessagesCountFromRealm()
            print("Remote Unseen messages count: ",unreadCount)
            print("Local Unseen messages count: ",localUnseenCount ?? 0)
        }
    }
}

//
//enum BufferedMessage {
//    case added(Message)
//    case modified(Message)
//    case removed(Message)
//}
//
//struct BufferedMessages
//{
//    var addedMessages: [Message]
//    var modifiedMessages: [Message]
//    var removedMessages: [Message]
//    
//    init(addedMessages: [Message], modifiedMessages: [Message], removedMessages: [Message]) {
//        self.addedMessages = addedMessages
//        self.modifiedMessages = modifiedMessages
//        self.removedMessages = removedMessages
//    }
//    
//    init() {
//        self.addedMessages = []
//        self.modifiedMessages = []
//        self.removedMessages = []
//    }
//    
//    mutating func removeAllBufferedMessages() {
//        addedMessages.removeAll()
//        modifiedMessages.removeAll()
//        removedMessages.removeAll()
//    }
//}
//
