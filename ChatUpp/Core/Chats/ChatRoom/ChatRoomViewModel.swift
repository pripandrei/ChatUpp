
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
    private var setupConversationTask: Task<Void, Never>?
    
    private(set) var realmService: ConversationRealmService?
    //    private(set) var messageFetcher : ConversationMessageFetcher
    private(set) var firestoreService: ConversationFirestoreService?
    private(set) var userListenerService : ConversationUsersListinerService?
    private(set) var messageListenerService : ConversationMessageListenerService?
    
    private(set) var conversation        : Chat?
    private(set) var participant         : User?
    private(set) var messageClusters     : [MessageCluster] = []
    private(set) var authUser            : AuthenticatedUserData = (try! AuthenticationManager.shared.getAuthenticatedUser())
    private var cancellables             = Set<AnyCancellable>()
    
    @Published private(set) var unseenMessagesCount: Int
    @Published private(set) var messageChangedTypes: [MessageChangeType] = []
    @Published private(set) var conversationInitializationStatus: ConversationInitializationStatus?
    
    private var bufferedMessages: [BufferedMessage] = []
    
    var isMessageBatchingInProcess: Bool = false {
        didSet {
            if oldValue == true && isMessageBatchingInProcess == false {
                processBufferedMessages()
            }
        }
    }
    
    var shouldEditMessage: ((String) -> Void)?
    var currentlyReplyToMessageID: String?
    
    private var lastMessageItem: MessageItem? {
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
        return realmService?.getUnreadMessagesCountFromRealm() == authParticipantUnreadMessagesCount
    }
    
    private lazy var authenticatedUser: User? = {
        guard let key = AuthenticationManager.shared.authenticatedUser?.uid else { return nil }
        return RealmDataBase.shared.retrieveSingleObject(ofType: User.self, primaryKey: key)
    }()
    
    private var isChatFetchedFirstTime: Bool
    {
        return conversation?.conversationMessages.count == 1
//        conversation?.isFirstTimeOpened ?? true
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
        initiateConversation()
        ChatRoomSessionManager.activeChatID = conversation.id
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
        
        guard let startMessage = messageClusters.last?.items.last?.message,
              let limit = conversation?.conversationMessages.count else {return}
        //TODO: - remove test start message and limit
        guard let startTestMessage = messageClusters.first?.items.first?.message else {return}
        let testLimit = 70
//        let testLimit = 35
        
        // Attach listener to upcoming messages only if all unseen messages
        // (if any) have been fetched locally
        if self.shouldAttachListenerToUpcomingMessages
        {
            messageListenerService?.addListenerToUpcomingMessages()
        }
//        messageListenerService?.addListenerToExistingMessages(startAtMesssageWithID: startTestMessage.id, ascending: false, limit: testLimit)
//        messageListenerService?.addListenerToExistingMessagesTest(startAtMesssageWithID: startTestMessage.id, ascending: false, limit: testLimit)
        messageListenerService?.addListenerToExistingMessagesTest(startAtMesssage: startTestMessage, ascending: false, limit: testLimit)
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
        
        let text = GroupEventMessage.userLeft.eventMessage
        let message = createNewMessage(ofType: .text, content: text)
        
        try await FirebaseChatService.shared.createMessage(message: message,
                                                           atChatPath: conversation.id)
        await firestoreService?.updateRecentMessageFromFirestoreChat(messageID: message.id)
        updateUnseenMessageCounter(shouldIncrement: true)
        
        let messages = getCurrentMessagesFromCluster()
        realmService?.addMessagesToConversationInRealm(messages)
        
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
        ChatRoomSessionManager.activeChatID = chat.id
    }
    
    func createNewMessage(ofType type: MessageType = .text,
                          content: String? = nil) -> Message
    {
        let isGroupChat = conversation?.isGroup == true
        let authUserID = AuthenticationManager.shared.authenticatedUser!.uid
        let seenByValue = (isGroupChat && type != .title) ? [authUserID] : nil
        
        return Message(
            id: UUID().uuidString,
            messageBody: type == .text ? content! : "",
            senderId: authUserID,
            timestamp: Date(),
            messageSeen: isGroupChat ? nil : false,
            seenBy: seenByValue,
            isEdited: false,
            imagePath: type == .image ? content : nil,
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
        realmService?.addMessageToRealmChat(message)
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
        
//        messageListenerService?.addListenerToExistingMessagesTest(
//            startAtMesssageWithID:messageID,
//            ascending: true,
//            limit: limit)
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
        let smallPath = path.replacingOccurrences(of: ".jpg", with: "_small.jpg")
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
        
//        guard conversation?.realm != nil,
//              var messages = conversation?.getMessages(),
//              !messages.isEmpty else { return }
        var messages = prepareMessagesForConversationInitialization()
        guard !messages.isEmpty else {return}
        
        if !shouldDisplayLastMessage {
            messages.removeFirst()
        }
        createMessageClustersWith(messages)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.1) {
            var totalMessagesCount = 0
            
            for cluster in self.messageClusters
            {
                totalMessagesCount += cluster.items.count
            }
            print("TOtal count: ",totalMessagesCount)
        }
//        let messageClustersCount = messageClusters.count
//        guard let startMessage = messageClusters[messageClustersCount - 1].items.last?.message else {return}
//                print("START MESSAGE : ", startMessage)
//                print("cluster count: ", messageClustersCount)
    }
    
    private func prepareMessagesForConversationInitialization() -> [Message]
    {
        guard let conversation = conversation else { return [] }
        if let message = getFirstUnseenMessage()
        {
            let messagesAscending = conversation.getMessages(startingFrom: message.id,
                                                    isMessageIncluded: true,
                                                    ascending: true,
                                                    limit: 20)
            let messagesDescending = conversation.getMessages(startingFrom: message.id,
                                                              isMessageIncluded: false,
                                                              ascending: false,
                                                              limit: 20).reversed()
            return Array(messagesDescending + messagesAscending)
        } else {
            let messages = conversation.getMessagesResults().prefix(31)
            return Array(messages)
        }
    }
    
    func paginateAdditionalLocalMessages(ascending: Bool) -> ([IndexPath], IndexSet?)?
    {
        let paginatedMessages = prepareAdditionalMessagesForConversation(ascending: ascending)
        if !paginatedMessages.isEmpty
        {
            let clusterSnapshot = messageClusters
            createMessageClustersWith(paginatedMessages)
            let (newRows, newSections) = getIndexPathsForAdditionalMessages(fromClusterSnapshot: clusterSnapshot)
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
                                                    ascending: ascending,
                                                    limit: 30)
            return messages
        }
        
        let messageClustersCount = messageClusters.count
        guard let startMessage = messageClusters[messageClustersCount - 1].items.last?.message
        else {return [] }
        
        let messages = conversation.getMessages(startingFrom: startMessage.id,
                                                isMessageIncluded: false,
                                                ascending: ascending,
                                                limit: 30)
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
    
    private func sortOutRemovedMessages(by messagesIDs: Set<String>) -> Set<Message>
    {
        let messagesToRemove: Set<Message> = Set(
            (conversation?
                .getMessagesResults()
                .filter("id NOT IN %@", messagesIDs)
                .map { $0 } ?? []
            )
        )

        return messagesToRemove
    }
    
