//
//  ConversationViewDataSource.swift
//  ChatUpp
//
//  Created by Andrei Pripa on 10/17/23.
//

import UIKit

class ConversationViewDataSource: NSObject, UICollectionViewDataSource {
    
    var conversationViewModel: ConversationViewModel!
    weak var collectionView: UICollectionView!
    
    init(conversationViewModel: ConversationViewModel) {
        self.conversationViewModel = conversationViewModel
        super.init()
        self.setupBinding()
    }
    
    private func setupBinding() {
        conversationViewModel.messages.bind { [weak self] messages in
            if !messages.isEmpty {
                DispatchQueue.main.async {
                    self?.collectionView.reloadData()
                }
            }
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return conversationViewModel.messages.value.count
    }

    func collectionView(_ collectionView: UICollectionView,
                        cellForItemAt indexPath: IndexPath) -> UICollectionViewCell
    {
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: CellIdentifire.conversationMessageCell, for: indexPath) as? ConversationCollectionViewCell else { fatalError("Could not dequeu custom collection cell") }
        
        cell.messageContainer.text = conversationViewModel.messages.value[indexPath.item].messageBody
        cell.mainCellContainerMaxWidth = collectionView.bounds.width
        let authUser = (try? AuthenticationManager.shared.getAuthenticatedUser())!.uid
        if conversationViewModel.messages.value[indexPath.item].senderId == authUser {
            cell.adjustMessageSide(.right)
        } else {
            cell.adjustMessageSide(.left)
        }
        cell.handleMessageBubbleLayout()
        
        
        return cell
    }
}
