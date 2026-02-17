//
//  MessageCluster.swift
//  ChatUpp
//
//  Created by Andrei Pripa on 2/16/26.
//

import Foundation

typealias MessageItem = MessageCellViewModel

struct MessageCluster: Hashable
{
    let id: UUID
    let date: Date
    var items: [MessageCellViewModel]
    
    init(id: UUID = UUID(), date: Date, items: [MessageItem])
    {
        self.id = id
        self.date = date
        self.items = items
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    static func ==(lhs: MessageCluster, rhs: MessageCluster) -> Bool
    {
        lhs.id == rhs.id
    }
}

