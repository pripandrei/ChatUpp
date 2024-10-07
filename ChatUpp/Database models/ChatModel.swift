//
//  ChatModel.swift
//  ChatUpp
//
//  Created by Andrei Pripa on 10/3/23.
//

import Foundation
import RealmSwift

class Chat: Object, Codable {
    @Persisted(primaryKey: true) var id: String
    @Persisted var members: List<String>
    @Persisted var recentMessageID: String?
    @Persisted var messagesCount: Int?
    
    @Persisted var conversationMessages: List<Message>
    
    enum CodingKeys: String, CodingKey {
        case id = "id"
        case members = "members"
        case recentMessageID = "recent_message"
        case messagesCount = "messages_count"
    }
    
    required convenience init(from decoder: Decoder) throws {
        self.init()
        
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try container.decode(String.self, forKey: .id)
        self.recentMessageID = try container.decodeIfPresent(String.self, forKey: .recentMessageID)
        self.messagesCount = try container.decodeIfPresent(Int.self, forKey: .messagesCount)
        let members = try container.decode([String].self, forKey: .members)
        self.members.append(objectsIn: members)
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(self.id, forKey: .id)
        try container.encode(self.members, forKey: .members)
        try container.encodeIfPresent(self.recentMessageID, forKey: .recentMessageID)
        try container.encodeIfPresent(self.messagesCount, forKey: .messagesCount)
    }
    
    convenience init(id: String, members: [String], recentMessageID: String?, messagesCount: Int?) {
        self.init()
        
        self.id = id
        self.members.append(objectsIn: members)
        self.recentMessageID = recentMessageID
        self.messagesCount = messagesCount
    }
    
    func appendConversationMessage(_ message: Message) {
        conversationMessages.append(message)
    }
    
    func getMessages() -> [Message] {
        return Array(conversationMessages.sorted(byKeyPath: Message.CodingKeys.timestamp.rawValue, ascending: true))
    }

    func getLastMessage() -> Message? {
        return conversationMessages.sorted(byKeyPath: Message.CodingKeys.timestamp.rawValue, ascending: false).first
    }
    
}


extension Chat {
    static func == (lhs: Chat, rhs: Chat) -> Bool {
        lhs.id == rhs.id &&
        lhs.members == rhs.members &&
        lhs.recentMessageID == rhs.recentMessageID
        
    }
}
