//
//  ChatCellViewModel.swift
//  ChatUpp
//
//  Created by Andrei Pripa on 10/6/23.
//

import Foundation
import Combine
import Kingfisher



class ChatCellViewModel
{
    private var dataFetchTask: Task<Void,Never>?
    
    private var authUser = try! AuthenticationManager.shared.getAuthenticatedUser()
    
    private var cancellables = Set<AnyCancellable>()
    private var recentMessagesCancellables = Set<AnyCancellable>()
    private(set) var profileImageDataSubject = PassthroughSubject<Data?,Never>()
    
    private let serialQueue: DispatchQueue = .init(label: "recentMessageUpdateQueue")
    private let dispatchGroup: DispatchGroup = .init()
    
    @Published private(set) var chat: Chat
    @Published private(set) var chatUser: User?
    @Published private(set) var isParticipantActive: Bool?
    @Published private(set) var unreadMessageCount: Int?
    {
        didSet {
            handleUnreadMessageCountChange(oldValue: oldValue,
                                           newValue: unreadMessageCount)
        }
    }

    @Published private(set) var recentMessage: Message? {
        didSet {
            if oldValue != recentMessage && recentMessage != nil
            {
                self.addListenersToRecentMessage()
            }
        }
    }
                 
    private func addListenersToRecentMessage()
    {
        recentMessagesCancellables.forEach { cancellable in
            cancellable.cancel()
        }
        self.observeRealmRecentMessage()
        Task {
            do {
                try await observeFirestoreRecentMessage()
            } catch {
                print("Error attaching listeners to recent message: \(error)")
            }
        }
    }
    
    init(chat: Chat)
    {
        self.chat = chat
        
        initiateChatDataLoad()
        addRealmObserverToChat()
        observeAuthParticipantChanges()
    }

    var isAuthUserSenderOfRecentMessage: Bool {
        return authUser.uid == recentMessage?.senderId
    }
    
    private func initiateChatDataLoad()
    {
        retrieveDataFromRealm()
        
        self.dataFetchTask = Task
        { [weak self] in
            do {
                try await self?.fetchDataFromFirestore()
                await self?.addObserverToUser()
                await self?.addListenerToUser()
            } catch {
                print("task was cancelled: \(error)")
            }
        }
    }
    
    deinit {
//        print("Cell vm was deinit")
    }

    
    // image data cache
    @MainActor
    private func cacheChatAvatarImageData(_ data: Data)
    {
        if let path = profileImageThumbnailPath {
            CacheManager.shared.saveData(data, toPath: path)
        }
    }
    @MainActor
    func retrieveChatAvatarFromCache() -> Data?
    {
        guard let photoURL = profileImageThumbnailPath else { return nil }
        return CacheManager.shared.retrieveData(from: photoURL)
    }
    
    func retrieveMessageImageData(_ path: String) -> Data?
    {
        return CacheManager.shared.retrieveData(from: path)
    }
    
    func getStickerThumbnail(name: String) -> Data?
    {
        guard let url = Bundle.main.url(forResource: name, withExtension: "png") else
        { return nil }
        return try? Data(contentsOf: url)
    }
    
    /// other (not self) member in private chat if any
    ///
    private func findMemberID() -> String?
    {
        return chat.participants.first(where: { $0.userID != authUser.uid } )?.userID
    }
    
    private func handleUnreadMessageCountChange(oldValue: Int?, newValue: Int?)
    {
        guard let new = newValue, oldValue != new else { return }
        let delta: Int
        
        if let old = oldValue, old > 0 {
            delta = new - old
        } else {
            delta = new
        }
        ChatManager.shared.incrementUnseenMessageCount(by: delta)
    }
}

//MARK: - Computed properties
extension ChatCellViewModel
{
    @MainActor
    var profileImageThumbnailPath: String?
    {
        guard let originalURL = chat.isGroup ? chat.thumbnailURL : chatUser?.photoUrl else {
            return nil
        }
        return originalURL.addSuffix("medium")
    }

    
    @MainActor
    var recentMessageImageThumbnailPath: String?
    {
        guard let path = recentMessage?.imagePath else {
            return nil
        }
        return path.addSuffix("small")
    }
    
