//
//  ReactionBadgeView.swift
//  ChatUpp
//
//  Created by Andrei Pripa on 4/19/25.
//

import SwiftUI

//extension ReactionBadgeView
//{
//    init(sourceMessage: Message)
//    {
//        self._viewModel = StateObject(wrappedValue:  ReactionViewModel(message: sourceMessage))
//    }
//}

struct ReactionBadgeView: View
{
    @StateObject var viewModel: ReactionViewModel
    @State private var showReactionPresentationSheet: Bool = false
    
    var body: some View
    {
        HStack(spacing: 3)
        {
            ForEach(viewModel.reactions.sorted(by: { $0.value.count > $1.value.count }).prefix(4), id: \.key) { emoji, _ in
                Text("\(emoji)")
                    .font(.system(size: 15))
            }
            
            Text(verbatim: "\(viewModel.reactions.values.reduce(0) { $0 + $1.count})")
                .font(.system(size: 14))
        }
        .padding(.horizontal, 6)
        .padding(.vertical, 2)
        .background {
            RoundedRectangle(cornerRadius: 50)
                .fill(Color(#colorLiteral(red: 0.6555908918, green: 0.5533221364, blue: 0.5700033307, alpha: 1)))
        }
        .onTapGesture {
            showReactionPresentationSheet = true
        }
        .sheet(isPresented: $showReactionPresentationSheet, content: {
            ReactionPresentationSheetView(viewModel: viewModel)
                .presentationDetents([.medium])
                .presentationDragIndicator(.visible)
        })
    }
}

#Preview {
    let message = Message(id: "sdsadasasdsad", messageBody: "hello test message", senderId: "asdasd", timestamp: Date(), messageSeen: nil, isEdited: false, imagePath: nil, imageSize: nil, repliedTo: nil)
//    ReactionBadgeView(sourceMessage: message)
    let vm = ReactionViewModel(message: message)
    ReactionBadgeView(viewModel: vm)
}


struct ReactionPresentationSheetView: View
{
    @ObservedObject var viewModel: ReactionViewModel
    
    var body: some View
    {
        List
        {
            ForEach(viewModel.reactions.sorted(by: { $0.value.count > $1.value.count }), id: \.key) { emoji, memberIDs in
                userReactionView(memberIDs, reaction: emoji)
                //            ForEach(viewModel.flattenedReactions, id: \.user.id) { item in
                
                //                for memberID in memberIDs {
                //                    guard let user = viewModel.retreiveRealmUser(memberID) else {continue}
                //                    UserView(userItem: user)
                //                }
                ////                return EmptyView()
                ////                UserView(userItem: viewModel.retreiveRealmUser(memberIDs.first!)!)
                //            }
            }
            //        .listStyle(.plain)
        }
    }
}

extension ReactionPresentationSheetView
{
    @ViewBuilder
    private func userReactionView(_ userIDs: Set<String>,
                                  reaction: String) -> some View
    {
        ForEach(Array(userIDs), id: \.self) { userID in
            if let user = viewModel.retreiveRealmUser(userID) {
                UserView(userItem: user) {
                    Spacer()
                    Text(verbatim: reaction)
                        .font(.system(size: 17))
                }
            }
        }
    }
}



class ReactionViewModel: SwiftUI.ObservableObject
{
    private(set) var message: Message
    
//    private(set) var reactions2: [String: Set<String>] = [:]
    
    init(message: Message) {
        self.message = message
    }
    
    @Published private(set) var reactions: [String: Set<String>] =
    [
        "🧐": ["jpBpnYPVxKgyBwYrRAuhNLknO2w2","GRPSZIyNqrhRqMSV6AHb1KOiUOr1"],
        "☺️": ["LRDSeeVBZJRNrlMpvfgYLCtjlrg1","qH9NmwwOu9MRQLceoYiP96IYAFG2","kRs3yeQ3a2YQdxKFOXP9UdsKbWS2"],
        "🙃": ["Nvb0A7VblEOeZAyXlSvZGcG6m6o1","f0aNVBFrYlTVWxnjDNhwEGjd4xq1", "tZ1v5qRsLSNL7w3Myd4jlsyeYUl2", "ozg8xmCD6lMMZ3Wp3NCtcXaKrqi1"],
        "😎": ["Gjs2WNj8d6WLwZ5bKaXgsWoRlk72",],
        "🥳": ["o4z5W31LsmYfIROV2vGzin7fy4I3"]
    ]
    
//    var flattenedReactions: [(emoji: String, user: User)]
//    {
//        reactions.flatMap { emoji, userIDs in
//            userIDs.compactMap { userID in
//                guard let user = retreiveRealmUser(userID) else { return nil }
//                return (emoji, user)
//            }
//        }
//    }
    
    func retreiveRealmUser(_ userID: String) -> User?
    {
        return RealmDataBase.shared.retrieveSingleObject(ofType: User.self, primaryKey: userID)
    }
}

struct ReactionItem {
    var emoji: String
    var userID: String
}
