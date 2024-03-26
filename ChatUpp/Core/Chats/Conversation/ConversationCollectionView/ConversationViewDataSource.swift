//
//  ConversationViewDataSource.swift
//  ChatUpp
//
//  Created by Andrei Pripa on 10/17/23.
//

import UIKit

final class ConversationViewDataSource: NSObject, UITableViewDataSource {
    var conversationViewModel: ConversationViewModel!
    
    init(conversationViewModel: ConversationViewModel) {
        self.conversationViewModel = conversationViewModel
        super.init()
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return conversationViewModel.cellMessageGroups.count
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return conversationViewModel.cellMessageGroups[section].cellViewModels.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: CellIdentifire.conversationMessageCell, for: indexPath) as? ConversationCollectionViewCell else { fatalError("Could not dequeu custom collection cell") }
        
//        let viewModel = conversationViewModel.cellViewModels[indexPath.section][indexPath.row]
        let viewModel = conversationViewModel.cellMessageGroups[indexPath.section].cellViewModels[indexPath.row]
//        let message = conversationViewModel.cellMessageGroups[indexPath.section].messages[indexPath.row]
        let message = viewModel.cellMessage
        let authUserID = conversationViewModel.authenticatedUserID
        let cellSide = message.senderId == authUserID ?
        ConversationCollectionViewCell.BubbleMessageSide.right : ConversationCollectionViewCell.BubbleMessageSide.left
        
        cell.configureCell(usingViewModel: viewModel, forSide: cellSide)
        
        return cell
    }
    
}




