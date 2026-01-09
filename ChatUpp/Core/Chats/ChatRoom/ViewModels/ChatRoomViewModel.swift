
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
    private(set) var realmService: ConversationRealmService?
    private(set) var firestoreService: ConversationFirestoreService?
    private(set) var messageListenerService: ConversationMessageListenerService?
    private(set) var remoteMessagePaginator: RemoteMessagePaginator?
    private(set) var datasourceUpdateType = PassthroughSubject<DatasourceRowAnimation, Never>()
    private let messagesSeenStatusUpdater: MessageSeenSyncService = .init()
    private let unseenMessageCounterUpdater: MessageUnseenCounterSyncService = .init()
    
    private(set) var conversation        : Chat?
    private(set) var participant         : User?
    private(set) var authUser            : AuthenticatedUserData = (try! AuthenticationManager.shared.getAuthenticatedUser())
    private(set) var lastPaginatedMessage: Message?
    private var cancellables             = Set<AnyCancellable>()
    
    @Published private(set) var messageClusters     : [MessageCluster] = []
    @Published private(set) var unseenMessagesCount: Int
    @Published private(set) var messageChangedTypes: Set<MessageChangeType> = []
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
        
    func getMessageSender(_ senderID: String) -> User?
    {
        return RealmDatabase.shared.retrieveSingleObject(ofType: User.self, primaryKey: senderID)
    }
    
    private lazy var authenticatedUser: User? = {
        guard let key = AuthenticationManager.shared.authenticatedUser?.uid else { return nil }
        return RealmDatabase.shared.retrieveSingleObject(ofType: User.self, primaryKey: key)
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
        self.remoteMessagePaginator = .init()
    }
    
    private func getPrivateChatMember(from chat: Chat) -> User?
    {
        guard let memberID = chat.participants.first(where: { $0.userID != authUser.uid })?.userID,
              let user = RealmDatabase.shared.retrieveSingleObject(ofType: User.self, primaryKey: memberID) else { return nil }
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
        
//        testMessagesCountAndUnseenCount() // test functions
    }
    
    init(participant: User?)
    {
        self.participant = participant
        self.unseenMessagesCount = 0
    }
    
    deinit
    {
        print(String(describing: Self.self) + " deinit")
    }
    
    private func observeParticipantChanges()
    {
        guard let chat = conversation else {return}
        guard let participant = chat.getParticipant(byID: authUser.uid) else {return}
        
        RealmDatabase.shared.observeChanges(for: participant)
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
        
        observeParticipantChanges()
         
        guard let startMessage = messageClusters.first?.items.first?.message
        else {
            // chat is empty, safe to attache to upcoming messages
            messageListenerService?.addListenerToUpcomingMessages()
            return
        }

        // Attach listener to upcoming messages only if all unseen messages
        // (if any) have been fetched locally
        if self.shouldAttachListenerToUpcomingMessages
        {
            messageListenerService?.addListenerToUpcomingMessages()
        }
        
        let totalMessagesCount = messageClusters.reduce(0) { total, cluster in
            total + cluster.items.filter { $0.message != nil }.count
        }
        messageListenerService?.addListenerToExistingMessages(
            startAtMesssage: startMessage,
            ascending: false,
            limit: totalMessagesCount
        )
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
        guard let conversation = conversation
        else { return }
        
        let participant = ChatParticipant(userID: authUser.uid, unseenMessageCount: 0)
        conversation.participants.append(participant)
        try await FirebaseChatService.shared.addParticipant(participant: participant,
                                                            toChat: conversation.id)
        RealmDatabase.shared.add(object: conversation)
        
        let text = GroupEventMessage.userJoined.eventMessage
        let newMessage = createNewMessage(ofType: .title, messageText: text)
         
        try await FirebaseChatService.shared.createMessage(message: newMessage,
                                                           atChatPath: conversation.id)
        await firestoreService?.updateRecentMessageFromFirestoreChat(messageID: newMessage.id)
        
        let threadSafeChat = RealmDatabase.shared.makeThreadSafeObject(object: conversation)
        await self.unseenMessageCounterUpdater.updateParticipantsUnseenCounterRemote(chat: threadSafeChat)
        
        var messages = getCurrentMessagesFromCluster()
        messages.insert(newMessage, at: 0)
        
        realmService?.addMessagesToConversationInRealm(messages)
        
        createMessageClustersWith([newMessage])
        messageChangedTypes = [.added(IndexPath(row: 0, section: 0))]
        
        //Add new chat row
        ChatManager.shared.broadcastJoinedGroupChat(conversation)
        if let unseenMessage = getUnseenMessage(sortedAscending: false)
        {
            await syncMessagesSeenStatus(startFrom: unseenMessage)
        }
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
            bindToMessages()
            bindToDeletedMessages()
            addListeners()
        }
        ChatManager.shared.broadcastNewCreatedChat(chat)
        
        ChatRoomSessionManager.activeChatID = chat.id
    }
    
    @MainActor
    func createVoiceMessage(fromURL url: URL, withAudioSamples samples: [Float])
    {
        ensureConversationExists()
        let message = createMessageLocally(
            ofType: .audio,
            text: nil,
            media: .audio(path: url.lastPathComponent, samples: samples)
        )
        syncMessageWithFirestore(message.freeze(), imageRepository: nil)
    }
    
    // Extract samples from audio file to generate waveforms
    func generateWaveform(from url: URL) async -> [Float]
    {
        await Task.detached(priority: .userInitiated)
        {
            return AudioSessionManager.shared.extractSamples(from: url, targetSampleCount: 40)
        }.value
    }
    
    @MainActor
    func createMessageLocally(ofType type: MessageType,
                              text: String?,
                              media: MessageMediaContent?) -> Message
    {
        guard let chat = conversation else { return .init() }
        let message = createNewMessage(ofType: type,
                                       messageText: text,
                                       mediaParameters: media)
        
        realmService?.addMessagesToRealmChat([message])
        
        createMessageClustersWith([message])
        return message
    }
    
    private func createNewMessage(ofType type: MessageType = .text,
                                  messageText: String? = nil,
                                  mediaParameters: MessageMediaContent? = nil) -> Message
    {
        let isGroupChat = conversation?.isGroup == true
        let authUserID = AuthenticationManager.shared.authenticatedUser!.uid
        let seenByValue = isGroupChat ? [authUserID: true] : nil
        let messageText = (messageText != nil) ? messageText! : ""
 
        return Message(
            id: UUID().uuidString,
            messageBody: messageText,
            senderId: authUserID,
            timestamp:  Date(),
            messageSeen: isGroupChat ? nil : false,
            seenBy: seenByValue,
            isEdited: false,
            imagePath: mediaParameters?.imagePath,
            imageSize: nil,
            repliedTo: currentlyReplyToMessageID,
            type: type,
            sticker: mediaParameters?.stickerPath,
            voicePath: mediaParameters?.audioPath,
            audioSamples: mediaParameters?.audioSamples
        )
    }
    
    func ensureConversationExists()
    {
        if self.conversation == nil { setupConversation() }
    }
    
    func syncMessageWithFirestore(_ message: Message,
                                  imageRepository: ImageSampleRepository?)
    {
        guard let chat = self.conversation else {return}
        let threadSafeChat = RealmDatabase.shared.makeThreadSafeObject(object: chat)
        
        Task.detached { [weak self] in
            
            guard let self else { return }
           
            await self.setupConversationTask?.value
            
            if let repo = imageRepository
            {
                await self.saveImagesRemotelly(fromImageRepository: repo, for: message.id)
            }
            
            if let path = message.voicePath,
               let voiceMessageURL = CacheManager.shared.getURL(for: path)
            {
                await FirebaseStorageManager.shared.saveVoice(fromURL: voiceMessageURL, to: .message(.audio(message.id)))
            }
            
            await self.firestoreService?.addMessageToFirestoreDataBase(message)
            await self.firestoreService?.updateRecentMessageFromFirestoreChat(messageID: message.id)
            await self.unseenMessageCounterUpdater.updateParticipantsUnseenCounterRemote(chat: threadSafeChat)
        }
    }

    private func setupMessageListenerOnChatCreation()
    {
        guard let message = conversation?.getLastMessage(),
              let limit = conversation?.conversationMessages.count else { return }

        messageListenerService?.addListenerToExistingMessages(
            startAtMesssage: message,
            ascending: true,
            limit: limit)
    }
 
    /// unseen messages counter update
    ///
    @MainActor
    func updateMessagesUnseenCounter(numberOfUpdatedMessages: Int,
                                     increment: Bool) async
    {
        guard let chat = conversation,
              numberOfUpdatedMessages > 0 else { return }
        let threadSafeChat = RealmDatabase.shared.makeThreadSafeObject(object: chat)
        
        await unseenMessageCounterUpdater.updateLocal(chat: threadSafeChat,
                                                      userID: authUser.uid,
                                                      numberOfUpdatedMessages: numberOfUpdatedMessages,
                                                      increment: false)
        await unseenMessageCounterUpdater.scheduleRemoteUpdate(chatID: chat.id,
                                                               userID: authUser.uid,
                                                               increment: false)
    }
    
    /// update unseen messages
    ///
    @MainActor
    @discardableResult
    func syncMessagesSeenStatus(startFrom message: Message) async -> Result<Int, Error>
    {
        guard let chat = conversation else { return .failure(ChatUnwrappingError.chatIsNil) }
        
        let isGroup = conversation?.isGroup ?? false
        let threadSafeChat = RealmDatabase.shared.makeThreadSafeObject(object: chat)
          
        let updatedMessagesCount = await messagesSeenStatusUpdater.updateLocally(chat: threadSafeChat,
                                                                                 authUserID: authUser.uid,
                                                                                 isGroup: isGroup,
                                                                                 timestamp: message.timestamp)
        await messagesSeenStatusUpdater.updateRemote(startingFrom: message.id,
                                                     chatID: chat.id,
                                                     seenByUser: isGroup ? authUser.uid : nil,
                                                     limit: updatedMessagesCount)
        return .success(updatedMessagesCount)
    }
    
    
    func findLastUnseenMessageIndexPath() -> IndexPath?
    {
        for (sectionIndex, messageGroup) in messageClusters.enumerated().reversed()
        {
            if let rowIndex = messageGroup.items
                .lastIndex(where: { cellVM in
                    guard cellVM.message?.senderId != authUser.uid else {return false}
                    if conversation?.isGroup == true
                    {
                        guard let message = cellVM.message else {return false}
                        return !message.seenBy.contains(authUser.uid)
                    }
                    return cellVM.message?.messageSeen == false
                })
            {
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
        RealmDatabase.shared.update(object: message) { realmMessage in
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
        let reactions = message.mapReactionsForEncoding(message.reactions)
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
                    CacheManager.shared.saveData(imageData, toPath: path)
//                    print("Cached image: \(imageData) \(path)")
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
                                       to: .message(.image(messageID)),
                                       imagePath: path)
//                        print("Saved Image with path: \(path)")
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
        
        let imagesExistLocally = paths.allSatisfy { path in
            return CacheManager.shared.doesFileExist(at: path)
        }
        
        if imagesExistLocally { return }
        
        do
        {
            try await withThrowingTaskGroup(of: Void.self) { group in
                for path in paths
                {
                    group.addTask {
                        let imageData = try await FirebaseStorageManager.shared.getImage(
                            from: .message(.image(message.id)),
                            imagePath: path
                        )
                        CacheManager.shared.saveData(imageData, toPath: path)
                    }
                }
                for try await _ in group {}
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
        if let message = getUnseenMessage(sortedAscending: true)
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
        guard !shouldFetchNewMessages else {return false}
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
            createMessageClustersWith(paginatedMessages)
            self.lastPaginatedMessage = paginatedMessages.last
            self.validateMessagesForDeletion(paginatedMessages)
            return true
        }
        return false
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
    
    private func getUnseenMessage(sortedAscending: Bool) -> Message?
    {
        guard let conversation = conversation else { return nil }
        
        let filter = conversation.isGroup ?
        NSPredicate(format: "NONE seenBy CONTAINS %@ AND senderId != %@", authUser.uid, authUser.uid)
        :
        NSPredicate(format: "messageSeen == false AND senderId != %@", authUser.uid )
        
        let unseenMessage = conversation.conversationMessages
            .filter(filter)
            .sorted(byKeyPath: Message.CodingKeys.timestamp.rawValue, ascending: sortedAscending)
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
                    await self.isPaginationInactiveStream
                        .first(where: { true })
                    
                    guard let messagesToDelete = RealmDatabase
                        .shared
                        .retrieveObjects(ofType: Message.self,
                                         filter: NSPredicate(format: "id IN %@", messageIDs)) else {return}
                    
                    self.handleRemovedMessages(Array(messagesToDelete))
                    self.deletedMessageIDs.removeAll()
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
                RealmDatabase.shared.add(objects: users)
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
                if !CacheManager.shared.doesFileExist(at: path) {
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
        return RealmDatabase.shared.retrieveObjects(ofType: User.self, filter: filter)?.toArray() ?? []
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
                            CacheManager.shared.saveData(imageData, toPath: path)
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
    private func bindToMessages()
    {
        messageListenerService?.$updatedMessages
            .debounce(for: .seconds(0.5), /// See FootNote.swift [18]
                      scheduler: DispatchQueue.global(qos: .background))
            .filter { !$0.isEmpty }
            .sink { [weak self] messagesTypes in
                guard let self = self else { return }
                self.messageListenerService?.updatedMessages.removeAll()
                Task {
                    guard self.conversation?.isInvalidated == false else {return} // See FootNote.swift [11]
                    await self.remoteMessagePaginator?.perform {
                        await self.processMessageChanges(messagesTypes)
                    }
                }
            }
            .store(in: &cancellables)
        
        messageListenerService?.$eventMessage
            .sink { [weak self] eventMessage in
                guard let message = eventMessage else {return}
                self?.createMessageClustersWith([message])
                self?.datasourceUpdateType.send(DatasourceRowAnimation.none)
            }.store(in: &cancellables)
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

        await self.handleRemovedMessages(Array(removedMessages))
        await self.handleAddedMessages(Array(filteredAdded))
        await self.handleModifiedMessage(Array(filteredModified))
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
    private func handleAddedMessages(_ messages: [Message]) async
    {
        guard !messages.isEmpty else {return}
        
        var newMessages = [Message]()
        var updatedMessages = [Message]()
        
        for remoteMessage in messages
        {
            guard let dbMessage = RealmDatabase.shared.retrieveSingleObject(
                ofType: Message.self,
                primaryKey: remoteMessage.id
            ) else {
                // Message does not exist locally, treat as new
                newMessages.append(remoteMessage)
                continue
            }
           
            /// See FootNote.swift [12]
            ///
            let dbMessageMarkedAsSeen = dbMessage.messageSeen ?? dbMessage.seenBy.contains(authUser.uid)
            let remoteMessageMarkedAsSeen = remoteMessage.messageSeen ?? remoteMessage.seenBy.contains(authUser.uid)

            if dbMessageMarkedAsSeen && !remoteMessageMarkedAsSeen
            {
                let updatedMessage = (conversation?.isGroup ?? false) ?
                remoteMessage.updateSeenBy(authUser.uid) : remoteMessage.updateSeenStatus(seenStatus: true)

                updatedMessages.append(updatedMessage)
            } else {
                // Use remote version as-is
                updatedMessages.append(remoteMessage)
            }
        }
        
        RealmDatabase.shared.add(objects: updatedMessages)

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
    }
    
    @MainActor
    private func handleRemovedMessages(_ messages: [Message])
    {
        guard !messages.isEmpty else { return }
        
        for message in messages
        {
            let day = message.timestamp.formatToYearMonthDay()
            guard let clusterIndex = messageClusters.firstIndex(where: { $0.date == day }) else {continue}
            
            // TODO: - crash on last message removal. Check chat cell recent message if it's deleted before this code runs
            //
            guard let cellVMIndex = messageClusters[clusterIndex].items.firstIndex(where: { $0.message?.id == message.id } ) else {continue}
            
            let _ = messageClusters[clusterIndex].items.remove(at: cellVMIndex)
            
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
            
            if messageClusters.isEmpty
            {
                Task { @MainActor in
                    guard let chatID = self.conversation?.id else { return }
                    do {
                       try await FirebaseChatService.shared.removeRecentMessage(fromChat: chatID)
                    } catch {
                        print("could not delete last message: ", error)
                    }
                }
            }
        }
        realmService?.removeMessagesFromRealm(messages: messages)
        
        self.datasourceUpdateType.send(.fade)
    }
    
    @MainActor
    func handleModifiedMessage(_ messages: [Message])
    {
        guard !messages.isEmpty else {return}
        
        /// Message update is handled from within cell
        RealmDatabase.shared.add(objects: messages)
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
        
        if message.voicePath != nil,
           !CacheManager.shared.doesFileExist(at: message.voicePath!)
        {
            tasks.append { await self.downloadVoiceMessageData(from: message) }
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
    private func downloadVoiceMessageData(from message: Message) async
    {
        do {
            let voiceData = try await FirebaseStorageManager.shared.getVoiceData(
                from: .message(.audio(message.id)),
                voicePath: message.voicePath!)
            CacheManager.shared.saveData(voiceData, toPath: message.voicePath!)
        } catch {
            print("Could not get voice data for message \(message.id): \(error)")
        }
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
        let realmRefMessage = RealmDatabase.shared.retrieveSingleObjectFromNewRalmInstance(
            ofType: Message.self,
            primaryKey: refMessageID
        )?.freeze()
        
        let referencedMessage = realmRefMessage == nil ? try await fetchMessage(withID: refMessageID) : realmRefMessage!
        
        if let path = referencedMessage.imagePath
        {
            let imageExists = CacheManager.shared.doesFileExist(at: path.addSuffix("small"))
            imageExists ? () : await self.downloadImageData(from: referencedMessage)
        }
        
        await syncGroupUsers(for: [referencedMessage])
        
        await MainActor.run {
            realmRefMessage == nil ?  self.realmService?.addMessagesToConversationInRealm([referencedMessage]) : ()
        }
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
                inclusive: false,
                fetchDirection: .descending
            )
            let ascendingMessages = try await FirebaseChatService.shared.fetchMessagesFromChat(
                chatID: conversation.id,
                startingFrom: startAtMessage.id,
                inclusive: true,
                fetchDirection: .ascending
            )
            return descendingMessages + ascendingMessages
        default: return []
        }
    }
    
    private func getStrategyForAdditionalMessagesFetch(direction: PaginationDirection) -> MessageFetchStrategy?
    {
        let startMessage: Message?
        
        if direction == .ascending {
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
        
        switch direction {
        case .ascending: return .ascending(startAtMessage: startMessage, included: false)
        case .descending: return .descending(startAtMessage: startMessage, included: false)
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

    @MainActor
    func paginateRemoteMessages(direction: PaginationDirection) async throws -> MessagesPaginationResult
    {
        guard let strategy = getStrategyForAdditionalMessagesFetch(direction: direction) else {return .noMoreMessagesToPaginate}
        
        let newMessages = try await fetchConversationMessages(using: strategy)
        guard !newMessages.isEmpty else { return .noMoreMessagesToPaginate }
        
        await fetchMessagesMetadata(Set(newMessages))
        await isPaginationInactiveStream.first(where: { true })
        
        if conversation?.realm != nil
        { 
            let startMessage = newMessages.first!
            realmService?.addMessagesToConversationInRealm(newMessages)
            messageListenerService?.addListenerToExistingMessages(
                startAtMesssage: startMessage,
                ascending: direction == .ascending ? true : false,
                limit: newMessages.count)
            
            if newMessages.last?.id == conversation?.recentMessageID
            {
                messageListenerService?.addListenerToUpcomingMessages()
            }
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
    var mediaItems: [MediaItem]
    {
        return conversation!.conversationMessages
            .filter("imagePath != nil")
            .sorted(by: { $0.timestamp < $1.timestamp })
            .compactMap { message in
                guard let url = CacheManager.shared.getURL(for: message.imagePath!) else {return nil}
                return MediaItem(
                    imagePath: url,
                    imageText: message.messageBody)
            }
    }
}


extension ChatRoomViewModel
{
    func retrieveImageDataFromCache(for path: String) -> Data?
    {
        return CacheManager.shared.retrieveData(from: path)
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
