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
    
    private var photo: Data? {
        didSet {
            // TODO: Upload picture to storage
            // and assigne URL link to usermanager
        }
    }
    
//    private var profilePictureURL: String
    
    var items: [String?] {
        return [name,phone,nickName]
    }
    
    init(name: String, phone: String?, nickName: String?) {
        self.name = name
        self.phone = phone
        self.nickName = nickName
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
    
//    var authUserID: String {
//        if let userID = try? AuthenticationManager.shared.getAuthenticatedUser().uid {
//            return userID
//        }
//    }
    
    var profilePictureURL: String {
        do {
            let photoURL = try AuthenticationManager.shared.getAuthenticatedUser().photoURL
            return photoURL!
        } catch {
            return "default_profile_photo"
        }
    }
    
//    func saveEditedData() {
//        UserManager.shared.updateUser(with: authUserID, usingName: name, profilePhotoURL: photo , complition: <#T##(ResposneStatus) -> Void#>)
//    }
    
    //TODO: implement data saving in to db
    
    
    
    
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
