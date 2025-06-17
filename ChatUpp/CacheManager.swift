//
//  CacheManager.swift
//  ChatUpp
//
//  Created by Andrei Pripa on 9/13/24.
//

import Foundation
import Kingfisher

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
    
    func retrieveImageData(from path: String) -> Data?
    {
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
    
    func retrieveImageData2(from path: String, completion: @escaping (Data?) -> Void) {
        DispatchQueue.global(qos: .userInitiated).async {
            guard let pathURL = self.cacheDirectory?.appending(path: path),
                  FileManager.default.fileExists(atPath: pathURL.path()) else {
                DispatchQueue.main.async { completion(nil) }
                return
            }
            
            do {
                let data = try Data(contentsOf: pathURL)
                DispatchQueue.main.async { completion(data) }
            } catch {
                print("Error while retrieving image data from cache: ", error.localizedDescription)
                DispatchQueue.main.async { completion(nil) }
            }
        }
    }
    
    func doesImageExist(at path: String) -> Bool
    {
        guard let pathURL = cacheDirectory?.appending(path: path) else {return false}
        return FileManager.default.fileExists(atPath: pathURL.path())
    }
}


class ImageCacheService
{
    static let shered = ImageCacheService()
    
    private init() {}
    
    func cacheImageData(_ data: Data, for key: String)
    {
        ImageCache.default.storeToDisk(data, forKey: key)
//        ImageCache.default.retrieve
    }
}
