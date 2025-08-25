//
//  ConversationViewDataSource.swift
//  ChatUpp
//
//  Created by Andrei Pripa on 10/17/23.
//

import UIKit
import SkeletonView


extension ConversationDataSourceManager
{
    enum Section: Hashable
    {
        case date(Date)
    }
    
    enum InsertPosition {
        case beginning
        case end
    }
    
    typealias DataSource = UITableViewDiffableDataSource<Section,MessageCellViewModel>
    typealias Snapshot = NSDiffableDataSourceSnapshot<Section,MessageCellViewModel>
}

//MARK: - Dequeue cell
extension ConversationDataSourceManager
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
        cell.configureCell(using: viewModel,
                           layoutConfiguration: messageLayoutConfiguration)
        
        cell.containerStackView.handleContentRelayout = { [weak tableView] in
            guard let tableView else {return}
            tableView.beginUpdates()
            tableView.endUpdates()
        }
        return cell
    }
}

final class ConversationDataSourceManager
{
    private var diffableDataSource :DataSource!
    private var tableView: UITableView!
    
    private var viewModel: ChatRoomViewModel!
    
    init(conversationViewModel: ChatRoomViewModel,
         tableView: UITableView)
    {
        self.viewModel = conversationViewModel
        self.tableView = tableView
        self.diffableDataSource = makeDataSource()
        self.configureSnapshot()
    }
    
    private func makeDataSource() -> DataSource
    {
        let dataSource = DataSource(tableView: tableView,
                                    cellProvider:
                                        { tableView, indexPath, cellViewModel in
            
            if cellViewModel.displayUnseenMessagesTitle == true
            {
                return self.dequeueUnseenTitleCell(for: indexPath, in: tableView)
            }
            
            if cellViewModel.message?.type == .title {
                return self.dequeueMessageEventCell(for: indexPath, in: tableView, with: cellViewModel)
            }
            
            return self.dequeueMessageCell(for: indexPath, in: tableView, with: cellViewModel)
        })
        return dataSource
    }
    
    func configureSnapshot(
        animationType: DatasourceRowAnimation = .none,
        completion: @escaping () -> Void = {}
    )
    {
        var snapshot = NSDiffableDataSourceSnapshot<Section, MessageCellViewModel>()
        
        for cluster in viewModel.messageClusters
        {
            let section: Section = .date(cluster.date)
            snapshot.appendSections([section])
            snapshot.appendItems(cluster.items, toSection: section)
        }
        
        let shouldAnimate: Bool = animationType.animation != .none
        diffableDataSource.defaultRowAnimation = animationType.animation

        diffableDataSource.apply(snapshot,
                                 animatingDifferences: shouldAnimate)
        {
            completion()
        }
    }
    
//    private func offsetContentBack()
//    {
//        visibleCell = self.rootView.tableView.visibleCells.first as? MessageTableViewCell
//        if self.tableView.contentOffset.y < -97.5
//        {
//            if let visibleCell = visibleCell,
//               let indexPathOfVisibleCell = self.tableView.indexPath(for: visibleCell)
//            {
//                let lastCellRect = self.tableView.rectForRow(at: indexPathOfVisibleCell)
//                self.tableView.contentOffset.y = currentOffsetY + lastCellRect.minY
//            }
//        }
//    }
    
//    func updateDataSourceSnapshot(_ item: MessageCellViewModel)
//    {
//        var snapshot = diffableDataSource.snapshot()
//        snapshot.reloadItems([item])
//        diffableDataSource.defaultRowAnimation = .left
//        diffableDataSource.apply(snapshot, animatingDifferences: true)
//    }
    
    func updateTest(_ update: MessagesUpdateType,
                    insertPosition: InsertPosition = .beginning)
    {
        var snapshot = diffableDataSource.snapshot()
        print(snapshot.itemIdentifiers.count)
        switch update {
        case .updated(let items):
            snapshot.reloadItems(items)
            diffableDataSource.defaultRowAnimation = .left
        case .removed(let items):
            snapshot.deleteItems(items)
            diffableDataSource.defaultRowAnimation = .fade
        case .added(let items):
            addItems(items,
                     insertPosition: insertPosition,
                     snapshot: &snapshot)
        }
        diffableDataSource.apply(snapshot,
                                 animatingDifferences: true)
    }
    
