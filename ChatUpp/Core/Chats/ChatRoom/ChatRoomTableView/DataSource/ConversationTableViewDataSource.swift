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
    
    /// Skeleton display is driven by REAL rows in the diffable data source
    /// rather than SkeletonView's data-source wrapper: the wrapper reloads the
    /// whole table on every trait-collection pass (it swizzles
    /// `traitCollectionDidChange`) and re-dequeues reuse-pool cells into
    /// different rows, so the skeleton bars visibly "reset" their sizes while
    /// the chat room waits for remote messages. Being ordinary diffable items,
    /// skeleton rows produce EMPTY diffs on re-applies, so reloads are
    /// geometric no-ops.
    private(set) var isSkeletonDisplayed = false
    /// created once per skeleton session: stable identities keep every
    /// re-apply a no-op diff
    private var skeletonCellViewModels: [MessageCellViewModel] = []
    private var skeletonSectionDate = Date()
    /// shifts the deterministic skeleton bar widths so every chat room open
    /// gets a fresh skeleton arrangement
    private let skeletonBarSeed = Int.random(in: 0...100_000)
    
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
            
            if cellViewModel.displaySkeletonBar == true
            {
                return self.dequeueSkeletonCell(for: indexPath, in: tableView)
            }
            
            if cellViewModel.displayUnseenMessagesTitle == true
            {
                return self.dequeueUnseenTitleCell(for: indexPath, in: tableView)
            }
            
            if cellViewModel.message?.isInvalidated == true
            {
                print("stop")
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
        
        if isSkeletonDisplayed
        {
            snapshot.appendSections([.date(skeletonSectionDate)])
            snapshot.appendItems(skeletonCellViewModels, toSection: .date(skeletonSectionDate))
        }
        
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
    
    /// switches the table's content between skeleton placeholder rows and the
    /// real message clusters; also (re)builds the stable skeleton items
    func setSkeletonDisplay(displayed: Bool)
    {
        if displayed
        {
            if skeletonCellViewModels.isEmpty
            {
                /// match SkeletonView's own sizing: enough rows to fill the
                /// table at the skeleton's 50pt estimated row height
                let rowCount = max(8, Int(ceil(tableView.frame.height / 50.0)))
                skeletonCellViewModels = (0..<rowCount).map { _ in
                    MessageCellViewModel(isSkeletonCell: true)
                }
            }
        }
        else
        {
            isSkeletonDisplayed = false
            configureSnapshot(animationType: .none)
            return
        }
        
        isSkeletonDisplayed = true
        configureSnapshot(animationType: .none)
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
    private func dequeueSkeletonCell(for indexPath: IndexPath,
                                     in tableView: UITableView) -> UITableViewCell
    {
        guard let cell = tableView.dequeueReusableCell(
            withIdentifier: ReuseIdentifire.ConversationTableCell.messageSekeleton.identifire,
            for: indexPath) as? SkeletonViewCell else
        {
            fatalError("Could not dequeue skeleton cell")
        }
        
        cell.setSkeletonBarWidth(forRow: indexPath.row, seed: skeletonBarSeed)
        cell.showBarSkeleton()
        return cell
    }
    
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


