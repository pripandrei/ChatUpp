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
    
    @Published var navigationStack = [GroupCreationRoute]()
    @Published var selectedGroupMembers = [UserItem]()
    @Published var imageSampleRepository: ImageSampleRepository?
    
    var disableNextButton: Bool
    {
        return selectedGroupMembers.isEmpty
    }
    
    var showSelectedUsers: Bool
    {
        return selectedGroupMembers.count > 0
    }
    
    func toggleUserSelection(_ user: UserItem)
    {
        if isUserSelected(user)
        {
            selectedGroupMembers.removeAll { $0.id == user.id }
        } else {
            selectedGroupMembers.append(user)
        }
    }
    
    func isUserSelected(_ user: UserItem) -> Bool
    {
        let isSelected = selectedGroupMembers.contains(where: { return $0.id == user.id })
        return isSelected
    }
}

//MARK: Image update
extension GroupCreationViewModel
{
    func updateImageRepository(repository: ImageSampleRepository)
    {
        self.imageSampleRepository = repository
    }
    
//    private func processImageSamples() async throws {
//        guard let sampleRepository = imageSampleRepository else { return }
//        
//        for (key, imageData) in sampleRepository.samples {
//            let path = sampleRepository.imagePath(for: key)
//            try await saveImageDataToFirebase(imageData, path: path)
//            CacheManager.shared.saveImageData(imageData, toPath: path)
//        }
//    }
//    
//    private func saveImageDataToFirebase(_ data: Data, id: String, path: String) async throws
//    {
////        let childObject = StorageChildObject.groups(id: groupID!)
//        let (_, _) = try await FirebaseStorageManager.shared.saveImage(data: data, storageChildObject: <#T##StorageChildObject#>)
//    }
}
