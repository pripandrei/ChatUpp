//
//  ChatModel.swift
//  ChatUpp
//
//  Created by Andrei Pripa on 10/3/23.
//

import Foundation
import RealmSwift


class ChatParticipant: EmbeddedObject, Codable
{
    @Persisted var userID: String
    @Persisted var isDeleted: Bool
    @Persisted var unseenMessagesCount: Int
    
    enum CodingKeys: String, CodingKey 
    {
        case userID = "user_id"
        case isDeleted = "is_deleted"
        case unseenMessagesCount = "unseen_messages_count"
    }
    
    convenience init(userID: String, unseenMessageCount: Int, isDeleted: Bool = false)
    {
        self.init()

        self.userID = userID
        self.isDeleted = isDeleted
        self.unseenMessagesCount = unseenMessageCount
    }
    
    convenience required init(from decoder: Decoder) throws
    {
        self.init()
        
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.userID = try container.decode(String.self, forKey: .userID)
        self.isDeleted = try container.decode(Bool.self, forKey: .isDeleted)
        self.unseenMessagesCount = try container.decode(Int.self, forKey: .unseenMessagesCount)
    }
    
    func encode(to encoder: Encoder) throws 
    {
        var container = encoder.container(keyedBy: CodingKeys.self)

        try container.encode(self.userID, forKey: .userID)
        try container.encode(self.isDeleted, forKey: .isDeleted)
        try container.encode(self.unseenMessagesCount, forKey: .unseenMessagesCount)
    }
}

class Chat: Object, Codable 
{
    @Persisted(primaryKey: true) var id: String
    @Persisted var recentMessageID: String?
    @Persisted var messagesCount: Int?
    @Persisted var participants: List<ChatParticipant>
    
    /// isFirstTimeOpened and conversationMessages fields are ment only for local database
    @Persisted var isFirstTimeOpened: Bool?
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
        
        let participants = try container.decode([String:ChatParticipant].self, forKey: .participants)
        for participant in participants.values {
            self.participants.append(participant)
        }
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(self.id, forKey: .id)
        try container.encode(self.participants, forKey: .participants)
        try container.encodeIfPresent(self.recentMessageID, forKey: .recentMessageID)
        try container.encodeIfPresent(self.messagesCount, forKey: .messagesCount)
        
        var dictParticipants: [String:ChatParticipant] = [:]
        for participant in participants {
            dictParticipants[participant.userID] = participant
        }
        try container.encode(dictParticipants, forKey: .participants)
    }
    
    convenience init(id: String,
                     participants: [ChatParticipant],
                     recentMessageID: String?,
                     messagesCount: Int? = 0,
                     isFirstTimeOpened: Bool? = nil)
    {
        self.init()
        
        self.id = id
        self.participants.append(objectsIn: participants)
        self.recentMessageID = recentMessageID
        self.messagesCount = messagesCount
        self.isFirstTimeOpened = isFirstTimeOpened
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
    
    func getFirstMessage() -> Message? {
        return conversationMessages.sorted(byKeyPath: Message.CodingKeys.timestamp.rawValue, ascending: true).first
    }
    
    func getParticipant(byID ID: String) -> ChatParticipant? {
        return participants.first(where: { $0.userID == ID })
    }
    
//    func incrementMessageCount() {
//        RealmDBManager.shared.update(object: self) { chat in
//            chat.messagesCount = (self.messagesCount ?? 0) + 1
//        }
//    }
    
    //    func getLastSeenMessage() -> Message? {
    //        guard let lastSeenMessage = conversationMessages
    //            .filter("messageSeen == true")
    //            .sorted(byKeyPath: "timestamp", ascending: false)
    //            .first else { return nil }
    //
    //        return lastSeenMessage
    //    }
    
}


extension Chat {
    static func == (lhs: Chat, rhs: Chat) -> Bool {
        lhs.id == rhs.id &&
        lhs.participants == rhs.participants &&
        lhs.recentMessageID == rhs.recentMessageID
        
    }
}
