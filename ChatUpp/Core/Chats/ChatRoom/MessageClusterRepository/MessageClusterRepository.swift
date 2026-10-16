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
    @Published var messageClusters: [MessageCluster] = []
    
    func addMessages(_ messages: [Message])
    {
        insertMessagesInOrder(messages)
    }
    
    func insertMessagesInOrder(_ messages: [Message]) {
        guard !messages.isEmpty else { return }
        
        var tempClusters = self.messageClusters
        
        for message in messages.sorted(by: { $0.timestamp < $1.timestamp }) {
            guard let date = message.timestamp.formatToYearMonthDay() else { continue }

            // Listener snapshots can contain a message that was already loaded
            // locally. Keep the existing cell view model so diffable data source
            // identity remains stable.
            guard !tempClusters.contains(where: { cluster in
                cluster.items.contains { $0.message?.id == message.id }
            }) else { continue }

            let newItem = MessageItem(message: message)
            
            let clusterIndex: Int
            if let existingIndex = tempClusters.firstIndex(where: { $0.date == date }) {
                clusterIndex = existingIndex
            } else {
                let newCluster = MessageCluster(date: date, items: [])
                
                let insertionIndex = tempClusters.firstIndex { $0.date > date } ?? tempClusters.count
                tempClusters.insert(newCluster, at: insertionIndex)
                clusterIndex = insertionIndex
            }
            
            let insertionIndex = tempClusters[clusterIndex].items.firstIndex {
                guard let existingTimestamp = $0.message?.timestamp else { return false }
                return existingTimestamp > message.timestamp
            } ?? tempClusters[clusterIndex].items.count
            
            tempClusters[clusterIndex].items.insert(newItem, at: insertionIndex)
        }
        
        self.messageClusters = tempClusters
    }
}
