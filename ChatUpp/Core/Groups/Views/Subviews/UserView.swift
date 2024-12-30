//
//  SwiftUIView.swift
//  ChatUpp
//
//  Created by Andrei Pripa on 12/29/24.
//

import SwiftUI

// MARK: - Users section
struct UserView<Content: View>: View
{
    private let userItem: UserItem
    private let trailingItems: Content
    
    init(userItem: UserItem,
         @ViewBuilder trailingItems: () -> Content = { EmptyView() })
    {
        self.userItem = userItem
        self.trailingItems = trailingItems()
    }
    
    var body: some View {
        HStack {
            Circle()
                .frame(width: 37, height: 37)
                .padding(.trailing, 10)
            
            VStack(alignment: .leading) {
                Text(userItem.name)
                    .bold()
                    .foregroundStyle(.primary)
                
                Text(userItem.bio ?? "No bio")
                    .font(.caption)
                    .foregroundStyle(.gray)
            }
            trailingItems
        }
    }
}
