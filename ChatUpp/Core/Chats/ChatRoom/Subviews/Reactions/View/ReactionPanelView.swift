
import SwiftUI

extension ReactionPanelView { static let panelHeight: CGFloat = 50 }

struct ReactionPanelView: View
{
    @State private var showReactionsBackground = false
    @State private var visibleReactions: Set<ReactionType> = []
    
    @State private var reactionsAreLoaded: Bool = false

    var onReactionSelection: ((String) -> Void)?
    
    var body: some View
    {
        ZStack(alignment: .leading)
        {
            RoundedRectangle(cornerRadius: 28)
                .fill(Color(#colorLiteral(red: 0.2106938958, green: 0.1273534, blue: 0.2237152457, alpha: 0.7475769501)))
                .overlay(content: {
                    RoundedRectangle(cornerRadius: 28)
//                    Rectangle()
                        .strokeBorder(Color(#colorLiteral(red: 0.3875865638, green: 0.2960451245, blue: 0.3973323107, alpha: 1)), lineWidth: 1)
                })
                .frame(width: showReactionsBackground ? 312 : 0, height: Self.panelHeight)
                .animation(
                    .interpolatingSpring(stiffness: 170, damping: 14).delay(0.2),
                    value: showReactionsBackground
                )
            
            // Reaction Emojis
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 20)
                {
                    ForEach(ReactionType.allCases) { reaction in
                        Text(verbatim: reaction.rawValue)
//                            .font(.system(size: 17)) // Add explicit font size
                            .scaleEffect(visibleReactions.contains(reaction) ? 1.6 : 0)
                            .onTapGesture
                        {
                            print(reaction.rawValue)
                            onReactionSelection?(reaction.rawValue)
                        }
                    }
                }
                .padding(.leading)
                .padding(.vertical, 18) // Add vertical padding
            }
            
//            .background(.blue)
            .frame(width: 312, height: Self.panelHeight, alignment: .center)
            .clipShape(RoundedRectangle(cornerRadius: 28))
        }
        .onAppear {
            Task {
                try? await Task.sleep(for: .seconds(0.33))
                activateReactionView()
                guard !reactionsAreLoaded else {return}
                reactionsAreLoaded = true
                addRestOfEmojis()
            }
        }
    }
    
    private func activateReactionView()
    {
        showReactionsBackground.toggle()
        
        for reaction in ReactionType.allCases.prefix(7)
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
    
    private func addRestOfEmojis()
    {
        for reaction in ReactionType.allCases.suffix(from: 7)
        {
            if visibleReactions.contains(reaction) {
                visibleReactions.remove(reaction)
            } else {
                visibleReactions.insert(reaction)
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


