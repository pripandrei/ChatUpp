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
    
//    private var onChatRoomVCDidDissapear: (() -> Void)?
    
    private var authUser = try! AuthenticationManager.shared.getAuthenticatedUser()
    
    private var cancellables = Set<AnyCancellable>()
    private var recentMessagesCancellables = Set<AnyCancellable>()
    
    private(set) var profileImageDataSubject = PassthroughSubject<Data?,Never>()
    private(set) var messageImageDataSubject = PassthroughSubject<Data?,Never>()
    
    @Published private(set) var chat: Chat
    @Published private(set) var chatUser: User?
    @Published private(set) var titleName: String?
    @Published private(set) var unreadMessageCount: Int?
    {
        didSet {
            handleUnreadMessageCountChange(oldValue: oldValue,
                                           newValue: unreadMessageCount)
        }
    }

    @Published private(set) var recentMessage: Message? {
        didSet {
            if oldValue != recentMessage
            {
                self.addListenersToRecentMessage()
//                if recentMessage?.imagePath != nil {
//                    Task { await self.performMessageImageUpdate() }
//                }
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
//        setupBinding()
    }
    
//    private func setupBinding()
//    {
//        ChatRoomSessionManager.activeChatID
//            .dropFirst()
//            .sink { activeChatID in
//                if activeChatID != self.chat.id {
//                    self.onChatRoomVCDidDissapear?()
//                }
//            }.store(in: &cancellables)
//    }
    
    var isAuthUserSenderOfRecentMessage: Bool {
        return authUser.uid == recentMessage?.senderId
    }
    
    private func initiateChatDataLoad()
    {
        do {
            try retrieveDataFromRealm()
        }
        catch {
            print("Error retrieving data from Realm: \(error)")
        }
        
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
        print("Cell vm was deinit")
    }

    
    // image data cache
    @MainActor
    private func cacheImageData(_ data: Data)
    {
        if let path = profileImageThumbnailPath {
            CacheManager.shared.saveImageData(data, toPath: path)
        }
    }
    @MainActor
    func retrieveImageFromCache() -> Data?
    {
        guard let photoURL = profileImageThumbnailPath else { return nil }
        return CacheManager.shared.retrieveImageData(from: photoURL)
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
        notifyUnseenCountChanged(delta)
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
        return CacheManager.shared.doesImageExist(at: path) == false
    }
    
    @MainActor
    private var shouldFetchMessageImage: Bool
    {
        guard let path = recentMessageImageThumbnailPath else {return false}
        return CacheManager.shared.doesImageExist(at: path) == false
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
    private func setNewRecentMessage(messageID: String)
    {
        let chatID = chat.id
        guard let newMessage = RealmDataBase.shared.retrieveSingleObject(ofType: Message.self,
                                                                         primaryKey: messageID) else
        {
            Task {
                guard let recentMessage = await loadRecentMessage() else {return}
                await performMessageImageUpdate(messageID)
                
                if chatID == ChatRoomSessionManager.activeChatID
                {
                    try await Task.sleep(for: .seconds(1))
                }
                 
                await MainActor.run
                {
//                    /// See FootnNote.swift - [4]
//                    guard ChatRoomSessionManager.activeChatID.value != self.chat.id else
//                    {
//                        self.onChatRoomVCDidDissapear = {
//                            self.addMessageToRealm(recentMessage)
//                            self.recentMessage = recentMessage
//                        }
//                        return
//                    }
                    addMessageToRealm(recentMessage)
                    self.recentMessage = recentMessage
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
    
    func retrieveDataFromRealm() throws 
    {
        self.unreadMessageCount = try retrieveAuthParticipant().unseenMessagesCount
        self.recentMessage = try retrieveRecentMessage()
        
        if !chat.isGroup { self.chatUser = try retrieveMember() }
    }
    
    private func retrieveMember() throws -> User 
    {
        guard let memberID = findMemberID(),
              let member = RealmDataBase.shared.retrieveSingleObject(ofType: User.self, primaryKey: memberID) else {
            throw
            RealmRetrieveError.memberNotPresent }
        return member
    }
    
    private func retrieveRecentMessage() throws -> Message
    {
        guard let messageID = chat.recentMessageID,
              let message = RealmDataBase.shared.retrieveSingleObject(ofType: Message.self, primaryKey: messageID) else {
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
        RealmDataBase.shared.add(object: message)
        
        if !chat.conversationMessages.contains(where: { $0.id == message.id} )
        {
            RealmDataBase.shared.update(object: chat) { chat in
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
        
        if let message = await loadRecentMessage() {
            addMessageToRealm(message)
            self.recentMessage = message
        }
        try Task.checkCancellation()
        
        if !chat.isGroup
        {
            if let user = await loadOtherMemberOfChat() {
                RealmDataBase.shared.add(object: user)
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
            await performMessageImageUpdate(recentMessage!.id)
        }
        self.profileImageDataSubject.send(retrieveImageFromCache())
    }
    
//    private func checkIfAuthUserIsStillMemberOfChat() -> Bool
//    {
//        FirebaseChatService.shared.
//    }
    
    private func updateNewUser(_ user: User)
    {
        RealmDataBase.shared.add(object: user)
        
        if user.photoUrl != self.chatUser?.photoUrl
        {
            
        }
        self.chatUser = user
    }
    
    private func performProfileImageDataUpdate() async
    {
        do {
            guard let imageData = try await fetchImageData() else {return}
            await cacheImageData(imageData)
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
    private func loadRecentMessage() async -> Message?
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
    
    
    private func performMessageImageUpdate(_ messageID: String) async
    {
        guard let path = await recentMessageImageThumbnailPath else { return }
        let paths = [path, path.addSuffix("small")]
        do {
            for path in paths {
                let imageData = try await FirebaseStorageManager.shared.getImage(from: .message(messageID), imagePath: path)
                CacheManager.shared.saveImageData(imageData, toPath: path)
                
            }
            self.recentMessage = self.recentMessage // trigger message image update
            
        } catch {
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
                    self?.chatUser = updatedUser
                    RealmDataBase.shared.add(object: updatedUser)
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
                    RealmDataBase.shared.add(object: updatedUser)
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
        
        RealmDataBase.shared.observeChanges(for: participant)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] change in
                guard let self = self, change.0.name == "unseenMessagesCount" else { return }
                self.unreadMessageCount = change.0.newValue as? Int ?? self.unreadMessageCount
            }.store(in: &cancellables)
    }
    
    /// - chat observer
    ///
    
    private func addRealmObserverToChat()
    {
        RealmDataBase.shared.observeChanges(for: chat)
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
                RealmDataBase.shared.add(object: changeObject.data)
                
                if changeObject.data.imagePath != nil {
                    Task {
                        await self?.performMessageImageUpdate(changeObject.data.id)
                    }
                } else {
                    self?.recentMessage = changeObject.data
                }
            }
            if changeObject.changeType == .removed {
                DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                    guard let message = RealmDataBase.shared.retrieveSingleObject(ofType: Message.self, primaryKey: changeObject.data.id) else {return}
                    RealmDataBase.shared.delete(object: message)                    
                }
            }
        }.store(in: &recentMessagesCancellables)
    }
    
    private func observeRealmRecentMessage()
    {
        guard let recentMessage = recentMessage else {return}
        
        RealmDataBase.shared.observeChanges(for: recentMessage)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] propertyChange in
                guard let self = self else { return }
                guard let property = MessageObservedProperty(from: propertyChange.0.name) else { return }
                guard let messageID = self.recentMessage?.id else { return }
                
                switch property
                {
                case .imagePath:
                    guard let _ = propertyChange.0.newValue as? String else { return }
                    Task { await self.performMessageImageUpdate(messageID) }
                case .messageSeen:
                    self.recentMessage = propertyChange.1 as? Message
                }
                
            }.store(in: &recentMessagesCancellables)
    }
}

//MARK: - Helper functions
extension ChatCellViewModel
{
    private func handleRecentMessageChange(_ newValue: Any?) {
        guard let recentMessageID = newValue as? String else { return }
        self.setNewRecentMessage(messageID: recentMessageID)
    }

    private func handleParticipantsChange() {
        if !self.chat.isGroup, self.findMemberID() == nil {
            Task { await self.updateUserAfterDeletion() }
        }
    }

    private func handleThumbnailChange() {
        Task { [weak self] in
            guard let imageURL = await self?.profileImageThumbnailPath else { return }

            let imageIsCached = CacheManager.shared.doesImageExist(at: imageURL)

            if !imageIsCached {
                await self?.performProfileImageDataUpdate()
            }
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

//MARK: - Notification
extension ChatCellViewModel
{
    private func notifyUnseenCountChanged(_ updatedCount: Int)
    {
        NotificationCenter.default.post(name: .didUpdateUnseenMessageCount,
                                        object: nil,
                                        userInfo: ["unseen_messages_count": updatedCount])
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
//        titleName = nil
//        unreadMessageCount = nil
//        chatUser = nil
//        recentMessage = nil
    }
}

class ChatRoomSessionManager
{
//    static var activeChatID = CurrentValueSubject<String?, Never>(nil)
    static var activeChatID: String? = nil
}


enum ChatObservedProperty: String
{
    case recentMessageID
    case participants
    case thumbnailURL

    init?(from name: String) {
        self.init(rawValue: name)
    }
}

enum MessageObservedProperty: String {
    case imagePath
    case messageSeen

    init?(from name: String) {
        self.init(rawValue: name)
    }
}
