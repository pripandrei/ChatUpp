//
//  Enums.swift
//  ChatUpp
//
//  Created by Andrei Pripa on 1/16/25.
//

import UIKit

enum MessageValueModification
{
    case text
    case seenStatus
    
    var animationType: UITableView.RowAnimation {
        switch self {
        case .text: return .left
        case .seenStatus: return .none
        }
    }
}

enum MessageChangeType {
    case modified(IndexPath, MessageValueModification)
    case added
    case removed(IndexPath)
}

enum MessageFetchStrategy
{
    case ascending(startAtMessage: Message?, included: Bool)
    case descending(startAtMessage: Message?, included: Bool)
    case hybrit(startAtMessage: Message)
    case none
}

enum MessagesFetchDirection {
    case ascending
    case descending
    case both
}

enum MessagesListenerRange
{
    case forExisting(startAtMessage: Message, endAtMessage: Message)
    case forPaged(startAtMessage: Message, endAtMessage: Message)
}

enum ConversationInitializationStatus {
    case inProgress
    case finished
}
