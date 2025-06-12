//
//  NotificationCenter+Extensions.swift
//  ChatUpp
//
//  Created by Andrei Pripa on 6/13/25.
//

import Foundation

extension Notification.Name {
    static let didJoinNewChat = Notification.Name("didJoinNewChat")
    static let didCreateNewChat = Notification.Name("didCreateNewChat")
    static let didUpdateUnseenMessageCount = Notification.Name("didUpdateUnseenMessageCount")
}
