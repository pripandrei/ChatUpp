//
//  ConversationViewDataSource.swift
//  ChatUpp
//
//  Created by Andrei Pripa on 10/17/23.
//

import UIKit
import SkeletonView


final class ConversationViewDataSource: NSObject, UITableViewDataSource {
    var conversationViewModel: ConversationViewModel!
    
    init(conversationViewModel: ConversationViewModel) {
        self.conversationViewModel = conversationViewModel
        super.init()
    }
//
    func numberOfSections(in tableView: UITableView) -> Int {
        return conversationViewModel.messageGroups.count
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return conversationViewModel.messageGroups[section].cellViewModels.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: CellIdentifire.conversationMessageCell, for: indexPath) as? ConversationTableViewCell else { fatalError("Could not dequeu custom collection cell") }
    
        let viewModel = conversationViewModel.messageGroups[indexPath.section].cellViewModels[indexPath.row]
        let message = viewModel.cellMessage
        let authUserID = conversationViewModel.authenticatedUserID
        let cellSide = message.senderId == authUserID ?
        ConversationTableViewCell.BubbleMessageSide.right : ConversationTableViewCell.BubbleMessageSide.left
        
        /// set sender name and text of message messageToBeReplied if any
        if let repliedToMessageID = message.repliedTo {
            conversationViewModel.setReplyMessageData(fromReplyMessageID: repliedToMessageID, toViewModel: viewModel)
        }
        cell.configureCell(usingViewModel: viewModel, forSide: cellSide)

        return cell
    }
}


// MARK: - SKELETONVIEW DATASOURCE
extension ConversationViewDataSource: SkeletonTableViewDataSource
{
    func collectionSkeletonView(_ skeletonView: UITableView, cellIdentifierForRowAt indexPath: IndexPath) -> ReusableCellIdentifier {
       return CellIdentifire.conversationSkeletonCell
    }
}
