//
//  ThemeGridItemViewModel.swift
//  ChatUpp
//
//  Created by Andrei Pripa on 12/2/25.
//

import SwiftUI

final class ThemeGridItemViewModel: SwiftUI.ObservableObject
{
    @Published private(set) var imageData: Data?

    private let themeName: String

    init(themeName: String) {
        self.themeName = themeName
        self.setupImage()
    }
}


//MARK: - Image setup
private extension ThemeGridItemViewModel
{
    func setupImage()
    {
        if let cachedData = CacheManager.shared.retrieveData(from: localPath)
        {
            self.imageData = cachedData
            return
        }

        Task {
            await loadImage()
        }
    }

    func loadImage() async
    {
        do {
            let data = try await SupabaseStorageManager.shared.getTheme(
                from: .themes("thumbnails"),
                themePath: themeName
            )

            CacheManager.shared.saveData(data, toPath: localPath)

            await MainActor.run { self.imageData = data }
        } catch {
            print("❌ Failed to load image:", error)
        }
    }

    var localPath: String {
        "/Themes/thumbnails/\(themeName)"
    }
}
