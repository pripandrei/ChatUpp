//
//  AddGroupMembersScreen.swift
//  ChatUpp
//
//  Created by Andrei Pripa on 12/29/24.
//

import SwiftUI

struct AddGroupMembersScreen: View
{
    @ObservedObject var viewModel: GroupCreationViewModel
    @State var searchText: String = ""
    
    var body: some View
    {
        List {
            if viewModel.showSelectedUsers {
                Text("item")
            }
            Section {
                ForEach([UserItem.placeholder]) { user in
                    Button {
                        print("item tapped")
                        viewModel.toggleUserSelection(user)
                    } label: {
                        userRowView(user)
                    }.buttonStyle(.plain)
                    
                }
            }
        }
        .searchable(text: $searchText,
                    placement: .navigationBarDrawer(displayMode: .always),
                    prompt: "Search users")
        .animation(.easeInOut, value: viewModel.showSelectedUsers)
    }
    
    private func userRowView(_ user: UserItem) -> some View
    {
        return UserView(userItem: UserItem.placeholder)
        {
            Spacer()
            createTrailingItem(for: user)
        }
    }
    
    private func createTrailingItem(for user: UserItem) -> some View
    {
        let isUserSelected = viewModel.isUserSelected(user)
        let image = isUserSelected ? Image(systemName: "checkmark.circle.fill") : Image(systemName: "circle")
        let foregroundColor = isUserSelected ? Color.green : Color.gray
        return image
            .foregroundStyle(foregroundColor)
            .imageScale(.large)
    }
}

#Preview {
    NavigationStack{
        AddGroupMembersScreen(viewModel: GroupCreationViewModel())
    }
}
