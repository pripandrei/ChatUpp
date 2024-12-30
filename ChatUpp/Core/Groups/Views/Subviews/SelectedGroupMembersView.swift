//
//  SelectedMembersView.swift
//  ChatUpp
//
//  Created by Andrei Pripa on 12/30/24.
//

import SwiftUI

struct SelectedGroupMembersView: View
{
    @Binding var selectedMembers: [UserItem]
    
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
    
    private func selectedMemberItem(_ user: UserItem) -> some View
    {
        VStack {
            Circle()
                .frame(width: 60, height: 60)
                .foregroundStyle(.gray)
                .overlay(alignment: .topTrailing) {
                    cancelButton(for: user)
                }
            
            Text(user.name)
                .font(Font.system(.subheadline))
                .fontWeight(.semibold)
                .foregroundStyle(Color(#colorLiteral(red: 0.2674642503, green: 0.2521909475, blue: 0.2465424836, alpha: 1)))
        }
    }
    
    private func cancelButton(for user: UserItem) -> some View {
        Button {
            selectedMembers.removeAll(where: { $0.id == user.id })
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
    SelectedGroupMembersView(selectedMembers: .constant(UserItem.placeholders))
}
