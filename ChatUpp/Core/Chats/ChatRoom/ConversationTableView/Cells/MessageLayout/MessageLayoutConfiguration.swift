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
    static func getLayoutConfiguration(for chatType: ChatType,
                                       showSenderName: Bool,
                                       showAvatar: Bool) -> MessageLayoutConfiguration
    {
        switch chatType
        {
        case ._private:
            return MessageLayoutConfiguration(shouldShowSenderName: false,
                                              shouldShowAvatar: false,
                                              avatarSize: nil,
                                              leadingConstraintConstant: 10)
        case ._group:
            return MessageLayoutConfiguration(shouldShowSenderName: showSenderName,
                                              shouldShowAvatar: showAvatar,
                                              avatarSize: CGSize(width: 35, height: 35),
                                              leadingConstraintConstant: 52)
        }
    }
}

