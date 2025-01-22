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
    @Persisted var dateCreated: Date?
    
    @Persisted var name: String?
    @Persisted var thumbnailURL: String?
    @Persisted var admins: List<String>
    
    /// isFirstTimeOpened and conversationMessages fields are ment only for local database
    @Persisted var isFirstTimeOpened: Bool?
    @Persisted var conversationMessages: List<Message>
    
    enum CodingKeys: String, CodingKey {
        case id = "id"
        case participants = "participants"
        case recentMessageID = "recent_message"
        case messagesCount = "messages_count"
        case name = "name"
        case thumbnailURL = "thumbnail_url"
        case admins = "admins"
        case dateCreated = "date_created"
    }
    
    required convenience init(from decoder: Decoder) throws
    {
        self.init()
        
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try container.decode(String.self, forKey: .id)
        self.recentMessageID = try container.decodeIfPresent(String.self, forKey: .recentMessageID)
        self.messagesCount = try container.decodeIfPresent(Int.self, forKey: .messagesCount)
        self.name = try container.decodeIfPresent(String.self, forKey: .name)
        self.thumbnailURL = try container.decodeIfPresent(String.self, forKey: .thumbnailURL)
        self.dateCreated = try container.decodeIfPresent(Date.self, forKey: .dateCreated)
        
        if let admins = try container.decodeIfPresent([String].self, forKey: .admins) {
            self.admins.append(objectsIn: admins)
        }
        
        let participants = try container.decode([String:ChatParticipant].self, forKey: .participants)
        for participant in participants.values {
            self.participants.append(participant)
        }
    }
    
    func encode(to encoder: Encoder) throws
    {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(self.id, forKey: .id)
        try container.encode(self.participants, forKey: .participants)
        try container.encodeIfPresent(self.recentMessageID, forKey: .recentMessageID)
        try container.encodeIfPresent(self.messagesCount, forKey: .messagesCount)
        try container.encodeIfPresent(self.name, forKey: .name)
        try container.encodeIfPresent(self.thumbnailURL, forKey: .thumbnailURL)
        try container.encodeIfPresent(self.dateCreated, forKey: .dateCreated)
        
        let encodedAdmins = Array(self.admins)
        try container.encode(encodedAdmins, forKey: .admins)
        
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
                     isFirstTimeOpened: Bool? = nil,
                     dateCreated: Date? = nil,
                     name: String? = nil,
                     thumbnailURL: String? = nil,
                     admins: [String]? = nil)
    {
        self.init()
        
        self.id = id
        self.participants.append(objectsIn: participants)
        self.recentMessageID = recentMessageID
        self.messagesCount = messagesCount
        self.isFirstTimeOpened = isFirstTimeOpened
        self.dateCreated = dateCreated
        self.name = name
        self.thumbnailURL = thumbnailURL
        
        if let admins = admins {
            self.admins.append(objectsIn: admins)
        }
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
    
    
    // MARK: - Test functions
    
    var title: String
    {
        if let name = name { return name }
        
        if let authUser = try? AuthenticationManager.shared.getAuthenticatedUser(),
           let participant = participants.first(where: { $0.userID != authUser.uid }),
           let user = RealmDataBase.shared.retrieveSingleObject(ofType: User.self, primaryKey: participant.userID)
        {
            return user.name ?? "Unknown"
        }
        return "Unknown"
    }

    
    var members: [User] {
        let participants = Array( participants.map { $0.userID } )
        let filter = NSPredicate(format: "id IN %@", argumentArray: participants)
        let users = RealmDataBase.shared.retrieveObjects(ofType: User.self, filter: filter)?.toArray()
        return users ?? []
    }
    
    var isGroup: Bool {
        participants.count > 2
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
