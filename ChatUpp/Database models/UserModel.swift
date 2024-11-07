//
//  UserModel.swift
//  ChatUpp
//
//  Created by Andrei Pripa on 10/3/23.
//

import Foundation
import RealmSwift

// MARK: - User model

class User: Object, Codable
{
    @Persisted(primaryKey: true) var id: String
    @Persisted var name: String?
    @Persisted var dateCreated: Date?
    @Persisted var email: String?
    @Persisted var photoUrl: String?
    @Persisted var phoneNumber: String?
    @Persisted var isActive: Bool?
    @Persisted var lastSeen: Date?
    var nickname: String?
        
        enum CodingKeys: String, CodingKey {
            case id = "user_id"
            case name = "name"
            case dateCreated = "date_created"
            case email = "email"
            case photoUrl = "photo_url"
            case phoneNumber = "phone_number"
            case nickname = "nickname"
            case isActive = "is_active"
            case lastSeen = "last_seen"
        }
    
    convenience init(auth: AuthDataResultModel) {
        self.init()
        
        self.id = auth.uid
        self.name = auth.name
        self.email = auth.email
        self.photoUrl = auth.photoURL
        self.phoneNumber = auth.phoneNumber
        self.dateCreated = Date()
        self.lastSeen = Date()
        self.isActive = nil
    }
    
    convenience init(userId: String,
         name: String?,
         email: String?,
         photoUrl: String?,
         phoneNumber: String?,
         nickName: String?,
         dateCreated: Date?,
         lastSeen: Date?,
         isActive: Bool
    )
    {
        self.init()
        
        self.id = userId
        self.name = name
        self.email = email
        self.photoUrl = photoUrl
        self.phoneNumber = phoneNumber
        self.dateCreated = dateCreated
        self.lastSeen = lastSeen
        self.isActive = isActive
    }
    
    convenience required init(from decoder: Decoder) throws {
        self.init()
        
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try container.decode(String.self, forKey: .id)
        self.name = try container.decodeIfPresent(String.self, forKey: .name)
        self.dateCreated = try container.decodeIfPresent(Date.self, forKey: .dateCreated)
        self.email = try container.decodeIfPresent(String.self, forKey: .email)
        self.photoUrl = try container.decodeIfPresent(String.self, forKey: .photoUrl)
        self.phoneNumber = try container.decodeIfPresent(String.self, forKey: .phoneNumber)
        self.nickname = try container.decodeIfPresent(String.self, forKey: .nickname)
        self.isActive = try container.decodeIfPresent(Bool.self, forKey: .isActive)
        
        /// if last seen is fetched from Realtime database, it will be of type double
        /// if from Firestore it will be of type Date
        if let timestamp = try? container.decodeIfPresent(Double.self, forKey: .lastSeen) {
            self.lastSeen = Date(timeIntervalSince1970: timestamp)
        } else {
            self.lastSeen = try container.decodeIfPresent(Date.self, forKey: .lastSeen)
        }
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(self.id, forKey: .id)
        try container.encodeIfPresent(self.name, forKey: .name)
        try container.encodeIfPresent(self.dateCreated, forKey: .dateCreated)
        try container.encodeIfPresent(self.email, forKey: .email)
        try container.encodeIfPresent(self.photoUrl, forKey: .photoUrl)
        try container.encodeIfPresent(self.phoneNumber, forKey: .phoneNumber)
        try container.encodeIfPresent(self.nickname, forKey: .nickname)
        try container.encodeIfPresent(self.isActive, forKey: .isActive)
        try container.encodeIfPresent(self.lastSeen, forKey: .lastSeen)
    }
}


//MARK: - Temporary methods while firebase functions are deactivated

extension User {
    func updateActiveStatus(lastSeenDate: Date, isActive: Bool) -> User {
        return User(userId: self.id, name: self.name, email: self.email, photoUrl: self.photoUrl, phoneNumber: self.phoneNumber, nickName: self.nickname, dateCreated: self.dateCreated, lastSeen: lastSeenDate.toLocalTime(), isActive: isActive)
    }
}
