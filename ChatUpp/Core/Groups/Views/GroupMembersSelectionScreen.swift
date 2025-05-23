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
                    .listRowBackground(Color(ColorManager.listCellBackgroundColor))
            }
            
            Section {
                ForEach(viewModel.allUsers) { user in
                    Button {
                        viewModel.toggleUserSelection(user)
                    } label: {
                        rowView(for: user)
                    }.buttonStyle(.plain)
                        .listRowBackground(Color(ColorManager.listCellBackgroundColor))
                }
            }
        }
        .scrollContentBackground(.hidden)
        .background(Color(ColorManager.appBackgroundColor))
        .animation(.easeInOut, value: viewModel.showSelectedUsers)
        .searchable(text: $searchText,
                    placement: .navigationBarDrawer(displayMode: .always),
                    prompt: "Search users")
        .toolbar {
            toolbarContent()
        }
        .navigationBarTitleDisplayMode(.inline)
    }
}

//MARK: - List row
extension GroupMembersSelectionScreen
{
    private func rowView(for user: User) -> some View
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

//MARK: - Toolbar items
extension GroupMembersSelectionScreen
{
    @ToolbarContentBuilder
    private func toolbarContent() -> some ToolbarContent
    {
        ToolbarItem(placement: .principal)
        {
            let selectedParticipants = viewModel.selectedGroupMembers.count
            VStack {
                Text("Add participants")
                    .fontWeight(.bold)
                    .foregroundStyle(.white)
                Text("\(selectedParticipants)/30")
                    .font(.system(size: 15))
                    .foregroundStyle(Color.gray)
            }
        }
        
        ToolbarItem(placement: .topBarTrailing)
        {
            let foregroundColor = viewModel.disableNextButton ? Color.gray : Color(ColorManager.actionButtonsTintColor)
            Button("Next") {
                viewModel.navigationStack.append(.setupGroupDetails)
            }
            .fontWeight(.bold)
            .foregroundStyle(foregroundColor)
            .disabled(viewModel.disableNextButton)
        }
    }
}

#Preview {
    NavigationStack{
        GroupMembersSelectionScreen(viewModel: GroupCreationViewModel())
    }
}

