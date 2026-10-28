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
    @FocusState private var isSearchFocused: Bool
    
    init(viewModel: GroupCreationViewModel)
    {
        self._viewModel = ObservedObject(wrappedValue: viewModel)
    }
    
    var body: some View
    {
        List {
            if viewModel.showSelectedUsers
            {
                SelectedGroupMembersView(selectedMembers: $viewModel.selectedGroupMembers)
                    .listRowBackground(Color(ColorScheme.listCellBackgroundColor))
            }
            
            Section {
                ForEach(viewModel.usersToShow) { user in
                    Button {
                        viewModel.toggleUserSelection(user)
                    } label: {
                        rowView(for: user)
                    }.buttonStyle(.plain)
                        .listRowBackground(Color(ColorScheme.listCellBackgroundColor))
                }
            }
        }
        .scrollContentBackground(.hidden)
        .background(Color(ColorScheme.appBackgroundColor))
        .animation(.easeInOut, value: viewModel.showSelectedUsers)
        .safeAreaInset(edge: .top, spacing: 0) {
            searchBar()
        }
        .foregroundStyle(Color(ColorScheme.textFieldTextColor))
        .toolbar {
            toolbarContent()
        }
        .onDisappear {
            isSearchFocused = false
        }
        .onChange(of: viewModel.searchText, { oldValue, newValue in
            if !newValue.isEmpty
            {
                Task
                {
                    await viewModel.performSearch(query: newValue)                    
                }
            }
            if newValue.isEmpty
            {
                viewModel.emptySearchUsers()
            }
        })
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(.hidden, for: .navigationBar)
    }
}

//MARK: - Search
extension GroupMembersSelectionScreen
{
    @ViewBuilder
    private func searchBar() -> some View
    {
        let field = HStack(spacing: 8) {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(.gray)
            TextField("Search users", text: $viewModel.searchText)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .submitLabel(.search)
                .focused($isSearchFocused)
                .onSubmit { isSearchFocused = false }

            if !viewModel.searchText.isEmpty {
                Button {
                    viewModel.searchText = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(.gray)
                }
                .accessibilityLabel("Clear search")
            }
        }
        .padding(10)
        .frame(maxWidth: .infinity)

        Group {
            if #available(iOS 26.0, *) {
                field.glassEffect(.regular.tint(Color(ColorScheme.appBackgroundColor)).interactive(), in: .capsule)
            } else {
                field.background(Color(ColorScheme.appBackgroundColor), in: RoundedRectangle(cornerRadius: 10))
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(Color(ColorScheme.appBackgroundColor))
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
                Text("\(selectedParticipants)/100000")
                    .font(.system(size: 15))
                    .foregroundStyle(Color.gray)
            }
        }
        
        ToolbarItem(placement: .topBarTrailing)
        {
            let foregroundColor = viewModel.disableNextButton ? Color.gray : Color(ColorScheme.actionButtonsTintColor)
            Button("Next") {
                isSearchFocused = false
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

