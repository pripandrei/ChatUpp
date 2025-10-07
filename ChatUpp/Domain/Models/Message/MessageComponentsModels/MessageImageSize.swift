//
//  MessageImageSize.swift
//  ChatUpp
//
//  Created by Andrei Pripa on 9/18/25.
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
