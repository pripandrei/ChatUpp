//
//  ConversationViewDataSource.swift
//  ChatUpp
//
//  Created by Andrei Pripa on 10/17/23.
//

import UIKit
import SkeletonView

//protocol ChatRoomDataSourceProviding {
//    var messageClusters : [ChatRoomViewModel.MessageCluster] { get }
//}

protocol ChatRoomDataSourceProviding {
    var messageClusters : [MessageCluster] { get }
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
    private var dataProvider: ChatRoomDataSourceProviding
    private var layoutProvider: MessageLayoutProvider
    private var diffableDataSource: DataSource!
    private var tableView: UITableView
    private var pendingNewestMessageInsertionID: String?
    
    init(dataProvider: ChatRoomDataSourceProviding,
         layoutProvider: MessageLayoutProvider,
         tableView: UITableView)
    {
        self.dataProvider = dataProvider
        self.layoutProvider = layoutProvider
        self.tableView = tableView
        self.diffableDataSource = makeDataSource()
        self.configureSnapshot()
    }
    
//    deinit
//    {
//        print("ConversationDataSourceManager deinit")
//    }
    
    private func makeDataSource() -> DataSource
    {
        let dataSource = DataSource(tableView: tableView,
                                    cellProvider:
                                        { tableView, indexPath, cellViewModel in
            
            if cellViewModel.message?.isInvalidated == true
            {
                print("stop")
            }

            let cell: UITableViewCell
            if cellViewModel.displayUnseenMessagesTitle == true {
                cell = self.dequeueUnseenTitleCell(for: indexPath, in: tableView)
            } else if cellViewModel.message?.type == .title {
                cell = self.dequeueMessageEventCell(for: indexPath, in: tableView, with: cellViewModel)
            } else {
                cell = self.dequeueMessageCell(for: indexPath, in: tableView, with: cellViewModel)
            }

            cell.transform = .identity
            cell.alpha = 1.0
            if self.pendingNewestMessageInsertionID == cellViewModel.message?.id {
                cell.alpha = 0.0
                self.pendingNewestMessageInsertionID = nil
            }
            return cell
        })
        return dataSource
    }

    func prepareForNewestMessageInsertion(messageID: String)
    {
        pendingNewestMessageInsertionID = messageID
    }

    func clearPendingNewestMessageInsertion()
    {
        pendingNewestMessageInsertionID = nil
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
    
    func reloadItems(_ items: [MessageCellViewModel])
    {
        var snapshot = diffableDataSource.snapshot()
        snapshot.reloadItems(items)
        diffableDataSource.defaultRowAnimation = .fade
        diffableDataSource.apply(snapshot, animatingDifferences: true)
    }
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
        guard let messageType = viewModel.message?.type else {
            fatalError("Message type should be valid")
        }
        
        let layoutConfiguration = layoutProvider.makeLayoutConfigurationForCell(at: indexPath)
        
        switch messageType
        {
        case .sticker:
            guard let cell = tableView.dequeueReusableCell(
                withIdentifier: ReuseIdentifire.ConversationTableCell.stickerMessage.identifire,
                for: indexPath
            ) as? StickerMessageCell else {
                fatalError("Could not dequeue \(ReuseIdentifire.ConversationTableCell.stickerMessage.identifire))")
            }
            
            cell.configureCell(using: viewModel, layoutConfiguration: layoutConfiguration)
            cell.onRelayoutNeeded = { [weak tableView] in
                guard let tableView else { return }
                tableView.beginUpdates()
                tableView.endUpdates()
            }
            
            return cell
            
        case .text, .image, .imageText:
            guard let cell = tableView.dequeueReusableCell(
                withIdentifier: ReuseIdentifire.ConversationTableCell.textImageMessage.identifire,
                for: indexPath
            ) as? TextImageMessageCell else {
                fatalError("Could not dequeue \(ReuseIdentifire.ConversationTableCell.textImageMessage.identifire)")
            }
            
            cell.configureCell(using: viewModel, layoutConfiguration: layoutConfiguration)
            cell.onRelayoutNeeded = { [weak tableView] in
                guard let tableView else { return }
                tableView.beginUpdates()
                tableView.endUpdates()
            }
            
            return cell
            
        case .audio:
            guard let cell = tableView.dequeueReusableCell(
                withIdentifier: ReuseIdentifire.ConversationTableCell.voiceMessage.identifire,
                for: indexPath
            ) as? VoiceMessageCell else {
                fatalError("Could not dequeue \(ReuseIdentifire.ConversationTableCell.voiceMessage.identifire)")
            }
            
            cell.configureCell(using: viewModel, layoutConfiguration: layoutConfiguration)
            cell.onRelayoutNeeded = { [weak tableView] in
                guard let tableView else { return }
                tableView.beginUpdates()
                tableView.endUpdates()
            }
            
            return cell
            
        default:
            fatalError("Unhandled message type: \(messageType)")
        }
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