//    private func sortOutRemovedMessages2(by messagesIDs: Set<String>,
//                                         limit: Int = 70) -> Set<Message>
//    {
//        
//        let messagesIDsSorted = Array(messagesIDs).sorted(by: <)
//        let startMessage = messagesIDsSorted.first
//        // Step 1: Get sorted messages in ascending order
//        guard let allMessages = conversation?.getMessagesResults()
//            .sorted(byKeyPath: Message.CodingKeys.timestamp.rawValue, ascending: true)
//        else {
//            return []
//        }
//
//        // Step 2: Skip until you find the startMessage, then take the next `limit`
//        let limitedMessages = allMessages
//            .drop(while: { $0.id != startMessage.id }) // find start point (inclusive)
//            .prefix(limit)
//
//        // Step 3: Filter out messages that were not in the provided messagesIDs
//        let messagesToRemove = Set(limitedMessages.filter { !messagesIDsSorted.contains($0.id) })
//
//        return messagesToRemove
//    }
    
    
    private func initializeWithMessages(_ messages: [Message])
    {
        if !messages.isEmpty
        {
            createMessageClustersWith(messages)
        }
        conversationInitializationStatus = .finished
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
                        let optimizedURL = avatarURL.replacingOccurrences(of: ".jpg", with: "_small.jpg")
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

//MARK: - Buffer messages
extension ChatRoomViewModel
{
    private func bufferMessage(messageType: DatabaseChangedObject<Message>)
    {
        switch messageType.changeType {
        case .added: bufferedMessages.append(.added(messageType.data))
        case .modified: bufferedMessages.append(.modified(messageType.data))
        case .removed: bufferedMessages.append(.removed(messageType.data))
        }
        print("Buffered message: \(messageType.data.id)")
    }
    
    private func processBufferedMessages()
    {
        guard !bufferedMessages.isEmpty else {return}
        
//        for buffered in bufferedMessages {
//            switch buffered {
//            case .added(let msg): Task { await self.handleAddedMessage(msg) }
//            case .modified(let msg): self.handleModifiedMessage(msg)
//            case .removed(let msg): self.handleRemovedMessage(msg)
//            }
//        }
//        bufferedMessages.removeAll()
        print("processed buffered messages !")
    }
}

//MARK: - Message listener bindings
extension ChatRoomViewModel
{
    private func bindToMessages()
    {
        messageListenerService?.$updatedMessages
            .debounce(for: .seconds(0.4), scheduler: DispatchQueue.main)
            .filter { !$0.isEmpty }
            .sink { messagesTypes in
                
                Task { @MainActor in
                    
                    var removedMessages : Set<Message> = []
                    var modifiedMessages: Set<Message> = []
                    var addedMessages   : Set<Message> = []
                     
                    for messageType in messagesTypes
                    {
                        switch messageType.changeType
                        {
                        case .removed  : removedMessages.insert(messageType.data)
                        case .modified : modifiedMessages.insert(messageType.data)
                        case .added    : addedMessages.insert(messageType.data)
                        }
                    }
                    
                    /// sort added & modified messages
                    /// that are not present in removed messages
                    ///
                    let removedIDs   = Set(removedMessages.map { $0.id })
                    modifiedMessages = modifiedMessages
                        .filter { !removedIDs.contains($0.id) }
                    addedMessages    = addedMessages
                        .filter { !removedIDs.contains($0.id) }
                    
                    /// get and sort indexPaths in descending order ,
                    /// to avoid index shift on removal
                    ///
                    let removedIndexPaths = removedMessages
                        .compactMap { self.indexPath(of: $0) }
                        .sorted(by: >)
                    
                    let removedTypes: [MessageChangeType] = removedIndexPaths
                        .compactMap { self.handleRemovedMessage(at: $0) }
                    
                    let modifiedTuples: [(message: Message, indexPath: IndexPath)] = modifiedMessages.compactMap { message in
                        guard let indexPath = self.indexPath(of: message) else { return nil }
                        return (message, indexPath)
                    }
                    
                    let modifiedTypes: [MessageChangeType] = modifiedTuples.compactMap { tuple in
                        self.handleModifiedMessage(tuple.message, at: tuple.indexPath)
                    }
                    
                    for message in addedMessages
                    {
                        guard self.realmService?.retrieveMessageFromRealm(message) == nil else
                        {
                            RealmDataBase.shared.add(object: message) // just update existing message in realm with fresh one
                            addedMessages.remove(message)
                            continue
                        }
                        await self.handleAddedMessage(message)
                    }
                    
                    let addedIndexPaths = addedMessages
                        .compactMap { self.indexPath(of: $0) }
                    let addedTypes      = addedIndexPaths.compactMap { MessageChangeType.added($0) }
//                    await withTaskGroup(of: Void.self) { group in
//                        for message in addedMessages {
//                            group.addTask {
//                                await self.handleAddedMessage(message)
//                            }
//                        }
//                    }
                    
                    let allChanges: [MessageChangeType] = removedTypes + modifiedTypes + addedTypes
                    self.messageChangedTypes = allChanges
                    
                    self.messageListenerService?.updatedMessages.removeAll()
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
        realmService?.addMessageToRealmChat(message)
        
        if message.imagePath != nil {
            await downloadImageData(from: message)
        }
        
        if message.type == .title
        {
            await syncGroupUsers(for: [message])
        }
        createMessageClustersWith([message])
    }
    
    private func handleRemovedMessage(at indexPath: IndexPath) -> MessageChangeType?
    {
        guard let message = messageClusters[indexPath.section].items[indexPath.row].message else {return nil}
        
        var isLastMessageInSection: Bool = false
        
        messageClusters.removeClusterItem(at: indexPath)
        if messageClusters[indexPath.section].items.isEmpty {
            messageClusters.remove(at: indexPath.section)
            isLastMessageInSection = true
        }
        
        realmService?.removeMessageFromRealm(message: message) // message becomes unmanaged from here on, freeze it before accessing it further in current scope (ex. on debug with print)
         
        if indexPath.isFirst(), let lastMessageID = lastMessageItem?.message?.id
        {
            Task {
                await firestoreService?.updateRecentMessageFromFirestoreChat(messageID: lastMessageID)                
            }
        }
        return .removed(indexPath, isLastItemInSection: isLastMessageInSection)
    }
    
    func handleModifiedMessage(_ message: Message, at indexPath: IndexPath) -> MessageChangeType?
    {
        guard let cellVM = messageClusters.getCellViewModel(at: indexPath),
              let modificationValue = cellVM.getModifiedValueOfMessage(message)
        else { return nil }
        
        realmService?.updateMessage(message)
        return .modified(indexPath, modificationValue)
    }
    
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

        var limit: Int = 35
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
    
//    private func loadAdditionalMessages(inAscendingOrder ascendingOrder: Bool) async throws -> [Message]
//    {
//        let startMessage: Message?
//        
//        if ascendingOrder {
//            startMessage = lastMessageItem?.message
//        } else {
//            // last message can be UnseenMessagesTitle, so we need to check and get one before last message instead
//            guard let items = messageClusters.last?.items else { return [] }
//                  
//            if let lastItem = items.last, lastItem.displayUnseenMessagesTitle == true
//            {
//                startMessage = items.dropLast().last?.message
//            } else {
//                startMessage = items.last?.message
//            }
//        }
//        
//        switch ascendingOrder {
//        case true: return try await fetchConversationMessages(using: .ascending(startAtMessage: startMessage, included: false))
//        case false: return try await fetchConversationMessages(using: .descending(startAtMessage: startMessage, included: false))
//        }
//    }
    
    private func getStrategyForAdditionalMessagesFetch(inAscendingOrder ascendingOrder: Bool) -> MessageFetchStrategy?
    {
        let startMessage: Message?
        
        if ascendingOrder {
            startMessage = lastMessageItem?.message
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
    //
//    func createMessageClustersWith(_ messages: [Message]) {
//        // Map existing clusters by date for quick lookup
//        var dateToIndex = Dictionary(uniqueKeysWithValues: self.messageClusters.enumerated().map {
//            ($0.element.date, $0.offset)
//        })
//        var tempMessageClusters = self.messageClusters
//
//        // Helper: Binary search to find insert index in a list of real message items
//        func findInsertIndex(in items: [MessageItem], for newMessage: Message) -> Int {
//            var low = 0
//            var high = items.count - 1
//
//            while low <= high {
//                let mid = (low + high) / 2
//                guard let midTimestamp = items[mid].message?.timestamp else {
//                    // If this ever happens here, something is wrong, since we only pass real message items
//                    break
//                }
//
//                if midTimestamp == newMessage.timestamp {
//                    return mid
//                } else if midTimestamp < newMessage.timestamp {
//                    // New message is newer → insert before mid
//                    high = mid - 1
//                } else {
//                    // New message is older → search right half
//                    low = mid + 1
//                }
//            }
//
//            return low
//        }
//
//        for message in messages {
//            guard let date = message.timestamp.formatToYearMonthDay() else { continue }
//            let messageItem = MessageItem(message: message)
//
//            if let index = dateToIndex[date] {
//                // Cluster exists — insert into it
//                var clusterItems = tempMessageClusters[index].items
//
//                // Filter only items that have real messages
//                let realMessageItems = clusterItems.filter { $0.message != nil }
//
//                // Find index in filtered array
//                let insertIndexInFiltered = findInsertIndex(in: realMessageItems, for: message)
//
//                // Map filtered index back to actual index in full array
//                var messageCount = 0
//                var actualInsertIndex = clusterItems.count // fallback: insert at end
//
//                for (i, item) in clusterItems.enumerated() {
//                    if item.message != nil {
//                        if messageCount == insertIndexInFiltered {
//                            actualInsertIndex = i
//                            break
//                        }
//                        messageCount += 1
//                    }
//                }
//
//                // If inserting at end (no match in loop), just insert after all items
//                clusterItems.insert(messageItem, at: actualInsertIndex)
//                tempMessageClusters[index].items = clusterItems
//
//            } else {
//                // No cluster for this date → create a new one
//                let newCluster = MessageCluster(date: date, items: [messageItem])
//
//                // Insert cluster in descending order by date (newest at top)
//                let insertClusterIndex = tempMessageClusters.firstIndex(where: { $0.date < date }) ?? tempMessageClusters.count
//                tempMessageClusters.insert(newCluster, at: insertClusterIndex)
//
//                // Update date lookup
//                dateToIndex = Dictionary(uniqueKeysWithValues: tempMessageClusters.enumerated().map {
//                    ($0.element.date, $0.offset)
//                })
//            }
//        }
//
//        self.messageClusters = tempMessageClusters
//    }
    
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

        if conversation?.isGroup == true {
            await syncGroupUsers(for: newMessages)
        }
        
        if conversation?.realm != nil
        {
            let startMessage = newMessages.first!
            realmService?.addMessagesToConversationInRealm(newMessages)
            messageListenerService?.addListenerToExistingMessagesTest(
                startAtMesssage: startMessage,
                ascending: order)
        }
        print("All additional fetched messages: ", "\n ", newMessages)
        let clusterSnapshot = messageClusters
        createMessageClustersWith(newMessages)
        let (newRows, newSections) = getIndexPathsForAdditionalMessages(fromClusterSnapshot: clusterSnapshot)
        
        assert(!newRows.isEmpty, "New rows array should not be empty at this point!")
        
        return (newRows, newSections)
    }
}







//MARK: - Message cluster insertion different options


//    func createMessageClustersWith(_ messages: [Message]) {
//        guard !messages.isEmpty else { return }
//
//        var dateToIndex = Dictionary(uniqueKeysWithValues: self.messageClusters.enumerated().map { ($0.element.date, $0.offset) })
//        var tempMessageClusters = self.messageClusters
//
//        // Determine insertion direction by comparing timestamps
//        let isNewerThanCurrent = {
//            guard let firstCurrent = self.messageClusters.first?.items.first?.message?.timestamp,
//                  let lastNew = messages.last?.timestamp else {
//                return false
//            }
//            return lastNew > firstCurrent
//        }()
//
//        for message in messages {
//            guard let date = message.timestamp.formatToYearMonthDay() else { continue }
//            let messageItem = MessageItem(message: message)
//
//            if let index = dateToIndex[date] {
//                if isNewerThanCurrent {
//                    tempMessageClusters[index].items.insert(messageItem, at: 0)
//                } else {
//                    tempMessageClusters[index].items.append(messageItem)
//                }
//            } else {
//                let newCluster = MessageCluster(date: date, items: [messageItem])
//                if isNewerThanCurrent {
//                    tempMessageClusters.insert(newCluster, at: 0)
//                    dateToIndex[date] = 0
//                } else {
//                    tempMessageClusters.append(newCluster)
//                    dateToIndex[date] = tempMessageClusters.count - 1
//                }
//            }
//        }
//
//        self.messageClusters = tempMessageClusters
//    }

//    func createMessageClustersWith(_ messages: [Message], insertPosition: MessageInsertionPosition) {
//        var dateToIndex = Dictionary(uniqueKeysWithValues: self.messageClusters.enumerated().map { ($0.element.date, $0.offset) })
//        var tempMessageClusters = self.messageClusters
//
//        messages.forEach { message in
//            guard let date = message.timestamp.formatToYearMonthDay() else { return }
//            let messageItem = MessageItem(message: message)
//
//            if let index = dateToIndex[date] {
//                switch insertPosition {
//                case .insertAtBeginning:
//                    tempMessageClusters[index].items.insert(messageItem, at: 0)
//                case .appendToEnd:
//                    tempMessageClusters[index].items.append(messageItem)
//                }
//            } else {
//                let newCluster = MessageCluster(date: date, items: [messageItem])
//                switch insertPosition {
//                case .insertAtBeginning:
//                    tempMessageClusters.insert(newCluster, at: 0)
//                    dateToIndex[date] = 0
//                case .appendToEnd:
//                    tempMessageClusters.append(newCluster)
//                    dateToIndex[date] = tempMessageClusters.count - 1
//                }
//            }
//        }
//
//        self.messageClusters = tempMessageClusters
//    }
    
//    func createMessageClustersWith(_ messages: [Message],
//                                   ascending: Bool? = nil)
//    {
//        var dateToIndex = Dictionary(uniqueKeysWithValues: self.messageClusters.enumerated().map { ($0.element.date, $0.offset) })
//        var tempMessageClusters = self.messageClusters
//
//        messages.forEach { message in
//            guard let date = message.timestamp.formatToYearMonthDay() else { return }
//            let messageItem = MessageItem(message: message)
//
//            if let index = dateToIndex[date] {
//                ascending == true
//                    ? tempMessageClusters[index].items.insert(messageItem, at: 0)
//                    : tempMessageClusters[index].items.append(messageItem)
//            } else {
//                let newCluster = MessageCluster(date: date, items: [messageItem])
//                if ascending == true {
//                    tempMessageClusters.insert(newCluster, at: 0)
//                    dateToIndex[date] = 0
//                } else {
//                    tempMessageClusters.append(newCluster)
//                    dateToIndex[date] = tempMessageClusters.count - 1
//                }
//            }
//        }
//        self.messageClusters = tempMessageClusters
//    }

//enum MessageInsertionPosition {
//    case appendToEnd      // user scrolled to top, loading older messages
//    case insertAtBeginning // user scrolled to bottom, loading newer messages
//}

