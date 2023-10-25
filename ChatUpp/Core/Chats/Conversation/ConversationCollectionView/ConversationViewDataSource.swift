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
//        cell.label.setTitle(conversationViewModel.messages.value[indexPath.item].messageBody, for: .normal)
        cell.messageBody.text = conversationViewModel.messages.value[indexPath.item].messageBody
        
//        if cell.messageBody.text! == "Test message to be written, as I want to see the width of it" {
//            print("out", cell.messageBody.textBoundingRect.size)
//
//        }
//
        cell.customViewMaxWidth = collectionView.bounds.width
        cell.handlePositioning()
        
        
//        let targetSize = CGSize(width: collectionView.bounds.width, height: UIView.layoutFittingCompressedSize.height)
//        let size = cell.systemLayoutSizeFitting(targetSize, withHorizontalFittingPriority: .required, verticalFittingPriority: .fittingSizeLevel)

        // The `size` variable now contains the calculated height of the cell
//        let cellHeight = size.height
//        print("cellHight",cellHeight)
        return cell
    }
    
    
}
