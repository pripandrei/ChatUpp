//
//  MessageComponentsViewModel.swift
//  ChatUpp
//
//  Created by Andrei Pripa on 10/23/25.
//

import Foundation
import Combine

//MARK: -
final class MessageComponentsViewModel
{
    let message: Message
    var componentsContext: ComponentsContext
    private var cancellables: Set<AnyCancellable> = []
    
    init(message: Message,
         context: ComponentsContext)
    {
        self.message = message
        self.componentsContext = context
    }
    
    deinit
    {
        print(String(describing: Self.self), "deinit")
    }
    
    var timestamp: String? {
        let hoursAndMinutes = message.timestamp.formatToHoursAndMinutes()
        return hoursAndMinutes
    }
    
    var isMessageSeen: Bool
    {
        return message.messageSeen ?? (message.seenBy.count > 1)
    }
}
