//
//  ConversationViewDataSource.swift
//  ChatUpp
//
//  Created by Andrei Pripa on 10/17/23.
//

import UIKit

final class ConversationViewDataSource: NSObject, UICollectionViewDataSource {
    
    var conversationViewModel: ConversationViewModel!
    
    init(conversationViewModel: ConversationViewModel) {
        self.conversationViewModel = conversationViewModel
        super.init()
    }
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return conversationViewModel.cellViewModels.count
    }

    func collectionView(_ collectionView: UICollectionView,
                        cellForItemAt indexPath: IndexPath) -> UICollectionViewCell
    {
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: CellIdentifire.conversationMessageCell, for: indexPath) as? ConversationCollectionViewCell else { fatalError("Could not dequeu custom collection cell") }
        
        
        cell.mainCellContainerMaxWidth = collectionView.bounds.width
        cell.configureCell(usingViewModel: conversationViewModel.cellViewModels[indexPath.item])
        
//        cell.messageContainer.text = conversationViewModel.cellViewModels[indexPath.item].messageText
//        cell.messageContainer.text = conversationViewModel.messages[indexPath.item].messageBody
        
        
        let authUserID = conversationViewModel.authenticatedUserID
        if conversationViewModel.cellViewModels[indexPath.item].senderId == authUserID {
            cell.adjustMessageSide(.right)
        } else {
            cell.adjustMessageSide(.left)
        }
        cell.handleMessageBubbleLayout()
//        print("CELL FRAME SIZE",cell.frame.size)
//        print("messageContainer FRAME SIZE",cell.messageContainer.frame.size)
//        print("messageContainer intrinsic FRAME SIZE",cell.intrinsicContentSize)
        return cell
    }
}




