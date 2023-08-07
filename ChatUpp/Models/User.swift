//
//  User.swift
//  ChatUpp
//
//  Created by Andrei Pripa on 6/26/23.
//

import Foundation

struct UserCustom
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
        self.id = UserCustom.getUniqueIdentifire()
        self.phoneNumber = phoneNumber
    }
}

struct Chat {
    var messages: [Message] = []
    let sender: UserCustom
}

struct Message {
    var content: String
    var date: Date
}

final class ObservableObject<T> {
    var value: T {
        didSet {
            listiner?(value)
        }
    }

    var listiner: ((T) -> Void)?

    init(value: T) {
        self.value = value
    }

    func bind(_ listiner: @escaping((T) -> Void)) {
        self.listiner = listiner
        listiner(value)
    }
}
