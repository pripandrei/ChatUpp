//
//  SwiftUIView.swift
//  ChatUpp
//
//  Created by Andrei Pripa on 12/29/24.
//

import SwiftUI

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
        
        if let imageData = viewModel.retrieveUserImageData(),
           let image = UIImage(data: imageData)
        {
            return Image(uiImage: image)
                .resizable()
                .scaledToFill()
                .frame(width: imageSize, height: imageSize)
                .clipShape(Circle())
            
        } else {
            return Image("default_profile_photo")
                .resizable()
                .scaledToFill()
                .frame(width: imageSize, height: imageSize)
                .clipShape(Circle())
        }
    }
}


final class UserViewViewModel: SwiftUI.ObservableObject
{
    private let user: User
    
    init(user: User)
    {
        self.user = user
    }
    
    var imageURL: String?
    {
        if let imageURL = user.photoUrl {
            return imageURL.replacingOccurrences(of: ".jpg", with: "_small.jpg")
        }
        return nil
    }
    
    func retrieveUserImageData() -> Data?
    {
        guard let url = imageURL else {return nil}
        return CacheManager.shared.retrieveImageData(from: url)
    }
}
