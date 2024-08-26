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
    
    enum CodingKeys: String, CodingKey {
        case id = "id"
        case members = "members"
        case recentMessageID = "recent_message"
    }
    
    required init(from decoder: Decoder) throws {
        super.init()
        
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try container.decode(String.self, forKey: .id)
        self.recentMessageID = try container.decodeIfPresent(String.self, forKey: .recentMessageID)
        let members = try container.decode([String].self, forKey: .members)
        self.members.append(objectsIn: members)
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(self.id, forKey: .id)
        try container.encode(self.members, forKey: .members)
        try container.encode(self.recentMessageID, forKey: .recentMessageID)
    }
    
    init(id: String, members: [String], lastMessage: String?) {
        super.init()
        
        self.id = id
        self.members.append(objectsIn: members)
//        self.members = members
        self.recentMessageID = lastMessage
    }
}
