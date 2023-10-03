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
    let lastMessage: String?
    
//    let messages: [Message]?
    
    enum CodingKeys: String, CodingKey {
        case id = "id"
        case members = "members"
        case lastMessage = "last_message"
        case messages = "message"
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try container.decode(String.self, forKey: .id)
        self.members = try container.decode([String].self, forKey: .members)
        self.lastMessage = try container.decodeIfPresent(String.self, forKey: .lastMessage)
//        self.messages = try container.decodeIfPresent([Message].self, forKey: .messages)
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(self.id, forKey: .id)
        try container.encode(self.members, forKey: .members)
        try container.encodeIfPresent(self.lastMessage, forKey: .lastMessage)
//        try container.encodeIfPresent(self.messages, forKey: .messages)
    }
    
    init(id: String,
         members: [String],
         lastMessage: String?
//         messages: [Message]?
    )
    {
        self.id = id
        self.members = members
        self.lastMessage = lastMessage
//        self.messages = messages
    }
}
