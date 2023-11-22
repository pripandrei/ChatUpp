//
//  ConversationViewDataSource.swift
//  ChatUpp
//
//  Created by Andrei Pripa on 10/17/23.
//

import UIKit

class ConversationViewDataSource: NSObject, UICollectionViewDataSource {
    
    var conversationViewModel: ConversationViewModel!
    
    init(conversationViewModel: ConversationViewModel) {
        self.conversationViewModel = conversationViewModel
        super.init()
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return conversationViewModel.cellViewModels.value.count
    }

    func collectionView(_ collectionView: UICollectionView,
                        cellForItemAt indexPath: IndexPath) -> UICollectionViewCell
    {
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: CellIdentifire.conversationMessageCell, for: indexPath) as? ConversationCollectionViewCell else { fatalError("Could not dequeu custom collection cell") }
        
        
        cell.configureCell(usingViewModel: conversationViewModel.cellViewModels.value[indexPath.item])
        
//        cell.messageContainer.text = conversationViewModel.cellViewModels[indexPath.item].messageText
//        cell.messageContainer.text = conversationViewModel.messages.value[indexPath.item].messageBody
        
        cell.mainCellContainerMaxWidth = collectionView.bounds.width
        
        let authUserID = conversationViewModel.authenticatedUserID
        if conversationViewModel.cellViewModels.value[indexPath.item].senderId == authUserID {
            cell.adjustMessageSide(.right)
        } else {
            cell.adjustMessageSide(.left)
        }
        cell.handleMessageBubbleLayout()

        return cell
    }
}