    private func addItems(_ vms: [MessageCellViewModel],
                          insertPosition: InsertPosition = .beginning,
                          snapshot: inout Snapshot)
    {
        guard !vms.isEmpty else { return }
        
        for vm in vms
        {
            let date = vm.message?.timestamp.formatToYearMonthDay() ?? Date()
            let section = Section.date(date)
            
            // Ensure section exists
            if !snapshot.sectionIdentifiers.contains(section)
            {
                switch insertPosition {
                case .beginning:
                    if let firstSection = snapshot.sectionIdentifiers.first {
                        snapshot.insertSections([section], beforeSection: firstSection)
                    } else {
                        // No existing sections, just append
                        snapshot.appendSections([section])
                    }
                case .end:
                    snapshot.appendSections([section])
                }
            }
            
            // Update or insert item
            if snapshot.indexOfItem(vm) != nil {
                snapshot.reloadItems([vm])
            } else {
                switch insertPosition {
                case .beginning:
                    let firstItem = snapshot.itemIdentifiers(inSection: section).first
                    if let firstItem = firstItem {
                        snapshot.insertItems([vm], beforeItem: firstItem)
                    } else {
                        snapshot.appendItems([vm], toSection: section)
                    }
                case .end:
                    snapshot.appendItems([vm], toSection: section)
                }
            }
        }
    }
}

extension ConversationDataSourceManager
{
    private func makeLayoutConfigurationForCell(at indexPath: IndexPath) -> MessageLayoutConfiguration
    {
        let chatType: ChatType = viewModel.conversation?.isGroup == true ? ._group : ._private
        
        let showUserAvatar = (chatType == ._group) ? shouldShowUserAvatarForCell(at: indexPath) : false
        
        let showSenderName = (chatType == ._group) ? shouldShowSenderName(at: indexPath) : false
        
        let configuration = MessageLayoutConfiguration
            .getLayoutConfiguration(for: chatType,
                                    showSenderName: showSenderName,
                                    showAvatar: showUserAvatar)
        
        return configuration
    }
    
    private func shouldShowUserAvatarForCell(at indexPath: IndexPath) -> Bool
    {
        let messageItems = viewModel.messageClusters[indexPath.section].items
        
        guard messageItems[indexPath.row].messageAlignment == .left else { return false }
        
        guard indexPath.row > 0 else { return true }
        
        guard
            let currentMessage = messageItems[indexPath.row].message,
            let previousMessage = messageItems[indexPath.row - 1].message
        else {
            return false
        }
        
        guard currentMessage.type != .title else { return false }
        guard previousMessage.type != .title else { return true }
        
        return currentMessage.senderId != previousMessage.senderId
    }
    
    private func shouldShowSenderName(at indexPath: IndexPath) -> Bool
    {
        let messageItems = viewModel.messageClusters[indexPath.section].items
        guard messageItems[indexPath.row].messageAlignment == .left else
        { return false }
        guard indexPath.row < messageItems.count - 1 else { return true }
        
        guard
            let currentMessage = messageItems[indexPath.row].message,
            let nextMessage = messageItems[indexPath.row + 1].message
        else {
            return false
        }
        
        guard currentMessage.type != .title else { return false }
        guard nextMessage.type != .title else { return true }
        
        return currentMessage.senderId != nextMessage.senderId
    }
}














//final class ConversationTableViewDataSource: NSObject, UITableViewDataSource
//{
//    var conversationViewModel: ChatRoomViewModel!
//    
//    init(conversationViewModel: ChatRoomViewModel) {
//        self.conversationViewModel = conversationViewModel
//        super.init()
//    }
////
//    func numberOfSections(in tableView: UITableView) -> Int {
//        return conversationViewModel.messageClusters.count
//    }
//    
//    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int
//    {
//        return conversationViewModel.messageClusters[section].items.count
//    }
//    
//    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell
//    {
//        guard (conversationViewModel.messageClusters.count - 1) >= indexPath.section && (conversationViewModel.messageClusters[indexPath.section].items.count - 1) >= indexPath.row else
//        {
//            let cell = UITableViewCell()
//            return cell
//        }
//        let viewModel = conversationViewModel.messageClusters[indexPath.section].items[indexPath.row]
//        
//        if viewModel.displayUnseenMessagesTitle == true
//        {
//            return dequeueUnseenTitleCell(for: indexPath, in: tableView)
//        }
//        
//        if viewModel.message?.type == .title {
//            return dequeueMessageEventCell(for: indexPath, in: tableView, with: viewModel)
//        }
//        
//        return dequeueMessageCell(for: indexPath, in: tableView, with: viewModel)
//    }
//}

