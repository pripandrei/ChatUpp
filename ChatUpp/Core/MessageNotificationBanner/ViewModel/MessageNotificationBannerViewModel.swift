//
//  MessageNotificationBannerViewModel.swift
//  ChatUpp
//
//  Created by Andrei Pripa on 8/25/25.
//

import Foundation
import SwiftUI

final class MessageNotificationBannerViewModel: SwiftUI.ObservableObject
{
    let messageBannerData: MessageBannerData
    
    init(messageBannerData: MessageBannerData)
    {
        self.messageBannerData = messageBannerData
    }
    
    var messageText: String
    {
        switch messageBannerData.message.type
        {
        case .text, .imageText, .title:
            return messageBannerData.message.messageBody
        case .image:
            return "Photo"
        case .sticker:
            return "Sticker"
        case .audio:
            return "Voice message"
        case .video:
            return "Video message"
        case .none:
            return ""
        }
    }
    
    var defaultImageName: String
    {
        switch messageBannerData.chat.isGroup
        {
        case true: "default_group_photo"
        case false: "default_profile_photo"
        }
    }
    
    var onTap: (() -> Void)?
}
