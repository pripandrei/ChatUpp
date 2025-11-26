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
    @EnvironmentObject var coordinator: MainCoordinator
    @ObservedObject var viewModel: GroupCreationViewModel
    
    @State private var imageDataContainer: IdentifiableItem<Data>?
    @State private var profilePhotoItem: PhotosPickerItem?
    
    @State private var isGroupCreationInProgress: Bool = false
    @State private var showGroupCreationAlertError: Bool = false
    @State private var groupCreationErrorMessage: String = ""
    
    var body: some View {
        List {
            headerSection()
            addedMembersSection()
        }
        .scrollContentBackground(.hidden)
        .background(Color(ColorScheme.appBackgroundColor))
        .navigationTitle("New Group")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            toolbarTrailingItem()
        }
        .onChange(of: viewModel.chatGroup) { newGroup in
            guard let newGroup else { return }
            Task {
                try await openChatGroup(with: newGroup)
            }
        }
        .errorAlert(title: "Network connection error",
                    message: groupCreationErrorMessage,
                    isPresented: $showGroupCreationAlertError)
//        .modifier(AlertModifier(isPresented: $showGroupCreationAlertError,
//                                message: errorMessage))
    }

    private func toolbarTrailingItem() -> some ToolbarContent
    {
        ToolbarItem(placement: .topBarTrailing)
        {
            if isGroupCreationInProgress
            {
                ProgressView()
                    .progressViewStyle(.circular)
                    .padding(.trailing, 8)
                    .scaleEffect(1.3)
                    .tint(Color(ColorScheme.actionButtonsTintColor))
            } else {
                Button {
                    dismissKeyboard()
                    self.isGroupCreationInProgress = true
                    Task {
                        await initiateGroupCreationProcess()
                    }
                } label: {
                    Text("Create")
                        .foregroundStyle(viewModel.groupName.isEmpty ? .gray : Color(ColorScheme.actionButtonsTintColor))
                }
                .disabled(viewModel.groupName.isEmpty)
            }
        }
    }
}

//MARK: Sections
extension NewGroupSetupScreen
{
    private func headerSection() -> some View {
           Section {
               HStack {
                   groupImage()
                   groupNameTextField()
                   removeTextButton()
               }
               .onChange(of: profilePhotoItem) { _ in
                   Task {
                       if let imageData = await extractImageData() {
                           self.imageDataContainer = IdentifiableItem(item: imageData)
                       }
                   }
               }
           }
           .listRowBackground(Color(ColorScheme.listCellBackgroundColor))
           .sheet(item: $imageDataContainer) { container in
               CropViewControllerRepresentable(imageData: container.item, imageRepositoryRepresentable: viewModel)
           }
       }
    
    private func addedMembersSection() -> some View
    {
        Section {
            ForEach(viewModel.selectedGroupMembers) { user in
                UserView(userItem: user)
                    .listRowBackground(Color(ColorScheme.listCellBackgroundColor))
            }
        }
    }
}

//MARK: Header Components
extension NewGroupSetupScreen
{
    private func groupImage() -> some View
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
                if let image = viewModel.imageSampleRepository?.samples[.small],
                   let image = UIImage(data: image)
                {
                    Image(uiImage: image)
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
                        .foregroundStyle(Color(ColorScheme.actionButtonsTintColor))
                        .background(Color(ColorScheme.mainAppBackgroundColorGradientTop))
                        .clipShape(Circle())
                }
            }
            .buttonStyle(.plain)
        }
    }
    
    private func groupNameTextField() -> some View {
        TextField("",
                  text: $viewModel.groupName,
                  prompt: Text(verbatim: "Group Name").foregroundColor(Color(ColorScheme.textFieldPlaceholderColor))
        )
        .padding(.leading, 10)
        .font(Font.system(size: 19, weight: .semibold))
        .foregroundStyle(Color(ColorScheme.textFieldTextColor))
    }
    
    private func removeTextButton() -> some View
    {
        Button {
            viewModel.groupName = ""
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
    private func extractImageData() async -> Data?
    {
        return try? await self.profilePhotoItem?.loadTransferable(type: Data.self)
    }
    
    private func openChatGroup(with group: Chat) async throws
    {
        let chatRoomVM = ChatRoomViewModel(conversation: group)
        Utilities.windowRoot?.dismiss(animated: true)
        try await Task.sleep(for: .seconds(0.5))
        coordinator.openConversationVC(conversationViewModel: chatRoomVM)
    }
    
    private func dismissKeyboard()
    {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder),
                                        to: nil,
                                        from: nil,
                                        for: nil)
    }
    
    private func initiateGroupCreationProcess() async
    {
        do {
            try await viewModel.finishGroupCreation()
        }
        catch let error as NetworkError
        {
            self.showGroupCreationAlertError = true
            self.groupCreationErrorMessage = error.errorDescription ?? error.localizedDescription
            print("Could not create group: \(error)")
        } catch {
            self.showGroupCreationAlertError = true
            self.groupCreationErrorMessage = error.localizedDescription
            print("Could not create group: \(error)")
        }
        self.isGroupCreationInProgress = false
    }
}

struct IdentifiableItem<T>: Identifiable
{
    let id = UUID()
    let item: T
}

#Preview {
    NavigationStack {
        NewGroupSetupScreen(viewModel: GroupCreationViewModel())
    }
}
