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
    let userName: String
    let userID: String
    let userImageURL: String
    var userImageData: ObservableObject<Data?> = ObservableObject(nil)
    
    init(userID: String, userName: String, userImageURL: String, chat: Chat? = nil, imageData: Data? = nil) {
        self.userName = userName
        self.userID = userID
        self.userImageURL = userImageURL
        self.chat = chat
        self.userImageData.value = imageData
//        fetchImageData()
    }

    func fetchImageData() {
        Task {
            do {
                userImageData.value = try await StorageManager.shared.getUserImage(userID: userID, path: userImageURL)
            } catch {
                print("Error getting user image form storage: ", error)
            }
        }
    }
}
