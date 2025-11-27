//
//  ChatRoomInformationScreen.swift
//  ChatUpp
//
//  Created by Andrei Pripa on 3/17/25.
//

import SwiftUI

struct ChatRoomInformationScreen: View
{
    @ObservedObject var viewModel: ChatRoomInformationViewModel
    @State private var showLeaveGroupAlert: Bool = false
    @State private var presentEditScreen: Bool = false
    @State private var refreshID: UUID = UUID()
    
    var body: some View
    {
        VStack(spacing: 0)
        {
            ZStack(alignment: .bottomLeading)
            {
                VStack {
                    groupImage().id(refreshID)
                }
                
                VStack(alignment: .leading, spacing: 1)
                {
                    Text(viewModel.groupName).id(refreshID)
                        .font(.system(size: 24, weight: .semibold))
                        .lineLimit(1)
                        .padding(.trailing, 25)
                    Text("\(viewModel.membersCount) members")
                        .font(.system(size: 15))
                }
                .foregroundStyle(.white)
                .padding(.leading, 20)
                .padding(.bottom, 20)
                
                if viewModel.isAuthUserGroupMember
                {
                    HStack {
                        Spacer()
                        ForEach(ButtonOption.allCases) { option in
                            ButtonOptionView(option: option) {
                                handleButtonTap(for: option)
                            }
                        }
                    }
                    .padding(.trailing, 30)
                    .padding(.bottom, -30)
                    .fullScreenCover(isPresented: $presentEditScreen) {
                        NavigationStack {
                            let chatRoomIformationEditVM = ChatRoomInformationEditViewModel(conversation: viewModel.chat)
                            ChatRoomInformationEditScreen(viewModel: chatRoomIformationEditVM,
                                                          refreshID: $refreshID)
                        }
                    }
                }
            }
            .frame(width: UIScreen.main.bounds.width, height: 400)
            
            List {
                Section {
                    ForEach(viewModel.members) { member in
                        UserView(userItem: member)
                            .onAppear {
                                if member == viewModel.members.last {
                                    Task {
                                        await viewModel.fetchUsers()
                                    }
                                }
                            }
                    }
                } header: {
                    Text("Members")
                        .textCase(.uppercase)
                        .font(.subheadline)
                        .bold()
                        .foregroundStyle(Color(ColorScheme.tabBarNormalItemsTintColor))
                }
                .listRowBackground(Color(ColorScheme.listCellBackgroundColor))
                .headerProminence(.increased)
//                .listRowInsets(.init(top: 10, leading: 20, bottom: 10, trailing: 0))
            }
            .scrollContentBackground(.hidden)
            .padding(.top, 38)
            
        }
        .ignoresSafeArea(.all)
        .toolbarBackground(.clear, for: .navigationBar)
        .background(Color(ColorScheme.appBackgroundColor))
        
        LeaveChatAlert(viewModel: viewModel,
                       isPresented: $showLeaveGroupAlert)
    }
}

//MARK: Group image
extension ChatRoomInformationScreen
{
    private func groupImage() -> some View
    {
        GeometryReader { geometry in
            let width = geometry.size.width
            
            if let imageData = viewModel.retrieveGroupImage(),
               let image = UIImage(data: imageData)
            {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
                    .frame(width: width)
                    .clipped()
            } else {
                Image("default_group_photo")
                    .resizable()
                    .scaledToFill()
                    .frame(width: width)
                    .clipped()
            }
        }
    }
}

//MARK: Button options
extension ChatRoomInformationScreen
{
    enum ButtonOption: String, CaseIterable, Identifiable
    {
        case leaveGroup = "leave group"
        case edit = "edit"
        
        var id: String {
            return rawValue
        }
        
        var icon: String {
            switch self {
            case .edit: return "pencil.tip.crop.circle"
            case .leaveGroup: return "door.right.hand.open"
            }
        }
    }
    
    private struct ButtonOptionView: View
    {
        let option: ButtonOption
        let action: () -> Void
        
        var body: some View
        {
            Button {
                action()
            } label: {
                setupButtonOptionLabel()
            }
            .buttonStyle(.plain)
        }
        
        private func setupButtonOptionLabel() -> some View
        {
            VStack {
                Image(systemName: option.icon)
                    .resizable()
                    .frame(width: 25, height: 25)
                    .foregroundStyle(Color(ColorScheme.actionButtonsTintColor))

                Text(option.rawValue)
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(Color(ColorScheme.actionButtonsTintColor))
            }
            .frame(width: 70, height: 40)
            .padding(.horizontal, 8)
            .padding(.vertical, 8)
            .background(Color(ColorScheme.listCellBackgroundColor).opacity(0.9))
            .clipShape(.rect(cornerRadius: 12))
            .overlay {
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color(#colorLiteral(red: 0.4868350625, green: 0.345061183, blue: 0.5088059902, alpha: 1)), lineWidth: 1)
            }
        }
    }
    
    private func handleButtonTap(for option: ButtonOption)
    {
        switch option {
        case .edit: presentEditScreen = true
        case .leaveGroup: showLeaveGroupAlert = true
        }
    }
}

//MARK: Leave chat alert
extension ChatRoomInformationScreen
{
    private struct LeaveChatAlert: View
    {
        @ObservedObject var viewModel: ChatRoomInformationViewModel
        @Binding var isPresented: Bool
        
        var body: some View
        {
            VStack {}
                .alert("Leave group", isPresented: $isPresented) {
                    Button("Cancel", role: .cancel) {
                        isPresented = false
                    }
                    Button("Leave", role: .destructive) {
                        Task {
                            try await viewModel.leaveGroup()
                            Utilities.windowRoot?.chatsNavigationController?.popViewController(animated: true)
                            Utilities.windowRoot?.chatsNavigationController?.popToRootViewController(animated: true)
                        }
                    }
                } message: {
                    Text("Are you sure you want to leave this group?")
                }
        }
    }
}

#Preview {
    ChatRoomInformationScreen(viewModel: ChatRoomInformationViewModel(chat: Chat(id: "CB3C83A8-2638-46EA-BE6B-A7274C08ED4E", participants: [ChatParticipant(userID: "DESg2qjjJPP20KQDWfKpJJnozv53", unseenMessageCount: 0)], recentMessageID: "Group created")))
    //    ChatRoomInformationScreen()
}

