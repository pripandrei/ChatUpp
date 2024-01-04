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
    private let initialeName: String
    
    private var name: String
    private var phone: String?
    private var nickName: String?
    
    var profilePhoto: Data
    
    private var profilePictureURL: String?
    var onSaveProfileData: (() -> Void)?
    var userDataToTransferBack: ((_ name: String?,
                                _ phone: String?,
                                _ nickname: String?,
                                _ profilePhoto: Data?) -> Void)?
    
    var items: [String?] {
        return [name,phone,nickName]
    }
    
    init(name: String, phone: String?, nickName: String?, profilePicutre: Data) {
        self.name = name
        self.phone = phone
        self.nickName = nickName
        self.profilePhoto = profilePicutre
        self.initialeName = name
    }
    
    func applyTitle(title: String, toItem item: Int) {
        switch item {
        case 0: name = title.isEmpty ? initialeName : title
        case 1: phone = title.isEmpty ? nil : title
        case 2: nickName = title.isEmpty ? nil : title
        default:break
        }
    }
    
    var authUserID: String {
        if let userID = try? AuthenticationManager.shared.getAuthenticatedUser().uid {
            return userID
        }
        fatalError("user is missing")
    }
    
//    func saveImageToStorage() {
//        Task {
//           let (path,name) = try await StorageManager.shared.saveUserImage(data: profilePhoto, userId: authUserID)
//            profilePictureURL = name
//            print("PATH AND NAME: ", path, name)
//        }
//    }
    
    
    func saveImageToStorage() async throws {
        let (_,name) = try await StorageManager.shared.saveUserImage(data: profilePhoto, userId: authUserID)
        profilePictureURL = name
    }
    
    func saveProfileData() {
        UserManager.shared.updateUser(with: authUserID, usingName: name, profilePhotoURL: profilePictureURL, phoneNumber: phone, nickname: nickName) { [weak self] respons in
            guard let self = self else {return}
            
            if respons == .success {
                userDataToTransferBack?(name,phone,nickName,profilePhoto)
                onSaveProfileData?()
            }
        }
    }

    
    
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
