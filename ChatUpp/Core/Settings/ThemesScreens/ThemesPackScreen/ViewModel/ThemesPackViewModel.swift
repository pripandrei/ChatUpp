//
//  ThemesPackViewModel.swift
//  ChatUpp
//
//  Created by Andrei Pripa on 11/29/25.
//

import SwiftUI

final class ThemesPackViewModel: SwiftUI.ObservableObject
{
    @Published var themes = (1...30).map { index in
        "chat_background_theme_\(index).jpg"
    }
    
    @Published var selectedTheme = ""
    
    init()
    {
//        CacheManager.shared.clearCacheDirectory(name: "Themes")
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

    func applySelectedTheme()
    {
        let key = ChatManager.currentlySelectedChatThemeKey
        UserDefaults.standard.set(selectedTheme, forKey: key)
    }
}



