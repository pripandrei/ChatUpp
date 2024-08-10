//
//  UserModel.swift
//  ChatUpp
//
//  Created by Andrei Pripa on 10/3/23.
//

import Foundation

// MARK: - User model
struct DBUser: Codable
{
    let userId: String
    let name: String?
    let dateCreated: Date?
    let email: String?
    let photoUrl: String?
    let phoneNumber: String?
    var nickname: String?
    let isActive: Bool
    let lastSeen: Date?
        
        enum CodingKeys: String, CodingKey {
            case userId = "user_id"
            case name = "name"
            case dateCreated = "date_created"
            case email = "email"
            case photoUrl = "photo_url"
            case phoneNumber = "phone_number"
            case nickname = "nickname"
            case isActive = "is_active"
            case lastSeen = "last_seen"
        }
    
    init(auth: AuthDataResultModel) {
        self.userId = auth.uid
        self.name = auth.name
        self.email = auth.email
        self.photoUrl = auth.photoURL
        self.phoneNumber = auth.phoneNumber
        self.dateCreated = Date()
        self.lastSeen = Date()
        self.isActive = true
    }
    
    init(userId: String,
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
        self.userId = userId
        self.name = name
        self.email = email
        self.photoUrl = photoUrl
        self.phoneNumber = phoneNumber
        self.dateCreated = dateCreated
        self.lastSeen = lastSeen
        self.isActive = isActive
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.userId = try container.decode(String.self, forKey: .userId)
        self.name = try container.decodeIfPresent(String.self, forKey: .name)
        self.dateCreated = try container.decodeIfPresent(Date.self, forKey: .dateCreated)
        self.email = try container.decodeIfPresent(String.self, forKey: .email)
        self.photoUrl = try container.decodeIfPresent(String.self, forKey: .photoUrl)
        self.phoneNumber = try container.decodeIfPresent(String.self, forKey: .phoneNumber)
        self.nickname = try container.decodeIfPresent(String.self, forKey: .nickname)
        self.isActive = try container.decode(Bool.self, forKey: .isActive)
        self.lastSeen = try container.decodeIfPresent(Date.self, forKey: .lastSeen)
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(self.userId, forKey: .userId)
        try container.encodeIfPresent(self.name, forKey: .name)
        try container.encodeIfPresent(self.dateCreated, forKey: .dateCreated)
        try container.encodeIfPresent(self.email, forKey: .email)
        try container.encodeIfPresent(self.photoUrl, forKey: .photoUrl)
        try container.encodeIfPresent(self.phoneNumber, forKey: .phoneNumber)
        try container.encodeIfPresent(self.nickname, forKey: .nickname)
        try container.encodeIfPresent(self.isActive, forKey: .isActive)
        try container.encodeIfPresent(self.lastSeen, forKey: .lastSeen)
    }
    
    func updateActiveStatus(lastSeenDate: Date) -> DBUser {
        return DBUser(userId: self.userId, name: self.name, email: self.email, photoUrl: self.photoUrl, phoneNumber: self.phoneNumber, nickName: self.nickname, dateCreated: self.dateCreated, lastSeen: lastSeenDate.toLocalTime(), isActive: !self.isActive)
    }
}
