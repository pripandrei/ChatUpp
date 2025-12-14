//
//  ChatRoomIformationEditScreen.swift
//  ChatUpp
//
//  Created by Andrei Pripa on 3/24/25.
//

import SwiftUI
import PhotosUI

struct ChatRoomInformationEditScreen: View
{
    @Environment(\.dismiss) private var dismiss
    
//    @ObservedObject var viewModel: ChatRoomInformationEditViewModel
    @StateObject private var viewModel: ChatRoomInformationEditViewModel
    @State private var photoPickerItem: PhotosPickerItem?
    @State private var imageDataContainer: IdentifiableItem<Data>?
    @State private var isLoading: Bool = false
    @Binding private var refreshID: UUID
    
    init(chat: Chat, refreshID: Binding<UUID>)
    {
        let viewModel = ChatRoomInformationEditViewModel(conversation: chat)
        self._viewModel = .init(wrappedValue: viewModel)
        self._refreshID = refreshID
    }
    
    var body: some View
    {
        ZStack {
            List {
                Section {
                    ForEach(EditOptionFields.allCases) { option in
                        switch option {
                        case .title:
                            textField($viewModel.groupTitle,
                                      placeholder: option.placeHolder)
                        case .groupInfo:
                            textField($viewModel.groupDescription,
                                      placeholder: option.placeHolder)
                        }
                    }
                } header: {
                    headerView()
                }
                .listRowBackground(Color(ColorScheme.listCellBackgroundColor))
            }
            .scrollContentBackground(.hidden)
            .background(Color(ColorScheme.appBackgroundColor))
            .toolbar {
                toolbarContent()
            }
            .toolbarBackground(.hidden, for: .navigationBar)
        }
        .isLoading(isLoading)
    }
}

//MARK: - Custom textField
extension ChatRoomInformationEditScreen
{
    private func textField(_ text: Binding<String>,
                           placeholder: String) -> some View
    {
        return TextField("",
                         text: text,
                         prompt: Text(verbatim: placeholder).foregroundColor(Color(ColorScheme.textFieldPlaceholderColor)))
        .foregroundStyle(Color(ColorScheme.textFieldTextColor))
    }
}

//MARK: - Edit Option Fields
extension ChatRoomInformationEditScreen
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
extension ChatRoomInformationEditScreen
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
                    .foregroundStyle(Color(ColorScheme.actionButtonsTintColor))
            }
        }.buttonStyle(.plain)
    }
    
    private func groupImage() -> some View
    {
        let imageSize = 120.0
        
        return ZStack
        {
            if let imageFromRepository = viewModel.imageSampleRepository?.samples[.original],
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
extension ChatRoomInformationEditScreen
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

//MARK: - Toolbar content
extension ChatRoomInformationEditScreen
{
    @ToolbarContentBuilder
    private func toolbarContent() -> some ToolbarContent
    {
        ToolbarItem(placement: .topBarTrailing) {
            saveButton()
        }
        
        ToolbarItem(placement: .topBarLeading) {
            cancelButton()
        }
    }
    
    private func cancelButton() -> some View
    {
        Button {
            dismiss()
        } label: {
            Text("Cancel")
                .font(.system(size: 16))
                .bold()
                .foregroundStyle(Color(ColorScheme.actionButtonsTintColor))
        }
    }
    
    private func saveButton() -> some View
    {
        Button {
            Task {
                do {
                    self.isLoading = true
                    let editedStatus = try await viewModel.saveEditedData()
                    editedStatus == .changed ? (refreshID = UUID()) : ()
                } catch {
                    print("Error while saving edited data: \(error)")
                }
                self.isLoading = false
                dismiss()
            }
        } label: {
            Text("Save")
                .font(.system(size: 16))
                .bold()
                .foregroundStyle(Color(ColorScheme.actionButtonsTintColor))
        }
    }
}

#Preview
{
    let chat = Chat(id: "CB3C83A8-2638-46EA-BE6B-A7274C08ED4E", participants: [ChatParticipant(userID: "DESg2qjjJPP20KQDWfKpJJnozv53", unseenMessageCount: 0)], recentMessageID: "Group created")
    
    ChatRoomInformationEditScreen(chat: chat, refreshID: .constant(UUID()))
}
