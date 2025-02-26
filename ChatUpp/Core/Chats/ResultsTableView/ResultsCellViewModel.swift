//
//  ResultsCellViewModel.swift
//  ChatUpp
//
//  Created by Andrei Pripa on 1/27/24.
//

import Foundation

// MARK: - RESULTSCELL VIEWMODEL

final class ResultsCellViewModel
{
    let chat: Chat?
    let participant: User?
    var unreadMessageCount: Int?
    
    @Published var imageData: Data?
    
//    init(memberUser: User?, chat: Chat? = nil, imageData: Data? = nil, unreadMessageCount: Int? = nil) {
//        self.participant = memberUser
//        self.chat = chat
//        self.imageData = imageData
//        self.unreadMessageCount = unreadMessageCount
//    }
    
    init(memberUser: User) {
        self.participant = memberUser
        self.chat = nil
    }
    
    init(chat: Chat) {
        self.chat = chat
        self.participant = nil
    }
    
    init(chat: Chat?, user: User?) {
        self.chat = chat
        self.participant = user
    }
    
    var imageURL: String?
    {
        if let chatImageURL = chat?.thumbnailURL {
            return chatImageURL
        }
        if let participantImageURL = participant?.photoUrl {
            return participantImageURL
        }
        return nil
    }

    func setImageData() {
        guard let data = retrieveImageData() else {
            Task {
                if let imageData = await fetchImageData() {
                    self.imageData = imageData
                    cacheImageData(imageData, path: imageURL!)
                }
            }
            return
        }
        self.imageData = data
    }
    
    /// Firestore fetch
    ///
    
    @MainActor
    private func fetchImageData() async -> Data?
    {
        guard let imageURL = imageURL, let userID = participant?.id else {return nil}
        do {
            return try await FirebaseStorageManager.shared.getImage(from: .user(userID), imagePath: imageURL)
        } catch {
            print("Error getting user image form storage: ", error)
        }
        return nil
    }
    
    
    /// Cache retrieve/set
    ///
    private func cacheImageData(_ data: Data, path: String) {
        CacheManager.shared.saveImageData(data, toPath: path)
    }
    
    private func retrieveImageData() -> Data? {
        if let path = imageURL {
            return CacheManager.shared.retrieveImageData(from: path)
        }
        return nil
    }
}
