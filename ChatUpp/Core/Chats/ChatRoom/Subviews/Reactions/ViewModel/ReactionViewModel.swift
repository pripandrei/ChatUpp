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
    @Published private(set) var currentReactions: [Reaction] = []
    @Published private(set) var reactionsCount: Int = 0
    private var subscribers = Set<AnyCancellable>()
    
    init(reactions: [Reaction])
    {
        self.currentReactions = reactions.map { $0.freeze() }
        self.reactionsCount = countReactions(reactions)
    }
    
    var reactions: [Reaction] {
        return Array(currentReactions.prefix(4))
    }
    
    func retreiveRealmUser(_ userID: String) -> User?
    {
        return RealmDatabase.shared.retrieveSingleObject(ofType: User.self, primaryKey: userID)
    }
    
    func countReactions(_ reactions: [Reaction]) -> Int
    {
        return reactions.reduce(0) { count, reaction in
            //            if reaction.isInvalidated { return count }
            return count + reaction.userIDs.count
        }
    }
    
    func updateMessage(_ reactions: [Reaction])
    {
        self.reactionsCount = countReactions(reactions)
        
        syncReactions(original: &currentReactions,
                      with: Array(reactions.prefix(4)))
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
}

