//
//  ConversationViewModel+Extensions.swift
//  ChatUpp
//
//  Created by Andrei Pripa on 1/16/25.
//

import Foundation

//MARK: - Model representing section of messages
extension ChatRoomViewModel: ChatRoomDataSourceProviding
{
    typealias MessageItem = MessageCellViewModel
    
    struct MessageCluster: Hashable
    {
        let id: UUID
        let date: Date
        var items: [MessageCellViewModel]
        
        init(id: UUID = UUID(), date: Date, items: [MessageItem]) {
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
}
