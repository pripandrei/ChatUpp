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
    let participant: DBUser
    var userImageData: ObservableObject<Data?> = ObservableObject(nil)
    var unreadMessageCount: Int?
    
    init(memberUser: DBUser, chat: Chat? = nil, imageData: Data? = nil, unreadMessageCount: Int? = nil) {
        self.participant = memberUser
        self.chat = chat
        self.userImageData.value = imageData
        self.unreadMessageCount = unreadMessageCount
    }

    func fetchImageData() {
        guard let imageURL = participant.photoUrl else {return}
        Task {
            do {
                userImageData.value = try await StorageManager.shared.getUserImage(userID: participant.userId, path: imageURL)
            } catch {
                print("Error getting user image form storage: ", error)
            }
        }
    }
}
