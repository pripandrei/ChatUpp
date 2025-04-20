////
////  ReactionView.swift
////  ChatUpp
////
////  Created by Andrei Pripa on 4/15/25.
////
//
//import UIKit
//
//enum ReactionType {
//    case like
//    case love
//    case angry
//    case sad
//}
//
//class ReactionView: UIView
//{
//    private let stackView = UIStackView()
//    var onReaction: ((ReactionType) -> Void)?
//
//    private let reactions: [(title: String, type: ReactionType)] = [
//        ("👍", .like),
//        ("❤️", .love),
//        ("😡", .angry),
//        ("😢", .sad)
//    ]
//
//    // MARK: - Init
//
//    override init(frame: CGRect) {
//        super.init(frame: frame)
//        setupView()
//        setupReactions()
//        doAnimation()
//    }
//
//    required init?(coder: NSCoder) {
//        super.init(coder: coder)
//        setupView()
//        setupReactions()
//        doAnimation()
//    }
//
//    // MARK: - Setup
//
//    private func setupView() {
//        backgroundColor = UIColor.systemGray6
//        layer.cornerRadius = 10
//        clipsToBounds = true
//
//        stackView.axis = .horizontal
//        stackView.alignment = .center
//        stackView.distribution = .fillEqually
//        stackView.spacing = 12
//        stackView.translatesAutoresizingMaskIntoConstraints = false
//
//        addSubview(stackView)
//
//        NSLayoutConstraint.activate([
//            stackView.topAnchor.constraint(equalTo: topAnchor, constant: 8),
//            stackView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -8),
//            stackView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 12),
//            stackView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -12)
//        ])
//    }
//
//    private func setupReactions()
//    {
//        for (emoji, type) in reactions
//        {
//            let button = UIButton(type: .system)
//            button.setTitle(emoji, for: .normal)
//            button.titleLabel?.font = UIFont.systemFont(ofSize: 28)
//            button.addTarget(self, action: #selector(reactionTapped(_:)), for: .touchUpInside)
//            button.tag = reactions.firstIndex(where: { $0.type == type }) ?? 0
//            stackView.addArrangedSubview(button)
//        }
//    }
//
//    // MARK: - Animation
//
//    func doAnimation() {
//        let offset = CGPoint(x: UIScreen.main.bounds.width, y: 0)
//        transform = CGAffineTransform(translationX: offset.x, y: offset.y)
//        alpha = 0
//        UIView.animate(withDuration: 0.6,
//                       delay: 0,
//                       usingSpringWithDamping: 0.7,
//                       initialSpringVelocity: 0.8,
//                       options: .curveEaseOut,
//                       animations: {
//            self.transform = .identity
//            self.alpha = 1
//        }, completion: { [weak self] _ in
//            self?.stackView.arrangedSubviews.forEach { view in
//                UIView.animate(withDuration: 0.5,
//                               delay: 0,
//                               options: .curveEaseIn,
//                               animations: {
//                    view.transform = CGAffineTransform.identity.scaledBy(x: 1.5, y: 1.5)
//                }, completion: { _ in
//                    UIView.animate(withDuration: 0.5) {
//                        view.transform = .identity
//                    }
//                })
//            }
//        })
//    }
//
//    // MARK: - Actions
//
//    @objc private func reactionTapped(_ sender: UIButton) {
//        let type = reactions[sender.tag].type
//        onReaction?(type)
//    }
//}
//
//
////
////  MessageListView.swift
////  AnimatedMessageReactions
////
////  Created by Stefan Blos on 14.12.21.
////
//
//import SwiftUI
//
//struct ReactionViewSwiftUI: View {
//
//    private var reactionColor = #colorLiteral(red: 0.8342090249, green: 0.3331268132, blue: 0.5160290003, alpha: 1)
//
//    @State private var showReactionsBackground = false
//
//    @State private var showLike = false
//    @State private var showThumbsUp = false
//    @State private var thumbsUpRotation: Double = -45 // 🤔
//    @State private var showThumbsDown = false
//    @State private var thumbsDownRotation: Double = -45 // 🤔
//    @State private var showLol = false
//    @State private var showWutReaction = false
//
//    var isThumbsUpRotated: Bool {
//        thumbsUpRotation == -45
//    }
//
//    var isThumbsDownRotated: Bool {
//        thumbsDownRotation == -45
//    }
//
//    var body: some View
//    {
//        ZStack(alignment: .leading)
//        {
//            HStack {
//                RoundedRectangle(cornerRadius: 28)
//                    .fill(Color(#colorLiteral(red: 0.8017910123, green: 0.6400276423, blue: 0.8262925148, alpha: 1)).opacity(0.4))
//                    .clipped()
//                    .frame(width: showReactionsBackground ? 312 : 0, height: 45)
//                //                        .scaleEffect(showReactionsBackground ? 1 : 0,
//                //                                     anchor: .leading)
//                    .animation(
//                        .interpolatingSpring(stiffness: 170, damping: showLike ? 30 : 14).delay(0.2),
//                        value: showReactionsBackground
//                    )
//            }
//            //                .frame(maxWidth: .infinity, alignment: .leading)
//
//            HStack(spacing: 20)
//            {
//
//                ForEach(ReactionEmoji.allCases) { reaction in
//                    Text(verbatim: reaction.emoji)
//                        .scaleEffect(showThumbsUp ? 1.5 : 0)
//                }
//
//                //                    Text(verbatim: "🤩")
//                //                        .scaleEffect(showThumbsUp ? 1.5 : 0)
//                //
//                //                    Text(verbatim: "🥳")
//                //                        .scaleEffect(showThumbsUp ? 1.5 : 0)
//                //
//                //                    Text(verbatim: "❤️")
//                //                        .scaleEffect(showThumbsDown ? 1.5 : 0)
//                //
//                //                    Text(verbatim: "🤣")
//                //                        .scaleEffect(showLol ? 1.5 : 0)
//                //
//                //                    Text(verbatim: "✌️")
//                //                        .scaleEffect(showLol ? 1.5 : 0)
//                //
//                //                    Text(verbatim: "😎")
//                //                        .scaleEffect(showWutReaction ? 1.5 : 0)
//                //
//                //                    Text(verbatim: "👽")
//                //                        .scaleEffect(showWutReaction ? 1.5 : 0)
//
//                //                    Text(verbatim: "🤣 😉🤭😇😎👽✌️🤣🤩😌❤️👍🤣🥳")
//            }
//            .padding(.leading)
//        }
//        //            .padding()
//        .onAppear {
//            Task {
//                try? await Task.sleep(for: .seconds(0.33))
//                activateReactionView()
//            }
//        }
//    }
//}
//
//extension ReactionViewSwiftUI
//{
//    private func activateReactionView()
//    {
//        showReactionsBackground.toggle()
//
//        withAnimation(.interpolatingSpring(stiffness: 170, damping: showLike ? 30 : 15).delay(0.1)) {
//            showLike.toggle()
//        }
//
//        withAnimation(.interpolatingSpring(stiffness: 170, damping: showLike ? 25 : 15).delay(0.15)) {
//            showThumbsUp.toggle()
//            thumbsUpRotation = isThumbsUpRotated ? 0 : -45
//        }
//
//        withAnimation(.interpolatingSpring(stiffness: 170, damping: showLike ? 20 : 15).delay(0.20)) {
//            showThumbsDown.toggle()
//            thumbsDownRotation = isThumbsDownRotated ? 0 : -45
//        }
//
//        withAnimation(.interpolatingSpring(stiffness: 170, damping: showLike ? 15 : 15).delay(0.27)) {
//            showLol.toggle()
//        }
//
//        withAnimation(.interpolatingSpring(stiffness: 170, damping: showLike ? 10 : 79).delay(0.35)) {
//            showWutReaction.toggle()
//        }
//    }
//}

