//
//  ProfileEditingViewModel.swift
//  ChatUpp
//
//  Created by Andrei Pripa on 12/31/23.
//

import Foundation
import Combine

final class ProfileEditingViewModel
{
    @Published private(set) var profileDataIsEdited: Bool?
    private(set) var initialProfilePhoto: Data
    private var user: User
    private var userData: (name: String?, phone: String?, nickname: String?)
    
    private var imageSampleRepository: ImageSampleRepository?
    
    deinit {
//        print("ProfileEditingViewModel was deinited")
    }
    
    var userDataItems: [String?]
    {
        let userDataMirror = Mirror(reflecting: userData)
        return userDataMirror.children.map({ $0.value }) as! [String?]
    }
    
    private var authUser: AuthenticatedUserData {
        if let user = try? AuthenticationManager.shared.getAuthenticatedUser() {
            return user
        }
        fatalError("user is missing")
    }
    
    var userNickname: String
    {
        return user.nickname ?? ""
    }
    
    init(user: User, profilePicutre: Data)
    {
        self.userData.name = user.name!
        self.userData.phone = user.phoneNumber
        self.userData.nickname = user.nickname
        self.initialProfilePhoto = profilePicutre
        
        self.user = user
    }
    
    func applyTitle(title: String, toItem item: Int)
    {
        switch item {
        case 0: userData.name = title.isEmpty ? nil : title
        case 1: userData.phone = title
        case 2: userData.nickname = title
        default:break
        }
    }
    
    func handleProfileDataUpdate() {
        Task {
            do {
                try await processImageSamples()
                await removePreviousImage()
                try await updateFirestoreUser()

                Task { @MainActor in
                    let updatedUser = createUpdatedUser()
                    updateAuthUser(with: updatedUser)
                    updateRealmUser(updatedUser)
//                    updateCacheProfileImageData()
                    profileDataIsEdited = true
                }
            } catch {
                print("Error occurred while updating user data: ", error)
            }
        }
    }
}

//MARK: - User update
extension ProfileEditingViewModel
{
    private func createUpdatedUser() -> User
    {
        return User(userId: user.id,
                    name: userData.name,
                    email: user.email,
                    photoUrl: imageSampleRepository?.imagePath(for: .original) ?? user.photoUrl,
                    phoneNumber: userData.phone,
                    nickName: userData.nickname,
                    dateCreated: user.dateCreated,
                    lastSeen: user.lastSeen,
                    isActive: user.isActive)
    }
    
    private func updateRealmUser(_ user: User)
    {
        RealmDatabase.shared.add(object: user)
    }
    
    private func updateAuthUser(with dbUser: User)
    {
        AuthenticationManager.shared.updateAuthUserData(
            name: dbUser.name,
            phoneNumber: dbUser.phoneNumber,
            photoURL: dbUser.photoUrl
        )
    }
    
    private func updateFirestoreUser() async throws
    {
        try await FirestoreUserService.shared.updateUser(with: authUser.uid,
                                                         usingName: userData.name,
                                                         profilePhotoURL: imageSampleRepository?.imagePath(for: .original),
                                                         phoneNumber: userData.phone,
                                                         nickname: userData.nickname)
    }
}

//MARK: - Image update
extension ProfileEditingViewModel
{
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
        try await FirebaseStorageManager.shared.saveImage(
            data: imageData,
            to: .user(authUser.uid),
            imagePath: path
        )
        CacheManager.shared.saveData(imageData, toPath: path)
    }
    
    private func removePreviousImage() async
    {
        guard imageSampleRepository != nil,
        let photoURL = authUser.photoURL else {return}
        
        for sizeCase in ImageSample.SizeKey.allCases {
            do {
                let imagePath = sizeCase == .original ? photoURL : photoURL.addSuffix(sizeCase.rawValue)
                
                try await FirebaseStorageManager.shared.deleteImage(
                    from: .user(authUser.uid),
                    imagePath: imagePath)
            } catch {
                print("Error occure while removing previous image!: ", error)
            }
        }
    }
    
    private func removeProfileImage(ofUser userID: String, urlPath: String) async throws
    {
        try await FirebaseStorageManager.shared.deleteImage(
            from: .user(userID),
            imagePath: urlPath
            )
    }
    
    func updateImageRepository(repository: ImageSampleRepository) {
        self.imageSampleRepository = repository
    }
}

//MARK: - Items placeholder
extension ProfileEditingViewModel
{
    enum ProfileEditingItemsPlaceholder: String, CaseIterable
    {
        case name = "name"
        case phone = "ex. +37376445934"
        case username = "username"
    }
}
