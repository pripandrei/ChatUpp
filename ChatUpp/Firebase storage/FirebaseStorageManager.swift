//
//  StorageManager.swift
//  ChatUpp
//
//  Created by Andrei Pripa on 11/20/23.
//

import Foundation
import FirebaseStorage


final class FirebaseStorageManager {
    
    static var shared = FirebaseStorageManager()
    
    private init() {}
    
    private let storage = Storage.storage().reference()
    
    private func userReference(userID: String) -> StorageReference {
        storage.child("users").child(userID)
    }
    
    private func messageReference(messageID: String) -> StorageReference {
        storage.child("messages").child(messageID)
    }
    
    func getUserImage(userID: String, path: String) async throws -> Data {
        return try await userReference(userID: userID).child(path).data(maxSize: 3 * 1024 * 1024)
    }
    
    func getUserImageURL(userID: String, path: String) async throws -> URL {
        return try await userReference(userID: userID).child(path).downloadURL()
    }
    
//    func getPath(constructingFrom sizeSample: ImageSample.SizeKey) -> String
//    {
//        var path = sizeSample == .original ? "" : sizeSample.rawValue
//        
//        if !path.isEmpty {
//            path = "\(UUID().uuidString)" + "_\(path).jpeg"
//        } else {
//            path = "\(UUID().uuidString).jpeg"
//        }
//        return path
//    }
//    
    func saveUserImage(data: Data, userId: String, path: String) async throws -> (path :String, name :String)
    {
        let meta = StorageMetadata()
        meta.contentType = "image/jpeg"
        
//        let path = getPath(constructingFrom: sizeSample)
        
        let metaData = try await userReference(userID: userId).child(path).putDataAsync(data, metadata: meta)
        
        guard let fullPath = metaData.path, let name = metaData.name else {
            print("Invalid Storage metaData path/name")
            throw URLError(.badServerResponse)
        }
        return (fullPath,name)

    }
    
    func getMessageImage(messageId: String, path: String) async throws -> Data {
        return try await messageReference(messageID: messageId).child(path).data(maxSize: 3 * 1024 * 1024)
    }
    
    func saveMessageImage(data: Data, messageID: String) async throws -> (path: String, name: String) {
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
    
    func deleteProfileImage(ofUser userID: String, path: String) async throws {
        try await userReference(userID: userID).child(path).delete()
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
