//
//  MessageLayoutConfiguration.swift
//  ChatUpp
//
//  Created by Andrei Pripa on 8/10/25.
//

import UIKit

struct MessageLayoutConfiguration
{
    let shouldShowSenderName: Bool
    let shouldShowAvatar: Bool
    let avatarSize: CGSize?
    let leadingConstraintConstant: CGFloat
}

extension MessageLayoutConfiguration
{
    func withUpdatedAvatar(_ shouldShow: Bool) -> MessageLayoutConfiguration
    {
        return MessageLayoutConfiguration(shouldShowSenderName: shouldShowSenderName,
                                          shouldShowAvatar: shouldShow,
                                          avatarSize: avatarSize,
                                          leadingConstraintConstant: leadingConstraintConstant)
    }
    
    func withUpdatedSenderName(_ shouldShow: Bool) -> MessageLayoutConfiguration
    {
        return MessageLayoutConfiguration(shouldShowSenderName: shouldShow,
                                          shouldShowAvatar: shouldShowAvatar,
                                          avatarSize: avatarSize,
                                          leadingConstraintConstant: leadingConstraintConstant)
    }
    
    static func getLayoutConfiguration(for chatType: ChatType) -> MessageLayoutConfiguration
    {
        switch chatType {
        case ._private:
            return MessageLayoutConfiguration(shouldShowSenderName: false,
                                              shouldShowAvatar: false,
                                              avatarSize: nil,
                                              leadingConstraintConstant: 10)
        case ._group:
            return MessageLayoutConfiguration(shouldShowSenderName: true,
                                              shouldShowAvatar: false, // Adjusted dynamically
                                              avatarSize: CGSize(width: 35, height: 35),
                                              leadingConstraintConstant: 52)
        }
    }
}
