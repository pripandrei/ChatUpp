//
//  ResultsCellViewModel.swift
//  ChatUpp
//
//  Created by Andrei Pripa on 1/27/24.
//

import Foundation

// MARK: - RESULTSCELL VIEWMODEL

final class ResultsCellViewModel {
    
    let chat: Chat?
//    let userName: String
//    let userID: String
//    let userImageURL: String?
    var userImageData: ObservableObject<Data?> = ObservableObject(nil)
    
    let memberUser: DBUser
    
//    init(userID: String, userName: String, userImageURL: String?, chat: Chat? = nil, imageData: Data? = nil) {
//        self.userName = userName
//        self.userID = userID
//        self.userImageURL = userImageURL
//        self.chat = chat
//        self.userImageData.value = imageData
////        fetchImageData()
//    }
    
    init(memberUser: DBUser, chat: Chat? = nil, imageData: Data? = nil) {
//        self.init(userID: memberUser.userId, userName: memberUser.name!, userImageURL: memberUser.photoUrl, chat: chat)
        self.memberUser = memberUser
        self.chat = chat
        self.userImageData.value = imageData
    }

    func fetchImageData() {
        guard let imageURL = memberUser.photoUrl else {return}
        Task {
            do {
                userImageData.value = try await StorageManager.shared.getUserImage(userID: memberUser.userId, path: imageURL)
            } catch {
                print("Error getting user image form storage: ", error)
            }
        }
    }
}
