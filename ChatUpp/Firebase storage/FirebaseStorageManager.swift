//
//  StorageManager.swift
//  ChatUpp
//
//  Created by Andrei Pripa on 11/20/23.
//

import Foundation
import FirebaseStorage

// MARK: - StoragePathType
enum StoragePathType
{
    case user(String)
    case message(String)
    case group(String)
    
    var reference: StorageReference {
        let storage = Storage.storage().reference()
        switch self {
        case .user(let id):
            return storage.child("users").child(id)
        case .message(let id):
            return storage.child("messages").child(id)
        case .group(let id):
            return storage.child("groups").child(id)
        }
    }
}

// MARK: - ImageMetadata
struct ImageMetadata {
    let path: String
    let name: String
}

final class FirebaseStorageManager
{
    static let shared = FirebaseStorageManager()
    private let maxImageSize: Int64 = 3 * 1024 * 1024  // 3MB
    
    private init() {}
    
    func getImage(from path: StoragePathType, imagePath: String) async throws -> Data {
        try await path.reference.child(imagePath).data(maxSize: maxImageSize)
    }
    
    func getImageURL(from path: StoragePathType, imagePath: String) async throws -> URL {
        try await path.reference.child(imagePath).downloadURL()
    }
    
    @discardableResult
    func saveImage(data: Data,
                   to path: StoragePathType,
                   imagePath: String? = nil) async throws -> ImageMetadata
    {
        let meta = StorageMetadata()
        meta.contentType = "image/jpeg"
        
        let finalPath = imagePath ?? "\(UUID().uuidString).jpeg"
        
        let metaData = try await path.reference.child(finalPath).putDataAsync(data, metadata: meta)
        
        guard let returnedPath = metaData.path,
              let returnedName = metaData.name else {
            throw URLError(.badServerResponse)
        }
        return ImageMetadata(path: returnedPath, name: returnedName)
    }
    
    func deleteImage(from path: StoragePathType, imagePath: String) async throws {
        try await path.reference.child(imagePath).delete()
    }
}







//
//enum StorageChildType: String {
//    case users
//    case groups
//    case messages
//}
//
//final class FirebaseStorageManager {
//
//    static let shared = FirebaseStorageManager()
//    private init() {}
//
//    private let storage = Storage.storage().reference()
//
//    private func reference(for type: StorageChildType, id: String) -> StorageReference {
//        storage.child(type.rawValue).child(id)
//    }
//
//    private func generateDefaultPath(with extension2: String = "jpeg") -> String {
//        return "\(UUID().uuidString).\(extension2)"
//    }
//
//    private func createMetadata(contentType: String = "image/jpeg") -> StorageMetadata {
//        let metadata = StorageMetadata()
//        metadata.contentType = contentType
//        return metadata
//    }
//
//    func fetchImage(for type: StorageChildType, id: String, path: String) async throws -> Data {
//        try await reference(for: type, id: id).child(path).data(maxSize: 3 * 1024 * 1024)
//    }
//
//    func fetchImageURL(for type: StorageChildType, id: String, path: String) async throws -> URL {
//        try await reference(for: type, id: id).child(path).downloadURL()
//    }
//
//    func saveImage(data: Data, for type: StorageChildType, id: String, path: String? = nil) async throws -> (path: String, name: String) {
//        let metadata = createMetadata()
//        let resolvedPath = path ?? generateDefaultPath()
//
//        let result = try await reference(for: type, id: id).child(resolvedPath).putDataAsync(data, metadata: metadata)
//
//        guard let fullPath = result.path, let name = result.name else {
//            throw URLError(.badServerResponse)
//        }
//
//        return (fullPath, name)
//    }
//
//    func deleteImage(for type: StorageChildType, id: String, path: String) async throws {
//        try await reference(for: type, id: id).child(path).delete()
//    }
//}



