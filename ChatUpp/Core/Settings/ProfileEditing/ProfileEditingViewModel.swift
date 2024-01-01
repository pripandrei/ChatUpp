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
    
    private var name: String?
    private var phone: String?
    private var nickName: String?
    
    private var photo: Data?
    
    var items: [String?] {
        return [name,phone,nickName]
    }
    
    init(name: String?, phone: String?, nickName: String?) {
        self.name = name
        self.phone = phone
        self.nickName = nickName
    }
    
    func applyTitle(title: String, toItem item: Int) {
        switch item {
        case 0: name = title
        case 1: phone = title
        case 2: nickName = title
        default:break
        }
    }
    
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
