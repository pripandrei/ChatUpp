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
    static var currentlySelectedChatThemeKey: String = "main_theme_key_0001"
    
    private init() {}
    
    @Published private(set) var totalUnseenMessageCount: Int = 0
    {
        didSet {
//            print("ChatManager total count: \(totalUnseenMessageCount)")
        }
    }
    @Published private(set) var newCreatedChat: Chat?
//    @Published private(set) var newCreatedMessage: Message?
    @Published private(set) var joinedGroupChat: Chat?
    private(set) var newCreatedMessageSubject = PassthroughSubject<Message,Never>()
    private(set) var newStickerSubject = PassthroughSubject<String,Never>()

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
    
    func addNewSticker(_ path: String)
    {
        newStickerSubject.send(path)
    }
    
    func sendNewMessage(_ message: Message)
    {
        newCreatedMessageSubject.send(message)
    }
    
    func resetTotalUnseenMessageCount()
    {
        totalUnseenMessageCount = 0
    }
}
