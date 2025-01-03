//
//  MessageModel.swift
//  ChatUpp
//
//  Created by Andrei Pripa on 10/3/23.
//

import Foundation
import RealmSwift

class MessageImageSize: EmbeddedObject, Codable
{
    @Persisted var width: Int
    @Persisted var height: Int
    
    convenience init(width: Int, height: Int) {
        self.init()
        self.width = width
        self.height = height
    }
    
    enum CodingKeys: CodingKey {
//        case id
        case width
        case height
    }
    
    convenience required init(from decoder: any Decoder) throws
    {
        self.init()
        
        let container = try decoder.container(keyedBy: CodingKeys.self)
//        self.id = try container.decode(String.self, forKey: .id)
        self.width = try container.decode(Int.self, forKey: .width)
        self.height = try container.decode(Int.self, forKey: .height)
    }
    
    func encode(to encoder: any Encoder) throws
    {
        var container = encoder.container(keyedBy: CodingKeys.self)
//        try container.encode(self.id, forKey: .id)
        try container.encode(self.width, forKey: .width)
        try container.encode(self.height, forKey: .height)
    }
}

class Message: Object, Codable 
{
    @Persisted(primaryKey: true) var id: String
    @Persisted var messageBody: String
    @Persisted var senderId: String
    @Persisted var timestamp: Date
    @Persisted var messageSeen: Bool
    @Persisted var isEdited: Bool
    @Persisted var imagePath: String?
    @Persisted var repliedTo: String?
    
    @Persisted var imageSize: MessageImageSize?
    
    enum CodingKeys: String, CodingKey {
        case id = "id"
        case messageBody = "message_body"
        case senderId = "sent_by"
        case imagePath = "image_path"
        case timestamp = "timestamp"
        case messageSeen = "message_seen"
        case imageSize = "image_size"
        case isEdited = "is_edited"
        case repliedTo = "replied_to"
    }
    
    convenience required init(from decoder: Decoder) throws {
        self.init()
        
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try container.decode(String.self, forKey: .id)
        self.messageBody = try container.decode(String.self, forKey: .messageBody)
        self.senderId = try container.decode(String.self, forKey: .senderId)
        self.imagePath = try container.decodeIfPresent(String.self, forKey: .imagePath)
        self.timestamp = try container.decode(Date.self, forKey: .timestamp)
        self.messageSeen = try container.decode(Bool.self, forKey: .messageSeen)
        self.isEdited = try container.decode(Bool.self, forKey: .isEdited)
        self.imageSize = try container.decodeIfPresent(MessageImageSize.self, forKey: .imageSize)
        self.repliedTo = try container.decodeIfPresent(String.self, forKey: .repliedTo)
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(self.id, forKey: .id)
        try container.encode(self.messageBody, forKey: .messageBody)
        try container.encode(self.senderId, forKey: .senderId)
        try container.encodeIfPresent(self.imagePath, forKey: .imagePath)
        try container.encode(self.timestamp, forKey: .timestamp)
        try container.encode(self.messageSeen, forKey: .messageSeen)
        try container.encode(self.isEdited, forKey: .isEdited)
        try container.encodeIfPresent(self.imageSize, forKey: .imageSize)
        try container.encodeIfPresent(self.repliedTo, forKey: .repliedTo)
    }
    
    convenience init(id: String,
         messageBody: String,
         senderId: String,
         timestamp: Date,
         messageSeen: Bool,
         isEdited: Bool,
         imagePath: String?,
         imageSize: MessageImageSize?,
         repliedTo: String?
    )
    {
        
        self.init()
        self.id = id
    
        self.messageBody = messageBody
        self.senderId = senderId
        self.imagePath = imagePath
        self.timestamp = timestamp
        self.messageSeen = messageSeen
        self.imageSize = imageSize
        self.isEdited = isEdited
        self.repliedTo = repliedTo
    }
}
