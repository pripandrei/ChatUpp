//
//  ConversationViewDataSource.swift
//  ChatUpp
//
//  Created by Andrei Pripa on 10/17/23.
//

import UIKit
import SkeletonView

protocol ChatRoomDataSourceProviding {
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
    private var dataProvider: ChatRoomDataSourceProviding
    private var layoutProvider: MessageLayoutProvider
    private var diffableDataSource: DataSource!
    private var tableView: UITableView
    
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
                withIdentifier: "StickerMessageCell",
                for: indexPath
            ) as? StickerMessageCell else {
                fatalError("Could not dequeue StickerMessageCell")
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
                withIdentifier: "TextImageMessageCell",
                for: indexPath
            ) as? TextImageMessageCell else {
                fatalError("Could not dequeue TextImageMessageCell")
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
                withIdentifier: "VoiceMessageCell",
                for: indexPath
            ) as? VoiceMessageCell else {
                fatalError("Could not dequeue VoiceMessageCell")
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
    
//    private func dequeueMessageCell(for indexPath: IndexPath,
//                                    in tableView: UITableView,
//                                    with viewModel: MessageCellViewModel) -> UITableViewCell
//    {
//        guard let cell = tableView.dequeueReusableCell(
//            withIdentifier: ReuseIdentifire.ConversationTableCell.message.identifire,
//            for: indexPath
//        ) as? ConversationMessageCell else {
//            fatalError("Could not dequeue conversation cell")
//        }
//        
//        let layoutConfiguration = layoutProvider.makeLayoutConfigurationForCell(at: indexPath)
//        cell.configureCell(using: viewModel,
//                           layoutConfiguration: layoutConfiguration)
//   
//        (cell.contentContainer as? RelayoutNotifying)?.onRelayoutNeeded = { [weak tableView] in
//            guard let tableView else {return}
//            tableView.beginUpdates()
//            tableView.endUpdates()
//        }
//        
//        return cell
//    }
    
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


