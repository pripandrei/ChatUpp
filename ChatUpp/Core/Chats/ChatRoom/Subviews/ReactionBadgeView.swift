//
//  ReactionBadgeView.swift
//  ChatUpp
//
//  Created by Andrei Pripa on 4/19/25.
//

import SwiftUI
import Combine

//extension ReactionBadgeView
//{
//    init(sourceMessage: Message)
//    {
//        self._viewModel = StateObject(wrappedValue: ReactionViewModel(message: sourceMessage))
//    }
//}

//MARK: - reaction badge

struct ReactionBadgeView: View
{
    @ObservedObject var viewModel: ReactionViewModel
    @State private var showReactionPresentationSheet: Bool = false
    
    var body: some View
    {
        HStack(spacing: 3)
        {
            ForEach(viewModel.reactions, id: \.emoji) { reaction in
                Text("\(reaction.emoji)")
                    .font(.system(size: 15))
            }
            
            Text(verbatim: "\(viewModel.reactionsCount)")
                .font(.system(size: 14))
        }
        .padding(.horizontal, 6)
        .padding(.vertical, 2)
        .background {
            RoundedRectangle(cornerRadius: 50)
                .fill(Color(#colorLiteral(red: 0.6555908918, green: 0.5533221364, blue: 0.5700033307, alpha: 1)))
        }
        .overlay(content: {
            RoundedRectangle(cornerRadius: 50)
                .stroke(Color(#colorLiteral(red: 0.4449622631, green: 0.3755400777, blue: 0.3865504265, alpha: 1)), lineWidth: 0.5)
        })
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

class ReactionViewModel: SwiftUI.ObservableObject
{
    private(set) var message: Message
    private var subscribers = Set<AnyCancellable>()
    
    init(message: Message) {
        self.message = message
//        self.addReactionObserver()
    }
    
    var reactions: [Reaction] {
        return Array(message.reactions.prefix(4))
    }
    
    var reactionsCount: Int {
        return message.reactions.reduce(0) { $0 + $1.userIDs.count}
    }

    func retreiveRealmUser(_ userID: String) -> User?
    {
        return RealmDataBase.shared.retrieveSingleObject(ofType: User.self, primaryKey: userID)
    }
    
    private func addReactionObserver()
    {
        RealmDataBase.shared.observeChanges(for: message)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] properyChange in
                if properyChange.name == "reactions" {
                    self?.objectWillChange.send()
                }
            }.store(in: &subscribers)
    }
}


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
        }
        .listStyle(.plain)
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
    ReactionBadgeView(viewModel: vm)
}
