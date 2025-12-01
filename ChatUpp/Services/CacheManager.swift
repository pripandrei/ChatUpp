
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

//
//
////
////  ThemeSelectionScreen.swift
////  ChatUpp
////
////  Created by Andrei Pripa on 11/28/25.
////
//
//import SwiftUI
//
//struct ThemesPackScreen: View
//{
//    @StateObject var viewModel: ThemesPackViewModel = .init()
//    @State var showThemeSelectionScreenSheet: Bool = false
//    
//    let columns: Array = Array(repeating: GridItem(.flexible(),
//                                                   spacing: -20,
//                                                   alignment: .center),
//                               count: 3)
//    
//    var body: some View
//    {
//        ScrollView()
//        {
//            GridHeader()
//            
//            LazyVGrid(columns: columns, spacing: 10)
//            {
//                ForEach(viewModel.themes, id: \.self) { theme in
////                    GridImageItem(theme)
//                    GridThemeItemView(viewModel: viewModel, imageName: theme)
//                }
//            }
//        }
//        .background(Color(ColorScheme.appBackgroundColor))
////        .sheet(isPresented: $showThemeSelectionScreenSheet) {
////            showThemeSelectionScreenSheet = false
////        } content: {
////            NavigationStack
////            {
////                ThemeSelectionScreen(viewModel: viewModel)
////                    .presentationDetents([.large])
////                    .presentationDragIndicator(.hidden)
////            }
////        }
//    }
//}
//
//struct GridThemeItemView: View
//{
//    @ObservedObject var viewModel: ThemesPackViewModel
//    @State var imageName: String
//    @State var image: UIImage?
//    @State var showThemeSelectionScreenSheet: Bool = false
//    
//    var body: some View
//    {
//        VStack
//        {
//            if let image
//            {
//                Image(uiImage: image)
//                    .resizable()
//                //                        .scaledToFit()
//                    .frame(width: 110, height: 170)
//                    .clipShape(.rect(cornerRadius: 10))
//                    .overlay {
//                        if imageName == viewModel.selectedTheme
//                        {
//                            selectionView()
//                        }
//                    }
//                    .onTapGesture {
//                        viewModel.selectedTheme = imageName
//                        showThemeSelectionScreenSheet = true
//                    }
//            } else {
//                PlaceholderView()
//            }
//        }
//        .sheet(isPresented: $showThemeSelectionScreenSheet) {
//            showThemeSelectionScreenSheet = false
//        } content: {
//            NavigationStack
//            {
//                ThemeSelectionScreen(viewModel: viewModel)
//                    .presentationDetents([.large])
//                    .presentationDragIndicator(.hidden)
//            }
//        }
//        .task {
////            guard let imageData = await viewModel.loadImage(imageName) else {return}
////            self.image = UIImage(data: imageData)
//        }
//    }
//}
//
//extension GridThemeItemView
//{
//    private func selectionView() -> some View
//    {
//        Circle()
//            .frame(width: 45, height: 45)
//            .foregroundStyle(Color(ColorScheme.incomingMessageBackgroundColor))
//            .overlay {
//                Image(systemName: "checkmark")
//                    .resizable()
//                    .scaledToFit()
//                    .frame(width: 18, height: 18)
//                    .foregroundStyle(.white)
//            }
//    }
//    
//    private func PlaceholderView() -> some View
//    {
//        RoundedRectangle(cornerRadius: 10)
//            .frame(width: 110, height: 170)
//            .background(Color.gray)
//            .overlay {
//                ProgressView()
//            }
//    }
//}
//
//extension ThemesPackScreen
//{
//    private func GridImageItem(_ name: String) -> some View
//    {
//        Image(name)
//            .resizable()
////                        .scaledToFit()
//            .frame(width: 110, height: 170)
//            .clipShape(.rect(cornerRadius: 10))
//            .overlay {
//                if name == viewModel.selectedTheme
//                {
//                    selectionView()
//                }
//            }
//            .onTapGesture {
//                viewModel.selectedTheme = name
//                showThemeSelectionScreenSheet = true
//            }
//    }
//    
//    private func GridHeader() -> some View
//    {
//        Text("Themes")
//            .font(Font.system(size: 18, weight: .semibold))
//            .padding([.bottom, .top], 10)
//            .foregroundStyle(.white)
//    }
//}
//
//
//extension ThemesPackScreen
//{
//    private func selectionView() -> some View
//    {
//        Circle()
//            .frame(width: 45, height: 45)
//            .foregroundStyle(Color(ColorScheme.incomingMessageBackgroundColor))
//            .overlay {
//                Image(systemName: "checkmark")
//                    .resizable()
//                    .scaledToFit()
//                    .frame(width: 18, height: 18)
//                    .foregroundStyle(.white)
//            }
//    }
//}
//
//
////#Preview {
////    ThemesPackScreen()
//////    ThemeSelectionScreen(viewModel: .init())
////}
//
//
//struct BlurView: UIViewRepresentable {
//    let style: UIBlurEffect.Style
//    
//    func makeUIView(context: Context) -> UIVisualEffectView {
//        UIVisualEffectView(effect: UIBlurEffect(style: style))
//    }
//    
//    func updateUIView(_ uiView: UIVisualEffectView, context: Context) {}
//}










