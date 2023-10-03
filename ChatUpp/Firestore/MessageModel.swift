//
//  MessageModel.swift
//  ChatUpp
//
//  Created by Andrei Pripa on 10/3/23.
//

import Foundation


struct Message: Codable {
    let id: String
    let messageBody: String
    let senderId: String
    let imageUrl: String?
    let timestamp: String
    
    enum CodingKeys: String, CodingKey {
        case id = "id"
        case messageBody = "message_body"
        case senderId = "sender_id"
        case imageUrl = "image_url"
        case timestamp = "timestamp"
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try container.decode(String.self, forKey: .id)
        self.messageBody = try container.decode(String.self, forKey: .messageBody)
        self.senderId = try container.decode(String.self, forKey: .senderId)
        self.imageUrl = try container.decodeIfPresent(String.self, forKey: .imageUrl)
        self.timestamp = try container.decode(String.self, forKey: .timestamp)
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(self.id, forKey: .id)
        try container.encode(self.messageBody, forKey: .messageBody)
        try container.encode(self.senderId, forKey: .senderId)
        try container.encodeIfPresent(self.imageUrl, forKey: .imageUrl)
        try container.encode(self.timestamp, forKey: .timestamp)
    }
    
    init(id: String,
         messageBody: String,
         senderId: String,
         imageUrl: String?,
         timestamp: String)
    {
        self.id = id
        self.messageBody = messageBody
        self.senderId = senderId
        self.imageUrl = imageUrl
        self.timestamp = timestamp
    }
}
