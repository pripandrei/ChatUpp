//
//  ConversationViewDataSource.swift
//  ChatUpp
//
//  Created by Andrei Pripa on 10/17/23.
//

import UIKit
import SkeletonView

protocol DataSourceProviding {
    var messageClusters : [ChatRoomViewModel.MessageCluster] { get }
}

fileprivate class ConversationTableViewDataSource: UITableViewDiffableDataSource<Section,MessageCellViewModel>
{}

extension ConversationDataSourceManager
{
    private typealias DataSource = ConversationTableViewDataSource
    private typealias Snapshot = NSDiffableDataSourceSnapshot<Section, MessageCellViewModel>
}

final class ConversationDataSourceManager
{
    private var dataProvider: DataSourceProviding
    private var layoutProvider: MessageLayoutProvider
    private var diffableDataSource: DataSource!
    private var tableView: UITableView
    
    init(dataProvider: DataSourceProviding,
         layoutProvider: MessageLayoutProvider,
         tableView: UITableView)
    {
        self.dataProvider = dataProvider
        self.layoutProvider = layoutProvider
        self.tableView = tableView
        self.diffableDataSource = makeDataSource()
        self.configureSnapshot()
    }
    
    deinit
    {
        print("ConversationDataSourceManager -- dienit")
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
        
        for cluster in dataProvider.messageClusters
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
//    
//    func updateTest(_ update: MessagesUpdateType,
//                    insertPosition: InsertPosition = .beginning, completion: @escaping () -> Void)
//    {
//        var snapshot = diffableDataSource.snapshot()
//        print(snapshot.itemIdentifiers.count)
//        switch update {
//        case .updated(let items):
//            snapshot.reloadItems(items)
//            diffableDataSource.defaultRowAnimation = .left
//        case .removed(let items):
//            snapshot.deleteItems(items)
//            diffableDataSource.defaultRowAnimation = .fade
//        case .added(let items):
//            diffableDataSource.defaultRowAnimation = .none
//            addItems(items,
//                     insertPosition: insertPosition,
//                     snapshot: &snapshot)
//        }
//        diffableDataSource.apply(snapshot,
//                                 animatingDifferences: true) { completion() }
//    }
//    
//    private func addItems(_ vms: [MessageCellViewModel],
//                          insertPosition: InsertPosition = .beginning,
//                          snapshot: inout Snapshot)
//    {
//        guard !vms.isEmpty else { return }
//        
//        for vm in vms
//        {
//            let date = vm.message?.timestamp.formatToYearMonthDay() ?? Date()
//            let section = Section.date(date)
//            
//            // Ensure section exists
//            if !snapshot.sectionIdentifiers.contains(section)
//            {
//                switch insertPosition {
//                case .beginning:
//                    if let firstSection = snapshot.sectionIdentifiers.first {
//                        snapshot.insertSections([section], beforeSection: firstSection)
//                    } else {
//                        // No existing sections, just append
//                        snapshot.appendSections([section])
//                    }
//                case .end:
//                    snapshot.appendSections([section])
//                }
//            }
//            
//            // Update or insert item
//            if snapshot.indexOfItem(vm) != nil {
//                snapshot.reloadItems([vm])
//            } else {
//                switch insertPosition {
//                case .beginning:
//                    let firstItem = snapshot.itemIdentifiers(inSection: section).first
//                    if let firstItem = firstItem {
//                        snapshot.insertItems([vm], beforeItem: firstItem)
//                    } else {
//                        snapshot.appendItems([vm], toSection: section)
//                    }
//                case .end:
//                    snapshot.appendItems([vm], toSection: section)
//                }
//            }
//        }
//    }
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
        ) as? ConversationMessageCell else {
            fatalError("Could not dequeue conversation cell")
        }
        
        let layoutConfiguration = layoutProvider.makeLayoutConfigurationForCell(at: indexPath)
        cell.configureCell(using: viewModel,
                           layoutConfiguration: layoutConfiguration)
        
        cell.messageContentView?.handleContentRelayout = { [weak tableView] in
            guard let tableView else {return}
            tableView.beginUpdates()
            tableView.endUpdates()
        }
        return cell
    }
    
    func cleanup()
    {
        diffableDataSource = nil
    }
}

fileprivate enum Section: Hashable { case date(Date) }

extension ConversationDataSourceManager
{
    enum InsertPosition {
        case beginning
        case end
    }
}

// MARK: - SKELETONVIEW DATASOURCE
extension ConversationTableViewDataSource: SkeletonTableViewDataSource
{
    func collectionSkeletonView(_ skeletonView: UITableView, cellIdentifierForRowAt indexPath: IndexPath) -> ReusableCellIdentifier {
       return ReuseIdentifire.ConversationTableCell.messageSekeleton.identifire
    }
}

extension Array {
    subscript(safe index: Int) -> Element? {
        return indices.contains(index) ? self[index] : nil
    }
}


