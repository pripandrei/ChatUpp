//
//  ReactionBadgeView.swift
//  ChatUpp
//
//  Created by Andrei Pripa on 4/19/25.
//

import SwiftUI

struct ReactionBadgeView: View
{
    @State var reactions: [String: Int] =
    [
        "🧐": 1,
        "☺️": 6,
        "🙃": 1,
        "😎": 6,
        "🥳": 12
    ]
    
    var body: some View
    {
        HStack
        {
            ForEach(reactions.sorted(by: { $0.value > $1.value }).prefix(3), id: \.key) { emoji, count in
                Text("\(emoji)")
            }
            
            Text(verbatim: "\(reactions.values.reduce(0, +))")
                .padding(.leading, -2)
                .font(.system(size: 14))
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 4)
        .background {
            RoundedRectangle(cornerRadius: 50)
                .fill(Color(#colorLiteral(red: 0.6555908918, green: 0.5533221364, blue: 0.5700033307, alpha: 1).withAlphaComponent(0.5)))
        }
        .onTapGesture {
            
        }
    }
}

#Preview {
    ReactionBadgeView()
}
