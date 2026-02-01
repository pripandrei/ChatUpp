//
//  Untitled.swift
//  ChatUpp
//
//  Created by Andrei Pripa on 9/18/25.
//
import Foundation
import RealmSwift


class Reaction: EmbeddedObject, Codable, Identifiable
{
    @Persisted var emoji: String
    @Persisted var userIDs: List<String>
    
    convenience init(emoji: String, userIDs: List<String>) {
        self.init()
        self.emoji = emoji
        self.userIDs = userIDs
    }
}
