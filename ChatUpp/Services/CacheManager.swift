
import Foundation
import UIKit

final class CacheManager
{
    static let shared = CacheManager()
    
    private let imageCache = NSCache<NSString, UIImage>()
    
    private init()
    {
        imageCache.countLimit = 100
        imageCache.totalCostLimit = 50 * 1024 * 1024
    }
}

//MARK: - Storage data cache
extension CacheManager
{
    private var cacheDirectory: URL?
    {
        return FileManager.default.urls(
            for: .cachesDirectory,
            in: .userDomainMask).first
    }
    
    func saveData(_ data: Data, toPath path: String)
    {
        guard let pathURL = cacheDirectory?.appending(path: path) else {return}
        
        let dirName = pathURL.deletingLastPathComponent()
        
        do {
            try FileManager.default.createDirectory(
                at: dirName,
                withIntermediateDirectories: true,
                attributes: nil
            )
            
            try data.write(to: pathURL)
        } catch {
            print("Error while saving image data to cache: ", error.localizedDescription)
        }
    }
    
    func retrieveData(from path: String) -> Data?
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
    
    func doesFileExist(at path: String) -> Bool
    {
        guard let pathURL = cacheDirectory?.appending(path: path)
        else {return false}
        return FileManager.default.fileExists(atPath: pathURL.path())
    }
    
    func getURL(for path: String) -> URL?
    {
        return cacheDirectory?.appending(path: path)
    }
}

//MARK: - In memory image cache
extension CacheManager
{
    func cacheImage(image: UIImage, key: String)
    {
        imageCache.setObject(image, forKey: key as NSString)
    }
    
    func getCachedImage(forKey key: String) -> UIImage?
    {
        return imageCache.object(forKey: key as NSString)
    }
    
    func clear() {
        imageCache.removeAllObjects()
    }
}

// MARK: - Clear content
extension CacheManager
{
    func clearCacheDirectory(name folderName: String)
    {
        guard let dirURL = cacheDirectory?.appending(path: folderName,
                                                     directoryHint: .checkFileSystem) else {return}
        
        do {
            let contents = try FileManager.default.contentsOfDirectory(at: dirURL, includingPropertiesForKeys: nil)
            
            for fileURL in contents
            {
                try FileManager.default.removeItem(at: fileURL)
            }
        } catch {
            print("error while clearing cache dir: \(error)")
        }
    }
}
