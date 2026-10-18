//
//  ConversationViewModel+Extensions.swift
//  ChatUpp
//
//  Created by Andrei Pripa on 1/16/25.
//

import Foundation

protocol MessageClusterRepositoryProtocol: AnyObject, ChatRoomDataSourceProviding
{
    func addMessages(_ messages: [Message])
    func insertMessagesInOrder(_ messages: [Message])
}


final class MessageClusterRepository: MessageClusterRepositoryProtocol
{
    /// `messageClusters` is always kept in ASCENDING chronological order:
    /// index 0 is the oldest day/message, the last index is the newest.
    /// The table view renders top -> bottom in exactly this order.
    @Published var messageClusters: [MessageCluster] = []
    
    func addMessages(_ messages: [Message])
    {
        insertMessagesInOrder(messages)
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
                
                // keep clusters date-ascending: insert before the first newer day
                let insertionIndex = tempClusters.firstIndex { $0.date > date } ?? tempClusters.count
                tempClusters.insert(newCluster, at: insertionIndex)
                
                for i in insertionIndex..<tempClusters.count {
                    dateToClusterIndex[tempClusters[i].date] = i
                }
                
                clusterIndex = insertionIndex
            }
            
            // keep items timestamp-ascending: insert before the first newer message
            let insertionIndex = tempClusters[clusterIndex].items.firstIndex {
                guard let existingTimestamp = $0.message?.timestamp else { return false }
                return existingTimestamp > message.timestamp
            } ?? tempClusters[clusterIndex].items.count
            
            tempClusters[clusterIndex].items.insert(newItem, at: insertionIndex)
        }
        
        self.messageClusters = tempClusters
    }
}
