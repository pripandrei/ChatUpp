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
    let participant: User
    var userImageData: ObservableObject<Data?> = ObservableObject(nil)
    var unreadMessageCount: Int?
    
    init(memberUser: User, chat: Chat? = nil, imageData: Data? = nil, unreadMessageCount: Int? = nil) {
        self.participant = memberUser
        self.chat = chat
        self.userImageData.value = imageData
        self.unreadMessageCount = unreadMessageCount
    }

    func fetchImageData() {
        guard let imageURL = participant.photoUrl else {return}
        Task {
            do {
                userImageData.value = try await FirebaseStorageManager.shared.getImage(from: .user(participant.id), imagePath: imageURL)
            } catch {
                print("Error getting user image form storage: ", error)
            }
        }
    }
}
