//
//  NewGroupSetupScreen.swift
//  ChatUpp
//
//  Created by Andrei Pripa on 1/4/25.
//

import SwiftUI
import PhotosUI

struct NewGroupSetupScreen: View
{
    @State private var textFieldText: String = ""
    @ObservedObject var viewModel: GroupCreationViewModel
    
    @State private var profilePhotoItem: PhotosPickerItem?
    @State private var profileImage: Image?
    @State private var imageData: Data?
    
//    @State private var profileUIImage: UIImage?
//    @State private var profileUIImage: IdentifiableUIImage?
    
    @State private var showCropVC: Bool = false
    
    var body: some View {
        List {
            headerSection()
            addedMembersSection()
        }
        .navigationTitle("New Group")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            toolbarTrailingItem()
        }
    }
    
    private func toolbarTrailingItem() -> some ToolbarContent
    {
        ToolbarItem(placement: .topBarTrailing) {
            Button {
                
            } label: {
                Text("Create")
            }
        }
    }
}

//MARK: Sections
extension NewGroupSetupScreen
{
    private func headerSection() -> some View
    {
        Section {
            HStack {
                profilePicture()
                textField()
                removeTextButton()
            }
            .onChange(of: profilePhotoItem) { _ in
                extractImageData()
                showCropVC = true
            }
        }
        .sheet(isPresented: $showCropVC) {
            if let data = imageData {
                CropViewControllerRepresentable(imageData: data)
            }
        }
    }
    
    private func addedMembersSection() -> some View
    {
        Section {
            ForEach(viewModel.selectedGroupMembers) { user in
                UserView(userItem: user)
            }
        }
    }
}

//MARK: Header Components
extension NewGroupSetupScreen
{
    private func profilePicture() -> some View
    {
        let systemImageSize: CGFloat = 35
        let padding: CGFloat = 15
        let circleSize = systemImageSize + padding * 2
        
        return ZStack {
            PhotosPicker(
                selection: $profilePhotoItem,
                matching: .images,
                photoLibrary: .shared()
            ) {
                if let image = profileImage {
                    image
                        .resizable()
                        .scaledToFill()
                        .frame(width: circleSize, height: circleSize)
                        .clipShape(Circle())
                } else {
                    Image(systemName: "camera.fill")
                        .resizable()
                        .scaledToFit()
                        .frame(width: systemImageSize, height: systemImageSize)
                        .padding(padding)
                        .foregroundStyle(Color(#colorLiteral(red: 0.5159683824, green: 0.7356743217, blue: 0.9494176507, alpha: 1)))
                        .background(Color(#colorLiteral(red: 0.6000000238, green: 0.6000000238, blue: 0.6000000238, alpha: 1)))
                        .clipShape(Circle())
                }
            }
            .buttonStyle(.plain)
        }
    }
    
    private func textField() -> some View {
        TextField("Group Name", text: $textFieldText)
            .padding(.leading, 10)
            .font(Font.system(size: 19, weight: .semibold))
            .foregroundStyle(Color(#colorLiteral(red: 0.4086711407, green: 0.4086711407, blue: 0.4086711407, alpha: 1)))
    }
    
    private func removeTextButton() -> some View
    {
        Button {
            textFieldText = ""
        } label: {
            ZStack {
                Circle()
                    .fill(Color(#colorLiteral(red: 0.6000000238, green: 0.6000000238, blue: 0.6000000238, alpha: 1)))
                    .frame(width: 24, height: 24)
                
                Image(systemName: "xmark")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 10, height: 10)
                    .foregroundStyle(.white)
            }
        }
        .buttonStyle(.plain)
    }
}

//MARK: - Helper functions
extension NewGroupSetupScreen
{
    
    private func extractImageData()
    {
        Task {
            self.imageData = try await self.profilePhotoItem?.loadTransferable(type: Data.self)
        }
    }
    
//    private func setImage() {
////        Task {
////            if let image = try? await profilePhotoItem?.loadTransferable(type: Image.self) {
////                self.profileImage = image
////            }
////        }
//        
//        Task {
//            if let imageData = try? await profilePhotoItem?.loadTransferable(type: Data.self),
//               let uIImage = UIImage(data: imageData)
//            {
//                
//                self.profileImage = Image(uiImage: uIImage)
//            }
//        }
//    }
    
//    private func extractImage(from pickerItem: PhotosPickerItem?)
//    {
//        Task {
//            if let data = try? await pickerItem?.loadTransferable(type: Data.self),
//               let uiimage = UIImage(data: data)
//            {
//                self.profileUIImage = IdentifiableUIImage(image: uiimage)
////                self.profileUIImage = uiimage
//            }
//        }
//    }
}

#Preview {
    NavigationStack {
        NewGroupSetupScreen(viewModel: GroupCreationViewModel())
    }
}


struct IdentifiableUIImage: Identifiable {
    let id: String = UUID().uuidString
    var image: UIImage
}
