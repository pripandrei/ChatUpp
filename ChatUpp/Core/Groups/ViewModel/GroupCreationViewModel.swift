//
//  GroupCreationViewModel.swift
//  ChatUpp
//
//  Created by Andrei Pripa on 12/29/24.
//

import Foundation
import SwiftUI

enum GroupCreationRoute
{
    case addGroupMembers
    case setupGroupDetails
}

final class GroupCreationViewModel: SwiftUI.ObservableObject
{
    private var groupID: String?
    @Published private(set) var allUsers: [User] = []
    
    @Published private(set) var imageSampleRepository: ImageSampleRepository?
    @Published var navigationStack = [GroupCreationRoute]()
    @Published var selectedGroupMembers = [User]()
    
    @Published var groupName: String = ""

    init() {
        self.presentUsers()
    }
    
    var disableNextButton: Bool
    {
        return selectedGroupMembers.isEmpty
    }
    
    var showSelectedUsers: Bool
    {
        return selectedGroupMembers.count > 0
    }
    
    func toggleUserSelection(_ user: User)
    {
        if isUserSelected(user)
        {
            selectedGroupMembers.removeAll { $0.id == user.id }
        } else {
            selectedGroupMembers.append(user)
        }
    }
    
    func isUserSelected(_ user: User) -> Bool
    {
        let isSelected = selectedGroupMembers.contains(where: { return $0.id == user.id })
        return isSelected
    }
}

//MARK: - Group creation functions
extension GroupCreationViewModel
{
//    func createRecentMessage() {
//        
//    }
    
    func createGroup() -> Chat?
    {
        guard let authenticatedUserID = try? AuthenticationManager.shared.getAuthenticatedUser().uid else {return nil}
        
        let selfParticipant = ChatParticipant(userID: authenticatedUserID, unseenMessageCount: 0)
        var participants = selectedGroupMembers.map { ChatParticipant(userID: $0.id , unseenMessageCount: 0) }
        participants.append(selfParticipant)
        
        let group = Chat(id: UUID().uuidString,
                         participants: participants,
                         recentMessageID: "Group created",
                         messagesCount: 0,
                         isFirstTimeOpened: true,
                         dateCreated: Date(),
                         name: self.groupName,
                         thumbnailURL: imageSampleRepository?.imagePath(for: .original),
                         admins: [])
        return group
    }
    
    @MainActor
    func finishGroupCreation(_ group: Chat) async throws
    {
        self.groupID = group.id
        
        try await FirebaseChatService.shared.createNewChat(chat: group)
        try await processImageSamples()
        RealmDataBase.shared.add(objects: selectedGroupMembers)
        RealmDataBase.shared.add(object: group)
    }
}


//MARK: - Retrieve/fetch users
extension GroupCreationViewModel
{
    private func presentUsers()
    {
        let users = retrieveUsers()
        if users.isEmpty {
            Task { await fetchUsers() }
        } else {
            self.allUsers = users
        }
    }
    
    @MainActor
    private func fetchUsers() async
    {
        do {
            self.allUsers = try await FirestoreUserService.shared.fetchUsers()
        } catch {
            print("Could not fetch users: \(error)")
        }
    }
    
    private func retrieveUsers() -> [User] {
        return RealmDataBase.shared.retrieveObjects(ofType: User.self)?.toArray() ?? []
    }
}

//MARK: - Image update
extension GroupCreationViewModel
{
    func updateImageRepository(repository: ImageSampleRepository)
    {
        self.imageSampleRepository = repository
    }
    
    private func processImageSamples() async throws
    {
        guard let sampleRepository = imageSampleRepository else { return }
        
        for (key, imageData) in sampleRepository.samples {
            let path = sampleRepository.imagePath(for: key)
            try await saveImage(imageData, path: path)
        }
    }
    
    private func saveImage(_ imageData: Data, path: String) async throws
    {
        try await FirebaseStorageManager.shared.saveImage(data: imageData, to: .group(groupID!), imagePath: path)
        CacheManager.shared.saveImageData(imageData, toPath: path)
    }
}

extension GroupCreationViewModel : ImageRepositoryRepresentable {}
