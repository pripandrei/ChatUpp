//
//  SelectedMembersView.swift
//  ChatUpp
//
//  Created by Andrei Pripa on 12/30/24.
//

import SwiftUI

struct SelectedGroupMembersView: View
{
    @StateObject var viewModel: SelectedGroupMembersViewModel = SelectedGroupMembersViewModel()
    @Binding var selectedMembers: [User]
    
    var body: some View
    {
        ScrollView(.horizontal) {
            HStack {
                ForEach(selectedMembers) { user in
                    selectedMemberItem(user)
                }
            }
        }
        .scrollIndicators(.hidden)
    }
    
    private func selectedMemberItem(_ user: User) -> some View
    {
        VStack {
            Group {
                if let imageData = viewModel.retrieveImageData(for: user),
                   let image = UIImage(data: imageData)
                {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 60, height: 60)
                        .clipShape(.circle)
                } else {
                    Image("default_profile_photo")
                        .resizable()
                        .scaledToFill()
                        .frame(width: 60, height: 60)
                        .clipShape(.circle)
                }
            }
            .overlay(alignment: .topTrailing) {
                cancelButton(for: user)
            }
            
            Text(user.name ?? "Unknow")
                .font(Font.system(.subheadline))
                .fontWeight(.semibold)
                .foregroundStyle(.white)
        }
    }
    
    private func cancelButton(for user: User) -> some View {
        Button {
            selectedMembers.removeAll(where: { $0.id == user.id })
        } label: {
            Image(systemName: "xmark")
                .imageScale(.small)
                .padding(.all, 5)
                .background(Color(ColorManager.tabBarNormalItemsTintColor))
                .foregroundStyle(Color(ColorManager.textFieldTextColor))
                .clipShape(.circle)
        }

    }
}

final class SelectedGroupMembersViewModel: SwiftUI.ObservableObject
{
    
    func retrieveImageData(for member: User) -> Data?
    {
        guard let imagePath = getMemberProfileImagePath(member.photoUrl) else {return nil}
        return CacheManager.shared.retrieveImageData(from: imagePath)
    }
    
    private func getMemberProfileImagePath(_ path: String?) -> String?
    {
        if let path {
            return path.replacingOccurrences(of: ".jpg", with: "_small.jpg")
            
        }
        return nil
    }
}

#Preview {
    SelectedGroupMembersView(selectedMembers: .constant([User.dummy]))
}
