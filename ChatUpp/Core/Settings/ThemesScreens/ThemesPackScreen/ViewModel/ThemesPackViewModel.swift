//
//  ThemesPackViewModel.swift
//  ChatUpp
//
//  Created by Andrei Pripa on 11/29/25.
//

import SwiftUI

final class ThemesPackViewModel: SwiftUI.ObservableObject
{
    @Published var themes = (1...27).map { index in
        "chat_background_theme_\(index).jpg"
    }
    
    @Published private(set) var selectedTheme = ""
    @Published private(set) var selectedOriginalImageData: Data?
    
    init()
    {
        guard let key = Utilities.retrieveSelectedThemeKey() else {
           return
        }
        selectedTheme = key
    }
     
    func selectTheme(_ name: String)
    {
        selectedTheme = name
        selectedOriginalImageData = nil

        if let cachedData = CacheManager.shared.retrieveData(from: localPath(for: name))
        {
            selectedOriginalImageData = cachedData
            return
        }

        Task {
            await loadOriginalImage(named: name)
        }
    }

    func applySelectedTheme()
    {
        let key = ChatManager.currentlySelectedChatThemeKey
        UserDefaults.standard.set(selectedTheme, forKey: key)
    }
}

//MARK: - Original image loading
private extension ThemesPackViewModel
{
    func loadOriginalImage(named name: String) async
    {
        do {
            let data = try await SupabaseStorageManager.shared.getTheme(
                from: .themes("originals"),
                themePath: name
            )

            CacheManager.shared.saveData(data, toPath: localPath(for: name))

            await MainActor.run {
                guard self.selectedTheme == name else { return }
                self.selectedOriginalImageData = data
            }
        } catch {
            print("❌ Failed to load original theme image:", error)
        }
    }

    func localPath(for name: String) -> String {
        "/Themes/\(name)"
    }
}
