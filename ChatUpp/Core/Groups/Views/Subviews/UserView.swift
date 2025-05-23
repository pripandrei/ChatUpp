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
    private let userItem: User
    private let trailingItems: Content
    
    init(userItem: User,
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
                .foregroundStyle(Color(ColorManager.actionButtonsTintColor))
            
            VStack(alignment: .leading) {
                Text(userItem.name ?? "")
                    .bold()
                    .foregroundStyle(.white)
                
                Text(userItem.lastSeen?.formatToYearMonthDayCustomString() ?? "Last seen recently")
                    .font(.caption)
                    .foregroundStyle(Color(ColorManager.textFieldPlaceholderColor))
            }
            trailingItems
        }
    }
}
