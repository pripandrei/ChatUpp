//
//  MessageModel.swift
//  ChatUpp
//
//  Created by Andrei Pripa on 10/3/23.
//

import Foundation

struct MessageImageSize: Codable {
    let width: Int
    let height: Int
}

struct Message: Codable {
    let id: String
    let messageBody: String
    let senderId: String
    let timestamp: Date
    let messageSeen: Bool
    let isEdited: Bool
    let receivedBy: String?
    let imagePath: String?
    let repliedTo: String?
    
    var imageSize: MessageImageSize?
    
    enum CodingKeys: String, CodingKey {
        case id = "id"
        case messageBody = "message_body"
        case senderId = "sent_by"
        case imagePath = "image_path"
        case timestamp = "timestamp"
        case messageSeen = "message_seen"
        case receivedBy = "received_by"
        case imageSize = "image_size"
        case isEdited = "is_edited"
        case repliedTo = "replied_to"
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try container.decode(String.self, forKey: .id)
        self.messageBody = try container.decode(String.self, forKey: .messageBody)
        self.senderId = try container.decode(String.self, forKey: .senderId)
        self.imagePath = try container.decodeIfPresent(String.self, forKey: .imagePath)
        self.timestamp = try container.decode(Date.self, forKey: .timestamp)
        self.messageSeen = try container.decode(Bool.self, forKey: .messageSeen)
        self.isEdited = try container.decode(Bool.self, forKey: .isEdited)
        self.imageSize = try container.decodeIfPresent(MessageImageSize.self, forKey: .imageSize)
        self.receivedBy = try container.decodeIfPresent(String.self, forKey: .receivedBy)
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
        try container.encodeIfPresent(self.receivedBy, forKey: .receivedBy)
        try container.encodeIfPresent(self.imageSize, forKey: .imageSize)
        try container.encodeIfPresent(self.repliedTo, forKey: .repliedTo)
    }
    
    init(id: String,
         messageBody: String,
         senderId: String,
         timestamp: Date,
         messageSeen: Bool,
         isEdited: Bool,
         imagePath: String?,
         receivedBy: String?,
         imageSize: MessageImageSize?,
         repliedTo: String?
    )
    {
        self.id = id
        self.messageBody = messageBody
        self.senderId = senderId
        self.imagePath = imagePath
        self.timestamp = timestamp
        self.messageSeen = messageSeen
        self.receivedBy = receivedBy
        self.imageSize = imageSize
        self.isEdited = isEdited
        self.repliedTo = repliedTo
    }
    
    func updateMessageSeenStatus() -> Message {
        return Message(id: self.id, messageBody: self.messageBody, senderId: self.senderId, timestamp: self.timestamp, messageSeen: !self.messageSeen, isEdited: self.isEdited, imagePath: self.imagePath, receivedBy: self.receivedBy, imageSize: self.imageSize, repliedTo: self.repliedTo)
    }
}


struct RecentMessage: Codable {
    let messageBody: String
    let sentBy: String
    let timestamp: String

    enum CodingKeys: String, CodingKey {
        case messageBody = "message_body"
        case sentBy = "sent_by"
        case timestamp = "timestamp"
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.messageBody = try container.decode(String.self, forKey: .messageBody)
        self.sentBy = try container.decode(String.self, forKey: .sentBy)
        self.timestamp = try container.decode(String.self, forKey: .timestamp)
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(messageBody, forKey: .messageBody)
        try container.encode(sentBy, forKey: .sentBy)
        try container.encode(timestamp, forKey: .timestamp)    
    }
}
