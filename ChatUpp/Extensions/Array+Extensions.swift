//
//  Array+Extensions.swift
//  ChatUpp
//
//  Created by Andrei Pripa on 10/16/24.
//

import Foundation

extension Array where Element == ConversationMessageGroup
{
    mutating func removeCellViewModel(at indexPath: IndexPath) {
        self[indexPath.section].cellViewModels.remove(at: indexPath.row)
    }
    
    func getCellViewModel(at indexPath: IndexPath) -> ConversationCellViewModel {
        return self[indexPath.section].cellViewModels[indexPath.row]
    }
    
    func contains(elementWithID id: String) -> Bool {
        let existingMessageIDs: Set<String> = Set(self.flatMap { $0.cellViewModels.map { $0.cellMessage.id } })
        return existingMessageIDs.contains(id)
    }
}
