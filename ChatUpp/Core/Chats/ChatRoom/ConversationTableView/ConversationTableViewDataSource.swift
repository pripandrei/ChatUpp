//
//  ConversationViewDataSource.swift
//  ChatUpp
//
//  Created by Andrei Pripa on 10/17/23.
//

import UIKit
import SkeletonView


final class ConversationTableViewDataSource: NSObject, UITableViewDataSource
{
    var conversationViewModel: ChatRoomViewModel!
    
    init(conversationViewModel: ChatRoomViewModel) {
        self.conversationViewModel = conversationViewModel
        super.init()
    }
//
    func numberOfSections(in tableView: UITableView) -> Int {
        return conversationViewModel.messageClusters.count
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return conversationViewModel.messageClusters[section].items.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell
    {
        let viewModel = conversationViewModel.messageClusters[indexPath.section].items[indexPath.row]
        
        if viewModel.displayUnseenMessagesTitle == true {
            guard let cell = tableView.dequeueReusableCell(withIdentifier: ReuseIdentifire.ConversationTableCell.unseenTitle.identifire, for: indexPath) as? ConversationTableViewTitleCell else { fatalError("Could not dequeu custom collection cell") }
            return cell
        }
        
        guard let cell = tableView.dequeueReusableCell(withIdentifier: ReuseIdentifire.ConversationTableCell.message.identifire, for: indexPath) as? ConversationTableViewCell else { fatalError("Could not dequeu custom collection cell") }

        let message = viewModel.message
        let authUserID = conversationViewModel.authUser.uid
        
        let cellSide = message?.senderId == authUserID ?
        ConversationTableViewCell.MessageSide.right : ConversationTableViewCell.MessageSide.left
        
        /// set sender name and text of message messageToBeReplied if any
        if let repliedToMessageID = message?.repliedTo {
            conversationViewModel.setReplyMessageData(fromReplyMessageID: repliedToMessageID, toViewModel: viewModel)
        }
        
        let messageLayoutConfiguration = makeLayoutConfigurationForCell(at: indexPath)
        
        cell.configureCell(usingViewModel: viewModel,
                           layoutConfiguration: messageLayoutConfiguration,
                           forSide: cellSide)

        return cell
    }
    
    private func makeLayoutConfigurationForCell(at indexPath: IndexPath) -> MessageLayoutConfiguration
    {
        let chatType: ChatType = ((conversationViewModel.conversation?.isGroup) != nil) ? ._group : ._private
        var messageLayoutConfiguration = MessageLayoutConfigurationFactory.makeConfiguration(for: chatType)
        
        if chatType == ._group {
            let shouldShowUserAvatar = shouldShowAvatarForCell(at: indexPath)
            messageLayoutConfiguration.shouldShowAvatar = shouldShowUserAvatar
        }
        
        return messageLayoutConfiguration
    }
    
    private func shouldShowAvatarForCell(at indexPath: IndexPath) -> Bool
    {
        if indexPath.row == 0 { return true }
        let messageItems = conversationViewModel.messageClusters[indexPath.section].items
        return messageItems[indexPath.row].message?.senderId != messageItems[indexPath.row - 1].message?.senderId
    }
    
    //    private func establishCellMessageSide(for indexPath: IndexPath) -> MessageSide {
    //
    //    }
}


// MARK: - SKELETONVIEW DATASOURCE
extension ConversationTableViewDataSource: SkeletonTableViewDataSource
{
    func collectionSkeletonView(_ skeletonView: UITableView, cellIdentifierForRowAt indexPath: IndexPath) -> ReusableCellIdentifier {
       return ReuseIdentifire.ConversationTableCell.messageSekeleton.identifire
    }
}
