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
        return conversationViewModel.cellViewModels.count
    }

    func collectionView(_ collectionView: UICollectionView,
                        cellForItemAt indexPath: IndexPath) -> UICollectionViewCell
    {
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: CellIdentifire.conversationMessageCell, for: indexPath) as? ConversationCollectionViewCell else { fatalError("Could not dequeu custom collection cell") }
        
        
        cell.messageContainer.text = conversationViewModel.cellViewModels[indexPath.item].messageText
        
        cell.mainCellContainerMaxWidth = collectionView.bounds.width
        
        let authUserID = conversationViewModel.authenticatedUserID
        if conversationViewModel.cellViewModels[indexPath.item].senderId == authUserID {
            cell.adjustMessageSide(.right)
        } else {
            cell.adjustMessageSide(.left)
        }
        cell.handleMessageBubbleLayout()
        
        if indexPath.item == 0 {
            print("0")
        }
    
        return cell
    }
    
    
}
