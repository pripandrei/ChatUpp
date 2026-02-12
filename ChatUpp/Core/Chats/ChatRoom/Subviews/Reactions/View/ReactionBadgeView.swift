//
//  ReactionBadgeView.swift
//  ChatUpp
//
//  Created by Andrei Pripa on 4/19/25.
//

import SwiftUI
import Combine
import RealmSwift

//MARK: - reaction badge

struct ReactionBadgeView: View
{
    @ObservedObject var viewModel: ReactionViewModel
    @State private var showReactionPresentationSheet: Bool = false
    
    var body: some View
    {
        HStack(spacing: 3)
        {
            ForEach(viewModel.currentReactions, id: \.emoji) { reaction in
                Text("\(reaction.emoji)")
                    .font(.system(size: 15))
                    .transition(.scale)
            }
            
            Text(verbatim: "\(viewModel.reactionsCount)")
                .font(.system(size: 14))
        }
        .padding(.horizontal, 6)
        .padding(.vertical, 2)
        .animation(.spring(response: 0.4, dampingFraction: 0.4), value: viewModel.reactions)
        .background {
            RoundedRectangle(cornerRadius: 50)
//                .fill(Color(#colorLiteral(red: 0.6555908918, green: 0.5533221364, blue: 0.5700033307, alpha: 1)))
                .fill(Color(#colorLiteral(red: 0.6690413356, green: 0.4663018584, blue: 0.6267552376, alpha: 0.659084234)))
        }
//        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: viewModel.reactions)
        .overlay(content: {
            RoundedRectangle(cornerRadius: 50)
                .stroke(Color(#colorLiteral(red: 0.4449622631, green: 0.3755400777, blue: 0.3865504265, alpha: 1)), lineWidth: 0.5)
        })
//        .fixedSize()
        .onTapGesture {
            showReactionPresentationSheet = true
        }
        .sheet(isPresented: $showReactionPresentationSheet,
               content: {
            ReactionPresentationSheetView(viewModel: viewModel)
                .presentationDetents([.medium])
                .presentationDragIndicator(.visible)
        })
//        .drawingGroup()
    }
}

//#Preview {
//    let message = Message(id: "tester", messageBody: "hello test message", senderId: "asdasd", timestamp: Date(), messageSeen: nil, isEdited: false, imagePath: nil, imageSize: nil, repliedTo: nil)
////    ReactionBadgeView(sourceMessage: message)
//    let vm = ReactionViewModel(message: message)
//    ReactionBadgeView(viewModel: vm, message: message)
//}
