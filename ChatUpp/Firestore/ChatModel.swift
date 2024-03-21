//
//  ChatModel.swift
//  ChatUpp
//
//  Created by Andrei Pripa on 10/3/23.
//

import Foundation

struct Chat: Codable {
    let id: String
    let members: [String]
    let recentMessageID: String?
    let unreadMessages: Int
    
    enum CodingKeys: String, CodingKey {
        case id = "id"
        case members = "members"
        case recentMessage = "recent_message"
        case unreadMessages = "unread_messages"
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try container.decode(String.self, forKey: .id)
        self.members = try container.decode([String].self, forKey: .members)
        self.recentMessageID = try container.decodeIfPresent(String.self, forKey: .recentMessage)
        self.unreadMessages = try container.decode(Int.self, forKey: .unreadMessages)
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(self.id, forKey: .id)
        try container.encode(self.members, forKey: .members)
        try container.encode(self.recentMessageID, forKey: .recentMessage)
    }
    
    init(id: String,
         members: [String],
         lastMessage: String?,
         unreadMessages: Int
    )
    {
        self.id = id
        self.members = members
        self.recentMessageID = lastMessage
        self.unreadMessages = unreadMessages
    }
    
   
}