    @MainActor
    private var shouldFetchProfileImage: Bool
    {
        guard let path = profileImageThumbnailPath else {return false}
        return CacheManager.shared.doesFileExist(at: path) == false
    }
    
    @MainActor
    private var shouldFetchMessageImage: Bool
    {
        guard let path = recentMessageImageThumbnailPath else {return false}
        return CacheManager.shared.doesFileExist(at: path) == false
    }
    
    var isRecentMessagePresent: Bool
    {
        if chat.isInvalidated {return false}
        return chat.recentMessageID != nil
    }
}

//MARK: - Update cell data

extension ChatCellViewModel
{
    private func processNewRecentMessage(messageID: String)
    {
        let chatID = chat.id
        guard let newMessage = RealmDatabase.shared.retrieveSingleObject(ofType: Message.self,
                                                                         primaryKey: messageID) else
        {
            self.dispatchGroup.enter() // See FootNote.swift [20]
            
            Task {
                guard let recentMessage = await self.fetchRecentMessage() else {
                    self.dispatchGroup.leave()
                    return
                }
                await self.performMessageImageUpdate(recentMessage)
                
                if chatID == ChatRoomSessionManager.activeChatID
                { try await Task.sleep(for: .seconds(1)) }
                
                nonisolated(unsafe) let message = recentMessage
                
                await MainActor.run
                {
                    self.addMessageToRealm(message)
                    self.recentMessage = message
                    if chatID != ChatRoomSessionManager.activeChatID,
                       message.senderId != self.authUser.uid
                    {
                        self.showRecentMessageBanner()
                        if let url = Bundle.main.url(forResource: "notification_sound",
                                                     withExtension: "m4a")
                        {
                            AudioSessionManager.shared.play(audioURL: url)
                        }
                    }
                    self.dispatchGroup.leave()
                }
            }
            return
        }
        self.recentMessage = newMessage
    }

    /// - updated user after deletion
    func updateUserAfterDeletion() async 
    {
        let deletedUserID = FirestoreUserService.mainDeletedUserID
        do {
            self.chatUser = try await FirestoreUserService.shared.getUserFromDB(userID: deletedUserID)
            let imageData = try await self.fetchImageData()
            self.profileImageDataSubject.send(imageData)
        } catch {
            print("Error updating user while listening: ", error.localizedDescription)
        }
    }
}

//MARK: - Retrieve/add Realm db data

extension ChatCellViewModel {
    
    func retrieveDataFromRealm()
    {
        self.unreadMessageCount = try? retrieveAuthParticipant().unseenMessagesCount
        self.recentMessage = try? retrieveRecentMessage()
        
        if !chat.isGroup {
            self.chatUser = try? retrieveMember()
        }
    }
    
    private func retrieveMember() throws -> User 
    {
        guard let memberID = findMemberID(),
              let member = RealmDatabase.shared.retrieveSingleObject(ofType: User.self, primaryKey: memberID) else {
            throw
            RealmRetrieveError.memberNotPresent }
        return member
    }
    
    private func retrieveRecentMessage() throws -> Message
    {
        guard let messageID = chat.recentMessageID,
              let message = RealmDatabase.shared.retrieveSingleObject(ofType: Message.self, primaryKey: messageID) else {
            throw RealmRetrieveError.messageNotPresent }
        return message
    }
    
    private func retrieveAuthParticipant() throws -> ChatParticipant 
    {
        if let participant = chat.getParticipant(byID: authUser.uid) {
            return participant
        }
        throw NSError(domain: "com.chatUpp.retrieve.participant.error", code: 1, userInfo: [NSLocalizedDescriptionKey: "Auth participant is missing"])
    }
    
