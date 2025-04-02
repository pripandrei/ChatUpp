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
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let viewModel = conversationViewModel.messageClusters[indexPath.section].items[indexPath.row]
        
        if viewModel.displayUnseenMessagesTitle == true
        {
            return dequeueUnseenTitleCell(for: indexPath, in: tableView)
        }
        
        if viewModel.message?.type == .title {
            return dequeueMessageEventCell(for: indexPath, in: tableView, with: viewModel)
        }
        
        return dequeueMessageCell(for: indexPath, in: tableView, with: viewModel)
    }
}

// MARK: - Dequeue cell
extension ConversationTableViewDataSource
{
    private func dequeueUnseenTitleCell(for indexPath: IndexPath,
                                        in tableView: UITableView) -> UITableViewCell
    {
        guard let cell = tableView.dequeueReusableCell(
            withIdentifier: ReuseIdentifire.ConversationTableCell.unseenTitle.identifire,
            for: indexPath) as? UnseenMessagesTitleTableViewCell else
        {
            fatalError("Could not dequeue unseen title cell")
        }
        return cell
    }
    
    private func dequeueMessageEventCell(for indexPath: IndexPath,
                                         in tableView: UITableView,
                                         with viewModel: MessageCellViewModel) -> UITableViewCell
    {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: ReuseIdentifire.ConversationTableCell.eventMessage.identifire,
                                                       for: indexPath) as? MessageEventCell else
        {
            fatalError("Could not dequeue unseen title cell")
        }
        cell.configureCell(with: viewModel)
        return cell
    }
    
    private func dequeueMessageCell(for indexPath: IndexPath,
                                    in tableView: UITableView,
                                    with viewModel: MessageCellViewModel) -> UITableViewCell
    {
        guard let cell = tableView.dequeueReusableCell(
            withIdentifier: ReuseIdentifire.ConversationTableCell.message.identifire,
            for: indexPath
        ) as? MessageTableViewCell else {
            fatalError("Could not dequeue conversation cell")
        }
        
        let messageLayoutConfiguration = makeLayoutConfigurationForCell(at: indexPath)
        cell.configureCell(using: viewModel, layoutConfiguration: messageLayoutConfiguration)
        
        return cell
    }
}

// MARK: - Cell layout configuration provider functions
extension ConversationTableViewDataSource
{
    private func makeLayoutConfigurationForCell(at indexPath: IndexPath) -> MessageLayoutConfiguration
    {
        let chatType: ChatType = conversationViewModel.conversation?.isGroup == true ? ._group : ._private
        var configuration = chatType.messageLayoutConfiguration
        
        if chatType == ._group {
            configuration = configuration.withUpdatedAvatar(shouldShowUserAvatarForCell(at: indexPath))
        }
        
        return configuration
    }
    
    private func shouldShowUserAvatarForCell(at indexPath: IndexPath) -> Bool
    {
        let messageItems = conversationViewModel.messageClusters[indexPath.section].items
        guard indexPath.row > 0 else { return true }
        
        return messageItems[indexPath.row].message?.senderId != messageItems[indexPath.row - 1].message?.senderId
    }
}

// MARK: - SKELETONVIEW DATASOURCE
extension ConversationTableViewDataSource: SkeletonTableViewDataSource
{
    func collectionSkeletonView(_ skeletonView: UITableView, cellIdentifierForRowAt indexPath: IndexPath) -> ReusableCellIdentifier {
       return ReuseIdentifire.ConversationTableCell.messageSekeleton.identifire
    }
}



