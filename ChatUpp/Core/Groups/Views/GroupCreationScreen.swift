//
//  GroupCreationScreen.swift
//  ChatUpp
//
//  Created by Andrei Pripa on 12/24/24.
//

import SwiftUI

struct GroupCreationScreen: View
{
    @StateObject private var groupCreationViewModel = GroupCreationViewModel()
    
    @State private var searchText = ""
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack(path: $groupCreationViewModel.navigationStack) {
            List {
                ForEach(NewChatOption.allCases) { item in
                    NewChatOptionHeaderView(item: item)
                        .onTapGesture {
                            groupCreationViewModel.navigationStack.append(.addGroupMembers)
                        }
                }
                Section {
                    ForEach(groupCreationViewModel.allUsers) { member in
                        UserView(userItem: member)
                    }
                } header: {
                    Text("Users")
                        .font(.subheadline)
                        .bold()
                }
            }
            .padding(.top, 1)
            .background(Color(#colorLiteral(red: 0.949019134, green: 0.9490200877, blue: 0.9705253243, alpha: 1)))
            .searchable(text: $searchText,
                        placement: .navigationBarDrawer(displayMode: .always),
                        prompt: "search for name")
            .navigationTitle("New group")
            .navigationDestination(for: GroupCreationRoute.self, destination: { route in
                destinationRouteView(route)
            })
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarTrailingItem()
            }
            .onAppear {
                Task {
                    try await Task.sleep(for: .seconds(0.5))
                    groupCreationViewModel.selectedGroupMembers.removeAll()
                }
            }
        }
    }
}

extension GroupCreationScreen
{
    @ViewBuilder
    private func destinationRouteView(_ route: GroupCreationRoute) -> some View
    {
        switch route {
        case .addGroupMembers:
            GroupMembersSelectionScreen(viewModel: groupCreationViewModel)
        case .setupGroupDetails:
            NewGroupSetupScreen(viewModel: groupCreationViewModel)
        }
    }
}


//MARK: ToolBar
extension GroupCreationScreen
{
    @ToolbarContentBuilder
    private func ToolbarTrailingItem() -> some ToolbarContent
    {
        ToolbarItem(placement: .topBarTrailing) {
            cancelButton()
        }
    }
    
    private func cancelButton() -> some View
    {
        Button {
            dismiss()
//            dismiss.callAsFunction()
        } label: {
            Image(systemName: "xmark")
                .font(.system(size: 10))
                .bold()
                .foregroundStyle(.gray)
                .padding(7)
                .background(Color(.systemGray5))
                .clipShape(.circle)
        }
    }
}

// MARK: Sections
extension GroupCreationScreen
{
    // MARK: - Header section
    private struct NewChatOptionHeaderView: View
    {
        let item: NewChatOption
        
        var body: some View {
            Button {
                
            } label: {
                setupButtonLabel()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .contentShape(Rectangle())
            }
        }
        
        private func setupButtonLabel() -> some View
        {
            HStack {
                Image(systemName: item.imageName)
                    .font(.system(size: 15))
                    .frame(width: 37, height: 37)
                    .background(Color(.systemGray6))
                    .clipShape(.circle)
                    .padding(.trailing, 10)
                
                Text(item.title)
                    .font(.system(size: 16))
            }
        }
    }
}

// MARK: Chat creation options
enum NewChatOption: String, CaseIterable, Identifiable
{
    case newGroup = "New Group"
    case newContact = "New Contact"
    case newCommunity = "New Community"
    
    var id: String {
        return rawValue
    }
    
    var title: String {
        return rawValue
    }
    
    var imageName: String {
        switch self {
        case .newGroup:
            return "person.2.fill"
        case .newContact:
            return "person.fill.badge.plus"
        case .newCommunity:
            return "person.3.fill"
        }
    }
}



struct UserItem: Identifiable
{
    static let placeholder: Self = UserItem(name: "Placeholder", bio: "just chilling out")
    
    static var placeholders: [UserItem] =
    {
        let bios = ["I am thankful for support", "Have a nice life", "Get things done", "Smile some", "Lucky we", "can do this", "I am happy"]
        let names = ["kevin", "Adam", "Lilly", "Derik", "Faitha", "gabriel", "Barbara"]
        
        let userItems = (1..<17).map { number in
            UserItem(name: names.randomElement()!, bio: bios.randomElement()!)
        }

        return userItems
    }()
    
    let id: String
    let name: String
    var bio: String?
    var image: Data?
    
    init(id: String = UUID().uuidString, name: String, bio: String? = nil, image: Data? = nil)
    {
        self.id = id
        self.name = name
        self.bio = bio
        self.image = image
    }

}

//struct ContentView_Previews: PreviewProvider {
//    static var previews: some View {
//        GroupCreationScreen()
//    }
//}

#Preview {
    GroupCreationScreen()
//    UserView()
}
