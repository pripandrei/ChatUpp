//
//  ChatRoomInformationViewModel.swift
//  ChatUpp
//
//  Created by Andrei Pripa on 3/19/25.
//


import SwiftUI

final class ChatRoomInformationViewModel: SwiftUI.ObservableObject
{
    private(set) var chat: Chat
    
    @Published var members: [User] = []
    @Published var membersCount: Int = 0
    
    init(chat: Chat) {
        self.chat = chat
        self.membersCount = chat.participants.count
        self.presentMembers()
    }
    
    var isAuthUserGroupMember: Bool {
        return RealmDataBase.shared.retrieveSingleObject(ofType: Chat.self, primaryKey: chat.id) != nil
    }
    
    var groupName: String {
        chat.name ?? "unknown"
    }
    
    lazy var authenticatedUser: User? = {
        guard let key = AuthenticationManager.shared.authenticatedUser?.uid else { return nil }
        return RealmDataBase.shared.retrieveSingleObject(ofType: User.self, primaryKey: key)
    }()
    
    func retrieveGroupImage() -> Data?
    {
        guard let path = chat.thumbnailURL else { return nil }
        return CacheManager.shared.retrieveImageData(from: path)
    }
}

//MARK: - Retrieve/fetch users
extension ChatRoomInformationViewModel
{
    private func presentMembers()
    {
        let users = retrieveUsers()
        if users.isEmpty {
            Task { await fetchUsers() }
        } else {
            self.members = users
        }
    }
    
    @MainActor
    private func fetchUsers() async
    {
        do {
            let membersID = Array(chat.participants.map { $0.userID })
            self.members = try await FirestoreUserService.shared.fetchUsers(with: membersID)
        } catch {
            print("Could not fetch users: \(error)")
        }
    }
    
    private func retrieveUsers() -> [User]
    {
        let membersID = Array(chat.participants.map { $0.userID })
        let filter = NSPredicate(format: "id IN %@", membersID)
        return RealmDataBase.shared.retrieveObjects(ofType: User.self,
                                                    filter: filter)?.toArray() ?? []
    }
}


//MARK: - Leave group

extension ChatRoomInformationViewModel
{
    @MainActor
    func leaveGroup() async throws
    {
        guard let authUserID = try? AuthenticationManager.shared.getAuthenticatedUser().uid else {return}
        removeRealmParticipant(with: authUserID)
        try await removeFirestoreParticipant(with: authUserID)
        
        let text = "\(authenticatedUser?.name ?? "-") has left the group"
        let message = try await createMessage(messageText: text)
        
        try await updateUnseenMessageCounterRemote()
        try await FirebaseChatService.shared.updateChatRecentMessage(
            recentMessageID: message.id,
            chatID: chat.id
        )
    }
    
    @MainActor
    private func updateUnseenMessageCounterRemote() async throws
    {
        let currentUserID = AuthenticationManager.shared.authenticatedUser!.uid
        let otherUserIDs = Array(chat.participants
            .map(\.userID)
            .filter { $0 != currentUserID })

        try await FirebaseChatService.shared.updateUnreadMessageCount(
            for: otherUserIDs,
            inChatWithID: chat.id,
            increment: true
        )
    }
    
    private func removeRealmParticipant(with authUserID: String)
    {
        RealmDataBase.shared.update(object: chat) { realmChat in
            guard let authParticipantIndex = realmChat.participants.firstIndex(where: { $0.userID == authUserID }) else { return }
            realmChat.participants.remove(at: authParticipantIndex)
        }
    }
    
    @MainActor
    private func removeFirestoreParticipant(with authUserID: String) async throws
    {
        try await FirebaseChatService.shared.removeParticipant(participantID: authUserID,
                                                               fromChatWithID: chat.id)
    }
    
    @MainActor
    private func createMessage(messageText text: String) async throws -> Message
    {
        let authUserID = AuthenticationManager.shared.authenticatedUser!.uid
        let message = Message(
            id: UUID().uuidString,
            messageBody: text,
            senderId: authUserID,
            timestamp: Date(),
            messageSeen: nil,
            seenBy: [authUserID],
            isEdited: false,
            imagePath: nil,
            imageSize: nil,
            repliedTo: nil,
            type: .title
        )
        
        try await FirebaseChatService.shared.createMessage(message: message, atChatPath: chat.id)
        
        return message
    }
    
}
