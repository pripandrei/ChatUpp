//
//  SelectedMembersView.swift
//  ChatUpp
//
//  Created by Andrei Pripa on 12/30/24.
//

import SwiftUI

struct SelectedGroupMembersView: View
{
    @Binding var selectedMembers: [User]
    
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
    
    private func selectedMemberItem(_ user: User) -> some View
    {
        VStack {
            Circle()
                .frame(width: 60, height: 60)
                .foregroundStyle(Color(ColorManager.actionButtonsTintColor))
                .overlay(alignment: .topTrailing) {
                    cancelButton(for: user)
                }
            
            Text(user.name ?? "Unknow")
                .font(Font.system(.subheadline))
                .fontWeight(.semibold)
                .foregroundStyle(.white)
        }
    }
    
    private func cancelButton(for user: User) -> some View {
        Button {
            selectedMembers.removeAll(where: { $0.id == user.id })
        } label: {
            Image(systemName: "xmark")
                .imageScale(.small)
                .padding(.all, 5)
                .background(Color(ColorManager.tabBarNormalItemsTintColor))
                .foregroundStyle(Color(ColorManager.textFieldTextColor))
                .clipShape(.circle)
        }

    }
}
#Preview {
    SelectedGroupMembersView(selectedMembers: .constant([User.dummy]))
}
