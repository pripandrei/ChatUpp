//
//  ThemesPackViewModel.swift
//  ChatUpp
//
//  Created by Andrei Pripa on 11/29/25.
//

import SwiftUI

final class ThemesPackViewModel: SwiftUI.ObservableObject
{
//    let themes = ["chatRoom_background_1",
//                  "chatRoom_background_2",
//                  "chatRoom_background_3"]
    
//    @Published var selectedTheme = 1
//    let themes = Array(repeating: "chat_background_theme_", count: 30)
    @Published var themes = (1...30).map { index in
        "chat_background_theme_\(index).jpg"
    }
    
    @Published var selectedTheme = ""
    
    init()
    {
//        CacheManager.shared.clearCacheDirectory(name: "Themes")
    }
    
    // test version with cache simulation
//    func fetchImageData(_ name: String)
//    {
//        let path = "Themes/\(name)"
//        guard let fileURL = Bundle.main.path(forResource: name, ofType: "jpg"),
//              let themeIndex = themes.firstIndex(of: name) else {return}
//        
//        do
//        {
//            let data = try Data(contentsOf: .init(filePath: fileURL))
//            CacheManager.shared.saveData(data, toPath: path)
//            print("saved image: ", name)
//            themes[themeIndex] = name
//        } catch
//        {
//            print("Unable to retreive image data", error)
//        }
//    }
//    
    func fetchImageData(_ name: String) async
    {
        guard let themeIndex = themes.firstIndex(of: name) else {return}
        
        do
        {
            let imageData = try await FirebaseStorageManager.shared.getTheme(from: .themes, themePath: name)
            let path = "Themes/\(name)"
            CacheManager.shared.saveData(imageData, toPath: path)
            print("saved image: ", name)
            await MainActor.run {
                themes[themeIndex] = name
            }
        } catch
        {
            print("Unable to retreive image data", error)
        }
    }
    
    
    func retrieveImageData(_ name: String) -> Data?
    {
        let path = "/Themes/\(name)"
        if let imageData = CacheManager.shared.retrieveData(from: path)
        {
            return imageData
        }
        return nil
    }
    
    
    
    
    
    
    func loadImage(_ name: String) async -> Data?
    {
        let path = "Themes/\(name)"
        if let imageData = CacheManager.shared.retrieveData(from: path)
        {
            return imageData
        }
        
        guard let fileURL = Bundle.main.url(forResource: name, withExtension: "jpg") else {return nil}
        
        do
        {
            let data = try Data(contentsOf: fileURL)
            CacheManager.shared.saveData(data, toPath: name)
            return data
        } catch
        {
            print("Unable to retreive image data", error)
        }
        return nil
    }
}
