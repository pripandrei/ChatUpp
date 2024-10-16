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
    @Persisted var participants: List<String>
    @Persisted var recentMessageID: String?
    @Persisted var messagesCount: Int?
    
    @Persisted var conversationMessages: List<Message>
    
    enum CodingKeys: String, CodingKey {
        case id = "id"
        case participants = "participants"
        case recentMessageID = "recent_message"
        case messagesCount = "messages_count"
    }
    
    required convenience init(from decoder: Decoder) throws {
        self.init()
        
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try container.decode(String.self, forKey: .id)
        self.recentMessageID = try container.decodeIfPresent(String.self, forKey: .recentMessageID)
        self.messagesCount = try container.decodeIfPresent(Int.self, forKey: .messagesCount)
        let participants = try container.decode([String].self, forKey: .participants)
        self.participants.append(objectsIn: participants)
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(self.id, forKey: .id)
        try container.encode(self.participants, forKey: .participants)
        try container.encodeIfPresent(self.recentMessageID, forKey: .recentMessageID)
        try container.encodeIfPresent(self.messagesCount, forKey: .messagesCount)
    }
    
    convenience init(id: String, participants: [String], recentMessageID: String?, messagesCount: Int? = 0) {
        self.init()
        
        self.id = id
        self.participants.append(objectsIn: participants)
        self.recentMessageID = recentMessageID
        self.messagesCount = messagesCount
    }
    
    func appendConversationMessage(_ message: Message) {
        conversationMessages.append(message)
    }
    
    func getMessages() -> [Message] {
        return Array(conversationMessages.sorted(byKeyPath: Message.CodingKeys.timestamp.rawValue, ascending: false))
    }

    func getLastMessage() -> Message? {
        return conversationMessages.sorted(byKeyPath: Message.CodingKeys.timestamp.rawValue, ascending: false).first
    }
    
    
    
    /// Last message will always be the recent one (in local and remote db)
    /// However, next to last message will be in local db but,
    /// it will not necessarily be next to last in remote db
    /// So we need to get it's timestamp in order to fetch messages up from that timestamp

    func getPenultimateMessage() -> Message? {
        guard let nextToLastMessage = conversationMessages
            .sorted(byKeyPath: Message.CodingKeys.timestamp.rawValue, ascending: false)
            .dropFirst()
            .first else { return nil }
        
        return nextToLastMessage
    }
    
    func getLastSeenMessage() -> Message? {
        guard let lastSeenMessage = conversationMessages
            .filter("messageSeen == true")
            .sorted(byKeyPath: "timestamp", ascending: false)
            .first else { return nil }
        
        return lastSeenMessage
    }
    
    func getFirstMessage() -> Message? {
        return conversationMessages.sorted(byKeyPath: Message.CodingKeys.timestamp.rawValue, ascending: true).first
    }
    
    func incrementMessageCount() {
        RealmDBManager.shared.update(object: self) { chat in
            chat.messagesCount = (self.messagesCount ?? 0) + 1
        }
    }
    
}


extension Chat {
    static func == (lhs: Chat, rhs: Chat) -> Bool {
        lhs.id == rhs.id &&
        lhs.participants == rhs.participants &&
        lhs.recentMessageID == rhs.recentMessageID
        
    }
}
