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
        try await createMessage(messageText: text)
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
    
    private func createMessage(messageText text: String) async throws
    {
        let message = Message(
            id: UUID().uuidString,
            messageBody: text,
            senderId: AuthenticationManager.shared.authenticatedUser!.uid,
            timestamp: Date(),
            messageSeen: false,
            isEdited: false,
            imagePath: nil,
            imageSize: nil,
            repliedTo: nil
        )
        
        RealmDataBase.shared.add(object: message)
        try await FirebaseChatService.shared.createMessage(message: message, atChatPath: chat.id)
    }
    
}
