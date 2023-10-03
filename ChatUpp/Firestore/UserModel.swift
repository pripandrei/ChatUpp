//
//  UserModel.swift
//  ChatUpp
//
//  Created by Andrei Pripa on 10/3/23.
//

import Foundation


struct DBUser: Codable
{
    let userId: String
    let name: String?
    let dateCreated: Date?
    let email: String?
    let photoUrl: String?
    
    init(auth: AuthDataResultModel) {
        self.userId = auth.uid
        self.name = auth.name
        self.dateCreated = Date()
        self.email = auth.email
        self.photoUrl = auth.photoURL
    }
    
    enum CodingKeys: String, CodingKey {
        case userId = "user_id"
        case name = "name"
        case dateCreated = "date_created"
        case email = "email"
        case photoUrl = "photo_url"
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.userId = try container.decode(String.self, forKey: .userId)
        self.name = try container.decodeIfPresent(String.self, forKey: .name)
        self.dateCreated = try container.decodeIfPresent(Date.self, forKey: .dateCreated)
        self.email = try container.decodeIfPresent(String.self, forKey: .email)
        self.photoUrl = try container.decodeIfPresent(String.self, forKey: .photoUrl)
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(self.userId, forKey: .userId)
        try container.encodeIfPresent(self.name, forKey: .name)
        try container.encodeIfPresent(self.dateCreated, forKey: .dateCreated)
        try container.encodeIfPresent(self.email, forKey: .email)
        try container.encodeIfPresent(self.photoUrl, forKey: .photoUrl)
    }
}
