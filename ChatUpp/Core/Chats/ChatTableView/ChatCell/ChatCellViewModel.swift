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
    private(set) var chat: Chat
    private var usersListener: Listener?
    private var userObserver: RealtimeObservable?
    private var authUser = try! AuthenticationManager.shared.getAuthenticatedUser()
    private var cancellables = Set<AnyCancellable>()
    private(set) var imageDataUpdateSubject = PassthroughSubject<Void,Never>()
    
    @Published private(set) var chatUser: User?
    @Published private(set) var recentMessage: Message?
    @Published private(set) var unreadMessageCount: Int?
    
    
    init(chat: Chat) {
        self.chat = chat
        
        initiateChatDataLoad()
        observeAuthParticipantChanges()
    }
    
    private func initiateChatDataLoad()
    {
        try? retrieveDataFromRealm()
        
        Task
        {
            await fetchDataFromFirestore()
            await self.addObserverToUser()
            await self.addListenerToUser()
            self.addDataToRealm()
        }
    }
    
    private func addDataToRealm() {
        
        guard let member = chatUser else {return}
        
        Task { @MainActor in
            RealmDataBase.shared.add(object: member)
            addMessageToRealm()
        }
    }
    
    // image data cache
    @MainActor
    private func cacheImageData(_ data: Data)
    {
        if let path = profileImageThumbnailPath {
            CacheManager.shared.saveImageData(data, toPath: path)
        }
    }
    
    func retrieveProfileImageFromCache() -> Data?
    {
        guard let userProfilePhotoURL = profileImageThumbnailPath else { return nil }
        return CacheManager.shared.retrieveImageData(from: userProfilePhotoURL)
    }
}

//MARK: - Computed properties
extension ChatCellViewModel
{
    private var profileImageThumbnailPath: String?
    {
//        let thumbnailString = "_" + ImageSample.SizeKey.small.rawValue
        let thumbnailString = "_" + "thumbnail"
        let path = chatUser?.photoUrl?.replacingOccurrences(of: ".jpg", with: "\(thumbnailString).jpg")
        return path
    }
    
    private var profileImageChanged: Bool
    {
        let dbUser = try? retrieveMember()
        return self.chatUser?.photoUrl != dbUser?.photoUrl
    }
    
    private func findMemberID() -> String? {
        return chat.participants.first(where: { $0.userID != authUser.uid } )?.userID
    }
    
    var isRecentMessagePresent: Bool?
    {
        guard chatUser != nil else { return nil }
        if let _ = chat.recentMessageID { return true }
        return false
    }
}

//MARK: - Update cell data

extension ChatCellViewModel {
    
    func updateChatParameters()
    {
        if findMemberID() != chatUser?.id {
            Task { await updateUserAfterDeletion() }
        }
        if chat.recentMessageID != recentMessage?.id {
            Task {
                recentMessage = await loadRecentMessage()
                await MainActor.run { addMessageToRealm() }
            }
        }
    }

    /// - updated user after deletion
    func updateUserAfterDeletion() async 
    {
        let deletedUserID = FirestoreUserService.mainDeletedUserID
        do {
            self.chatUser = try await FirestoreUserService.shared.getUserFromDB(userID: deletedUserID)
            // TODO: this should be handleld
//            self.memberProfileImage = try await self.fetchImageData()
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
        self.chatUser = try retrieveMember()
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
    
    private func addMessageToRealm() {
        if let recentMessage = recentMessage,
            !chat.conversationMessages.contains(where: { $0.id == recentMessage.id} )
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
        do {
            async let loadRecentMessage = await loadRecentMessage()
            async let loadUser          = await loadOtherMemberOfChat()
            
            (recentMessage, chatUser)   = await (loadRecentMessage, loadUser)
            
            if profileImageChanged { try await performImageDataUpdate() }
        } catch {
            print("Could not fetch ChatCellVM data from Firestore: ", error.localizedDescription)
        }
    }
    
    private func performImageDataUpdate() async throws
    {
        guard let imageData = try await fetchImageData() else {return}
        await cacheImageData(imageData)
        self.imageDataUpdateSubject.send()
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
    func loadRecentMessage() async -> Message?
    {
        do {
            return try await FirebaseChatService.shared.getRecentMessage(from: chat)
        } catch {
            print("Error while loading recent message for chat cell: ", error.localizedDescription)
            return nil
        }
    }

    func fetchImageData() async throws -> Data? 
    {
        guard let user = self.chatUser,
              let userProfilePhotoURL = profileImageThumbnailPath else {
            return nil
        }
        let photoData = try await FirebaseStorageManager.shared.getImage(from: .user(user.id), imagePath: userProfilePhotoURL)
        return photoData
    }
}

//MARK: - Listeners

extension ChatCellViewModel {

    /// Observe user from Realtime db (Temporary fix while firebase functions are deactivated)
    @MainActor
    private func addObserverToUser() {
        guard let member = chatUser else {return}
        
        self.userObserver = RealtimeUserService.shared.addObserverToUsers(member.id) { [weak self] realtimeDBUser in
            
            if realtimeDBUser.isActive != self?.chatUser?.isActive
            {
                if let date = realtimeDBUser.lastSeen, let isActive = realtimeDBUser.isActive 
                {
                    self?.chatUser = self?.chatUser?.updateActiveStatus(lastSeenDate: date,isActive: isActive)
                }
            }
        }
    }
    
    /// Listen to user from Firestore db
    @MainActor
    private func addListenerToUser()
    {
        guard let memberID = chatUser?.id else {return}
        
        self.usersListener = FirestoreUserService.shared.addListenerToUsers([memberID]) { [weak self] users, documentsTypes in
            guard let self = self else {return}
            // since we are listening only for one user here
            // we can just get the first user and docType
            guard let docType = documentsTypes.first, let user = users.first, docType == .modified else {return}
            self.chatUser = user
        }
    }
}

//MARK: - participant observer
extension ChatCellViewModel
{
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
}

//MARK: - Equatable protocol subs

extension ChatCellViewModel: Equatable {
    static func == (lhs: ChatCellViewModel, rhs: ChatCellViewModel) -> Bool {
        lhs.chat == rhs.chat
    }
}