    private func addMessageToRealm(_ message: Message)
    {
        RealmDatabase.shared.add(object: message)
        
        if !chat.conversationMessages.contains(where: { $0.id == message.id} )
        {
            RealmDatabase.shared.update(object: chat) { chat in
                chat.conversationMessages.append(message)
            }
        }
    }
}

//MARK: - Fetch Firestore data

extension ChatCellViewModel 
{
    @MainActor
    private func fetchDataFromFirestore() async throws
    {
        try Task.checkCancellation()
        
        if let message = await fetchRecentMessage() {
            addMessageToRealm(message)
            self.recentMessage = message
        }
        try Task.checkCancellation()
        
        if !chat.isGroup
        {
            if let user = await loadOtherMemberOfChat() {
                RealmDatabase.shared.add(object: user)
                self.chatUser = user
            }
        }
        try Task.checkCancellation()
        
        if shouldFetchProfileImage
        {
            await performProfileImageDataUpdate()
        }
        try Task.checkCancellation()
        
        if shouldFetchMessageImage
        {
            await performMessageImageUpdate(recentMessage!)
        }
        
        self.profileImageDataSubject.send(retrieveChatAvatarFromCache())
    }
    
//    private func updateNewUser(_ user: User)
//    {
//        RealmDatabase.shared.add(object: user)
//        
//        if user.photoUrl != self.chatUser?.photoUrl
//        {
//            
//        }
//        self.chatUser = user
//    }
    
    private func performProfileImageDataUpdate() async
    {
        do {
            guard let imageData = try await fetchImageData() else {return}
            await cacheChatAvatarImageData(imageData)
            self.profileImageDataSubject.send(imageData)
        } catch {
            print("Could not perform image data update: ", error)
        }
    }
    
    @MainActor
    func loadOtherMemberOfChat() async -> User?
    {
        guard let memberID = findMemberID() else {return nil}
        do {
            let member = try await FirestoreUserService.shared.getUserFromDB(userID: memberID)
            return member
        } catch {
            print("Error while loading member for chat cell: ", error.localizedDescription)
            return nil
        }
    }
    
    @MainActor
    private func fetchRecentMessage() async -> Message?
    {
        do {
            return try await FirebaseChatService.shared.getRecentMessage(from: chat)
        } catch {
            print("Error while loading recent message for chat cell: ", error.localizedDescription)
            return nil
        }
    }
    
    @MainActor
    func fetchImageData(_ path: String? = nil) async throws -> Data?
    {
        guard let thumbnailURL = (path == nil) ? profileImageThumbnailPath : path else { return nil }
        
        let storagePathType: StoragePathType = chat.isGroup ? .group(chat.id) : .user(chatUser?.id ?? "Unknown")
        
        let photoData = try await FirebaseStorageManager.shared.getImage(
            from: storagePathType,
            imagePath: thumbnailURL)
        return photoData
    }
    
    @MainActor
    private func performMessageImageUpdate(_ recentMessage: Message) async
    {
        
        guard let originalPath = recentMessage.imagePath else { return }
        let thumbnailPath = originalPath.addSuffix("small")
        let messageID = recentMessage.id
//        guard let thumbnailPath = await recentMessageImageThumbnailPath else { return }
//        let originalPath = thumbnailPath.removeSuffix("small")
//        
        let paths = [thumbnailPath, originalPath]
        
        do
        {
            try await withThrowingTaskGroup(of: Void.self) { group in
                for path in paths
                {
                    group.addTask {
                        let imageData = try await FirebaseStorageManager.shared.getImage(from: .message(.image(messageID)), imagePath: path)
                        CacheManager.shared.saveData(imageData, toPath: path)

                        // trigger message update after thumbnail downloaded
                        if path == thumbnailPath
                        {
                            await MainActor.run { self.recentMessage = self.recentMessage }
                        }
                    }
                }
                for try await _ in group {}
            }
        }
        catch {
            print("Could not fetch message image data: ", error)
        }
    }
}

//MARK: - Observers/Listeners

