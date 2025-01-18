//
//  ConversationViewModel+Extensions.swift
//  ChatUpp
//
//  Created by Andrei Pripa on 1/16/25.
//

import Foundation

//MARK: - Model representing section of messages
extension ChatRoomViewModel
{
    typealias MessageItem = ConversationCellViewModel
    
    struct MessageCluster
    {
        let date: Date
        var items: [MessageItem]
    }
}
