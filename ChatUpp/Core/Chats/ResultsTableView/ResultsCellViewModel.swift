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
    
    init(memberUser: User) {
        self.participant = memberUser
        self.chat = nil
    }
    
    init(chat: Chat, memberUser: User? = nil) {
        self.chat = chat
        self.participant = memberUser
    }

    var titleName: String
    {
        if let chatName = chat?.name {
            return chatName
        }
        if let participantName = participant?.name {
            return participantName
        }
        
        return "No Name"
//        return chat?.name != nil ? chat?.name : participant?.name
    }
    
    var imageURL: String? {
        if let chatImageURL = chat?.thumbnailURL {
            return chatImageURL.addSuffix("medium")
        }
        if let participantImageURL = participant?.photoUrl {
            return participantImageURL.addSuffix("medium")
        }
        return nil
    }
    
    func setImageData()
    {
        guard let data = retrieveImageData() else {
            Task { @MainActor in
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
        guard let imageURL = imageURL else {return nil}
        
        guard let id = participant?.id ?? chat?.id else {return nil}
        
        let pathType: StoragePathType = chat?.isGroup == true ? .group(id) : .user(id)
        do {
            return try await FirebaseStorageManager.shared.getImage(from: pathType, imagePath: imageURL)
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
