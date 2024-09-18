//
//  MessageModel.swift
//  ChatUpp
//
//  Created by Andrei Pripa on 10/3/23.
//

import Foundation
import RealmSwift

class MessageImageSize: Object, Codable {
    @Persisted(primaryKey: true) private var id: String = UUID().uuidString
    @Persisted var width: Int
    @Persisted var height: Int
    
    init(width: Int, height: Int) {
        self.width = width
        self.height = height
    }
    override init() {
        super.init()
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
    
    func updateMessageText(_ text: String) -> Message {
        return Message(id: self.id, messageBody: text, senderId: self.senderId, timestamp: self.timestamp, messageSeen: !self.messageSeen, isEdited: true, imagePath: self.imagePath,  imageSize: self.imageSize, repliedTo: self.repliedTo)
    }
    
    func updateMessageSeenStatus() -> Message {
        return Message(id: self.id, messageBody: self.messageBody, senderId: self.senderId, timestamp: self.timestamp, messageSeen: !self.messageSeen, isEdited: self.isEdited, imagePath: self.imagePath,  imageSize: self.imageSize, repliedTo: self.repliedTo)
    }
}


//struct RecentMessage: Codable {
//    let messageBody: String
//    let sentBy: String
//    let timestamp: String
//
//    enum CodingKeys: String, CodingKey {
//        case messageBody = "message_body"
//        case sentBy = "sent_by"
//        case timestamp = "timestamp"
//    }
//    
//    init(from decoder: Decoder) throws {
//        let container = try decoder.container(keyedBy: CodingKeys.self)
//        self.messageBody = try container.decode(String.self, forKey: .messageBody)
//        self.sentBy = try container.decode(String.self, forKey: .sentBy)
//        self.timestamp = try container.decode(String.self, forKey: .timestamp)
//    }
//    
//    func encode(to encoder: Encoder) throws {
//        var container = encoder.container(keyedBy: CodingKeys.self)
//        try container.encode(messageBody, forKey: .messageBody)
//        try container.encode(sentBy, forKey: .sentBy)
//        try container.encode(timestamp, forKey: .timestamp)    
//    }
//}
