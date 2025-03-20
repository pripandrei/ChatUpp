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
    
    @Published var members: [User] = []
    
    init(chat: Chat) {
        self.chat = chat
        self.presentMembers()
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
    
    private func retrieveUsers() -> [User] {
//        return chat.members
        return RealmDataBase.shared.retrieveObjects(ofType: User.self)?.toArray() ?? []
    }
}
