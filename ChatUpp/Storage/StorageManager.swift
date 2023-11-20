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
    
    
    func saveImage(data: Data) async throws -> (path: String, name: String) {
        let meta = StorageMetadata()
        meta.contentType = "image/jpeg"
        
        let path = "\(UUID().uuidString).jpeg"
        let metaData = try await storage.child(path).putDataAsync(data, metadata: meta)
        
        guard let returnedPath = metaData.path, let returnedName = metaData.name else {
            print("Invalid Storage metaData path/name")
            throw URLError(.badServerResponse)
        }
        
        return (returnedPath, returnedName)
        
    }
}
