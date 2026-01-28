//
//  GroupCreationViewModel.swift
//  ChatUpp
//
//  Created by Andrei Pripa on 12/29/24.
//

import Foundation
import SwiftUI
import Combine

enum GroupCreationRoute
{
    case addGroupMembers
    case setupGroupDetails
}

final class GroupCreationViewModel: SwiftUI.ObservableObject
{
    private var groupID: String?
    
    @Published private(set) var chatGroup: Chat?
    @Published private(set) var allUsers: [User] = []
    @Published private(set) var searchedUsers: [User] = []
    @Published private(set) var imageSampleRepository: ImageSampleRepository?
    @Published var navigationStack = [GroupCreationRoute]()
    @Published var selectedGroupMembers = [User]()
    @Published var groupName: String = ""
    @Published var searchText: String = ""
    private var searchTask: Task<Void, Never>?

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

    var usersToShow: [User]
    {
        return !searchText.isEmpty ? searchedUsers : allUsers
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
    
    func emptySearchUsers()
    {
        self.searchedUsers.removeAll(keepingCapacity: true)
    }
}

//MARK: - User search
extension GroupCreationViewModel
{
    func performSearch(query: String) async
    {
        self.searchTask?.cancel()
        
        self.searchTask = Task { @MainActor in
            
            try? await Task.sleep(for: .seconds(0.3))
            guard !Task.isCancelled else { return }
            
            let normalizedText = query.normalizedSerachText()
            let localUsers = performLocalUsersSearch(from: normalizedText)
            
            if !localUsers.isEmpty
            {
                self.searchedUsers = localUsers
                return
            }
            
            let globalUsers = await performGlobalUserSearch(from: normalizedText)
            self.searchedUsers = globalUsers
        }
    }
    
    @MainActor
    private func performLocalUsersSearch(from query: String) -> [User] {
        let nameRawValue = User.CodingKeys.name.rawValue
        let nicknameRawValue = User.CodingKeys.nickname.rawValue
        
        let queryWords = query.components(separatedBy: " ").filter { !$0.isEmpty }
        var argumentsArray = [String]()
        
        let predicates = queryWords
            .map { word in
                argumentsArray.append(word)
                argumentsArray.append(word)
                // Each word must be found in name OR nickname
                return "(\(nameRawValue) CONTAINS[c] %@ OR \(nicknameRawValue) CONTAINS[c] %@)"
            }
            .joined(separator: " AND ")
        
        let finalPredicate = NSPredicate(format: predicates, argumentArray: argumentsArray)
        
        guard let result = RealmDatabase.shared.retrieveObjects(ofType: User.self,
                                                                filter: finalPredicate) else { return [] }
        return Array(result.prefix(20))
    }
    
    private func performGlobalUserSearch(from query: String) async -> [User]
    {
        do {
            return try await AlgoliaSearchManager.shared.searchInUsersIndex(withQuery: query)
        } catch {
            print("Could not perform search on users from Algolia: \(error)")
        }
        return []
    }
}

//MARK: - Group creation functions
extension GroupCreationViewModel
{
    private func createMessage(text: String) -> Message
    {
        let authUserID = AuthenticationManager.shared.authenticatedUser!.uid
        
        return Message(
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
    }
    
    @MainActor
    private func createGroup() -> Chat
    {
        let authenticatedUserID = try! AuthenticationManager.shared.getAuthenticatedUser().uid
        
        let selfParticipant = ChatParticipant(userID: authenticatedUserID, unseenMessageCount: 0)
        var participants = self.selectedGroupMembers.map { ChatParticipant(userID: $0.id , unseenMessageCount: 1) }
        participants.append(selfParticipant)
        
        let group = Chat(id: UUID().uuidString,
                         participants: participants,
                         recentMessageID: nil,
                         messagesCount: 0,
                         isFirstTimeOpened: true,
                         dateCreated: Date(),
                         name: self.groupName,
                         thumbnailURL: imageSampleRepository?.imagePath(for: .original),
                         admins: [])
        return group
    }
    
    @MainActor
    func finishGroupCreation(_ attempt: Int = 1) async throws
    {
        guard attempt < 6 else { throw NetworkError.timeout }
        
        if NetworkMonitor.shared.isReachable
        {
            let group = createGroup()
            self.groupID = group.id
             
            let message = createMessage(text: GroupEventMessage.created.eventMessage)
            
            RealmDatabase.shared.add(objects: self.selectedGroupMembers)
            RealmDatabase.shared.add(object: group)
            RealmDatabase.shared.update(object: group) { dbChat in
                dbChat.recentMessageID = message.id
                dbChat.conversationMessages.append(message)
            }
            
            try await FirebaseChatService.shared.createNewChat(chat: group)
            try await FirebaseChatService.shared.createMessage(message: message, atChatPath: group.id)
            try await processImageSamples()
            
            self.chatGroup = group
            
            ChatManager.shared.broadcastNewCreatedChat(group)
        } else {
            try await Task.sleep(for: .seconds(3))
            try await finishGroupCreation(attempt + 1)
        }
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

        guard let users = RealmDatabase.shared.retrieveObjects(ofType: User.self) else {return []}
        return Array(users.prefix(50))
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
        CacheManager.shared.saveData(imageData, toPath: path)
    }
}

extension GroupCreationViewModel : ImageRepositoryRepresentable {}




