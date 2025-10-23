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
    
//    static private var storage = Storage.storage().reference()
    
    var reference: StorageReference
    {
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





//MARK: - For Test 

extension FirebaseStorageManager
{
//    func migrateImages(completion: @escaping (Result<Void, Error>) -> Void) {
//        let rootRef = storage.reference().child("messages")
//        
//        // Step 1: list all "message" folders under messages/
//        rootRef.listAll { result, error in
//            if let error = error {
//                completion(.failure(error))
//                return
//            }
//            
//            guard let items = result?.items else {
//                completion(.failure(NSError(domain: "NoItemsFound", code: 0)))
//                return
//            }
//            
//            let dispatchGroup = DispatchGroup()
//            var encounteredError: Error?
//            
//            for file in items {
//                // Skip already migrated files
//                if file.fullPath.starts(with: "messages/images/") {
//                    continue
//                }
//                
//                // Only migrate images
//                if file.name.hasSuffix(".jpg") || file.name.hasSuffix(".png") {
//                    dispatchGroup.enter()
//                    self.moveFile(file) { error in
//                        if let error = error {
//                            encounteredError = error
//                        }
//                        dispatchGroup.leave()
//                    }
//                }
//            }
//            
//            dispatchGroup.notify(queue: .main) {
//                if let error = encounteredError {
//                    completion(.failure(error))
//                } else {
//                    completion(.success(()))
//                }
//            }
//        }
//    }
//    
//    private func moveFile(_ oldFile: StorageReference, completion: @escaping (Error?) -> Void) {
//        // Example: old path = messages/12345/image.jpg
//        // new path = messages/images/12345/image.jpg
//        let newPath = oldFile.fullPath.replacingOccurrences(of: "messages/", with: "messages/images/")
//        let newFile = storage.reference(withPath: newPath)
//        
//        // Step 2: Download data
//        oldFile.getData(maxSize: 10 * 1024 * 1024) { data, error in
//            guard let data = data, error == nil else {
//                completion(error)
//                return
//            }
//            
//            // Step 3: Upload to new path
//            newFile.putData(data, metadata: nil) { _, error in
//                if let error = error {
//                    completion(error)
//                    return
//                }
//                
//                // Step 4: Delete old file (optional)
//                oldFile.delete { deleteError in
//                    completion(deleteError)
//                }
//            }
//        }
//    }
//    
    
    
    func getUserIDs() -> [String] {
        return ["3MkyEPoXQ7hvbLLwWSwJ0KLYjhw2",
        "4aXrbFl1y9btJt7TD5jqQyc6cfV2",
        "6kRLuK6vhGV3XCA3GNZAQHq5I392",
        "8Ea160aQlQfLOH2jPM2l9Pioi7p2",
        "ArzzEyzTb7QRD5LhxIX3B5xqsql1",
        "C0zmSMXYQuwDE1Z9qgzs",
        "DESg2qjjJPP20KQDWfKpJJnozv53",
        "DefaultImage",
        "DeletedxE3btxSOXM2bRfkppe1P",
        "Df567CSKWyeYXyrqGBz6BRyqXI62",
        "DrKIgVVp34UkVl899GAo4Q0TupF2",
        "EHJyTqGeErg4iBW1ki4LGKwkQ183",
        "G7RpmD9dzgYW9oxal2ozXpJKF9d2",
        "GDVnswBRatNmY0nS8NSgCmyCHo92",
        "Gjs2WNj8d6WLwZ5bKaXgsWoRlk72",
        "JmKu631i6xWDWWbPIlyVyp0KmXy2",
        "Kq4jjKWFFEfThk81LTwWM6v0EgC2",
        "LRnuTD6dffSB2pC1NMoE52MhYoQ2",
        "Mntd4ELAwyb463KVTwnEFXylDtp1",
        "NqywYo4GP6hMkUmSILrqsqMXqNx1",
        "Nvb0A7VblEOeZAyXlSvZGcG6m6o1",
        "Pl4wKZ3wyLbUFc3aFAA3Let5wrE2",
        "SVFQ8U50xnNxRzQI312E3Zc9FgJ2",
        "SkZqGx72juTh42dhIiGNqK56nlG2",
        "T5VQdyHLAchrKXmP3hcomPzJ8Y52",
        "UNCwYgRrBxPxFZC49kxNMMaQKMy1",
        "UNrP3Kxb41URdE3D4lESNB08S7t2",
        "WStfJmLxnTfT7DacEU1RBNRZSTx1",
        "YHgMIf2x2FaKwrUfVY5xBJ7gRxQ2",
        "YfslJDxX9eOMNCJotJWQztGZCUE3",
        "ZS099HmTk4P7uw8RkHMEMflFS5G3",
        "boya7HmHBjdDxBpCUnYqD2o3JHM2",
        "dPRwJEBB2yNXqyki6N53zNs1FyJ2",
        "eI69kM6MVENufx36QMOtOZuK8Ux1",
        "f0aNVBFrYlTVWxnjDNhwEGjd4xq1",
        "gjVrgLyg7ZRzf9pM9RLpCSMH7Lk1",
        "jpBpnYPVxKgyBwYrRAuhNLknO2w2",
        "jrJiqkxnQfYEeaDMpjI8dwfqFOW2",
        "kvJXgzZGllcDDGboTu8w90EVpxq2",
        "lawcIgWpZRgp4uVq04vsinCNEyx1",
        "mEUBd6kqDIUgxkDT7oiSNplhtZx1",
        "mJCn9DH2sdg16fRNbOAQOEG363O2",
        "o4z5W31LsmYfIROV2vGzin7fy4I3",
        "ozg8xmCD6lMMZ3Wp3NCtcXaKrqi1",
        "p5kqlleDtzeXw5SHOrhkFarKr4E2",
        "r5qG53klqLNVsHix4ejVLXo30yE2",
        "tZ1v5qRsLSNL7w3Myd4jlsyeYUl2",
        "uLoAq22BhMVEdfJimGnC4H8XyLo2",
        "vmK12TflN7RrkTtLypIYBJvYsjo2",
        "wTq190bThGX2zo4NkH36k34dN563",
        "ztNIXMFq2aP2EsUoWTlH9dB5l123",
        "zyq08BhnAtWFmiKwg4ER5yPDw4x1"]
    }
    
    
    
    // download,convert and upload missing image with extension _medium.jpg or _medium.jpeg for all users that do not have it
    func processUserImageFolders() {
        let storage = Storage.storage()

        for userID in self.getUserIDs() {
//            if userID == "Kq4jjKWFFEfThk81LTwWM6v0EgC2" {
                let userFolderRef = storage.reference(withPath: "users/\(userID)")
                
                userFolderRef.listAll { (result, error) in
                if let error = error {
                    print("Failed to list files for user \(userID): \(error)")
                    return
                }
                
                guard let imageItems = result?.items else {return}
                
                // Check if any file ends in _medium.jpg or _medium.jpeg (case-insensitive)
                let hasMedium = imageItems.contains(where: { ref in
                    let lowercased = ref.name.lowercased()
                    return lowercased.hasSuffix("_medium.jpg") || lowercased.hasSuffix("_medium.jpeg")
                })
                
                if hasMedium {
                    print("User \(userID) already has a medium image. Skipping.")
                    return
                }
                
                guard let originalRef = imageItems.first else {
                    print("User \(userID) has no images. Skipping.")
                    return
                }
                
                let originalName = originalRef.name
                    
                    let metadata = StorageMetadata()
                    
                    if originalName.lowercased().hasSuffix(".jpeg") {
                        metadata.contentType = "image/jpeg"
                    } else if originalName.lowercased().hasSuffix(".jpg") {
                        metadata.contentType = "image/jpg"
                    } else {
                        // Fallback if needed
                        metadata.contentType = "image/jpeg"
                    }
                    
                let ext = (originalName as NSString).pathExtension.lowercased()
                
                guard ext == "jpg" || ext == "jpeg" else {
                    print("User \(userID)'s first image is not jpg/jpeg. Skipping.")
                    return
                }
                
                let baseName = (originalName as NSString).deletingPathExtension
                let newName = "\(baseName)_medium.\(ext)"
                let newRef = userFolderRef.child(newName)
                
                // Download original image data
                originalRef.getData(maxSize: 5 * 1024 * 1024) { data, error in
                    if let error = error {
                        print("Error downloading image for user \(userID): \(error)")
                        return
                    }
                    
                    guard let imageData = data else {
                        print("No data for image of user \(userID)")
                        return
                    }
                    
                    // Upload duplicated image with new name
                    newRef.putData(imageData, metadata: metadata) { metadata, error in
                        if let error = error {
                            print("Error uploading medium image for user \(userID): \(error)")
                        } else {
                            print("Successfully created _medium image for user \(userID)")
                        }
                    }
                }
            }
//        }
        }
    }
}
