//
//  MessageModel.swift
//  ChatUpp
//
//  Created by Andrei Pripa on 10/3/23.
//

import Foundation
import RealmSwift

enum MessageType: String, PersistableEnum, Codable
{
    case text
    case title
    case image
    case audio
    case video
}

class Reaction: EmbeddedObject, Codable
{
    @Persisted var emoji: String
    @Persisted var userIDs: List<String>
//    @Persisted var userIDs: List<String>
    
//    init(emoji: String, userIDs: List<String>)
//    {
////        super.init()
//        self.emoji = emoji
//        self.userIDs = userIDs
////        self.userIDs.append(objectsIn: userIDs)
//    }
}

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
    @Persisted var isEdited: Bool
    @Persisted var messageSeen: Bool?
    @Persisted var seenBy: List<String>
    @Persisted var imagePath: String?
    @Persisted var repliedTo: String?
    @Persisted var reactions: List<Reaction>
    
    @Persisted var type: MessageType?
    
    @Persisted var imageSize: MessageImageSize?
    
    enum CodingKeys: String, CodingKey {
        case id = "id"
        case messageBody = "message_body"
        case senderId = "sent_by"
        case imagePath = "image_path"
        case timestamp = "timestamp"
        case messageSeen = "message_seen"
        case seenBy = "seen_by"
        case imageSize = "image_size"
        case isEdited = "is_edited"
        case repliedTo = "replied_to"
        case type = "type"
        case reactions = "reactions"
    }
    
    convenience required init(from decoder: Decoder) throws {
        self.init()
        
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try container.decode(String.self, forKey: .id)
        self.messageBody = try container.decode(String.self, forKey: .messageBody)
        self.senderId = try container.decode(String.self, forKey: .senderId)
        self.imagePath = try container.decodeIfPresent(String.self, forKey: .imagePath)
        self.timestamp = try container.decode(Date.self, forKey: .timestamp)
        self.messageSeen = try container.decodeIfPresent(Bool.self, forKey: .messageSeen)
        self.isEdited = try container.decode(Bool.self, forKey: .isEdited)
        self.imageSize = try container.decodeIfPresent(MessageImageSize.self, forKey: .imageSize)
        self.repliedTo = try container.decodeIfPresent(String.self, forKey: .repliedTo)
        self.type = try container.decodeIfPresent(MessageType.self, forKey: .type)
        
        let seenBy = try container.decodeIfPresent([String].self, forKey: .seenBy)
        self.seenBy.append(objectsIn: seenBy ?? [])
        
        let reactionsMap = try container.decode([String: [String]].self, forKey: .reactions)
        self.reactions = mapDecodedReactions(reactionsMap)
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(self.id, forKey: .id)
        try container.encode(self.messageBody, forKey: .messageBody)
        try container.encode(self.senderId, forKey: .senderId)
        try container.encodeIfPresent(self.imagePath, forKey: .imagePath)
        try container.encode(self.timestamp, forKey: .timestamp)
        try container.encodeIfPresent(self.messageSeen, forKey: .messageSeen)
        try container.encode(self.isEdited, forKey: .isEdited)
        try container.encodeIfPresent(self.imageSize, forKey: .imageSize)
        try container.encodeIfPresent(self.repliedTo, forKey: .repliedTo)
        try container.encodeIfPresent(self.type, forKey: .type)
        
        let seenBy = Array(self.seenBy)
        try container.encodeIfPresent(seenBy, forKey: .seenBy)
        
        let mapedReactions = mapEncodedReactions(self.reactions)
        try container.encode(mapedReactions, forKey: .reactions)
    }
    
    convenience init(id: String,
                     messageBody: String,
                     senderId: String,
                     timestamp: Date,
                     messageSeen: Bool?,
                     seenBy: [String]? = nil,
                     isEdited: Bool,
                     imagePath: String?,
                     imageSize: MessageImageSize?,
                     repliedTo: String?,
                     type: MessageType? = nil
    )
    {
        
        self.init()
        self.id = id
    
        self.messageBody = messageBody
        self.senderId = senderId
        self.imagePath = imagePath
        self.timestamp = timestamp
        self.messageSeen = messageSeen
        self.seenBy.append(objectsIn: seenBy ?? [])
        self.imageSize = imageSize
        self.isEdited = isEdited
        self.repliedTo = repliedTo
        self.type = type
        self.reactions = List<Reaction>()
    }
}

//MARK: - map reactions firebase <--> realm
extension Message
{
    private func mapDecodedReactions(_ reactions: [String: [String]]) -> List<Reaction>
    {
        var reactionsList = List<Reaction>()
        for (emoji, userIDs) in reactions
        {
            let reaction = Reaction()
            reaction.emoji = emoji
            reaction.userIDs.append(objectsIn: userIDs)
            reactionsList.append(reaction)
        }
        return reactionsList
    }
    
    private func mapEncodedReactions(_ reactions: List<Reaction>) -> [String: [String]]
    {
        var mapedReactions = [String: [String]]()
        for reaction in reactions
        {
            mapedReactions[reaction.emoji] = Array(reaction.userIDs)
        }
        return mapedReactions
    }
}


//MARK: - manager for fetching test data
final class TestHelper
{
    static let shared = TestHelper()
    
    private init() {}
    
    func downloadUser() {
        Task {
            let user = try await FirestoreUserService.shared.getUserFromDB(userID: "DESg2qjjJPP20KQDWfKpJJnozv53")
            RealmDataBase.shared.add(object: user)
        }
    }
    
    func downlaodUserAvatar() {
        Task {
            let path = "D131B2EF-2DCC-4483-BB1E-98F0B49014A0_small.jpeg"
            let imageData = try await FirebaseStorageManager.shared.getImage(from: .user("DESg2qjjJPP20KQDWfKpJJnozv53"), imagePath: path)
            CacheManager.shared.saveImageData(imageData, toPath: path)
        }
    }
}
