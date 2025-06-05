
//extension ReactionPanelView
//{
//    init(sourceMessage: Message)
//    {
//        self._viewModel = StateObject(wrappedValue: ReactionPanelViewModel(message: sourceMessage))
//    }
//}

import SwiftUI

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
                .fill(Color(#colorLiteral(red: 0.8017910123, green: 0.6400276423, blue: 0.8262925148, alpha: 1)).opacity(0.4))
                .frame(width: showReactionsBackground ? 312 : 0, height: 45)
                .animation(
                    .interpolatingSpring(stiffness: 170, damping: 14).delay(0.2),
                    value: showReactionsBackground
                )
            
            // Reaction Emojis
            HStack(spacing: 20)
            {
                ForEach(ReactionType.allCases) { reaction in
                    Text(verbatim: reaction.rawValue)
                        .scaleEffect(visibleReactions.contains(reaction) ? 1.5 : 0)
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



// MARK: - Models
enum ReactionType: String, CaseIterable, Identifiable
{
    case excited = "🤩"
    case celebrating = "🥳"
    case heart = "❤️"
    case laughing = "🤣"
    case peace = "✌️"
    case cool = "😎"
    case alien = "👽"
    
    var id: String { self.rawValue }
    
    var animationDelay: Double
    {
        switch self {
        case .excited, .celebrating: return 0.15
        case .heart: return 0.20
        case .laughing, .peace: return 0.27
        case .cool, .alien: return 0.35
        }
    }
    
    var animationDamping: Double
    {
        switch self {
        case .excited, .celebrating: return 25
        case .heart: return 20
        case .laughing, .peace: return 15
        case .cool, .alien: return 10
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


