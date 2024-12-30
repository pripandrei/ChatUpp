//
//  AddGroupMembersScreen.swift
//  ChatUpp
//
//  Created by Andrei Pripa on 12/29/24.
//

import SwiftUI

struct GroupMembersSelectionScreen: View
{
    @ObservedObject var viewModel: GroupCreationViewModel
    @State var searchText: String = ""
    
    var body: some View
    {
        List {
            if viewModel.showSelectedUsers {
                SelectedGroupMembersView(selectedMembers: $viewModel.selectedGroupMembers)
            }
            
            Section {
                ForEach(UserItem.placeholders) { user in
                    Button {
                        viewModel.toggleUserSelection(user)
                    } label: {
                        rowView(for: user)
                    }.buttonStyle(.plain)
                    
                }
            }
        }
        .searchable(text: $searchText,
                    placement: .navigationBarDrawer(displayMode: .always),
                    prompt: "Search users")
        .animation(.easeInOut, value: viewModel.showSelectedUsers)
    }
}

//MARK: - List row
extension GroupMembersSelectionScreen
{
    private func rowView(for user: UserItem) -> some View
    {
        UserView(userItem: user)
        {
            Spacer()
            let isUserSelected = viewModel.isUserSelected(user)
            createTrailingItem(withSelection: isUserSelected)
        }
    }
    
    private func createTrailingItem(withSelection isSelected: Bool) -> some View
    {
        let image = isSelected ? Image(systemName: "checkmark.circle.fill") : Image(systemName: "circle")
        let foregroundColor = isSelected ? Color.green : Color.gray
        return image
            .font(.system(size: 24))
            .foregroundStyle(foregroundColor)
    }
}

#Preview {
    NavigationStack{
        GroupMembersSelectionScreen(viewModel: GroupCreationViewModel())
    }
}

