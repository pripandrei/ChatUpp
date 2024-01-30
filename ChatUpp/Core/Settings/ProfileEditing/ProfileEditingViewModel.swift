//
//  ProfileEditingViewModel.swift
//  ChatUpp
//
//  Created by Andrei Pripa on 12/31/23.
//

import Foundation

final class ProfileEditingViewModel {
    
    enum ProfileEditingItemsPlaceholder: String, CaseIterable {
        case name = "name"
        case phone = "ex. +37376445934"
        case username = "username"
    }
    
    var initialProfilePhoto: Data
    var editedProfilePhoto: Data?
    private var profilePictureURL: String?
    
    var profileDataIsEdited: ObservableObject<Bool?> = ObservableObject(nil)
    var userDataToTransferOnSave: ((DBUser, Data?) -> Void)?
    
    private var userData: (name: String?, phone: String?, nickname: String?)
    
    var userDataItems: [String?] {
        let userDataMirror = Mirror(reflecting: userData)
        return userDataMirror.children.map({ $0.value }) as! [String?]
    }
    
    private var authUser: AuthDataResultModel {
        if let user = try? AuthenticationManager.shared.getAuthenticatedUser() {
            return user
        }
        fatalError("user is missing")
    }
    
    init(dbUser: DBUser, profilePicutre: Data) {
        self.userData.name = dbUser.name!
        self.userData.phone = dbUser.phoneNumber
        self.userData.nickname = dbUser.nickname
        self.initialProfilePhoto = profilePicutre
    }
    
    func applyTitle(title: String, toItem item: Int) {
        switch item {
        case 0: userData.name = title.isEmpty ? nil : title
        case 1: userData.phone = title
        case 2: userData.nickname = title
        default:break
        }
    }
    
    private func saveImageToStorage() async throws {
        if let editedPhoto = editedProfilePhoto {
            let (_,name) = try await StorageManager.shared.saveUserImage(data: editedPhoto, userId: authUser.uid)
            if let photoURL = authUser.photoURL {
                try await removeProfileImage(ofUser: authUser.uid, urlPath: photoURL)
            }
            profilePictureURL = name
        }
    }
    
    private func fetchFreshUserFromDB() async throws -> DBUser {
        return try await UserManager.shared.getUserFromDB(userID: authUser.uid)
    }
    
    private func updateDBUser() async throws {
        try await UserManager.shared.updateUser(with: authUser.uid, usingName: userData.name, profilePhotoURL: profilePictureURL, phoneNumber: userData.phone, nickname: userData.nickname)
    }
    
    func handleProfileDataUpdate() {
        Task {
            do {
                try await saveImageToStorage()
                try await updateDBUser()
                let dbUser = try await fetchFreshUserFromDB()
                updateAuthUser(with: dbUser)
                
                Task { @MainActor in
                    userDataToTransferOnSave?(dbUser, editedProfilePhoto)
                    profileDataIsEdited.value = true
                }
            } catch {
                print("Error occurred while updating user data: ", error)
            }
        }
    }
    
    private func updateAuthUser(with dbUser: DBUser) {
        AuthenticationManager.shared.updateAuthUserData(name: dbUser.name, phoneNumber: dbUser.phoneNumber, photoURL: dbUser.photoUrl)
    }
    
    private func removeProfileImage(ofUser userID: String, urlPath: String) async throws {
        try await StorageManager.shared.deleteProfileImage(ofUser: userID, path: urlPath)
    }
}


//MARK: - Profile Model
enum ProfileEditingItems {
    case name(String)
    case phone(String)
    case nickName(String)
    
    var item: Self {
        switch self {
        case .name(let name): return .name(name)
        case .phone(let phone): return .phone(phone)
        case .nickName(let nick): return .nickName(nick)
        }
    }
    
    var itemTitle: String {
        switch self {
        case .name(let name): return name
        case .phone(let phone): return phone
        case .nickName(let nick): return nick
        }
    }
}
