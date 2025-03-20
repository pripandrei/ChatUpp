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
                    Text("Chat Room Name")
                        .font(.system(size: 24, weight: .semibold))
                    Text("34 members")
                        .font(.system(size: 15))
                }
                .foregroundStyle(.white)
                .padding(.leading, 20)
                .padding(.bottom, 20)
            }
            .frame(width: UIScreen.main.bounds.width, height: 400)
            .ignoresSafeArea(.all)
            
            HStack {
                Spacer()
                ForEach(ButtonOption.allCases) { item in
                    ButtonOptionView(item: item)
                }
            }
            .padding(.trailing, 30)
            .padding(.top, -45)
            
            List {
                Section {
                    ForEach(viewModel.members) { member in
                        UserView(userItem: member)
                    }
                    
//                    ForEach(0..<10) { item in
//                        UserView(userItem: User(userId: "asdads3423", name: "Amiamin", email: "er", photoUrl: nil, phoneNumber: nil, nickName: nil, dateCreated: Date(), lastSeen: Date(), isActive: false))
////                        Text("Item \(item)")
//////                            .listRowInsets(EdgeInsets(top: 0, leading: 70, bottom: 0, trailing: 0))
//                    }
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
//            .background(Color(cgColor: #colorLiteral(red: 0.4392156899, green: 0.01176470611, blue: 0.1921568662, alpha: 1)))
            .padding(.top, 15)
        }
        .background(Color(cgColor: #colorLiteral(red: 0.5539219975, green: 0.5661839247, blue: 0.656108439, alpha: 1)))
    }
}

//MARK: Info Buttons
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
        let item: ButtonOption
        
        var body: some View {
            Button {
                
            } label: {
                setupButtonOptionLabel()
            }
            .buttonStyle(.plain)
        }
        
        private func setupButtonOptionLabel() -> some View
        {
            VStack {
                Image(systemName: item.icon)
                    .resizable()
                    .frame(width: 30, height: 30, alignment: .center)
                    .foregroundStyle(Color(cgColor: #colorLiteral(red: 0.92651546, green: 0.7966771722, blue: 1, alpha: 1)))
                    
                Text(item.rawValue)
                    .font(.system(size: 13, weight: .semibold))
//                    .font(.custom("HelveticaNeue", size: 14))
//                    .fontWeight(.bold)
                    .foregroundStyle(Color(cgColor: #colorLiteral(red: 0.92651546, green: 0.7966771722, blue: 1, alpha: 1)))
            }
            .frame(width: 80, height: 50)
            .padding(.horizontal, 8)
            .padding(.vertical, 8)
            .background(Color(cgColor: #colorLiteral(red: 0.4245440364, green: 0.4465940595, blue: 1, alpha: 1)).opacity(0.4))
            .clipShape(.rect(cornerRadius: 12))
        }
    }
}

#Preview {
    ChatRoomInformationScreen(viewModel: ChatRoomInformationViewModel(chat: Chat(id: "CB3C83A8-2638-46EA-BE6B-A7274C08ED4E", participants: [ChatParticipant(userID: "DESg2qjjJPP20KQDWfKpJJnozv53", unseenMessageCount: 0)], recentMessageID: "Group created")))
}
