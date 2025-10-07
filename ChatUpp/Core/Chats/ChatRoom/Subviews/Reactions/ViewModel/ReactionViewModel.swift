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
                if properyChange.0.name == "reactions" {
                    self?.objectWillChange.send()
                }
            }.store(in: &subscribers)
    }
}

