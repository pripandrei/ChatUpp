//
//  Reaction.swift
//  ChatUpp
//
//  Created by Andrei Pripa on 6/5/25.
//
import SwiftUI

//MARK: - presentation sheet
struct ReactionPresentationSheetView: View
{
    @ObservedObject var viewModel: ReactionViewModel
    
    var body: some View
    {
        List
        {
            ForEach(viewModel.message.reactions, id: \.emoji) { reaction in
                userReactionView(reaction)
            }
            .listRowBackground(Color(ColorScheme.appBackgroundColor))
        }
        .listStyle(.plain)
        .padding(.top, 30)
        .background(Color(ColorScheme.appBackgroundColor))
    }
}

extension ReactionPresentationSheetView
{
    @ViewBuilder
    private func userReactionView(_ reaction: Reaction) -> some View
    {
        ForEach(reaction.userIDs, id: \.self) { userID in
            if let user = viewModel.retreiveRealmUser(userID) {
                UserView(userItem: user) {
                    Spacer()
                    Text(verbatim: reaction.emoji)
                        .font(.system(size: 24))
                }
            }
        }
    }
}


#Preview {
    let message = Message(id: "tester", messageBody: "hello test message", senderId: "asdasd", timestamp: Date(), messageSeen: nil, isEdited: false, imagePath: nil, imageSize: nil, repliedTo: nil)
//    ReactionBadgeView(sourceMessage: message)
    let vm = ReactionViewModel(message: message)
    ReactionPresentationSheetView(viewModel: vm)
}
