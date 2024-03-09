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
        
        let viewModel = conversationViewModel.cellViewModels[indexPath.item]
       
        cell.configureCell(usingViewModel: viewModel)
    
        let authUserID = conversationViewModel.authenticatedUserID
        if viewModel.cellMessage.senderId == authUserID {
            cell.adjustMessageSide(.right)
        } else {
            cell.adjustMessageSide(.left)
        }
        
//        if viewModel.cellMessage.messageBody == "Mikey" || viewModel.cellMessage.messageBody == "Yy" {
//            print("Yeah")
//        }
//        if !viewModel.cellMessage.messageSeen && viewModel.cellMessage.senderId != authUserID {
//            guard let chatID = conversationViewModel.conversation else {return cell}
//            let messageID = viewModel.cellMessage.id
//
//            Task {
//                try await cell.cellViewModel.updateMessageSeenStatus(messageID, inChat: chatID.id)
//            }
//        }
        
        return cell
    }
}




