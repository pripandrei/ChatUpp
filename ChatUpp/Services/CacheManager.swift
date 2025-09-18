
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
    
    func saveImageData(_ imageData: Data, toPath path: String)
    {
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
    
    func doesImageExist(at path: String) -> Bool
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