extension ChatCellViewModel
{
    /// Observe user from Realtime db for online status update (Temporary fix while firebase functions are deactivated)
    @MainActor
    private func addObserverToUser()
    {
        guard let member = chatUser else {return}

        RealtimeUserService.shared.addObserverToUsers(member.id)
            .sink { [weak self] user in
                if let date = user.lastSeen, let isActive = user.isActive
                {
                    guard let updatedUser = self?.chatUser?.updateActiveStatus(
                        lastSeenDate: date,
                        isActive: isActive
                    ) else {return}
                    self?.isParticipantActive = isActive
//                    self?.chatUser = updatedUser
                    RealmDatabase.shared.add(object: updatedUser)
                }
            }.store(in: &cancellables)
    }
    
    /// Listen to user from Firestore db
    @MainActor
    private func addListenerToUser()
    {
        guard let memberID = chatUser?.id else {return}
        
        FirestoreUserService.shared.addListenerToUsers([memberID])
            .sink(receiveValue: {
                [weak self] userUpdateObject in
                if userUpdateObject.changeType == .modified
                {
                    let updatedUser = userUpdateObject.data
                    let oldPhotoURL = self?.chatUser?.photoUrl
                    self?.chatUser = updatedUser
                    RealmDatabase.shared.add(object: updatedUser)
                    if updatedUser.photoUrl != oldPhotoURL
                    {
                        self?.handleThumbnailChange()
                    }
                }
            }).store(in: &cancellables)
    }
    
    /// - participant observer
    ///
    private func observeAuthParticipantChanges()
    {
        guard let participant = chat.getParticipant(byID: authUser.uid) else {return}
        
        RealmDatabase.shared.observeChanges(for: participant)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] change in
                guard let self = self, change.0.name == "unseenMessagesCount" else { return }
                
                // See FootNote.swift [20]
                executeAfter(seconds: 0.1)
                {
                    self.dispatchGroup.notify(queue: self.serialQueue)
                    {
                        self.unreadMessageCount = change.0.newValue as? Int ?? self.unreadMessageCount
                    }
                }
            }.store(in: &cancellables)
    }
    
    /// - chat observer
    ///
    
    private func addRealmObserverToChat()
    {
        RealmDatabase.shared.observeChanges(for: chat)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] propertyChange in
                guard let property = ChatObservedProperty(from: propertyChange.0.name) else { return }
                
                switch property {
                case .recentMessageID:
                    self?.handleRecentMessageChange(propertyChange.0.newValue)
                case .participants:
                    self?.handleParticipantsChange()
                case .thumbnailURL:
                    self?.handleThumbnailChange()
                case .name:
                    if let chat = propertyChange.1 as? Chat
                    {
                        self?.chat = chat
                    }
                }
            }
            .store(in: &cancellables)
    }
    
    /// message observer
    @MainActor
    private func observeFirestoreRecentMessage() async throws
    {
        guard let recentMessage = recentMessage else {return}
        
        try await FirebaseChatService.shared.addListenerForExistingMessagesTest(
            inChat: chat.id,
            startAtMessageWithID: recentMessage.id,
            messageTimestamp: recentMessage.timestamp,
            ascending: true,
            limit: 1)
        .receive(on: DispatchQueue.main)
        .sink { [weak self] changeObjects in
            
            guard let changeObject = changeObjects.first else {return}
            // leave update of recent message to Chat Room VC if it is opened
            //
            guard ChatRoomSessionManager.activeChatID != self?.chat.id else {return}
            
            if changeObject.changeType == .modified
            {
                RealmDatabase.shared.add(object: changeObject.data)
                
                if changeObject.data.imagePath != nil {
                    Task {
                        await self?.performMessageImageUpdate(changeObject.data)
                    }
                } else {
                    self?.recentMessage = changeObject.data
                }
            }
            if changeObject.changeType == .removed {
                DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                    guard let message = RealmDatabase.shared.retrieveSingleObject(ofType: Message.self, primaryKey: changeObject.data.id) else {return}
                    RealmDatabase.shared.delete(objects: [message])                    
                }
            }
        }.store(in: &recentMessagesCancellables)
    }
    
    private func observeRealmRecentMessage()
    {
        guard let recentMessage = recentMessage else {return}
        
        RealmDatabase.shared.observeChanges(for: recentMessage)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] propertyChange in
                guard let self = self else { return }
                guard let property = MessageObservedProperty(from: propertyChange.0.name) else { return }
                guard let message = self.recentMessage else { return }
                
                switch property
                {
                case .imagePath:
                    guard let _ = propertyChange.0.newValue as? String else { return }
                    Task { await self.performMessageImageUpdate(message) }
                case .messageSeen:
                    self.recentMessage = propertyChange.1 as? Message
                default: break
                }
                
            }.store(in: &recentMessagesCancellables)
    }
}

