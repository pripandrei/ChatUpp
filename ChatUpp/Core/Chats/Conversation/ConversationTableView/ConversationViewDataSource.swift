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
//
    func numberOfSections(in tableView: UITableView) -> Int {
        return conversationViewModel.cellMessageGroups.count
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return conversationViewModel.cellMessageGroups[section].cellViewModels.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: CellIdentifire.conversationMessageCell, for: indexPath) as? ConversationTableViewCell else { fatalError("Could not dequeu custom collection cell") }
    
        let viewModel = conversationViewModel.cellMessageGroups[indexPath.section].cellViewModels[indexPath.row]
        let message = viewModel.cellMessage
        let authUserID = conversationViewModel.authenticatedUserID
        let cellSide = message.senderId == authUserID ?
        ConversationTableViewCell.BubbleMessageSide.right : ConversationTableViewCell.BubbleMessageSide.left
        
        /// set sender name and text of message messageToBeReplied if any
        if let repliedToMessageID = message.repliedTo {
            if let messageToBeReplied = conversationViewModel.getRepliedToMessage(messageID: repliedToMessageID) {
                let senderNameOfMessageToBeReplied = conversationViewModel.getMessageSenderName(usingSenderID: messageToBeReplied.senderId)
                (viewModel.senderNameOfMessageToBeReplied, viewModel.textOfMessageToBeReplied) = (senderNameOfMessageToBeReplied, messageToBeReplied.messageBody)
            }
        }
        
//        let messageToBeReplied: Message? = (message.repliedTo != nil) ? conversationViewModel.getRepliedToMessage(messageID: message.repliedTo!) : nil
//        let senderNameOfMessageToBeReplied = conversationViewModel.getMessageSenderName(usingSenderID: messageToBeReplied?.senderId)
//        
//        viewModel.messageToBeReplied = messageToBeReplied
        cell.configureCell(usingViewModel: viewModel, forSide: cellSide)
        
        return cell
    }
    
}




