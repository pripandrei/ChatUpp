
//extension ReactionPanelView
//{
//    init(sourceMessage: Message)
//    {
//        self._viewModel = StateObject(wrappedValue: ReactionPanelViewModel(message: sourceMessage))
//    }
//}

import SwiftUI

extension ReactionPanelView
{
    static let panelHeight: CGFloat = 50
}

//    .fill(Color(#colorLiteral(red: 0.2010305226, green: 0.09223289043, blue: 0.181774646, alpha: 0.6007254464)))
//    .overlay(content: {
//        RoundedRectangle(cornerRadius: 28)
//            .strokeBorder(Color(#colorLiteral(red: 0.3310527205, green: 0.2525947094, blue: 0.3390152454, alpha: 1)), lineWidth: 1)
//    })



struct ReactionPanelView: View
{
    @State private var showReactionsBackground = false
    @State private var visibleReactions: Set<ReactionType> = []

    var onReactionSelection: ((String) -> Void)?
    
    var body: some View
    {
        ZStack(alignment: .leading)
        {
            RoundedRectangle(cornerRadius: 28)
            //                .fill(Color(#colorLiteral(red: 0.8017910123, green: 0.6400276423, blue: 0.8262925148, alpha: 1)).opacity(0.4))
            //                .fill(Color(#colorLiteral(red: 0.3961045444, green: 0.2342843115, blue: 0.3487926126, alpha: 0.8558652491)).opacity(0.7))
            //                .fill(Color(#colorLiteral(red: 0.2725867629, green: 0.1601939797, blue: 0.2390740812, alpha: 0.6963257754)).opacity(0.7))
//                .fill(Color(#colorLiteral(red: 0.2262225449, green: 0.132930398, blue: 0.1983323693, alpha: 0.7214373825)))
            
            
//                .fill(Color(#colorLiteral(red: 0.2010305226, green: 0.09223289043, blue: 0.181774646, alpha: 0.6007254464)))
//                .overlay(content: {
//                    RoundedRectangle(cornerRadius: 28)
//                        .strokeBorder(Color(#colorLiteral(red: 0.3310527205, green: 0.2525947094, blue: 0.3390152454, alpha: 1)), lineWidth: 1)
//                })
                .fill(Color(#colorLiteral(red: 0.2106938958, green: 0.1273534, blue: 0.2237152457, alpha: 0.7475769501)))
                .overlay(content: {
                    RoundedRectangle(cornerRadius: 28)
                        .strokeBorder(Color(#colorLiteral(red: 0.3875865638, green: 0.2960451245, blue: 0.3973323107, alpha: 1)), lineWidth: 1)
                })
                .frame(width: showReactionsBackground ? 312 : 0, height: Self.panelHeight)
                .animation(
                    .interpolatingSpring(stiffness: 170, damping: 14).delay(0.2),
                    value: showReactionsBackground
                )
            
            // Reaction Emojis
            HStack(spacing: 20)
            {
                ForEach(ReactionType.allCases) { reaction in
                    Text(verbatim: reaction.rawValue)
                        .scaleEffect(visibleReactions.contains(reaction) ? 1.6 : 0)
                        .onTapGesture
                    {
                        print(reaction.rawValue)
                        onReactionSelection?(reaction.rawValue)
                    }
                }
            }
            .padding(.leading)
        }
        .onAppear {
            Task {
                try? await Task.sleep(for: .seconds(0.33))
                activateReactionView()
            }
        }
    }
    
    private func activateReactionView()
    {
        showReactionsBackground.toggle()
        
        for reaction in ReactionType.allCases
        {
            withAnimation(.interpolatingSpring(
                stiffness: 170,
                damping: reaction.animationDamping
            ).delay(reaction.animationDelay))
            {
                if visibleReactions.contains(reaction) {
                    visibleReactions.remove(reaction)
                } else {
                    visibleReactions.insert(reaction)
                }
            }
        }
    }
}

struct MessageListView_Previews: PreviewProvider
{
    static var previews: some View
    {
        let message = Message(id: "tester", messageBody: "hello test message", senderId: "asdasd", timestamp: Date(), messageSeen: nil, isEdited: false, imagePath: nil, imageSize: nil, repliedTo: nil)
//        let vm = ReactionPanelViewModel(message: message)
//        ReactionPanelView(viewModel: vm)
        ReactionPanelView()
    }
}


