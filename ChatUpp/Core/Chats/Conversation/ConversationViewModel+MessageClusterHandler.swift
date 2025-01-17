////
////  ConversationViewModel+MessageClusterHandler.swift
////  ChatUpp
////
////  Created by Andrei Pripa on 1/16/25.
////
//
//import Foundation
//import Combine
//
//// MARK: - messageCluster functions
//extension ConversationViewModel
//{
//    private func createMessageClustersWith(_ messages: [Message], ascending: Bool? = nil)
//    {
//        var dateToIndex = Dictionary(uniqueKeysWithValues: self.messageClusters.enumerated().map { ($0.element.date, $0.offset) })
//        var tempMessageClusters = self.messageClusters
//
//        messages.forEach { message in
//            guard let date = message.timestamp.formatToYearMonthDay() else { return }
//            let messageItem = MessageItem(message: message)
//
//            if let index = dateToIndex[date] {
//                ascending == true
//                    ? tempMessageClusters[index].items.insert(messageItem, at: 0)
//                    : tempMessageClusters[index].items.append(messageItem)
//            } else {
//                let newCluster = MessageCluster(date: date, items: [messageItem])
//                if ascending == true {
//                    tempMessageClusters.insert(newCluster, at: 0)
//                    dateToIndex[date] = 0
//                } else {
//                    tempMessageClusters.append(newCluster)
//                    dateToIndex[date] = tempMessageClusters.count - 1
//                }
//            }
//        }
//        self.messageClusters = tempMessageClusters
//    }
//
//    @MainActor
//    private func prepareMessageClustersUpdate(withMessages messages: [Message], inAscendingOrder: Bool) async throws -> ([IndexPath], IndexSet?)
//    {
//        let messageClustersBeforeUpdate = messageClusters
//        let startSectionCount = inAscendingOrder ? 0 : messageClusters.count
//        
//        createMessageClustersWith(messages, ascending: inAscendingOrder)
//        
//        let endSectionCount = inAscendingOrder ? (messageClusters.count - messageClustersBeforeUpdate.count) : messageClusters.count
//        
//        let newRows = findNewRowIndexPaths(inMessageClusters: messageClustersBeforeUpdate, ascending: inAscendingOrder)
//        let newSections = findNewSectionIndexSet(startSectionCount: startSectionCount, endSectionCount: endSectionCount)
//        
//        return (newRows, newSections)
//    }
//    
//    @MainActor
//    func handleAdditionalMessageClusterUpdate(inAscendingOrder order: Bool) async throws -> ([IndexPath], IndexSet?)? {
//        
//        let newMessages = try await loadAdditionalMessages(inAscendingOrder: order)
//        guard !newMessages.isEmpty else { return nil }
//        
//        let (newRows, newSections) = try await prepareMessageClustersUpdate(withMessages: newMessages, inAscendingOrder: order)
//        
//        if let timestamp = newMessages.first?.timestamp
//        {
//            messageListenerService.addListenerToExistingMessages(startAtTimestamp: timestamp, ascending: order)
//        }
//        realmService.addMessagesToConversationInRealm(newMessages)
//        
//        return (newRows, newSections)
//    }
//    
//    private func findNewRowIndexPaths(inMessageClusters messageClusters: [MessageCluster], ascending: Bool) -> [IndexPath]
//    {
//        guard let sectionBeforeUpdate = ascending ? messageClusters.first?.items : messageClusters.last?.items else {return []}
//        
//        let sectionIndex = ascending ? 0 : messageClusters.count - 1
//        
//        return self.messageClusters[sectionIndex].items
//            .enumerated()
//            .compactMap { index, viewModel in
//                return sectionBeforeUpdate.contains { $0.message == viewModel.message }
//                ? nil
//                : IndexPath(row: index, section: sectionIndex)
//            }
//    }
//    
//    private func findNewSectionIndexSet(startSectionCount: Int, endSectionCount: Int) -> IndexSet?
//    {
//        return (startSectionCount < endSectionCount)
//        ? IndexSet(integersIn: startSectionCount..<endSectionCount)
//        : nil
//    }
//}
