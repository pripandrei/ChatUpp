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
    case reactions
    
    var animationType: UITableView.RowAnimation {
        switch self {
        case .text: return .left
        case .seenStatus: return .none
        case .reactions: return .none
        }
    }
}

enum MessageChangeType {
    case modified(IndexPath, MessageValueModification)
    case added(message: Message)
    case removed(IndexPath, isLastItemInSection: Bool)
}

enum MessageFetchStrategy
{
    case ascending(startAtMessage: Message?, included: Bool)
    case descending(startAtMessage: Message?, included: Bool)
    case hybrit(startAtMessage: Message)
    case none
    
//    func fetch(from objectID: String) async throws -> [Message] {
//        switch self
//        {
//        case .ascending(let startAtMessage, let included):
//            return try await FirebaseChatService.shared.fetchMessagesFromChat(
//                chatID: objectID,
//                startingFrom: startAtMessage?.id,
//                inclusive: included,
//                fetchDirection: .ascending
//            )
//        case .descending(let startAtMessage, let included):
//            return try await FirebaseChatService.shared.fetchMessagesFromChat(
//                chatID: objectID,
//                startingFrom: startAtMessage?.id,
//                inclusive: included,
//                fetchDirection: .descending
//            )
//        case .hybrit(let startAtMessage):
//            let descendingMessages = try await FirebaseChatService.shared.fetchMessagesFromChat(
//                chatID: objectID,
//                startingFrom: startAtMessage.id,
//                inclusive: true,
//                fetchDirection: .descending
//            )
//            let ascendingMessages = try await FirebaseChatService.shared.fetchMessagesFromChat(
//                chatID: objectID,
//                startingFrom: startAtMessage.id,
//                inclusive: false,
//                fetchDirection: .ascending
//            )
//            return descendingMessages + ascendingMessages
//        default: return []
//        }
//    }
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
