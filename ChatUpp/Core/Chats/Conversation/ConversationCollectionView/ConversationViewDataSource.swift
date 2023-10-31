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
            guard let self = self else {return}
            if !messages.isEmpty {
                DispatchQueue.main.async {
                    self.collectionView.reloadData()
                    let indexPath = IndexPath(item: self.conversationViewModel.messages.value.count - 1, section: 0)
                    self.collectionView.scrollToItem(at: indexPath, at: .bottom, animated: false)
                    let contentInset = UIEdgeInsets(top: 0, left: 0, bottom: 10, right: 0)
                    self.collectionView.contentInset = contentInset
                }
            }
        }
    }
    
    
    
    func scrollToBottom() {
        if collectionView.contentSize.height > collectionView.frame.size.height {
            let offset = CGPoint(x: 0, y: collectionView.contentSize.height + collectionView.frame.size.height)
            collectionView.setContentOffset(offset, animated: false)
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
        
        let authUserID = conversationViewModel.authenticatedUserID
        if conversationViewModel.messages.value[indexPath.item].senderId == authUserID {
            cell.adjustMessageSide(.right)
        } else {
            cell.adjustMessageSide(.left)
        }
        cell.handleMessageBubbleLayout()
    
        return cell
    }
    
    
}
