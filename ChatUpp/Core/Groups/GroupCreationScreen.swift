//
//  GroupCreationScreen.swift
//  ChatUpp
//
//  Created by Andrei Pripa on 12/24/24.
//

import SwiftUI


class UserSettings: SwiftUI.ObservableObject {
    @Published var username: String = "Guest"
}


struct GroupCreationScreen: View
{
    @State private var searchText = ""
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            List {
                ForEach(NewChatOption.allCases) { item in
                    NewChatOptionHeaderView(item: item)
                }
                
                Section {
                    let dommyData = UserItem(name: "Avior Makory", bio: "hello there world")
                    ForEach(0..<15) { _ in
                        UserView(userItem: dommyData)
                    }
                } header: {
                    Text("Users")
//                        .textCase(nil)
                        .font(.subheadline)
                        .bold()
                }
            }
            .navigationTitle("New group")
            .navigationBarTitleDisplayMode(.inline)
            .searchable(text: $searchText, prompt: "search for name")
            .toolbar {
                ToolbarTrailingItem()
            }
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
                .font(.footnote)
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
            }
        }
        
        private func setupButtonLabel() -> some View
        {
            HStack {
                Image(systemName: item.imageName)
                    .font(.footnote)
                    .frame(width: 40, height: 40)
                    .background(Color(.systemGray6))
                    .clipShape(.circle)
                    .padding(.trailing, 10)
                
                Text(item.title)
            }
            
        }
    }
    
    // MARK: - Users section
    private struct UserView: View
    {
        let userItem: UserItem
        
        var body: some View {
            HStack {
                Circle()
                    .frame(width: 40, height: 40)
                    .padding(.trailing, 10)
                
                VStack(alignment: .leading) {
                    Text(userItem.name)
                        .bold()
                        .foregroundStyle(.primary)
                    
                    Text(userItem.bio ?? "No bio")
                        .font(.caption)
                        .foregroundStyle(.gray)
                }
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
 


struct UserItem
{
    let id: String = UUID().uuidString
    let name: String
    var bio: String?
    var image: Data?

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
