//
//  AddGroupMembersScreen.swift
//  ChatUpp
//
//  Created by Andrei Pripa on 12/29/24.
//

import SwiftUI

struct AddGroupMembersScreen: View
{
    @State var searchText: String = ""
    
    var body: some View
    {
            List {
                Text("Test one two three")
            }
            .padding(.top, 1)
            .background(Color(#colorLiteral(red: 0.949019134, green: 0.9490200877, blue: 0.9705253243, alpha: 1)))
            .searchable(text: $searchText, prompt: "Search users")
    }
}

#Preview {
    NavigationStack{
        AddGroupMembersScreen()
    }
}
