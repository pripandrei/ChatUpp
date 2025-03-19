//
//  ChatRoomInformationScreen.swift
//  ChatUpp
//
//  Created by Andrei Pripa on 3/17/25.
//

import SwiftUI

struct ChatRoomInformationScreen: View
{
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
            .padding(.top, -40)
            
            List {
                Section {
                    ForEach(0..<10) { item in
                        Text("Item \(item)")
                    }
                } header: {
                    Text("Members")
                        .font(.subheadline)
                        .bold()
                }
                .listRowBackground(Color(cgColor: #colorLiteral(red: 0.7054647803, green: 0.7069373131, blue: 0.8391894698, alpha: 1)))
            }
            .scrollContentBackground(.hidden)
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
                    .foregroundStyle(Color(cgColor: #colorLiteral(red: 0.4667027593, green: 0.2827162743, blue: 0.9599718451, alpha: 1)))
                    
                Text(item.rawValue)
//                    .font(.system(size: 12, weight: .semibold, design: .serif))
                    .font(.custom("HelveticaNeue", size: 14))
                    .foregroundStyle(Color(cgColor: #colorLiteral(red: 0.4667027593, green: 0.2827162743, blue: 0.9599718451, alpha: 1)))
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
    ChatRoomInformationScreen()
}
