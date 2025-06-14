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
    private var authUser = try! AuthenticationManager.shared.getAuthenticatedUser()
    private var cancellables = Set<AnyCancellable>()
    private(set) var imageDataSubject = PassthroughSubject<Data?,Never>()
    
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
            if oldValue != recentMessage {
                Task { try await addListernerToRecentMessage() }
            }
        }
    }
    
    deinit {
        print("deinit")
    }
    
    init(chat: Chat)
    {
        self.chat = chat

        initiateChatDataLoad()
        addObserverToChat()
        observeAuthParticipantChanges()
    }
    
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
        
        Task
        {
            await fetchDataFromFirestore()
            await self.addObserverToUser()
            await self.addListenerToUser()
            self.addDataToRealm()
        }
    }
    
    private func addDataToRealm()
    {
        Task { @MainActor in
            addMessageToRealm()
            
            guard let member = chatUser else {return}
            
            RealmDataBase.shared.add(object: member)
        }
    }
    
    // image data cache
    @MainActor
    private func cacheImageData(_ data: Data)
    {
        if let path = imageThumbnailPath {
            CacheManager.shared.saveImageData(data, toPath: path)
        }
    }
    @MainActor
    func retrieveImageFromCache() -> Data?
    {
        guard let photoURL = imageThumbnailPath else { return nil }
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
    var imageThumbnailPath: String?
    {
        guard let originalURL = chat.isGroup ? chat.thumbnailURL : chatUser?.photoUrl else {
            return nil
        }
        return originalURL.replacingOccurrences(of: ".jpg", with: "_medium.jpg")
    }
    
    @MainActor
    private var shouldFetchImage: Bool
    {
        guard let path = imageThumbnailPath else {return false}
        return CacheManager.shared.doesImageExist(at: path) == false
    }
    
    var isRecentMessagePresent: Bool
    {
        return chat.recentMessageID != nil
    }
}

//MARK: - Update cell data

extension ChatCellViewModel {
    
    // TODO:  add aditional update chekers
    // or better, add listener to chat realm and apply needed code to different update field scenario
    
    private func setNewRecentMessage(messageID: String)
    {
        guard let newMessage = RealmDataBase.shared.retrieveSingleObject(ofType: Message.self, primaryKey: messageID) else
        {
            Task {
                recentMessage = await loadRecentMessage()
                await MainActor.run { addMessageToRealm() }
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
            self.imageDataSubject.send(imageData)
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
    
    private func addMessageToRealm()
    {
        guard let recentMessage = recentMessage else {return}
        
        RealmDataBase.shared.add(object: recentMessage)
        
        if !chat.conversationMessages.contains(where: { $0.id == recentMessage.id} )
        {
            RealmDataBase.shared.update(object: chat) { chat in
                chat.conversationMessages.append(recentMessage)
            }
        }
    }
}

//MARK: - Fetch Firestore data

extension ChatCellViewModel 
{
    @MainActor
    private func fetchDataFromFirestore() async
    {
        self.recentMessage = await loadRecentMessage()
 
        if !chat.isGroup
        {
            self.chatUser = await loadOtherMemberOfChat()
        }
        
        if shouldFetchImage
        {
            await performImageDataUpdate()
        }
    }
    
    private func performImageDataUpdate() async
    {
        do {
            guard let imageData = try await fetchImageData() else {return}
            await cacheImageData(imageData)
            self.imageDataSubject.send(imageData)
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
        guard let thumbnailURL = (path == nil) ? imageThumbnailPath : path else { return nil }
        
        let storagePathType: StoragePathType = chat.isGroup ? .group(chat.id) : .user(chatUser?.id ?? "Unknown")
        
        let photoData = try await FirebaseStorageManager.shared.getImage(from: storagePathType, imagePath: thumbnailURL)
        return photoData
    }
}

//MARK: - Observers/Listeners

extension ChatCellViewModel
{
    /// Observe user from Realtime db (Temporary fix while firebase functions are deactivated)
    @MainActor
    private func addObserverToUser() {
        guard let member = chatUser else {return}
        
        RealtimeUserService.shared.addObserverToUsers(member.id)
            .sink(receiveValue: { [weak self] user in
                if user.isActive != self?.chatUser?.isActive
                {
                    if let date = user.lastSeen, let isActive = user.isActive
                    {
                        self?.chatUser = self?.chatUser?.updateActiveStatus(lastSeenDate: date,isActive: isActive)
                    }
                }
            }).store(in: &cancellables)
    }
    
    /// Listen to user from Firestore db
    @MainActor
    private func addListenerToUser()
    {
        guard let memberID = chatUser?.id else {return}
        
        FirestoreUserService.shared.addListenerToUsers([memberID])
            .sink(receiveValue: {
                [weak self] userUpdateObject in
                if userUpdateObject.changeType == .modified {
                    self?.chatUser = userUpdateObject.data
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
                guard let self = self, change.name == "unseenMessagesCount" else { return }
                self.unreadMessageCount = change.newValue as? Int ?? self.unreadMessageCount
            }.store(in: &cancellables)
    }
    
    /// - chat observer
    ///
    
    private func addObserverToChat()
    {
        RealmDataBase.shared.observeChanges(for: chat)
            .receive(on: DispatchQueue.main)
            .sink { propertyChange in
                
                switch propertyChange.name {
                case "recentMessageID":
                    guard let recentMessageID = propertyChange.newValue as? String else {return}
                    self.setNewRecentMessage(messageID: recentMessageID)
                case "participants":
                    if !self.chat.isGroup,
                       self.findMemberID() == nil
                    {
                        Task { await self.updateUserAfterDeletion() }
                    }
                case "thumbnailURL":
                    Task {
                        guard let imageURL = await self.imageThumbnailPath else {return}
                        
                        let imageIsCached = CacheManager.shared.doesImageExist(at: imageURL)
                        
                        if imageIsCached == false {
                            await self.performImageDataUpdate()
                        }
                    }
                default: break
                }
            }.store(in: &cancellables)
    }
    
    @MainActor
    private func addListernerToRecentMessage() async throws
    {
        guard let recentMessageID = recentMessage?.id else {return}
        
        try await FirebaseChatService.shared.addListenerForExistingMessages(
            inChat: chat.id,
            startAtMessageWithID: recentMessageID,
            ascending: true,
            limit: 1)
        .receive(on: DispatchQueue.main)
        .sink { changeObject in
            if changeObject.changeType == .modified {
                RealmDataBase.shared.add(object: changeObject.data)
                self.recentMessage = changeObject.data
            }
        }.store(in: &cancellables)
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
