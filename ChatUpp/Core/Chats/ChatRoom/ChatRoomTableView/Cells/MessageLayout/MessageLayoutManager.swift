//
//  MessageLayoutManager.swift
//  ChatUpp
//
//  Created by Andrei Pripa on 8/26/25.
//

import UIKit

protocol MessageLayoutProvider
{
    func makeLayoutConfigurationForCell(at indexPath: IndexPath) -> MessageLayoutConfiguration
}

struct MessageLayoutManager: MessageLayoutProvider
{
    private let chatType: ChatType
    private let sourceProvider: ChatRoomDataSourceProviding
    
    init(chatType: ChatType,
         sourceProvider: ChatRoomDataSourceProviding)
    {
        self.sourceProvider = sourceProvider
        self.chatType = chatType
    }
    
    func makeLayoutConfigurationForCell(at indexPath: IndexPath) -> MessageLayoutConfiguration
    {
        let showUserAvatar = (chatType == ._group) ? shouldShowUserAvatarForCell(at: indexPath) : false
        
        let showSenderName = (chatType == ._group) ? shouldShowSenderName(at: indexPath) : false
        
        return .getLayoutConfiguration(for: chatType,
                                       showSenderName: showSenderName,
                                       showAvatar: showUserAvatar)
    }
    
    private func shouldShowUserAvatarForCell(at indexPath: IndexPath) -> Bool
    {
        let messageItems = sourceProvider.messageClusters[indexPath.section].items
        
        guard messageItems[indexPath.row].messageAlignment == .left else { return false }
        
        guard indexPath.row > 0 else { return true }
        
        guard
            let currentMessage = messageItems[indexPath.row].message,
            let previousMessage = messageItems[indexPath.row - 1].message
        else {
            return false
        }
        
        guard currentMessage.type != .title else { return false }
        guard previousMessage.type != .title else { return true }
        
        return currentMessage.senderId != previousMessage.senderId
    }
    
    private func shouldShowSenderName(at indexPath: IndexPath) -> Bool
    {
        let messageItems = sourceProvider.messageClusters[indexPath.section].items
        guard messageItems[indexPath.row].messageAlignment == .left else
        { return false }
        guard indexPath.row < messageItems.count - 1 else { return true }
        
        guard
            let currentMessage = messageItems[indexPath.row].message,
            let nextMessage = messageItems[indexPath.row + 1].message
        else {
            return false
        }
        
        guard currentMessage.type != .title else { return false }
        guard nextMessage.type != .title else { return true }
        
        return currentMessage.senderId != nextMessage.senderId
    }
}