// MARK: - Dequeue cell
//extension ConversationTableViewDataSource
//{
//    private func dequeueUnseenTitleCell(for indexPath: IndexPath,
//                                        in tableView: UITableView) -> UITableViewCell
//    {
//        guard let cell = tableView.dequeueReusableCell(
//            withIdentifier: ReuseIdentifire.ConversationTableCell.unseenTitle.identifire,
//            for: indexPath) as? UnseenMessagesTitleTableViewCell else
//        {
//            fatalError("Could not dequeue unseen title cell")
//        }
//        return cell
//    }
//    
//    private func dequeueMessageEventCell(for indexPath: IndexPath,
//                                         in tableView: UITableView,
//                                         with viewModel: MessageCellViewModel) -> UITableViewCell
//    {
//        guard let cell = tableView.dequeueReusableCell(withIdentifier: ReuseIdentifire.ConversationTableCell.eventMessage.identifire,
//                                                       for: indexPath) as? MessageEventCell else
//        {
//            fatalError("Could not dequeue unseen title cell")
//        }
//        cell.configureCell(with: viewModel)
//        return cell
//    }
//    
//    private func dequeueMessageCell(for indexPath: IndexPath,
//                                    in tableView: UITableView,
//                                    with viewModel: MessageCellViewModel) -> UITableViewCell
//    {
//        guard let cell = tableView.dequeueReusableCell(
//            withIdentifier: ReuseIdentifire.ConversationTableCell.message.identifire,
//            for: indexPath
//        ) as? MessageTableViewCell else {
//            fatalError("Could not dequeue conversation cell")
//        }
//        
//        let messageLayoutConfiguration = makeLayoutConfigurationForCell(at: indexPath)
//        cell.configureCell(using: viewModel,
//                           layoutConfiguration: messageLayoutConfiguration)
//        
//        cell.containerStackView.handleContentRelayout = { [weak tableView] in
//            guard let tableView else {return}
//            tableView.beginUpdates()
//            tableView.endUpdates()
//        }
//        return cell
//    }
//}

// MARK: - Cell layout configuration provider functions
//extension ConversationTableViewDataSource
//{
//    private func makeLayoutConfigurationForCell(at indexPath: IndexPath) -> MessageLayoutConfiguration
//    {
//        let chatType: ChatType = conversationViewModel.conversation?.isGroup == true ? ._group : ._private
//
//        let showUserAvatar = (chatType == ._group) ? shouldShowUserAvatarForCell(at: indexPath) : false
//        
//        let showSenderName = (chatType == ._group) ? shouldShowSenderName(at: indexPath) : false
//        
//        let configuration = MessageLayoutConfiguration
//            .getLayoutConfiguration(for: chatType,
//                                    showSenderName: showSenderName,
//                                    showAvatar: showUserAvatar)
//        
//        return configuration
//    }
//    
//    private func shouldShowUserAvatarForCell(at indexPath: IndexPath) -> Bool
//    {
//        let messageItems = conversationViewModel.messageClusters[indexPath.section].items
//        
//        guard messageItems[indexPath.row].messageAlignment == .left else { return false }
//        
//        guard indexPath.row > 0 else { return true }
//
//        guard
//            let currentMessage = messageItems[indexPath.row].message,
//            let previousMessage = messageItems[indexPath.row - 1].message
//        else {
//            return false
//        }
//
//        guard currentMessage.type != .title else { return false }
//        guard previousMessage.type != .title else { return true }
//
//        return currentMessage.senderId != previousMessage.senderId
//    }
//    
//    private func shouldShowSenderName(at indexPath: IndexPath) -> Bool
//    {
//        let messageItems = conversationViewModel.messageClusters[indexPath.section].items
//        guard messageItems[indexPath.row].messageAlignment == .left else
//        { return false }
//        guard indexPath.row < messageItems.count - 1 else { return true }
//        
//        guard
//            let currentMessage = messageItems[indexPath.row].message,
//            let nextMessage = messageItems[indexPath.row + 1].message
//        else {
//            return false
//        }
//
//        guard currentMessage.type != .title else { return false }
//        guard nextMessage.type != .title else { return true }
//
//        return currentMessage.senderId != nextMessage.senderId
//    }
//}

//extension TestDataSurce: SkeletonTableViewDataSource
//{
//    func collectionSkeletonView(_ skeletonView: UITableView, cellIdentifierForRowAt indexPath: IndexPath) -> ReusableCellIdentifier {
//          return ReuseIdentifire.ConversationTableCell.messageSekeleton.identifire
//       }
//}
//
//class TestDataSurce: UITableViewDiffableDataSource<Int, String>
//{}


// MARK: - SKELETONVIEW DATASOURCE - GET BACK TO IT
//extension ConversationDataSourceManager: SkeletonTableViewDataSource
//{
//    func collectionSkeletonView(_ skeletonView: UITableView, cellIdentifierForRowAt indexPath: IndexPath) -> ReusableCellIdentifier {
//       return ReuseIdentifire.ConversationTableCell.messageSekeleton.identifire
//    }
//}

extension Array {
    subscript(safe index: Int) -> Element? {
        return indices.contains(index) ? self[index] : nil
    }
}


