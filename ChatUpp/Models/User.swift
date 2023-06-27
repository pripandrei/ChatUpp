//
//  User.swift
//  ChatUpp
//
//  Created by Andrei Pripa on 6/26/23.
//

import Foundation

struct User
{
    private static let identifireFactory: Int = 0
    private let id: Int
    var phoneNumber: Int
    var firstName: String?
    var lastName: Optional<String>?
    var chats: [Chat] = []
    
    private static func getUniqueIdentifire() -> Int {
        return identifireFactory + 1
    }
    
    init(phoneNumber: Int) {
        self.id = User.getUniqueIdentifire()
        self.phoneNumber = phoneNumber
    }
}

struct Chat {
    var messages: [Message] = []
    let sender: User
}

struct Message {
    var content: String
    var date: Date
}

