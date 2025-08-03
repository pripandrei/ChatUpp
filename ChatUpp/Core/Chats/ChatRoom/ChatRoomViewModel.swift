
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

enum BufferedMessage {
    case added(Message)
    case modified(Message)
    case removed(Message)
}

struct BufferedMessages
{
    var addedMessages: [Message]
    var modifiedMessages: [Message]
    var removedMessages: [Message]
    
    init(addedMessages: [Message], modifiedMessages: [Message], removedMessages: [Message]) {
        self.addedMessages = addedMessages
        self.modifiedMessages = modifiedMessages
        self.removedMessages = removedMessages
    }
    
    init() {
        self.addedMessages = []
        self.modifiedMessages = []
        self.removedMessages = []
    }
    
    mutating func removeAllBufferedMessages() {
        addedMessages.removeAll()
        modifiedMessages.removeAll()
        removedMessages.removeAll()
    }
}

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
     var messageClusters     : [MessageCluster] = []
    private(set) var authUser            : AuthenticatedUserData = (try! AuthenticationManager.shared.getAuthenticatedUser())
    private(set) var lastPaginatedMessage: Message?
    private var cancellables             = Set<AnyCancellable>()
    
    @Published private(set) var unseenMessagesCount: Int
    @Published private(set) var messageChangedTypes: Set<MessageChangeType> = []
    @Published private(set) var changedTypesOfRemovedMessages: Set<MessageChangeType> = []
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
    
    var shouldAttachListenerToUpcomingMessages: Bool
    {
        /// See FootNote.swift [7]
        self.shouldDisplayLastMessage
    }
    
    private lazy var authenticatedUser: User? = {
        guard let key = AuthenticationManager.shared.authenticatedUser?.uid else { return nil }
        return RealmDataBase.shared.retrieveSingleObject(ofType: User.self, primaryKey: key)
    }()
    
    private var isChatFetchedFirstTime: Bool
    {
        return conversation?.conversationMessages.count == 1
    }
    
    private var shouldDisplayLastMessage: Bool {
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
        return authParticipantUnreadMessagesCount != localUnreadMessageCount
    }
    
    func testGetUnreadMessagesCountFromRealm() -> [String]
    {
        guard let conversation = conversation
        else { return [] }
        let userID = authUser.uid
        let filter = conversation.isGroup ?
        NSPredicate(format: "NONE seenBy == %@ AND senderId != %@", userID, userID) : NSPredicate(format: "messageSeen == false AND senderId != %@", userID)

        return Array(conversation.conversationMessages.filter(filter)).compactMap { $0.id }
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
        
        bindToMessages()
        bindToDeletedMessages()
        initiateConversation()
        ChatRoomSessionManager.activeChatID = conversation.id
        
//       testMessagesCountAndUnseenCount() // 
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
                guard let self = self, change.0.name == "unseenMessagesCount" else { return }
                
                self.unseenMessagesCount = change.0.newValue as? Int ?? self.unseenMessagesCount
            }.store(in: &cancellables)
    }

    /// - listeners
    
    func addListeners()
    {
        guard conversation?.realm != nil else {return}
        
        userListenerService?.addUsersListener()
        userListenerService?.addUserObserver()
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
        updateUnseenMessageCounter(shouldIncrement: true)
        
        var messages = getCurrentMessagesFromCluster()
        messages.insert(newMessage, at: 0)
//        messages.append(newMessage)
        realmService?.addMessagesToConversationInRealm(messages)
        
        createMessageClustersWith([newMessage])
        messageChangedTypes = [.added(IndexPath(row: 0, section: 0))]
        
        //Add new chat row
        NotificationCenter.default.post(name: .didJoinNewChat,
                                        object: nil,
                                        userInfo: ["chatID": conversation.id])
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
        
        NotificationCenter.default.post(name: .didCreateNewChat,
                                        object: chat)
        
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
            timestamp: Date(),
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
        createMessageClustersWith([message])
        realmService?.addMessagesToRealmChat([message])
        updateUnseenMessageCounterLocal(shouldIncrement: true)
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
        updateUnseenMessageCounterRemote(shouldIncrement: true)
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
    
    private let unseenMessageUpdateQueue = DispatchQueue(label: "unseenMessageUpdateQueue")

    /// - update messages components
    @MainActor
    func updateUnseenMessageCounter(shouldIncrement: Bool,
                                    counter: Int? = nil)
    {
        updateUnseenMessageCounterLocal(shouldIncrement: shouldIncrement,
                                        counter: counter)
        updateUnseenMessageCounterRemote(shouldIncrement: shouldIncrement,
                                         counter: counter)
    }
    
    @MainActor
    private func updateUnseenMessageCounterLocal(shouldIncrement: Bool,
                                                 counter: Int? = nil)
    {
//        guard let conversation = conversation else { return }
        guard let conversationID = self.conversation?.id else { return }
//        let threadSafeChat = RealmDataBase.shared.makeThreadSafeObject(object: conversation)
        let authUserID = self.authUser.uid

//        Task.detached {
            self.unseenMessageUpdateQueue.async {
//                guard let chat = RealmDataBase.shared.resolveThreadSafeObject(threadSafeObject: threadSafeChat) else {return}
                guard let chat = RealmDataBase.shared.retrieveSingleObjectTest(ofType: Chat.self, primaryKey: conversationID) else {return}
                
                RealmDataBase.shared.updateTest(object: chat) { dbChat in
                    if shouldIncrement {
                        for participant in dbChat.participants where participant.userID != authUserID
                        {
                            let updatedCount = (counter != nil) ? counter! : 1
                            participant.unseenMessagesCount += updatedCount
                        }
                    } else {
                        if let participant = dbChat.getParticipant(byID: authUserID)
                        {
                            let updatedCount = (counter != nil) ? -counter! : -1
                            participant.unseenMessagesCount = max(0, participant.unseenMessagesCount + updatedCount) // use + instead of - here, because two minuses (- -) result in +
                            if participant.unseenMessagesCount <= 0 {
                                print("stop here")
                            }
                        }
                    }
                }
            }
//        }
    }
    
    @MainActor
    private func updateUnseenMessageCounterRemote(shouldIncrement: Bool,
                                                  counter: Int? = nil)
    {
        guard let conversationID = conversation?.id else { return }
        let authUserID = self.authUser.uid
        
        Task.detached
        {
            guard let chat = RealmDataBase.shared.retrieveSingleObjectTest(ofType: Chat.self, primaryKey: conversationID) else {return}
            
            let targetIDs = shouldIncrement
            ? chat.participants
                .filter { $0.userID != authUserID }
                .map { $0.userID }
            : [authUserID]
            do {
                try await FirebaseChatService.shared.updateUnreadMessageCount(
                    for: targetIDs,
                    inChatWithID: chat.id,
                    increment: shouldIncrement,
                    counter: counter
                )
            } catch {
                print("Failed to update Firebase unread message count: \(error)")
            }
        }
    }
    
    func updateFirebaseMessagesSeenStatus(_ messageIDs: [String])
    {
        guard let chatID = conversation?.id else { return }
        let authUserID = authUser.uid
        let isGroup = conversation?.isGroup ?? false
        
        Task.detached
        {
            try await FirebaseChatService
                .shared
                .updateMessagesSeenStatus(seenByUser: isGroup ? authUserID : nil,
                                          messageIDs,
                                          chatID: chatID)
        }
    }
    
    func updateRealmMessagesSeenStatus(_ messageIDs: [String])
    {
        let authUserID = authUser.uid
        let isGroup = conversation?.isGroup ?? false

        Task.detached
        {
            let filter = NSPredicate(format: "id IN %@", messageIDs)
            guard let messages = RealmDataBase.shared.retrieveObjectsTest(
                ofType: Message.self,
                filter: filter
            ) else {return}
            
            RealmDataBase.shared.update(objects: Array(messages)) { messages in
                for message in messages {
                    if isGroup {
                        message.seenBy.append(authUserID)
                        continue
                    }
                    message.messageSeen = true
                }
            }
        }
    }

//    @MainActor
//    func updateMessageSeenStatus(from cellViewModel: MessageCellViewModel)
//    {
//        guard let chatID = conversation?.id else { return }
//        let authUserID = authUser.uid
//
//        let isGroup = conversation?.isGroup ?? false
//        Task.detached {
//            await cellViewModel.updateFirestoreMessageSeenStatus(
//                by: isGroup ? authUserID : nil,
//                from: chatID
//            )
//        }
//    }
    
//    func updateMessageSeenStatusTest(from cellViewModel: MessageCellViewModel)
//    {
//        guard let chatID = conversation?.id else { return }
//        let authUserID = authUser.uid
//
//        let isGroup = conversation?.isGroup ?? false
//
//        DispatchQueue.main.asyncAfter(deadline: .now() + 5.1) {
//            Task.detached {
//                await cellViewModel.updateFirestoreMessageSeenStatusTest(
//                    by: isGroup ? authUserID : nil,
//                    from: chatID
//                )
//            }
//        }
//    }
    
    func clearMessageChanges() {
        Task {
            await MainActor.run {
                messageChangedTypes.removeAll()
            }
        }
    }
    
    func clearRemovedMessageChanges()
    {
        Task {
            await MainActor.run {
               changedTypesOfRemovedMessages.removeAll()
            }
        }
    }
    
    /// - unseen message check
    
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
        let conversationCellVM = MessageCellViewModel(isUnseenCell: true)
        messageClusters[indexPath.section].items.insert(conversationCellVM, at: indexPath.row + 1)
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
            messages.removeFirst()
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
    
    func paginateAdditionalLocalMessages(ascending: Bool) -> ([IndexPath], IndexSet?)?
    {
        guard conversation?.realm != nil else {return nil} // if group chat that we are not member of is opened
        
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
                return nil
            }
        }
        
        if !paginatedMessages.isEmpty
        {
            let clusterSnapshot = messageClusters
            createMessageClustersWith(paginatedMessages)
            let (newRows, newSections) = getIndexPathsForAdditionalMessages(fromClusterSnapshot: clusterSnapshot)
            self.lastPaginatedMessage = paginatedMessages.last
            self.validateMessagesForDeletion(paginatedMessages)
            return (newRows, newSections)
        }
        return nil
    }
    
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
                    let messageIDSFromRealm = Array(messagesToDelete.map { $0.id })
                    
                    let modificationTypes = await self.processRemovedMessages(Set(messagesToDelete))
                    
                    self.deletedMessageIDs.removeAll()
                    self.changedTypesOfRemovedMessages = modificationTypes
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
    
    // MARK: - Group Chat Handling
    @MainActor
    private func syncGroupUsers(for messages: [Message]) async
    {
        do {
            let missingUserIDs = findMissingUserIDs(from: messages)
            
            guard !missingUserIDs.isEmpty else { return }
            
            let users = try await FirestoreUserService.shared.fetchUsers(with: missingUserIDs)
            RealmDataBase.shared.add(objects: users)
            await fetchAvatars(for: users)
        } catch {
            print("Error in synchronizing users from messages: ", error)
        }
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
                        let optimizedURL = avatarURL.addSuffix("small")
                        let imageData = try await FirebaseStorageManager.shared.getImage(from: .user(userID), imagePath: optimizedURL)
                        CacheManager.shared.saveImageData(imageData, toPath: optimizedURL)
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
        
        // Process changes in order: remove, modify, add
        let removedTypes = await processRemovedMessages(removedMessages)
        let modifiedTypes = await processModifiedMessages(filteredModified)
        let addedTypes = await processAddedMessages(filteredAdded)
        
        // Combine all changes and update
        let allChanges: Set<MessageChangeType> = removedTypes.union(modifiedTypes.union(addedTypes))
        
        self.messageChangedTypes = allChanges

//         Clear processed messages
        self.messageListenerService?.updatedMessages.removeAll()
    }

    @MainActor
    private func processRemovedMessages(_ messages: Set<Message>) async -> Set<MessageChangeType>
    {
        let sortedIndexPaths = messages
            .compactMap { self.indexPath(of: $0) }
            .sorted(by: >)
        let changeTypes = sortedIndexPaths.compactMap { self.handleRemovedMessage(at: $0) }
        return Set(changeTypes)
    }

    @MainActor
    private func processModifiedMessages(_ messages: Set<Message>) async -> Set<MessageChangeType>
    {
        return Set(messages.compactMap { message in
            guard let indexPath = self.indexPath(of: message) else { return nil }
            return self.handleModifiedMessage(message, at: indexPath)
        })
    }

    @MainActor
    private func processAddedMessages(_ messages: Set<Message>) async -> Set<MessageChangeType>
    {
        // Separate messages that already exist vs new ones
        let (existingMessages, newMessages) = messages.reduce(into: ([Message](), [Message]())) { result, message in
            if RealmDataBase.shared.retrieveSingleObjectTest(ofType: Message.self, primaryKey: message.id) != nil {
                result.0.append(message)
            } else {
                result.1.append(message)
            }
        }
        
        // Add existing messages to database
        if !existingMessages.isEmpty {
            RealmDataBase.shared.add(objects: existingMessages)
        }
        
        let isMostRecentMessagePaginated = isMostRecentMessagePaginated
        
//        // Process new messages concurrently
        await self.handleAddedMessage(newMessages)

        // Create change types for all added messages
        return Set(newMessages
            .compactMap { newMessage in
                //TODO: check if messages are paginated up to most recent one
                self.indexPath(of: newMessage)
            }
            .map { MessageChangeType.added($0) })
    }
    
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
    private func handleAddedMessage(_ messages: [Message]) async
    {
//        let isMostRecentMessagePaginated = isMostRecentMessagePaginated // important to check before message was added
        realmService?.addMessagesToRealmChat(messages)
        
        //check if messages are paginated up to most recent one
//        if isMostRecentMessagePaginated {
            createMessageClustersWith(messages)
//        }
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

        /// See FootNote.swift [9]
        if message.type == .title {
            tasks.append { await self.syncGroupUsers(for: [message]) }
        }

        return tasks
    }

    
    @MainActor
    private func handleRemovedMessage(at indexPath: IndexPath) -> MessageChangeType?
    {
        guard let message = messageClusters[indexPath.section].items[indexPath.row].message else {return nil}
        
        var isLastMessageInSection: Bool = false
        
        messageClusters.removeClusterItem(at: indexPath)
        if messageClusters[indexPath.section].items.isEmpty
        {
            messageClusters.remove(at: indexPath.section)
            isLastMessageInSection = true
        }
        let messageID = message.id
        realmService?.removeMessageFromRealm(message: message) // message becomes unmanaged from here on, freeze it before accessing it further in current scope (ex. on debug with print)
         
        if indexPath.isFirst(), let recentMessageID = recentMessageItem?.message?.id
        {
            Task {
                await firestoreService?.updateRecentMessageFromFirestoreChat(messageID: recentMessageID)
            }
        }
        return .removed(indexPath, isLastItemInSection: isLastMessageInSection)
    }
    @MainActor
    func handleModifiedMessage(_ message: Message,
                               at indexPath: IndexPath) -> MessageChangeType?
    {
        guard let cellVM = messageClusters.getCellViewModel(at: indexPath),
              let modificationValue = cellVM.getModifiedValueOfMessage(message)
        else { return nil }
        
        realmService?.updateMessage(message)
        return .modified(indexPath, modificationValue)
    }
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
    func fetchConversationMessages(using strategy: MessageFetchStrategy? = nil) async throws -> [Message]
    {
        guard let conversation = conversation else { return [] }

        // TODO: - Remove after testing done
        var limit = 50
        
        if strategy != nil {
            limit = 10
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
                inclusive: true,
                fetchDirection: .descending,
                limit: limit
            )
            let ascendingMessages = try await FirebaseChatService.shared.fetchMessagesFromChat(
                chatID: conversation.id,
                startingFrom: startAtMessage.id,
                inclusive: false,
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
    func createMessageClustersWith(_ messages: [Message])
    {
        guard !messages.isEmpty else { return }
        
        var dateToIndex = Dictionary(uniqueKeysWithValues: self.messageClusters.enumerated().map { ($0.element.date, $0.offset) })
        var tempMessageClusters = self.messageClusters
        
        // Determine insertion direction by comparing timestamps
        let isNewerThanCurrent = {
            guard let firstCurrent = self.messageClusters.first?.items.first?.message?.timestamp,
                  let lastNew = messages.last?.timestamp else {
                return true /// since table view is inverted, return true
            }
            return lastNew > firstCurrent
        }()
        
        for message in messages {
            guard let date = message.timestamp.formatToYearMonthDay() else { continue }
            let messageItem = MessageItem(message: message)
            
            if let index = dateToIndex[date] {
                if isNewerThanCurrent {
                    tempMessageClusters[index].items.insert(messageItem, at: 0)
                } else {
                    tempMessageClusters[index].items.append(messageItem)
                }
            } else {
                let newCluster = MessageCluster(date: date, items: [messageItem])
                if isNewerThanCurrent {
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
    
    private func getIndexPathsForAdditionalMessages(fromClusterSnapshot clusterSnapshot: [MessageCluster]) -> ([IndexPath], IndexSet?)
    {
        let oldDates = Set(clusterSnapshot.map { $0.date })
        
        var newIndexPaths: [IndexPath] = []
        var newSections = IndexSet()
        
        for (sectionIndex, updatedCluster) in messageClusters.enumerated() {
            let isNewSection = !oldDates.contains(updatedCluster.date)
            
            if isNewSection
            {
                newSections.insert(sectionIndex)
                
                let updatedMessagesSet = Set(updatedCluster.items.compactMap { $0.message })
                for (index, _) in updatedMessagesSet.enumerated()
                {
                    newIndexPaths.append(IndexPath(row: index, section: sectionIndex))
                }
                continue
            }
            
            // Match existing section by date
            guard let oldSection = clusterSnapshot.first(where: { $0.date == updatedCluster.date }) else { continue }
            let oldMessagesSet = Set(oldSection.items.compactMap { $0.message })

            for (rowIndex, item) in updatedCluster.items.enumerated() {
                if let message = item.message, !oldMessagesSet.contains(message) {
                    newIndexPaths.append(IndexPath(row: rowIndex, section: sectionIndex))
                }
            }
        }
        
        return (newIndexPaths, newSections.isEmpty ? nil : newSections)
    }
    
    @MainActor
    func handleAdditionalMessageClusterUpdate(inAscendingOrder order: Bool) async throws -> ([IndexPath], IndexSet?)?
    {
        guard let strategy = getStrategyForAdditionalMessagesFetch(inAscendingOrder: order) else {return nil}
        
        let newMessages = try await fetchConversationMessages(using: strategy)
        guard !newMessages.isEmpty else { return nil }
        
//        if conversation?.isGroup == true {
//            await syncGroupUsers(for: newMessages)
//        }
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
        let clusterSnapshot = messageClusters
        createMessageClustersWith(newMessages)

        let (newRows, newSections) = getIndexPathsForAdditionalMessages(fromClusterSnapshot: clusterSnapshot)
        
        assert(!newRows.isEmpty, "New rows array should not be empty at this point!")
        
        return (newRows, newSections)
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
            
            print("local messages count", localMessageCount)
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
        
            let localUnseenCpunt = realmService?.getUnreadMessagesCountFromRealm()
            print("Remote Unseen messages count: ",unreadCount)
            print("Local Unseen messages count: ",localUnseenCpunt)
        }
    }
}