//
//  ThemesPackViewModel.swift
//  ChatUpp
//
//  Created by Andrei Pripa on 11/29/25.
////
//
//import SwiftUI
//
//struct ThemeImageItem: Identifiable
//{
//    let id: String = UUID().uuidString
//    let name: String
//    var image: Data?
//}
//
//final class ThemesPackViewModel: SwiftUI.ObservableObject
//{
////    let themes = ["chatRoom_background_1",
////                  "chatRoom_background_2",
////                  "chatRoom_background_3"]
//    
////    @Published var selectedTheme = 1
////    let themes = Array(repeating: "chat_background_theme_", count: 30)
//    @Published var themes = (1...30).map { index in
//        "chat_background_theme_\(index).jpg"
//    }
//    
//    @Published var themesImageItems: [ThemeImageItem] = []
//    
//    var selectedTheme = ""
//    
//    init()
//    {
//        CacheManager.shared.clearCacheDirectory(name: "Themes")
//        let themeItems = (1...30).map { index in
//            let name = "chat_background_theme_\(index).jpg"
//            let image = retrieveImageData(name)
//            return ThemeImageItem(name: name, image: image)
//        }
//        self.themesImageItems = themeItems
//    }
//    
//    // test version with cache simulation
////    func fetchImageData(_ name: String)
////    {
////        let path = "Themes/\(name)"
////        guard let fileURL = Bundle.main.path(forResource: name, ofType: "jpg"),
////              let themeIndex = themes.firstIndex(of: name) else {return}
////
////        do
////        {
////            let data = try Data(contentsOf: .init(filePath: fileURL))
////            CacheManager.shared.saveData(data, toPath: path)
////            print("saved image: ", name)
////            themes[themeIndex] = name
////        } catch
////        {
////            print("Unable to retreive image data", error)
////        }
////    }
////
//    func fetchImageData(_ name: String) async
//    {
////        guard let themeIndex = themes.firstIndex(of: name) else {return}
//        guard let themeIndex = themesImageItems.firstIndex(where: { $0.name == name }) else {return}
//        
//        do
//        {
//            let imageData = try await FirebaseStorageManager.shared.getTheme(from: .themes, themePath: name)
//            let path = "Themes/\(name)"
//            CacheManager.shared.saveData(imageData, toPath: path)
//            print("saved image: ", name)
//            await MainActor.run {
//                themesImageItems[themeIndex].image = imageData
//            }
//        } catch
//        {
//            print("Unable to retreive image data", error)
//        }
//    }
//    
//    
//    func retrieveImageData(_ name: String) -> Data?
//    {
//        let path = "/Themes/\(name)"
//        if let imageData = CacheManager.shared.retrieveData(from: path)
//        {
//            return imageData
//        }
//        return nil
//    }
//    
//    
//    
//    
//    
//    
//    func loadImage(_ name: String) async -> Data?
//    {
//        let path = "Themes/\(name)"
//        if let imageData = CacheManager.shared.retrieveData(from: path)
//        {
//            return imageData
//        }
//        
//        guard let fileURL = Bundle.main.url(forResource: name, withExtension: "jpg") else {return nil}
//        
//        do
//        {
//            let data = try Data(contentsOf: fileURL)
//            CacheManager.shared.saveData(data, toPath: name)
//            return data
//        } catch
//        {
//            print("Unable to retreive image data", error)
//        }
//        return nil
//    }
//}

