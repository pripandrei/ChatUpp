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
    
    var onTap: (() -> Void)?
}