//enum ReactionEmoji: String, CaseIterable, Identifiable
//{
//    case starryEyes
//    case partyFace
//    case heart
//    case laughingFace
//    case peaceHand
//    case faceWithSunglasses
//    case alien
//
//    var id: String {
//        return rawValue
//    }
//
//    var emoji: String
//    {
//        switch self {
//        case .starryEyes: return "🤩"
//        case .partyFace: return "🥳"
//        case .heart: return "❤️"
//        case .laughingFace: return "🤣"
//        case .peaceHand: return "✌️"
//        case .faceWithSunglasses: return "😎"
//        case .alien: return "👽"
//        }
//    }
//}































import SwiftUI

struct ReactionPanelView: View
{
    @State private var showReactionsBackground = false
    @State private var visibleReactions: Set<ReactionType> = []
    
    var dismissParentVC: ((Bool) -> Void)?
    
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
                        dismissParentVC?(true)
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

//// MARK: - Helper Views
//struct ReactionEmoji: View {
//    let emoji: String
//    let isVisible: Bool
//
//    var body: some View {
//        Text(verbatim: emoji)
//            .scaleEffect(isVisible ? 1.5 : 0)
//    }
//}


struct MessageListView_Previews: PreviewProvider {
    static var previews: some View {
        ReactionPanelView()
    }
}
