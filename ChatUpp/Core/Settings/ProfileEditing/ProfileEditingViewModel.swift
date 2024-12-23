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
    private var editedProfilePhoto: Data?
    private var profilePictureURL: String?
    private var user: User
    private var userData: (name: String?, phone: String?, nickname: String?)
    
    deinit {
        print("ProfileEditingViewModel was deinited")
    }
    
    var userDataItems: [String?]
    {
        let userDataMirror = Mirror(reflecting: userData)
        return userDataMirror.children.map({ $0.value }) as! [String?]
    }
    
    private var authUser: AuthDataResultModel {
        if let user = try? AuthenticationManager.shared.getAuthenticatedUser() {
            return user
        }
        fatalError("user is missing")
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
                try await saveImageToStorage()
                try await removePreviousImage()
                try await updateFirestoreUser()

                Task { @MainActor in
                    let updatedUser = createUpdatedUser()
                    updateAuthUser(with: updatedUser)
                    updateRealmUser(updatedUser)
                    updateCacheProfileImageData()
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
                    photoUrl: profilePictureURL ?? user.photoUrl,
                    phoneNumber: userData.phone,
                    nickName: userData.nickname,
                    dateCreated: user.dateCreated,
                    lastSeen: user.lastSeen,
                    isActive: user.isActive)
    }
    
    private func updateRealmUser(_ user: User)
    {
        RealmDataBase.shared.add(object: user)
    }
    
    private func updateAuthUser(with dbUser: User)
    {
        AuthenticationManager.shared.updateAuthUserData(name: dbUser.name, phoneNumber: dbUser.phoneNumber, photoURL: dbUser.photoUrl)
    }
    
    private func updateFirestoreUser() async throws
    {
        try await FirestoreUserService.shared.updateUser(with: authUser.uid,
                                                         usingName: userData.name,
                                                         profilePhotoURL: profilePictureURL,
                                                         phoneNumber: userData.phone,
                                                         nickname: userData.nickname)
    }
}

//MARK: - Image update
extension ProfileEditingViewModel
{
    private func saveImageToStorage() async throws
    {
        if let editedPhoto = editedProfilePhoto
        {
            let (_,name) = try await FirebaseStorageManager.shared.saveUserImage(data: editedPhoto,
                                                                                 userId: authUser.uid,
                                                                                 path: "testPath")
            profilePictureURL = name
        }
    }
    
    private func removePreviousImage() async throws {
        if let photoURL = authUser.photoURL
        {
            try await removeProfileImage(ofUser: authUser.uid,
                                         urlPath: photoURL)
        }
    }
    
    private func updateCacheProfileImageData()
    {
        guard let imageData = self.editedProfilePhoto,
              let pictureURL = profilePictureURL else {return}
        CacheManager.shared.saveImageData(imageData, toPath: pictureURL)
    }
    
    private func removeProfileImage(ofUser userID: String, urlPath: String) async throws
    {
        try await FirebaseStorageManager.shared.deleteProfileImage(ofUser: userID, path: urlPath)
    }
    
    func updateProfilePhotoData(_ data: Data?) {
        self.editedProfilePhoto = data
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
