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
//        executeAfter(seconds: 5.0) {
            self.setupImage()
//        }
    }
}


//MARK: - Image setup
private extension ThemeGridItemViewModel
{
    func setupImage()
    {
        let targets = makeTargets()

        let imagesExistLocally = targets
            .allSatisfy { CacheManager.shared.doesFileExist(at: localPath(for: $0.name)) }

        if imagesExistLocally
        {
            if let thumb = targets.first(where: { $0.folder == .thumbnails }) {
                self.imageData = CacheManager.shared.retrieveData(from: localPath(for: thumb.name))
            }
            return
        }

        Task {
            for target in targets {
                await loadImage(folder: target.folder, name: target.name)
            }
        }
    }

    func loadImage(folder: ImageFolder, name: String) async
    {
        do {
            let data = try await FirebaseStorageManager.shared.getTheme(
                from: .themes(folder.rawValue),
                themePath: name
            )

            CacheManager.shared.saveData(data, toPath: localPath(for: name))

            if folder == .thumbnails {
                await MainActor.run { self.imageData = data }
            }
        } catch {
            print("❌ Failed to load image:", error)
        }
    }

    func makeTargets() -> [(folder: ImageFolder, name: String)]
    {
        [
            (.originals, themeName),
            (.thumbnails, themeName.addSuffix("thumbnail"))
        ]
    }

    func localPath(for name: String) -> String {
        "/Themes/\(name)"
    }
}

private enum ImageFolder: String
{
    case thumbnails
    case originals
}
