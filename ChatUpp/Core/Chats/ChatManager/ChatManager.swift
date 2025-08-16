//
//  ChatManager.swift
//  ChatUpp
//
//  Created by Andrei Pripa on 8/16/25.
//

import Foundation
import Combine

final class ChatManager
{
    static let shared = ChatManager()
    
    private init() {}
    
    @Published private(set) var totalUnseenMessageCount: Int = 0
    @Published private(set) var newCreatedChat: Chat?
    @Published private(set) var joinedGroupChat: Chat?

    
    func incrementUnseenMessageCount(by value: Int)
    {
        totalUnseenMessageCount += value
    }
    
    func decrementUnseenMessageCount(by value: Int)
    {
        totalUnseenMessageCount = max(0, totalUnseenMessageCount - value)
    }
    
    func broadcastNewCreatedChat(_ chat: Chat)
    {
        newCreatedChat = chat
    }
    
    func broadcastJoinedGroupChat(_ chat: Chat)
    {
        joinedGroupChat = chat
    }
}
