//
//  ChatRoomInformationViewModel.swift
//  ChatUpp
//
//  Created by Andrei Pripa on 3/19/25.
//


import SwiftUI

final class ChatRoomInformationViewModel: SwiftUI.ObservableObject
{
    private let chat: Chat
    
//    @Published var navStack = [GroupCreationRoute]()
    @Published var members: [User] = []
    @Published var groupName: String = ""
    @Published var membersCount: Int = 0
    
    init(chat: Chat) {
        self.chat = chat
        self.groupName = chat.name ?? "No name"
        self.membersCount = chat.participants.count
        self.presentMembers()
    }
    
    var isAuthUserGroupMember: Bool {
        return RealmDataBase.shared.retrieveSingleObject(ofType: Chat.self, primaryKey: chat.id) != nil
    }
    
//    var groupName: String {
//        chat.name ?? "No name"
//    }
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
    
    private func retrieveUsers() -> [User] {
//        return chat.members
        return RealmDataBase.shared.retrieveObjects(ofType: User.self)?.toArray() ?? []
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
    }
    
    private func removeRealmParticipant(with authUserID: String)
    {
        RealmDataBase.shared.update(object: chat) { realmChat in
            guard let authParticipantIndex = realmChat.participants.firstIndex(where: { $0.userID == authUserID }) else {return}
            realmChat.participants.remove(at: authParticipantIndex)
        }
    }
    @MainActor
    private func removeFirestoreParticipant(with authUserID: String) async throws
    {
        try await FirebaseChatService.shared.removeParticipant(participantID: authUserID, fromChatWithID: chat.id)
    }
    
}
