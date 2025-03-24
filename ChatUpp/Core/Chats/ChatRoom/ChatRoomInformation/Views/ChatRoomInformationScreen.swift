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
    
    var body: some View
    {
        VStack(spacing: 0) {
            ZStack(alignment: .bottomLeading) {
                VStack {
                    Image("default_group_photo")
                        .resizable()
                        .scaledToFill()
                }
                
                VStack(alignment: .leading, spacing: 1) {
                    Text(viewModel.groupName)
                        .font(.system(size: 24, weight: .semibold))
                    Text("\(viewModel.membersCount) members")
                        .font(.system(size: 15))
                }
                .foregroundStyle(.white)
                .padding(.leading, 20)
                .padding(.bottom, 20)
                
                if viewModel.isAuthUserGroupMember {
                    HStack {
                        Spacer()
                        ForEach(ButtonOption.allCases) { option in
                            ButtonOptionView(option: option) {
                                handleButtonTap(for: option)
                            }
                        }
                    }
                    .padding(.trailing, 30)
                    .padding(.bottom, -45)
                    .fullScreenCover(isPresented: $presentEditScreen) {
                        NavigationStack {
                            let chatRoomIformationEditVM = ChatRoomIformationEditViewModel(conversation: viewModel.chat)
                            ChatRoomIformationEditScreen(viewModel: chatRoomIformationEditVM)                            
                        }
                    }
                }
            }
            .frame(width: UIScreen.main.bounds.width, height: 400)
            .ignoresSafeArea(.all)
            
            List {
                Section {
                    ForEach(viewModel.members) { member in
                        UserView(userItem: member)
                    }
                } header: {
                    Text("Members")
                        .font(.subheadline)
                        .bold()
                        .foregroundStyle(Color.white)
                }
                .listRowBackground(Color(cgColor: #colorLiteral(red: 0.7054647803, green: 0.7069373131, blue: 0.8391894698, alpha: 1)))
                .listRowInsets(.init(top: 10, leading: 20, bottom: 10, trailing: 0))
            }
            .scrollContentBackground(.hidden)
        }
        .toolbarBackground(.clear, for: .navigationBar)
        .background(Color(cgColor: #colorLiteral(red: 0.5539219975, green: 0.5661839247, blue: 0.656108439, alpha: 1)))
        .padding(.top, -45)
        
        LeaveChatAlert(viewModel: viewModel, isPresented: $showLeaveGroupAlert)
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
                    .frame(width: 30, height: 30, alignment: .center)
                    .foregroundStyle(Color(cgColor: #colorLiteral(red: 0.92651546, green: 0.7966771722, blue: 1, alpha: 1)))
                
                Text(option.rawValue)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(Color(cgColor: #colorLiteral(red: 0.92651546, green: 0.7966771722, blue: 1, alpha: 1)))
            }
            .frame(width: 80, height: 50)
            .padding(.horizontal, 8)
            .padding(.vertical, 8)
            .background(Color(cgColor: #colorLiteral(red: 0.4245440364, green: 0.4465940595, blue: 1, alpha: 1)).opacity(0.4))
            .clipShape(.rect(cornerRadius: 12))
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
