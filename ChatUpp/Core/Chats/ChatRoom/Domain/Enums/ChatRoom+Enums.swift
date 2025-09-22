//
//  ChatRoom+Enums.swift
//  ChatUpp
//
//  Created by Andrei Pripa on 9/22/25.
//

import UIKit

enum DatasourceRowAnimation
{
    case top
    case fade
    case left
    case automatic
    case none
    
    var animation: UITableView.RowAnimation {
        switch self {
        case .top: return .top
        case .fade: return .fade
        case .none: return .none
        case .left: return .left
        case .automatic: return .automatic
        }
    }
}

enum MessageValueModification
{
    case text
    case seenStatus
    case reactions
    
    var animationType: UITableView.RowAnimation {
        switch self {
        case .text: return .left
        case .seenStatus: return .none
        case .reactions: return .none
        }
    }
}

enum MessagesUpdateType: Hashable
{
    case added([MessageCellViewModel])
    case updated([MessageCellViewModel])
    case removed([MessageCellViewModel])
}

enum MessageChangeType: Hashable {
    case modified(IndexPath, MessageValueModification)
    case added(IndexPath)
    case removed(IndexPath, isLastItemInSection: Bool)
}

enum MessageFetchStrategy
{
    case ascending(startAtMessage: Message?, included: Bool)
    case descending(startAtMessage: Message?, included: Bool)
    case hybrit(startAtMessage: Message)
    case none
}

enum PaginationDirection {
    case ascending
    case descending
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

enum ConversationInitializationStatus
{
    case inProgress
    case finished
}

enum ChatType
{
    case _private
    case _group
}