//
//
//
//
////
////  ThemeSelectionScreen.swift
////  ChatUpp
////
////  Created by Andrei Pripa on 11/28/25.
////
//
//import SwiftUI
//import UIKit
//
//struct ThemesPackScreen: View
//{
//    @StateObject var viewModel: ThemesPackViewModel = .init()
//    @State var showThemeSelectionScreenSheet: Bool = false
//    
//    let columns: Array = Array(repeating: GridItem(.flexible(),
//                                                   spacing: -20,
//                                                   alignment: .center),
//                               count: 3)
//    
//    var body: some View
//    {
//        ScrollView()
//        {
//            GridHeader()
//            
//            LazyVGrid(columns: columns, spacing: 10)
//            {
//                ForEach(viewModel.themesImageItems, id: \.id) { theme in
//                    GridImageItem(theme)
//                }
//            }
//        }
//        .background(Color(ColorScheme.appBackgroundColor))
//        .sheet(isPresented: $showThemeSelectionScreenSheet) {
//            showThemeSelectionScreenSheet = false
//        } content: {
//            NavigationStack
//            {
//                Group {
//                    if let selectedImage = viewModel.retrieveImageData(viewModel.selectedTheme),
//                       let image = UIImage(data: selectedImage)
//                    {
//                        ThemeSelectionScreen(selectedImage: image)
//                            .presentationDetents([.large])
//                            .presentationDragIndicator(.hidden)
//                    } else {
//                        EmptyView()
//                    }
//                }
//            }
//        }
//    }
//}
//
//
//extension ThemesPackScreen
//{
//    @ViewBuilder
//    private func GridImageItem(_ item: ThemeImageItem) -> some View
//    {
//        if let imageData = item.image,
//           let image = UIImage(data: imageData)
//        {
//            Image(uiImage: image)
//                .resizable()
//            //                        .scaledToFit()
//                .frame(width: 110, height: 170)
//                .clipShape(.rect(cornerRadius: 10))
//                .overlay {
//                    if item.name == viewModel.selectedTheme
//                    {
//                        selectionView()
//                    }
//                }
//                .onTapGesture {
//                    viewModel.selectedTheme = item.name
//                    showThemeSelectionScreenSheet = true
//                }
//        }
//        else {
//            PlaceholderView()
//                .onAppear {
//                    Task {
//                        try await Task.sleep(for: .seconds(10))
//                        await viewModel.fetchImageData(item.name)
//                    }
//                }
//        }
//    }
//    
//    
////    @ViewBuilder
////    private func GridImageItem(_ name: String) -> some View
////    {
////        if let imageData = viewModel.retrieveImageData(name),
////           let image = UIImage(data: imageData)
////        {
////            Image(uiImage: image)
////                .resizable()
////            //                        .scaledToFit()
////                .frame(width: 110, height: 170)
////                .clipShape(.rect(cornerRadius: 10))
////                .overlay {
////                    if name == viewModel.selectedTheme
////                    {
////                        selectionView()
////                    }
////                }
////                .onTapGesture {
////                    viewModel.selectedTheme = name
////                    showThemeSelectionScreenSheet = true
////                }
////        }
////        else {
////            PlaceholderView()
////                .onAppear {
////                    Task {
////                        try await Task.sleep(for: .seconds(10))
////                        await viewModel.fetchImageData(name)
////                    }
////                }
////        }
////    }
////
//    private func PlaceholderView() -> some View
//    {
//        RoundedRectangle(cornerRadius: 10)
//            .fill(.gray)
//            .frame(width: 110, height: 170)
//            .overlay {
//                ProgressView()
//            }
//    }
//    
//    private func GridHeader() -> some View
//    {
//        Text("Themes")
//            .font(Font.system(size: 18, weight: .semibold))
//            .padding([.bottom, .top], 10)
//            .foregroundStyle(.white)
//    }
//}
//
//
//extension ThemesPackScreen
//{
//    private func selectionView() -> some View
//    {
//        Circle()
//            .frame(width: 45, height: 45)
//            .foregroundStyle(Color(ColorScheme.incomingMessageBackgroundColor))
//            .overlay {
//                Image(systemName: "checkmark")
//                    .resizable()
//                    .scaledToFit()
//                    .frame(width: 18, height: 18)
//                    .foregroundStyle(.white)
//            }
//    }
//}
//
//
//#Preview {
//    ThemesPackScreen()
////    ThemeSelectionScreen(viewModel: .init())
//}
//
//
//struct BlurView: UIViewRepresentable {
//    let style: UIBlurEffect.Style
//    
//    func makeUIView(context: Context) -> UIVisualEffectView {
//        UIVisualEffectView(effect: UIBlurEffect(style: style))
//    }
//    
//    func updateUIView(_ uiView: UIVisualEffectView, context: Context) {}
//}
//
