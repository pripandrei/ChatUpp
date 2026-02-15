//
//  ConversationViewModel+Extensions.swift
//  ChatUpp
//
//  Created by Andrei Pripa on 1/16/25.
//

import Foundation

//MARK: - Model representing section of messages
//extension ChatRoomViewModel: ChatRoomDataSourceProviding
//{
//    typealias MessageItem = MessageCellViewModel
//    
//    struct MessageCluster: Hashable
//    {
//        let id: UUID
//        let date: Date
//        var items: [MessageCellViewModel]
//        
//        init(id: UUID = UUID(), date: Date, items: [MessageItem])
//        {
//            self.id = id
//            self.date = date
//            self.items = items
//        }
//        
//        func hash(into hasher: inout Hasher) {
//            hasher.combine(id)
//        }
//        
//        static func ==(lhs: MessageCluster, rhs: MessageCluster) -> Bool
//        {
//            lhs.id == rhs.id
//        }
//    }
//}

typealias MessageItem = MessageCellViewModel

struct MessageCluster: Hashable
{
    let id: UUID
    let date: Date
    var items: [MessageCellViewModel]
    
    init(id: UUID = UUID(), date: Date, items: [MessageItem])
    {
        self.id = id
        self.date = date
        self.items = items
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    static func ==(lhs: MessageCluster, rhs: MessageCluster) -> Bool
    {
        lhs.id == rhs.id
    }
}

protocol MessageClusterRepositoryProtocol: AnyObject, ChatRoomDataSourceProviding
{
    func addMessages(_ messages: [Message])
    func insertMessagesInOrder(_ messages: [Message])
}


final class MessageClusterRepository: MessageClusterRepositoryProtocol
{
    @Published var messageClusters: [MessageCluster] = []
    {
        didSet
        {
            print("messageClusters: ", messageClusters)
        }
    }
    
    func addMessages(_ messages: [Message])
    {
        guard !messages.isEmpty else { return  }
        
        var dateToClusterIndex = Dictionary(uniqueKeysWithValues: self.messageClusters
            .enumerated()
            .map { ($0.element.date, $0.offset) }
        )
        var tempMessageClusters = self.messageClusters
        
        // Determine insertion direction by comparing timestamps
        let isAscendingInsertion = {
            guard let firstCurrent = self.messageClusters.first?.items.first?.message?.timestamp,
                  let lastNew = messages.last?.timestamp else
            {
                return true /// since table view is inverted, return true
            }
            return lastNew > firstCurrent
        }()
        
        for message in messages
        {
            guard let date = message.timestamp.formatToYearMonthDay() else { continue }
            
            let messageItem = MessageItem(message: message)
            
            if let index = dateToClusterIndex[date]
            {
                if isAscendingInsertion {
                    tempMessageClusters[index].items.insert(messageItem, at: 0)
                } else {
                    tempMessageClusters[index].items.append(messageItem)
                }
            } else
            {
                let newCluster = MessageCluster(date: date, items: [messageItem])
                if isAscendingInsertion {
                    tempMessageClusters.insert(newCluster, at: 0)
                    dateToClusterIndex[date] = 0
                } else {
                    tempMessageClusters.append(newCluster)
                    dateToClusterIndex[date] = tempMessageClusters.count - 1
                }
            }
        }
        
        self.messageClusters = tempMessageClusters
    }
    
    func insertMessagesInOrder(_ messages: [Message])
    {
        guard !messages.isEmpty else { return }
        
        var tempClusters = self.messageClusters
        var dateToClusterIndex: [Date: Int] = Dictionary(
            uniqueKeysWithValues: tempClusters.enumerated().map { ($0.element.date, $0.offset) }
        )
        
        for message in messages {
            guard let date = message.timestamp.formatToYearMonthDay() else { continue }
            let newItem = MessageItem(message: message)
            
            let clusterIndex: Int
            if let existingIndex = dateToClusterIndex[date] {
                clusterIndex = existingIndex
            } else {
                let newCluster = MessageCluster(date: date, items: [])
                let insertionIndex = tempClusters.firstIndex { $0.date > date } ?? tempClusters.count
                tempClusters.insert(newCluster, at: insertionIndex)
                
                // More efficient: rebuild affected portion of map
                for i in insertionIndex..<tempClusters.count {
                    dateToClusterIndex[tempClusters[i].date] = i
                }
                
                clusterIndex = insertionIndex
            }
            
            // Insert message in sorted order inside cluster
            let insertionIndex = tempClusters[clusterIndex].items.firstIndex {
                guard let existingTimestamp = $0.message?.timestamp else { return false }
                return existingTimestamp > message.timestamp
            } ?? tempClusters[clusterIndex].items.count
            
            tempClusters[clusterIndex].items.insert(newItem, at: insertionIndex)
        }
        
        self.messageClusters = tempClusters
    }
}
