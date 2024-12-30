//
//  SelectedMembersView.swift
//  ChatUpp
//
//  Created by Andrei Pripa on 12/30/24.
//

import SwiftUI

struct SelectedGroupMembersView: View
{
    var body: some View
    {
        ScrollView(.horizontal) {
            HStack {
                ForEach(UserItem.placeholders) { user in
                    selectedMemberItem(user.name)
                }
            }
        }
        .scrollIndicators(.hidden)
    }
    
    private func selectedMemberItem(_ name: String) -> some View
    {
        VStack {
            Circle()
                .frame(width: 60, height: 60)
                .foregroundStyle(.gray)
                .overlay(alignment: .topTrailing) {
                    cancelButton()
                }
            
            Text(name)
                .font(Font.system(.subheadline))
                .fontWeight(.semibold)
                .foregroundStyle(Color(#colorLiteral(red: 0.2674642503, green: 0.2521909475, blue: 0.2465424836, alpha: 1)))
        }
    }
    
    private func cancelButton() -> some View {
        Button {
            
        } label: {
            Image(systemName: "xmark")
                .imageScale(.small)
                .padding(.all, 5)
                .background(Color(.systemGray2))
                .foregroundStyle(Color.white)
                .clipShape(.circle)
        }

    }
}
#Preview {
    SelectedGroupMembersView()
}
