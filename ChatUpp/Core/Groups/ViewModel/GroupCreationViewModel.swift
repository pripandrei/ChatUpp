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
    private(set) var allUsers: [User] = []
    
    @Published var navigationStack = [GroupCreationRoute]()
//    @Published var selectedGroupMembers = [UserItem]()
    @Published var selectedGroupMembers = [User]() {
        didSet {
            print("Set users: ", selectedGroupMembers)
        }
    }
    @Published var imageSampleRepository: ImageSampleRepository?
    
//    init(groupID: String? = nil, navigationStack: [GroupCreationRoute] = [GroupCreationRoute](), selectedGroupMembers: [User] = [User](), imageSampleRepository: ImageSampleRepository? = nil, disableNextButton: Bool, showSelectedUsers: Bool) {
//        self.groupID = groupID
//        self.navigationStack = navigationStack
//        self.selectedGroupMembers = selectedGroupMembers
//        self.imageSampleRepository = imageSampleRepository
//    }
    
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

extension GroupCreationViewModel
{
    private func presentUsers()
    {
        let users = retrieveUsers()
        if users.isEmpty {
            self.allUsers = users
        } else {
            Task { await fetchUsers() }
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

//MARK: Image update
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
        let _ = try await FirebaseStorageManager.shared.saveImage(data: imageData, to: .group(groupID!), imagePath: path)
        CacheManager.shared.saveImageData(imageData, toPath: path)
    }
}
