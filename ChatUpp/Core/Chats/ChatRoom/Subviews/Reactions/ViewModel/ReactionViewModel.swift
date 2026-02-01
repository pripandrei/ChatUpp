//
//  ReactionViewModel.swift
//  ChatUpp
//
//  Created by Andrei Pripa on 9/17/25.
//

import SwiftUI
import Combine

class ReactionViewModel: SwiftUI.ObservableObject
{
//    private(set) var message: Message
//    @Published private(set) var _reactions: [Reaction]
    @Published private(set) var currentReactions: [Reaction] = []
    private var subscribers = Set<AnyCancellable>()
    
//    init(message: Message) {
    init(reactions: [Reaction]) {
//        self._reactions = reactions
        self.currentReactions = reactions.map { $0.freeze() }
//        self.message = message
//        self.addReactionObserver()
    }
    
    var reactions: [Reaction] {
        return Array(currentReactions.prefix(4))
    }
    
    var reactionsCount: Int {
        return currentReactions.reduce(0) { count, reaction in
//            if reaction.isInvalidated { return count }
            return count + reaction.userIDs.count
        }
    }

    func retreiveRealmUser(_ userID: String) -> User?
    {
        return RealmDatabase.shared.retrieveSingleObject(ofType: User.self, primaryKey: userID)
    }
    
    func updateMessage(_ reactions: [Reaction]) {

//        if _reactions.count < reactions.count {
//
//            guard let reaction = reactions.first(where: { newReaction in
//                !currentReactions.contains(where: { $0.emoji == newReaction.emoji })
//            }) else { return }
//
//            _reactions.append(reaction)
//
//        } else {
//
//            guard let removedIndex = currentReactions.firstIndex(where: { oldReaction in
//                !reactions.contains(where: { $0.emoji == oldReaction.emoji })
//            }) else { return }
//
//            _reactions.remove(at: removedIndex)
//        }

        syncReactions(original: &currentReactions, with: reactions)
        
//        let freezedReactions = reactions.map { $0.freeze() }
//        _reactions = reactions
//        currentReactions = freezedReactions
//        RealmDatabase.shared.refresh()
    }
    
    func syncReactions(
        original: inout [Reaction],
        with incoming: [Reaction]
    ) {
        // Snapshot emojis (value types = safe)
        let incomingEmojis = incoming.map(\.emoji)
        let incomingEmojiSet = Set(incomingEmojis)

        // Remove invalid / missing reactions
        original.removeAll { reaction in
            reaction.isInvalidated || !incomingEmojiSet.contains(reaction.emoji)
        }

        // Snapshot original emojis AFTER removal
        let originalEmojiSet = Set(original.map(\.emoji))

        // Append new reactions
        for reaction in incoming {
            if !originalEmojiSet.contains(reaction.emoji) {
                let freezedReaction = reaction.freeze()
                original.append(freezedReaction)
            }
        }
    }
    
//    private func addReactionObserver()
//    {
//        RealmDatabase.shared.observeChanges(for: message)
//            .receive(on: DispatchQueue.main)
//            .sink { [weak self] properyChange in
//                if properyChange.0.name == "reactions" {
//                    self?.objectWillChange.send()
//                }
//            }.store(in: &subscribers)
//    }
}

