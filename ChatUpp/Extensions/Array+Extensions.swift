//
//  Array+Extensions.swift
//  ChatUpp
//
//  Created by Andrei Pripa on 10/16/24.
//

import Foundation

extension Array where Element == ConversationViewModel.MessageCluster
{
    mutating func removeClusterItem(at indexPath: IndexPath) {
        self[indexPath.section].items.remove(at: indexPath.row)
    }

    func getCellViewModel(at indexPath: IndexPath) -> MessageCellViewModel {
        return self[indexPath.section].items[indexPath.row]
    }
    
    func contains(elementWithID id: String) -> Bool {
        let existingMessageIDs: Set<String> = Set(self.flatMap { $0.items.compactMap { $0.message?.id } })
        return existingMessageIDs.contains(id)
    }
}

extension Array where Element: Equatable
{
    mutating func move(element: Element, toIndex destinationIndex: Int) {
        guard let elementIndex = self.firstIndex(of: element) else {return}
        let removedElement = self.remove(at: elementIndex)
        insert(removedElement, at: destinationIndex)
    }
}