//MARK: - Helper functions
extension ChatCellViewModel
{
    private func handleRecentMessageChange(_ newValue: Any?)
    {
        guard let recentMessageID = newValue as? String else
        {
            self.recentMessage = nil
            return
        }
        self.processNewRecentMessage(messageID: recentMessageID)
    }

    private func handleParticipantsChange() {
        if !self.chat.isGroup, self.findMemberID() == nil {
            Task { await self.updateUserAfterDeletion() }
        }
    }

    private func handleThumbnailChange()
    {
        Task { [weak self] in
            guard let imageURL = await self?.profileImageThumbnailPath else { return }
            

            guard let imageData = CacheManager.shared.retrieveData(from: imageURL) else {
                await self?.performProfileImageDataUpdate()
                return
            }
            self?.profileImageDataSubject.send(imageData)
        }
    }
}


extension ChatCellViewModel
{
    private func showRecentMessageBanner()
    {
        Task { @MainActor in
            
            let name = chat.isGroup ? chat.name : chatUser?.name
            guard let message = recentMessage,
                  let name else { return }
            let avatarData = retrieveChatAvatarFromCache()
            
                
            let imageData: Data?
            if let imagePath = self.recentMessageImageThumbnailPath {
                imageData = retrieveMessageImageData(imagePath)
            } else if let sticker = message.sticker {
                imageData = getStickerThumbnail(name: sticker + "_thumbnail")
            } else { imageData = nil }
            
            let bannerData = MessageBannerData(chat: chat,
                                               message: message,
                                               avatar: avatarData,
                                               titleName: name,
                                               contentThumbnail: imageData
            )
            
            MessageBannerPresenter.shared.presentBanner(usingBannerData: bannerData)
        }
    }
}

// MARK: - Cleanup
extension ChatCellViewModel
{
    func removeObservers() {
        self.recentMessagesCancellables.forEach { cancellable in
            cancellable.cancel()
        }
        recentMessagesCancellables.removeAll()
        self.cancellables.forEach { cancellable in
            cancellable.cancel()
        }
        cancellables.removeAll()
    }
}

//MARK: - Equatable protocol subs

extension ChatCellViewModel: Equatable {
    static func == (lhs: ChatCellViewModel, rhs: ChatCellViewModel) -> Bool {
        lhs.chat == rhs.chat
    }
}


//MARK: - Cleanup
extension ChatCellViewModel
{
    private func cancelFetchTask() {
        dataFetchTask?.cancel()
        dataFetchTask = nil
    }
    
    func invalidateSelf() {
        removeObservers()
        cancelFetchTask()
    }
}

class ChatRoomSessionManager
{
    static var activeChatID: String? = nil
}


enum ChatObservedProperty: String
{
    case recentMessageID
    case participants
    case thumbnailURL
    case name

    init?(from rawValue: String) {
        self.init(rawValue: rawValue)
    }
}

enum MessageObservedProperty: String
{
    case imagePath
    case messageSeen
    case messageBody

    init?(from name: String) {
        self.init(rawValue: name)
    }
}
