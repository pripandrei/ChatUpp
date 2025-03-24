//
//  ChatRoomIformationEditScreen.swift
//  ChatUpp
//
//  Created by Andrei Pripa on 3/24/25.
//

import SwiftUI
import PhotosUI

struct ChatRoomIformationEditScreen: View
{
    @ObservedObject var viewModel: ChatRoomIformationEditViewModel
    @State private var photoPickerItem: PhotosPickerItem?
    @State private var imageDataContainer: IdentifiableItem<Data>?
    
    var body: some View
    {
        List {
            Section {
                ForEach(EditOptionFields.allCases) { option in
                    switch option {
                    case .title:  TextField(option.placeHolder, text: $viewModel.groupTitle)
                    case .groupInfo: TextField(option.placeHolder, text: $viewModel.groupDescription)
                    }
                }
            } header: {
                headerView()
            }
        }
    }
}


//MARK: - Edit Option Fields
extension ChatRoomIformationEditScreen
{
    enum EditOptionFields: String, Identifiable, CaseIterable
    {
        case title
        case groupInfo
        
        var id: String {
            return rawValue
        }
        
        var placeHolder: String {
            switch self {
            case .title: return rawValue.capitalized
            case .groupInfo: return "Description"
            }
        }
    }
}

//MARK: - Header view
extension ChatRoomIformationEditScreen
{
    private func headerView() -> some View {
        VStack {
            groupImage()
            setNewPhotoButton()
        }
        .onChange(of: photoPickerItem) { _ in
            Task {
                if let selectedImageData = await extractImageData() {
                    self.imageDataContainer = IdentifiableItem(item: selectedImageData)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .center)
        .padding(.vertical, 10)
        .sheet(item: $imageDataContainer) { item in
            CropViewControllerRepresentable(imageData: item.item, imageRepositoryRepresentable: viewModel)
        }
    }
    
    private func setNewPhotoButton() -> some View {
        Button {
            
        } label: {
            PhotosPicker(selection: $photoPickerItem, photoLibrary: .shared()) {
                Text("Set New Photo")
                    .font(.body)
                    .fontWeight(.medium)
                    .textCase(nil)
                    .foregroundStyle(Color.blue)
            }
        }.buttonStyle(.plain)
    }
    
    private func groupImage() -> some View
    {
        let imageSize = 120.0
        
        return ZStack
        {
            if let imageFromRepository = viewModel.imageSampleRepository?.samples[.medium],
                let image = UIImage(data: imageFromRepository)
            {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
                    .frame(width: imageSize, height: imageSize)
                    .clipShape(.circle)
            }
            else if let imageData = viewModel.retrieveImageData(),
               let image = UIImage(data: imageData)
            {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
                    .frame(width: imageSize, height: imageSize)
                    .clipShape(.circle)
            }
            else {
                Image("default_group_photo")
                    .resizable()
                    .scaledToFill()
                    .frame(width: imageSize, height: imageSize)
                    .clipShape(.circle)
            }
        }
    }
}

//MARK: - Header image functions
extension ChatRoomIformationEditScreen
{
    private func extractImageData() async -> Data? {
        do {
            return try await photoPickerItem?.loadTransferable(type: Data.self)
        } catch {
            print("Error extracting image data from picker item: \(error)")
            return nil
        }
    }
}

#Preview {
    ChatRoomIformationEditScreen(viewModel: ChatRoomIformationEditViewModel(conversation: Chat(id: "CB3C83A8-2638-46EA-BE6B-A7274C08ED4E", participants: [ChatParticipant(userID: "DESg2qjjJPP20KQDWfKpJJnozv53", unseenMessageCount: 0)], recentMessageID: "Group created"))
    )
}
