//
//  SwiftUIView.swift
//  ChatUpp
//
//  Created by Andrei Pripa on 12/29/24.
//

import SwiftUI
import Combine

// MARK: - Users section
struct UserView<Content: View>: View
{
    @StateObject private var viewModel: UserViewViewModel
    
    private let userItem: User
    private let trailingItems: Content
    
    init(userItem: User,
         @ViewBuilder trailingItems: () -> Content = { EmptyView() })
    {
        self.userItem = userItem
        self.trailingItems = trailingItems()
        
        self._viewModel = StateObject(wrappedValue: UserViewViewModel(user: userItem))
    }
    
    var body: some View {
        HStack
        {
            userImage()
            
            VStack(alignment: .leading) {
                Text(userItem.name ?? "")
                    .bold()
                    .foregroundStyle(.white)
                
                Text(userItem.lastSeen?.formatToYearMonthDayCustomString() ?? "Last seen recently")
                    .font(.caption)
                    .foregroundStyle(Color(ColorManager.textFieldPlaceholderColor))
            }
            trailingItems
        }
    }
}

extension UserView
{
    private func userImage() -> some View
    {
        let imageSize = 37.0
        
        return Group {
            if let data = viewModel.imageData,
               let image = UIImage(data: data) {
                Image(uiImage: image)
                    .resizable()
            } else {
                Image("default_profile_photo")
                    .resizable()
            }
        }
        .scaledToFill()
        .frame(width: imageSize, height: imageSize)
        .clipShape(Circle())
    }
}


final class UserViewViewModel: SwiftUI.ObservableObject
{
    private let user: User
    @Published private(set) var imageData: Data?
    
    init(user: User)
    {
        self.user = user
        Task { await loadImage() }
    }
    
    var imageURL: String?
    {
        if let imageURL = user.photoUrl {
            return imageURL.addSuffix("small")
        }
        return nil
    }
    
    @MainActor
    private func downloadImage(imagePath path: String) async -> Data?
    {
        do {
            return try await FirebaseStorageManager.shared.getImage(from: .user(user.id), imagePath: path)
        } catch {
            print("Could not download image for userView: ", error)
            return nil
        }
    }
    
    @MainActor
    private func loadImage() async
    {
        guard let url = imageURL else { return }
        
        if let data = CacheManager.shared.retrieveImageData(from: url)
        {
            imageData = data
        }
        else if let data = await downloadImage(imagePath: url)
        {
            imageData = data
            if let url = imageURL {
                CacheManager.shared.saveImageData(data, toPath: url)
            }
        }
    }
}
