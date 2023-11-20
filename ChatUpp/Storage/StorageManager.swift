//
//  StorageManager.swift
//  ChatUpp
//
//  Created by Andrei Pripa on 11/20/23.
//

import Foundation
import FirebaseStorage


final class StorageManager {
    
    static var shered = StorageManager()
    
    private init() {}
    
    private let storage = Storage.storage().reference()
    
    private var imageReference: StorageReference {
        storage.child("Images")
    }
    
    private func userReference(userID: String) -> StorageReference {
        storage.child("users").child(userID)
    }
    
    private func messageReference(messageID: String) -> StorageReference {
        storage.child("messages").child(messageID)
    }
    
    func saveImage(data: Data, messageID: String) async throws -> (path: String, name: String) {
        let meta = StorageMetadata()
        meta.contentType = "image/jpeg"
        
        let path = "\(UUID().uuidString).jpeg"
        let metaData = try await messageReference(messageID: messageID).child(path).putDataAsync(data, metadata: meta)
        
        guard let returnedPath = metaData.path, let returnedName = metaData.name else {
            print("Invalid Storage metaData path/name")
            throw URLError(.badServerResponse)
        }
        
        return (returnedPath, returnedName)
    }
    
//    func saveImage(data: Data, userId: String) async throws -> (path: String, name: String) {
//        let meta = StorageMetadata()
//        meta.contentType = "image/jpeg"
//
//        let path = "\(UUID().uuidString).jpeg"
//        let metaData = try await userReference(userID: userId).child(path).putDataAsync(data, metadata: meta)
//
//        guard let returnedPath = metaData.path, let returnedName = metaData.name else {
//            print("Invalid Storage metaData path/name")
//            throw URLError(.badServerResponse)
//        }
//
//        return (returnedPath, returnedName)
//    }
}