//final class FirebaseStorageManager {
//    
//    static var shared = FirebaseStorageManager()
//    
//    private init() {}
//    
//    private let storage = Storage.storage().reference()
//    
//    private func groupReference(groupID: String) -> StorageReference {
//        storage.child("groups").child(groupID)
//    }
//    
//    private func userReference(userID: String) -> StorageReference {
//        storage.child("users").child(userID)
//    }
//    
//    private func messageReference(messageID: String) -> StorageReference {
//        storage.child("messages").child(messageID)
//    }
//    
//    func getUserImage(userID: String, path: String) async throws -> Data {
//        return try await userReference(userID: userID).child(path).data(maxSize: 3 * 1024 * 1024)
//    }
//    
//    func getUserImageURL(userID: String, path: String) async throws -> URL {
//        return try await userReference(userID: userID).child(path).downloadURL()
//    }
//    
//    func getMessageImage(messageId: String, path: String) async throws -> Data {
//        return try await messageReference(messageID: messageId).child(path).data(maxSize: 3 * 1024 * 1024)
//    }
//    
//    func saveUserImage(data: Data, userId: String, path: String) async throws -> (path :String, name :String)
//    {
//        let meta = StorageMetadata()
//        meta.contentType = "image/jpeg"
//        
//        let metaData = try await userReference(userID: userId).child(path).putDataAsync(data, metadata: meta)
//        
//        guard let fullPath = metaData.path, let name = metaData.name else {
//            print("Invalid Storage metaData path/name")
//            throw URLError(.badServerResponse)
//        }
//        return (fullPath,name)
//    }
//    
//    func saveMessageImage(data: Data, messageID: String, path: String? = nil) async throws -> (path: String, name: String)
//    {
//        let meta = StorageMetadata()
//        meta.contentType = "image/jpeg"
//        
//        guard let path = (path != nil) ? path : "\(UUID().uuidString).jpeg" else {throw URLError(.badServerResponse)}
//        let metaData = try await messageReference(messageID: messageID).child(path).putDataAsync(data, metadata: meta)
//        
//        guard let returnedPath = metaData.path, let returnedName = metaData.name else {
//            print("Invalid Storage metaData path/name")
//            throw URLError(.badServerResponse)
//        }
//        return (returnedPath, returnedName)
//    }
//    
//    func saveGroupImage(data: Data, groupID: String, path: String? = nil) async throws -> (path: String, name: String)
//    {
//        let meta = StorageMetadata()
//        meta.contentType = "image/jpeg"
//        
//        guard let path = (path != nil) ? path : "\(UUID().uuidString).jpeg" else {throw URLError(.badServerResponse)}
//        let metaData = try await messageReference(messageID: groupID).child(path).putDataAsync(data, metadata: meta)
//        
//        guard let returnedPath = metaData.path, let returnedName = metaData.name else {
//            print("Invalid Storage metaData path/name")
//            throw URLError(.badServerResponse)
//        }
//        return (returnedPath, returnedName)
//    }
//
//    func deleteProfileImage(ofUser userID: String, path: String) async throws {
//        try await userReference(userID: userID).child(path).delete()
//    }
//}
//
//
////enum StorageChildObject
////{
////    case groups(id: String, fileName: String)
////    case users(id: String, fileName: String)
////    case messages(id: String, fileName: String)
////
////    var directoryName: String {
////        switch self {
////        case .groups: return "groups"
////        case .users: return "users"
////        case .messages: return "messages"
////        }
////    }
////
////    var id: String {
////        switch self {
////        case .groups(let id, _),
////             .users(let id, _),
////             .messages(let id, _):
////            return id
////        }
////    }
////
////    var fileName: String {
////        switch self {
////        case .groups(_, let name),
////             .users(_, let name),
////             .messages(_, let name):
////            return name
////        }
////    }
////
////    var fullPath: String {
////        "\(directoryName)/\(id)/\(fileName)"
////    }
////}
//
//enum StorageChildObject
//{
//    case groups
//    case users
//    case messages
//
//    var directoryName: String
//    {
//        switch self {
//        case .groups: return "groups"
//        case .users: return "users"
//        case .messages: return "messages"
//        }
//    }
//}






//
//enum StorageChildType: String {
//    case users
//    case groups
//    case messages
//}
//
//final class FirebaseStorageManager {
//    
//    static let shared = FirebaseStorageManager()
//    private init() {}
//    
//    private let storage = Storage.storage().reference()
//    
//    private func reference(for type: StorageChildType, id: String) -> StorageReference {
//        storage.child(type.rawValue).child(id)
//    }
//    
//    private func generateDefaultPath(with extension2: String = "jpeg") -> String {
//        return "\(UUID().uuidString).\(extension2)"
//    }
//    
//    private func createMetadata(contentType: String = "image/jpeg") -> StorageMetadata {
//        let metadata = StorageMetadata()
//        metadata.contentType = contentType
//        return metadata
//    }
//    
//    func fetchImage(for type: StorageChildType, id: String, path: String) async throws -> Data {
//        try await reference(for: type, id: id).child(path).data(maxSize: 3 * 1024 * 1024)
//    }
//    
//    func fetchImageURL(for type: StorageChildType, id: String, path: String) async throws -> URL {
//        try await reference(for: type, id: id).child(path).downloadURL()
//    }
//    
//    func saveImage(data: Data, for type: StorageChildType, id: String, path: String? = nil) async throws -> (path: String, name: String) {
//        let metadata = createMetadata()
//        let resolvedPath = path ?? generateDefaultPath()
//        
//        let result = try await reference(for: type, id: id).child(resolvedPath).putDataAsync(data, metadata: metadata)
//        
//        guard let fullPath = result.path, let name = result.name else {
//            throw URLError(.badServerResponse)
//        }
//        
//        return (fullPath, name)
//    }
//    
//    func deleteImage(for type: StorageChildType, id: String, path: String) async throws {
//        try await reference(for: type, id: id).child(path).delete()
//    }
//}
