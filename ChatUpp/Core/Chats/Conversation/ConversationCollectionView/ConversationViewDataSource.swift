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
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return conversationViewModel.cellViewModels.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: CellIdentifire.conversationMessageCell, for: indexPath) as? ConversationCollectionViewCell else { fatalError("Could not dequeu custom collection cell") }
        
        let viewModel = conversationViewModel.cellViewModels[indexPath.item]
        let authUserID = conversationViewModel.authenticatedUserID
        let cellSide = viewModel.cellMessage.senderId == authUserID ?
        ConversationCollectionViewCell.BubbleMessageSide.right : ConversationCollectionViewCell.BubbleMessageSide.left
        
        cell.configureCell(usingViewModel: viewModel, forSide: cellSide)
        
        return cell
    }
    
}




