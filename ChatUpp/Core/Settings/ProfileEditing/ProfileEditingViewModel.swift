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
    
    // initialeName in case user saves edits while name is empty,
    // the name will remain as it was at the beginning
    private var name: String?
    private var phone: String?
    private var nickName: String?
    
    var initialProfilePhoto: Data
    var editedProfilePhoto: Data?
    
    private var profilePictureURL: String?
    
    var profileDataIsEdited: ObservableObject<Bool?> = ObservableObject(nil)
    var userDataToTransferBack: ((DBUser, Data?) -> Void)?
    
    var editItems: [String?] {
        return [name,phone,nickName]
    }
    
    init(dbUser: DBUser, profilePicutre: Data) {
        self.name = dbUser.name!
        self.phone = dbUser.phoneNumber
        self.nickName = dbUser.nickname
        self.initialProfilePhoto = profilePicutre
    }

    var authUserID: String {
        if let userID = try? AuthenticationManager.shared.getAuthenticatedUser().uid {
            return userID
        }
        fatalError("user is missing")
    }
    
    func applyTitle(title: String, toItem item: Int) {
        switch item {
        case 0: name = title.isEmpty ? nil : title
        case 1: phone = title
        case 2: nickName = title
        default:break
        }
    }
    
    private func saveImageToStorage() async throws {
        if let editedPhoto = editedProfilePhoto {
            let (_,name) = try await StorageManager.shared.saveUserImage(data: editedPhoto, userId: authUserID)
            profilePictureURL = name
        }
    }
    
    private func fetchFreshUserFromDB() async throws -> DBUser {
        let uderID = try AuthenticationManager.shared.getAuthenticatedUser()
        return try await UserManager.shared.getUserFromDB(userID: uderID.uid)
    }
    
    private func updateDBUser() async throws {
        try await UserManager.shared.updateUser2(with: authUserID, usingName: name, profilePhotoURL: profilePictureURL, phoneNumber: phone, nickname: nickName)
    }
    
    func handleProfileDataUpdate() {
        Task {
            do {
                try await saveImageToStorage()
                try await updateDBUser()
                let dbUser = try await fetchFreshUserFromDB()
                
                Task { @MainActor in
                    userDataToTransferBack?(dbUser, initialProfilePhoto)
                    profileDataIsEdited.value = true
                }
            } catch {
                print("Error occurred while updating user data: ", error)
            }
        }
    }
    
    
//    func saveProfileData() {
//        UserManager.shared.updateUser(with: authUserID, usingName: name, profilePhotoURL: profilePictureURL, phoneNumber: phone, nickname: nickName) { [weak self] respons in
//            guard let self = self else {return}
//
//            if respons == .success {
//                userDataToTransferBack?(name,phone,nickName,profilePhoto)
//                onSaveProfileData?()
//            }
//        }
//    }
    
    
    
//    var name: ProfileEditingItems!
//    var phone: ProfileEditingItems!
//    var nickName: ProfileEditingItems!
    
//    init(name: ProfileEditingItems, phone: ProfileEditingItems, nickName: ProfileEditingItems) {
//        self.name = name
//        self.phone = phone
//        self.nickName = nickName
//    }
//    var items: [ProfileEditingItems]!
//
//    init(items:[ProfileEditingItems]) {
//        self.items = items
//    }
 
    
//    func applyTitle(title: String, toItemIndex index: Int) {
//        switch index {
//        case 0: items[index] = .name(title)
//        case 1: items[index] = .phone(title)
//        case 2: items[index] = .nickName(title)
//        default:break
//        }
//    }
    
}



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
