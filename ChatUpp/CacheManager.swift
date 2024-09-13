//
//  CacheManager.swift
//  ChatUpp
//
//  Created by Andrei Pripa on 9/13/24.
//

import Foundation

final class CacheManager {
    
    static let shared = CacheManager()
    
    private init() {}
    
    private var cacheDirectory: URL? {
        return FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first
    }
    
    func saveImageData(_ imageData: Data, toPath path: String) {
        guard let pathURL = cacheDirectory?.appending(path: path) else {return}
        do {
            try imageData.write(to: pathURL)
        } catch {
            print("Error while saving image data to cache: ", error.localizedDescription)
        }
        
    }
    
    func retrieveImageData(from path: String) -> Data? {
        guard let pathURL = cacheDirectory?.appending(path: path) else {return nil}
        
        if FileManager.default.fileExists(atPath: pathURL.path()) {
            do {
                return try Data(contentsOf: pathURL)
            } catch {
                print("Error while retrieving image data from cache: ", error.localizedDescription)
                return nil
            }
        }
        return nil
    }
}
