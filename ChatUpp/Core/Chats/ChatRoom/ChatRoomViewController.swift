//
//  ConversationViewController.swift
//  ChatUpp
//
//  Created by Andrei Pripa on 10/3/23.

// IMPORTANT: TABLE VIEW IS INVERTED, UPSIDE DOWN (BOTTOM -> TOP),
// THEREFORE, SOME PROPERTIES AND ADJUSTMENTS WERE MADE AND SET AS BOTTOM -> TOP.
// KEEP THIS IN MIND WHENEVER YOU WISH TO ADJUST TABLE VIEW


import UIKit
import SwiftUI
import Photos
import PhotosUI
import Combine
import SkeletonView


//MARK: - SCROLL VIEW DELEGATE
extension ChatRoomViewController: UIScrollViewDelegate
{
//    func scrollViewDidScroll(_ scrollView: UIScrollView)
//    {
////        if let cell = rootView.tableView.cellForRow(at: IndexPath(row: 0, section: 0))
////        {
////            let isSeen = checkIfCellIsFullyVisible(at: IndexPath(row: 0, section: 0))
////            print("first cell is currently visible: \(isSeen)")
////        }
//        
//        let now = Date()
//        
////        if let shouldIgnoreUnseenMessagesUpdateForTimePeriod
////        {
////            if now.timeIntervalSince(shouldIgnoreUnseenMessagesUpdateForTimePeriod) > 1.5
////            {
////                self.shouldIgnoreUnseenMessagesUpdateForTimePeriod = nil
////                self.pendingCellPathsForSeenStatusCheck.removeAll()
////            }
////            return
////        }
////        
//        if shouldIgnoreUnseenMessagesUpdate
//        {
//            shouldIgnoreUnseenMessagesUpdate = false
//            self.pendingCellPathsForSeenStatusCheck.removeAll()
//            return
//        }
//    
//        if let visibleIndices = rootView.tableView.indexPathsForVisibleRows
//        {
//            self.pendingCellPathsForSeenStatusCheck.formUnion(visibleIndices)
//        }
//        
//        if now.timeIntervalSince(lastSeenStatusCheckUpdate) > 1.0
//        {
//            self.lastSeenStatusCheckUpdate = now
//            
//            if viewModel.shouldHideJoinGroupOption { updateMessageSeenStatusIfNeeded() }
//        }
//        
//        isLastCellFullyVisible ?
//        toggleScrollBadgeButtonVisibility(shouldBeHidden: true)
//        :
//        toggleScrollBadgeButtonVisibility(shouldBeHidden: false)
//    }
    
    func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        toggleSectionHeaderVisibility(isScrollActive: true)
    }
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        toggleSectionHeaderVisibility(isScrollActive: false)
    }
    func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        toggleSectionHeaderVisibility(isScrollActive: decelerate)
    }
    
    private func toggleSectionHeaderVisibility(isScrollActive: Bool)
    {
        guard let lastVisibleCellIndex = rootView.tableView.indexPathsForVisibleRows?.last,
              let footerView = rootView.tableView.footerView(forSection: lastVisibleCellIndex.section)
        else {return}
        
        let isLastSectionDisplayed = (rootView.tableView.numberOfSections - 1) == lastVisibleCellIndex.section
        let animationDelay = isScrollActive ? 0.0 : 0.4
        
        UIView.animate(withDuration: 0.4, delay: animationDelay) {
            footerView.layer.opacity = (isScrollActive || isLastSectionDisplayed) ? 1.0 : 0.0
        }
    }
}

final class ChatRoomViewController: UIViewController
{
    weak var coordinatorDelegate :Coordinator?
    
    private var shouldIgnoreUnseenMessagesUpdate: Bool = false
    private var shouldIgnoreUnseenMessagesUpdateForTimePeriod: Date?
    private var pendingCellPathsForSeenStatusCheck = Set<IndexPath>()
    private var lastSeenStatusCheckUpdate: Date = Date()
    private var tableViewDataSource :ConversationTableViewDataSource!
    private var customNavigationBar :ChatRoomNavigationBar!
    private var rootView = ChatRoomRootView()
    private var viewModel: ChatRoomViewModel!
    private var inputMessageTextViewDelegate: InputBarMessageTextViewDelegate!
    private var subscriptions = Set<AnyCancellable>()

    private var isContextMenuPresented: Bool = false
    private var isKeyboardHidden: Bool = true
    private var didFinishInitialScroll: Bool = false
    private var didFinishInitialScrollToUnseenIndexPathIfAny: Bool = true
    
    private var isLastCellFullyVisible: Bool {
        checkIfCellIsFullyVisible(at: IndexPath(row: 0, section: 0))
    }
    
    //MARK: - Lifecycle
    
    convenience init(conversationViewModel: ChatRoomViewModel) {
        self.init()
        self.viewModel = conversationViewModel
    }
    
    override func loadView() {
        view = rootView
        inputMessageTextViewDelegate = InputBarMessageTextViewDelegate(view: rootView)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupController()
        
        Task {
            let authUserID = AuthenticationManager.shared.authenticatedUser?.uid ?? ""
            guard let senderID = viewModel.conversation?.participants
                .first(where: { $0.userID != authUserID })?.userID else {return}
            let unreadCount = try await FirebaseChatService.shared.getUnreadMessagesCountTest(
                from: viewModel.conversation!.id,
                whereMessageSenderID: senderID
            )
            print("Unseen messages count: ",unreadCount)
        }
    }

    private func scrollToCell(at indexPath: IndexPath)
    {
        guard indexPath.row < self.rootView.tableView.numberOfRows(inSection: indexPath.section) else {return}
        
        let updatedIndex = IndexPath(row: indexPath.row + 1, section: indexPath.section)
        
        self.rootView.tableView.scrollToRow(at: updatedIndex, at: .bottom, animated: false)
    }
    
    deinit {
        cleanUp()
//        print("====ConversationVC Deinit")
    }

    private func setupController()
    {
        self.rootView.setInputBarParametersVisibility(shouldHideJoinButton: viewModel.shouldHideJoinGroupOption)
        self.configureTableView()
        self.addGestureToTableView()
        self.setNavigationBarItems()
        self.addTargetsToButtons()
        self.addKeyboardNotificationObservers()
        self.setupBinding()
    }
    
    private func addTargetsToButtons() {
        addTargetToSendMessageBtn()
        addTargetToAddPictureBtn()
        addTargetToEditMessageBtn()
        addTargetToScrollToBottomBtn()
        addTargetToJoinGroupBtn()
    }
    
    private func refreshTableView() 
    {
        let indexPath = self.viewModel.findFirstUnseenMessageIndex()
        
        if indexPath != nil {
            self.didFinishInitialScrollToUnseenIndexPathIfAny = false
            // Delay table view willDisplay cell functionality
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                self.didFinishInitialScrollToUnseenIndexPathIfAny = true
            }
        }
        
        self.toggleSkeletonAnimation(.terminated)
        self.rootView.tableView.reloadData()
        self.view.layoutIfNeeded()

        if let indexPath = self.viewModel.findFirstUnseenMessageIndex() {
            self.scrollToCell(at: indexPath)
        }
        viewModel.isMessageBatchingInProcess = false
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        if viewModel.conversationInitializationStatus == .finished {
            finalizeConversationSetup()
        }
    }
    
    private func finalizeConversationSetup()
    {
        viewModel.resetInitializationStatus()
        viewModel.insertUnseenMessagesTitle()
        refreshTableView()
        viewModel.addListeners()
        viewModel.realmService?.updateChatOpenStatusIfNeeded()
        if viewModel.authParticipantUnreadMessagesCount > 0 {
            updateMessageSeenStatusIfNeeded()
        }
    }
    
    //MARK: - Bindings
    
    private func setupBinding()
    {
        viewModel.$unseenMessagesCount
            .receive(on: DispatchQueue.main)
            .sink { [weak self] unseenCount in
                self?.rootView.unseenMessagesBadge.unseenCount = unseenCount
            }.store(in: &subscriptions)
        
        viewModel.$conversationInitializationStatus
            .debounce(for: .milliseconds(50), scheduler: DispatchQueue.main)
            .sink { [weak self] initializationStatus in
                guard let self = self else {return}
                
                switch initializationStatus {
                case .inProgress: self.toggleSkeletonAnimation(.initiated)
                case .finished:
                    self.finalizeConversationSetup()
                default: break
                }
            }.store(in: &subscriptions)

        viewModel.$messageChangedTypes
            .receive(on: DispatchQueue.main)
            .sink { [weak self] changeTypes in
                guard let self = self, !changeTypes.isEmpty else { return }
                performBatchUpdateWithMessageChanges(changeTypes)
                viewModel.clearMessageChanges()
            }.store(in: &subscriptions)
        
        inputMessageTextViewDelegate.lineNumberModificationSubject
            .debounce(for: .seconds(0.1), scheduler: DispatchQueue.main)
            .sink { [weak self] updatedLinesNumber, currentLinesNumber in
                self?.adjustTableViewContent(withUpdatedNumberOfLines: updatedLinesNumber,
                                             currentNumberOfLines: currentLinesNumber)
            }
            .store(in: &subscriptions)
    }
    
    private func performBatchUpdateWithMessageChanges(_ changes: [MessageChangeType])
    {
        var addedIndexPaths: [IndexPath] = []
        var removedPaths: [(IndexPath, Bool)] = []
        var modifiedPaths: [(indexPath: IndexPath, animation: UITableView.RowAnimation)] = []
        
        for change in changes
        {
            switch change
            {
            case .added(let indexPath):
                if changes.count == 1
                {
                    handleTableViewCellInsertion(scrollToBottom: false)
                    return
                }
                addedIndexPaths.append(indexPath)
            case .removed(let indexPath, let isLastRowInSection):
                removedPaths.append((indexPath, isLastRowInSection))
            case .modified(let indexPath, let modification):
                modifiedPaths.append((indexPath, modification.animationType))
            }
        }

        /// Group modifications by animation type (for clarity and batch efficiency)
        let groupModifications = Dictionary(grouping: modifiedPaths,
                                            by: { $0.animation })
        
        rootView.tableView.performBatchUpdates
        {
            if !removedPaths.isEmpty
            {
                self.removeTableViewCells(at: removedPaths)
            }
            
            if !addedIndexPaths.isEmpty
            {
                let newSections = getNewAddedSectionsIndexes(at: addedIndexPaths)
                
                rootView.tableView.insertRows(at: addedIndexPaths, with: .fade)
                
                if !newSections.isEmpty
                {
                    rootView.tableView.insertSections(newSections, with: .fade)
                }
            }
        } completion: { completed in
            
            guard completed else {return}
            
            self.rootView.tableView.performBatchUpdates
            {
                for (animation, entrie) in groupModifications
                {
                    let indexPaths = entrie.map { $0.indexPath }
                    self.rootView.tableView.reloadRows(at: indexPaths, with: animation)
                }
            }
        }
        print("finish reloading table view")
    }
    
//    private func performBatchUpdateWithMessageChanges(_ changes: [MessageChangeType])
//    {
//        var addedMessages: [Message] = []
//        var removedPaths: [(IndexPath, Bool)] = []
//        var modifiedPaths: [(indexPath: IndexPath, animation: UITableView.RowAnimation)] = []
//        
//        for change in changes
//        {
//            switch change
//            {
//            case .added(let message):
//                if changes.count == 1
//                {
//                    handleTableViewCellInsertion(scrollToBottom: false)
//                    return
//                }
//                addedMessages.append(message)
//            case .removed(let indexPath, let isLastRowInSection):
//                removedPaths.append((indexPath, isLastRowInSection))
//            case .modified(let indexPath, let modification):
//                modifiedPaths.append((indexPath, modification.animationType))
//            }
//        }
//        
//        /// Filter out modifications that were also removed
//        ///
//        let removedIndexPaths = Set(removedPaths.map { $0.0 })
//        let safeModifications = modifiedPaths
//            .filter { !removedIndexPaths.contains($0.indexPath) }
//        
//        /// Group modifications by animation type (for clarity and batch efficiency)
//        let groupModifications = Dictionary(grouping: safeModifications,
//                                            by: { $0.animation })
//        
//        rootView.tableView.performBatchUpdates
//        {
//            if !removedPaths.isEmpty
//            {
//                self.removeTableViewCells(at: removedPaths)
//            }
//            
//            if !addedMessages.isEmpty {
//                let insertIndexPaths = addedMessages.compactMap {
//                    viewModel.indexPath(of: $0)
//                }
//                rootView.tableView.insertRows(at: insertIndexPaths, with: .fade)
//            }
//            
//            for (animation, entrie) in groupModifications
//            {
//                let indexPaths = entrie.map { $0.indexPath }
//                self.rootView.tableView.reloadRows(at: indexPaths, with: animation)
//            }
//        }
//    }
    
    
    //MARK: - Keyboard notification observers
    
    private func addKeyboardNotificationObservers() {
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow), name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide), name: UIResponder.keyboardWillHideNotification, object: nil)
    }

    @objc func keyboardWillShow(notification: NSNotification)
    {
        if let keyboardSize = (notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue
        {
            if rootView.inputBarContainer.frame.origin.y > 580 /// first character typed in textField triggers keyboardWillShow, so we perform this check
            {
                isKeyboardHidden = false
                guard isContextMenuPresented else {
                    handleTableViewOffset(usingKeyboardSize: keyboardSize)
                    return
                }
                
                let keyboardHeight = -336.0
                updateInputBarBottomConstraint(toSize: keyboardHeight)
            }
        }
    }
    
    @objc func keyboardWillHide(notification: NSNotification) 
    {
        if let keyboardSize = (notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue 
        {
            isKeyboardHidden = true
            guard !isContextMenuPresented else {
                updateInputBarBottomConstraint(toSize: 0)
                return
            }
            handleTableViewOffset(usingKeyboardSize: keyboardSize)
        }
    }
    
    //MARK: - Private functions
    
    private func cleanUp() {
        NotificationCenter.default.removeObserver(self)
        viewModel.removeAllListeners()
        CacheManager.shared.clear()
        ChatRoomSessionManager.activeChatID = nil
//        coordinatorDelegate = nil
//        viewModel = nil
//        tableViewDataSource = nil
//        customNavigationBar = nil
    }
    
    private func configureTableView() {
        tableViewDataSource = ConversationTableViewDataSource(conversationViewModel: viewModel)
        rootView.tableView.delegate = self
        rootView.tableView.dataSource = tableViewDataSource
    }
    
    private func updateInputBarBottomConstraint(toSize size: CGFloat) {
        self.rootView.inputBarBottomConstraint.constant = size
        view.layoutIfNeeded()
    }

    private func animateInputBarHeaderViewDestruction() {
        guard let inputBarHeaderView = rootView.inputBarHeader else {return}

        UIView.animate(withDuration: 0.2) {
            self.startInputBarHeaderViewDestruction(inputBarHeaderView)
        } completion: { complition in
            if complition {
                self.endInputBarHeaderViewDestruction()
            }
        }
    }
    
    private func startInputBarHeaderViewDestruction(_ inputBarHeaderView: InputBarHeaderView) {
        self.rootView.messageTextView.text.removeAll()
        inputBarHeaderView.editeViewHeightConstraint?.constant = 0
        inputBarHeaderView.subviews.forEach({ view in
            view.layer.opacity = 0.0
        })
        self.rootView.sendEditMessageButton.layer.opacity = 0.0
//        self.rootView.updateTableViewContentOffset(isInputBarHeaderRemoved: true)
        
        DispatchQueue.main.async {
            self.inputMessageTextViewDelegate.textViewDidChange(self.rootView.messageTextView)
        }
        self.rootView.scrollToBottomBtnBottomConstraint.constant += 45
        self.rootView.layoutIfNeeded()
    }
    
    private func endInputBarHeaderViewDestruction() {
        self.rootView.destroyinputBarHeaderView()
        self.rootView.sendEditMessageButton.isHidden = true
        self.rootView.sendEditMessageButton.layer.opacity = 1.0
    }

    /// - Photo picker setup
    private func configurePhotoPicker() {
        var configuration = PHPickerConfiguration()
        configuration.selectionLimit = 1
        configuration.filter = .images
        let pickerVC = PHPickerViewController(configuration: configuration)
        pickerVC.delegate = self
        present(pickerVC, animated: true)
    }
    
    /// - Navigation bar items setup
    private func setNavigationBarItems()
    {
        let dataProvider: NavigationBarDataProvider

        if let conversation = viewModel.conversation, conversation.isGroup {
            dataProvider = .chat(conversation)
        } else if let user = viewModel.participant {
            dataProvider = .user(user)
        } else {
            return
        }
        
        let navBarViewModel = ChatRoomNavigationBarViewModel(dataProvider: dataProvider)
        customNavigationBar = ChatRoomNavigationBar(viewController: self,
                                                    viewModel: navBarViewModel,
                                                    coordinator: coordinatorDelegate)
    }
    
    enum CellVisibilityStatus {
        case visible
        case underInputBar
        case offScreen
    }
    
    private func getCellVisibilityStatus(at indexPath: IndexPath) -> CellVisibilityStatus?
    {
        let table = rootView.tableView
        
        /// - data source is not empty and table didn't layed out cells yet, return true
        guard !table.visibleCells.isEmpty else {return nil}
        
        guard let cell = table.cellForRow(at: indexPath) else {
            return .offScreen
        }

        let cellRect = table.convert(cell.frame, to: rootView)
        let inputBarRect = rootView.inputBarContainer.frame

        let isCellVisible = inputBarRect.origin.y >= cellRect.origin.y
        return isCellVisible ? .visible : .underInputBar
//        return inputBarRect.origin.y >= cellRect.origin.y
    }
    
    private func checkIfCellIsFullyVisible(at indexPath: IndexPath) -> Bool
    {
        let table = rootView.tableView
        
        /// - data source is not empty and table didn't layed out cells yet, return true
        guard !table.visibleCells.isEmpty else {return true}
        
        guard let lastCell = table.cellForRow(at: indexPath) else {
            return false
        }

        let lastCellRect = table.convert(lastCell.frame, to: rootView)
        let inputBarRect = rootView.inputBarContainer.frame

        return inputBarRect.origin.y >= lastCellRect.origin.y
    }
    
    private func toggleScrollBadgeButtonVisibility(shouldBeHidden: Bool) 
    {
        UIView.animate(withDuration: 0.3) {
            self.rootView.scrollBadgeButton.layer.opacity = shouldBeHidden ? 0.0 : 1.0
        }
    }
    
    private func reloadCellRow(at indexPath: IndexPath, with animation: UITableView.RowAnimation)
    {
        guard let _ = self.rootView.tableView.cellForRow(at: indexPath) as? MessageTableViewCell else { return }
        self.rootView.tableView.reloadRows(at: [indexPath], with: animation)
    }

    /// ATENTION: should be initiated only inside table batch updates
    private func removeTableViewCells(at indexPathsWithFlags: [(IndexPath, Bool)])
    {
        let indexPathsToRemove = indexPathsWithFlags.map(\.0)
        let emptySections = Set(indexPathsWithFlags.compactMap { $0.1 ? $0.0.section : nil })
        
        if !indexPathsToRemove.isEmpty {
            rootView.tableView.deleteRows(at: indexPathsToRemove, with: .fade)
        }
//        let emptySections = indexPathsWithFlags.compactMap { path in
//            rootView.tableView.numberOfRows(inSection: path.section) == 0 ? path.section : nil
//        }
        if !emptySections.isEmpty {
            rootView.tableView.deleteSections(IndexSet(emptySections), with: .fade)
        }
    }
    
    private func getNewAddedSectionsIndexes(at indexPaths: [IndexPath]) -> IndexSet
    {
        var newSectionIndexes = IndexSet()
        
        let grouped = Dictionary(grouping: indexPaths, by: { $0.section })

        for (section, pathsInSection) in grouped {
            let insertedRowCount = pathsInSection.count
            let currentRowCount = viewModel.messageClusters[section].items.count

            if insertedRowCount == currentRowCount {
                newSectionIndexes.insert(section)
            }
        }
        return newSectionIndexes
    }
}

//MARK: - Handle cell message insertion
extension ChatRoomViewController {
    
    private func createMessageBubble()
    {
        DispatchQueue.main.async {
            self.handleTableViewCellInsertion(scrollToBottom: true)
        }
    }
    
//    private func tableViewRowInsertionValidation()
//    {
//        guard let messagesCountInFirstCluster = viewModel.messageClusters.first?.items.count else {return}
//        guard let messageCountInLastCluster = viewModel.messageClusters.last?.items.count else {return}
//        
//        let rowCountInFirstSection = rootView.tableView.numberOfRows(inSection: 0)
//
//        let numberOfSections = rootView.tableView.numberOfSections
//        
//        if numberOfSections == viewModel.messageClusters.count
//        {
//            let rowCountInLastSection = rootView.tableView.numberOfRows(inSection: viewModel.messageClusters.count - 1)
//            
//            assert(messagesCountInFirstCluster > rowCountInFirstSection, "Row count in first section must not be greater than messages count in first cluster before update")
//            assert(messageCountInLastCluster > rowCountInLastSection, "Row count in last section must not be greater than messages count in last cluster before update")
//        }
//    }
    
    private func handleTableViewCellInsertion(
        with indexPath: IndexPath = IndexPath(row: 0, section: 0),
        scrollToBottom: Bool)
    {
        let isNewSectionAdded = checkIfNewSectionWasAdded()
        let visibleIndexPaths = rootView.tableView.indexPathsForVisibleRows
        let isIndexPathVisible = visibleIndexPaths?.contains(indexPath) ?? false
        
//        tableViewRowInsertionValidation()
        
        handleRowAndSectionInsertion(with: indexPath, withAnimation: !isIndexPathVisible)
        if isIndexPathVisible || visibleIndexPaths?.isEmpty == true
        {
            animateCellOffsetOnInsertion(usingCellIndexPath: indexPath,
                                         withNewSectionAdded: isNewSectionAdded)
        }
        
        if scrollToBottom
        {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.15)
            {
                if self.rootView.tableView.visibleCells.count > 0
                {
                    self.rootView.tableView.layoutIfNeeded()
                    self.rootView.tableView.scrollToRow(at: IndexPath(row: 0, section: 0), at: .top, animated: true)
                }
            }
        }
    }
    
    private func handleRowAndSectionInsertion(with indexPath: IndexPath,
                                              withAnimation: Bool)
    {
        /// See FootNote.swift [5]
        if withAnimation {
            UIView.animate(withDuration: 0.0) {
                if self.viewModel.messageClusters.count > self.rootView.tableView.numberOfSections
                {
                    self.rootView.tableView.insertSections(IndexSet(integer: 0), with: .none)
                } else {
                    self.rootView.tableView.insertRows(at: [indexPath], with: .automatic)
                    //                self.rootView.tableView.reloadData()
                }
            }
        } else {
            // - See Footnote.swift [1]
            UIView.performWithoutAnimation {
    //        UIView.animate(withDuration: 0.0) {
                if self.viewModel.messageClusters.count > self.rootView.tableView.numberOfSections
                {
                    self.rootView.tableView.insertSections(IndexSet(integer: 0), with: .none)
                } else {
                    self.rootView.tableView.insertRows(at: [indexPath], with: .automatic)
    //                self.rootView.tableView.reloadData()
                }
            }
        }
    }
    
    private func animateCellOffsetOnInsertion(usingCellIndexPath indexPath: IndexPath,
                                              withNewSectionAdded isNewSectionAdded: Bool)
    {
        let tableView = self.rootView.tableView
        let currentOffSet = tableView.contentOffset
        
        rootView.tableView.layoutIfNeeded()
        //        DispatchQueue.main.async { [weak self] in
        //            guard let self = self,
        guard let cell = tableView.cellForRow(at: indexPath) else { return }
        
        // Shift content offset upward by new cell height + margin (if section inserted)
        let offsetAdjustment = cell.bounds.height + (isNewSectionAdded ? 50 : 0)
        let adjustedOffset = CGPoint(x: currentOffSet.x, y: currentOffSet.y + offsetAdjustment)
        tableView.setContentOffset(adjustedOffset, animated: false)
        
        let isFirstCell = tableView.numberOfSections == 1 && tableView.numberOfRows(inSection: 0) == 1
        
        let checkIndexPath: IndexPath = {
            if tableView.numberOfRows(inSection: 0) > 1 {
                return IndexPath(row: 1, section: 0)
            } else {
                return IndexPath(row: 0, section: 1)
            }
        }()
        
        guard isFirstCell || checkIfCellIsFullyVisible(at: checkIndexPath) else {return}
        
        // Slide-in animation: cell starts off-screen
        cell.frame.origin.y = -50
        
        UIView.animate(withDuration: 0.3, delay: 0.1) {
            cell.frame.origin.y = 0
            tableView.setContentOffset(currentOffSet, animated: false)
        }
        
        /// If previous cell (the one that was before this inserted one)
        /// was not fully visible, skip animation
        ///
        guard isNewSectionAdded else { return }
        
//        guard isNewSectionAdded else {return}
        
        // Animate section footer if new section added
        if isNewSectionAdded,
           let footer = tableView.footerView(forSection: 0)
        {
            footer.transform = CGAffineTransform(scaleX: 0.1, y: 0.1)
            UIView.animate(withDuration: 0.3, delay: 0.1) {
                footer.transform = CGAffineTransform(scaleX: 1, y: -1)
            }
        }
        //        }
    }
    
    private func checkIfNewSectionWasAdded() -> Bool {
        if rootView.tableView.numberOfSections < viewModel.messageClusters.count {
            return true
        }
        return false
    }
    
}

//MARK: - Message seen status handler
extension ChatRoomViewController 
{
    private func updateMessageSeenStatusIfNeeded()
    {
        let cellInexdesToProcess = self.pendingCellPathsForSeenStatusCheck
        self.pendingCellPathsForSeenStatusCheck.removeAll()
        
        var unseenMessageIDs: [String] = []
        
        for indexPath in cellInexdesToProcess
        {
//            guard checkIfCellIsFullyVisible(at: indexPath) else { continue }
            
//            guard let status = getCellVisibilityStatus(at: indexPath),
//                  [.visible, .offScreen].contains(status) else { continue }
            
//            guard let status = getCellVisibilityStatus(at: indexPath) else { continue }
//            
//            if status == .underInputBar {
//                self.pendingCellPathsForSeenStatusCheck.formUnion([indexPath])
//                continue
//            }
            
            guard indexPath.row < rootView.tableView.numberOfRows(inSection: indexPath.section),
                  !checkIfMessageWasSeen(at: indexPath)
            else
            {
                continue
            }
            
            // Get cell if it's still visible, or create a temporary one to get the data
            var cellViewModel: MessageCellViewModel?

            if let cell = rootView.tableView.cellForRow(at: indexPath) as? MessageTableViewCell
            {
                cellViewModel = cell.cellViewModel
            } else
            {
                // Cell is no longer visible, but we still want to mark it as seen
                cellViewModel = self.viewModel.messageClusters[indexPath.section].items[indexPath.row]
            }
            
            guard let cellViewModel = cellViewModel,
                  let message = cellViewModel.message
            else { continue }
            
            if message.realm == nil {
                print("opaa not realm message")
                print(message.messageBody," ", message.id)
            }
            unseenMessageIDs.append(message.id)
        }
        
        if unseenMessageIDs.count > 0 {
            self.viewModel.updateRealmMessagesSeenStatus(unseenMessageIDs)
            self.viewModel.updateFirebaseMessagesSeenStatus(unseenMessageIDs)
            self.viewModel.updateUnseenMessageCounter(shouldIncrement: false,
                                                      counter: unseenMessageIDs.count)
        }
    }
    
    private func checkIfCellIsCurrentlyVisible(_ cell: UITableViewCell) -> Bool
    {
        let cellFrame = cell.frame
        let tableRect = rootView.tableView.bounds.offsetBy(dx: 0, dy: 65)
        return tableRect.contains(cellFrame)
    }
    
    private func checkIfMessageWasSeen(at indexPath: IndexPath) -> Bool
    {
        let authUserID = viewModel.authUser.uid
        
        // proceed further only if message does not belong to authenticated user
        guard let message = viewModel.messageClusters[indexPath.section].items[indexPath.row].message,
              message.senderId != authUserID else { return true }
        
        let messageIsSeenByAuthUser: Bool
        
        if viewModel.conversation?.isGroup == true
        {
            messageIsSeenByAuthUser = message.seenBy.contains(authUserID)
        } else {
            messageIsSeenByAuthUser = message.messageSeen == true
        }

        guard !messageIsSeenByAuthUser else { return true }
        return false
    }
}

//MARK: - VIEW BUTTON'S TARGET'S
extension ChatRoomViewController {
    
    private func addTargetToScrollToBottomBtn() {
        rootView.scrollBadgeButton.addTarget(self, action: #selector(scrollToBottomBtnWasTapped), for: .touchUpInside)
    }
    private func addTargetToSendMessageBtn() {
        rootView.sendMessageButton.addTarget(self, action: #selector(sendMessageTapped), for: .touchUpInside)
    }
    private func addTargetToAddPictureBtn() {
        rootView.addPictureButton.addTarget(self, action: #selector(pictureAddBtnWasTapped), for: .touchUpInside)
    }
    private func addTargetToEditMessageBtn() {
        rootView.sendEditMessageButton.addTarget(self, action: #selector(editMessageBtnWasTapped), for: .touchUpInside)
    }
    private func addTargetToJoinGroupBtn() {
        rootView.joinChatRoomButton.addTarget(self, action: #selector(joinGroupBtnWasTapped), for: .touchUpInside)
    }
    
    @objc func joinGroupBtnWasTapped()
    {
        UIView.animate(withDuration: 0.4)
        {
            self.rootView.joinChatRoomButton.layer.opacity = 0.0
        } completion: { _ in
            self.rootView.joinChatRoomButton.isHidden = true
            self.rootView.joinActivityIndicator.startAnimating()
            
            Task { @MainActor in
                try await Task.sleep(for: .seconds(1))
                try await self.viewModel.joinGroup()
                
                self.rootView.joinActivityIndicator.stopAnimating()
                self.rootView.setInputBarParametersVisibility(shouldHideJoinButton: true, shouldAnimate: true)
            }
        }
    }

    @objc func scrollToBottomBtnWasTapped() {
        rootView.tableView.scrollToRow(at: IndexPath(row: 0, section: 0), at: .top, animated: true)
    }
    
    @objc func editMessageBtnWasTapped() {
        guard let editedMessage = rootView.messageTextView.text else {return}
        viewModel.shouldEditMessage?(editedMessage)
        rootView.sendEditMessageButton.isHidden = true
        rootView.messageTextView.text.removeAll()
        animateInputBarHeaderViewDestruction()
    }
    
    @objc func sendMessageTapped() 
    {
        let trimmedString = getTrimmedString()
        if !trimmedString.isEmpty
        {
            if !viewModel.conversationExists { viewModel.setupConversation() }
            
            let message = viewModel.createNewMessage(ofType: .text,
                                       content: trimmedString)
            viewModel.handleLocalUpdatesOnMessageCreation(message)
            
            removeTextViewText()
            inputMessageTextViewDelegate.invalidateTextViewSize()
            callTextViewDidChange()
            
            createMessageBubble()
            Task { await viewModel.initiateRemoteUpdatesOnMessageCreation(message) }
            closeInputBarHeaderView()
        }
    }

    @objc func pictureAddBtnWasTapped() {
        configurePhotoPicker()
    }
    
}

//MARK: - Helper functions
extension ChatRoomViewController
{
    private func getTrimmedString() -> String {
        return rootView.messageTextView.text.trimmingCharacters(in: .whitespacesAndNewlines)
    }
    private func removeTextViewText() {
        rootView.messageTextView.text.removeAll()
    }
    private func callTextViewDidChange() {
        let textView = rootView.messageTextView
        inputMessageTextViewDelegate.textViewDidChange(textView)
    }
}

//MARK: - TABLE OFFSET HANDLER
extension ChatRoomViewController 
{
//    private func handleTableViewOffset(usingKeyboardSize keyboardSize: CGRect)
//    {
//        let maxContainerY = 584.0 - 4.0
//        let isMaxLinesReached = rootView.inputBarContainer.frame.origin.y > maxContainerY
//        let keyboardHeight = isMaxLinesReached ? -keyboardSize.height : keyboardSize.height
//        
//        // Calculate text view height
//        let lineHeight = rootView.messageTextView.font!.lineHeight
//        let textViewHeight = (lineHeight * CGFloat(rootViewTextViewDelegate.messageTextViewNumberOfLines)) - lineHeight
//        
//        // Calculate total inset including text view height and header
//        let editViewHeight = rootView.inputBarHeader?.bounds.height ?? 0
//        let totalInset = textViewHeight + editViewHeight + (keyboardHeight < 0 ? abs(keyboardHeight) : 0)
//        
//        let currentOffset = rootView.tableView.contentOffset
//        let newOffset = CGPoint(x: currentOffset.x,
//                               y: keyboardHeight + currentOffset.y)
//        
//        // Update layout
//        rootView.inputBarBottomConstraint.constant = keyboardHeight < 0 ? keyboardHeight : 0
//        rootView.layoutSubviews()
//        rootView.tableView.contentInset.top = totalInset
//        rootView.tableView.setContentOffset(newOffset, animated: false)
//        rootView.tableView.verticalScrollIndicatorInsets.top = totalInset
//    }
//    

    private func handleTableViewOffset(usingKeyboardSize keyboardSize: CGRect)
    {
        // if number of lines inside textView is bigger than 1, it will expand
        let maxContainerViewY = 584.0 - 4.0
        let keyboardSize = CGRect(origin: keyboardSize.origin,
                                  size: CGSize(width:
                                                keyboardSize.size.width,
                                               height: keyboardSize.size.height - 30))
        let keyboardHeight = rootView.inputBarContainer.frame.origin.y > maxContainerViewY ? -keyboardSize.height : keyboardSize.height
        let editViewHeight = rootView.inputBarHeader?.bounds.height != nil ? rootView.inputBarHeader!.bounds.height : 0
        
        // if there is more than one line, textView height should be added to table view inset (max 5 lines allowed)
        let textViewHeight = (rootView.messageTextView.font!.lineHeight * CGFloat(inputMessageTextViewDelegate.messageTextViewNumberOfLines)) - CGFloat(rootView.messageTextView.font!.lineHeight)
        
        let customTableViewInset = keyboardHeight < 0 ? abs(keyboardHeight) + textViewHeight + editViewHeight : 0 + textViewHeight + editViewHeight
        let currentOffSet = rootView.tableView.contentOffset
        let offSet = CGPoint(x: currentOffSet.x, y: keyboardHeight + currentOffSet.y)
        
        rootView.inputBarBottomConstraint.constant = keyboardHeight < 0 ? keyboardHeight : 0
        rootView.layoutSubviews()
        rootView.tableView.contentInset.top = customTableViewInset
        rootView.tableView.setContentOffset(offSet, animated: false)
        rootView.tableView.verticalScrollIndicatorInsets.top = customTableViewInset
    }
    
    private func adjustTableViewContent(withUpdatedNumberOfLines numberOfLines: Int,
                                        currentNumberOfLines: Int)
    {
        let textView = rootView.messageTextView
        let tableView = rootView.tableView
        let numberOfAddedLines = CGFloat(numberOfLines - currentNumberOfLines)
        let editViewHeight = rootView.inputBarHeader?.bounds.height ?? 0
        let updatedContentOffset = tableView.contentOffset.y - (textView.font!.lineHeight * numberOfAddedLines)
        let updatedContentTopInset = rootView.tableViewInitialTopInset +
        (textView.font!.lineHeight * CGFloat(numberOfLines - 1)) + editViewHeight
        
        UIView.animate(withDuration: 0.15)
        {
            tableView.verticalScrollIndicatorInsets.top = updatedContentTopInset
            tableView.contentInset.top = updatedContentTopInset
            tableView.setContentOffset(CGPoint(x: 0, y: updatedContentOffset), animated: false)
        }
        inputMessageTextViewDelegate.updateLinesNumber(numberOfLines)
    }
}

//MARK: - PHOTO PICKER CONFIGURATION & DELEGATE
extension ChatRoomViewController: PHPickerViewControllerDelegate {
    
    func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
        picker.dismiss(animated: true)
        
        results.forEach { result in
            result.itemProvider.loadObject(ofClass: UIImage.self) { [weak self] reading, error in
                
                guard let self = self,
                      let image = reading as? UIImage, error == nil else {
                    print("Could not read image!")
                    return
                }
                
                let imageRepository = ImageSampleRepository(image: image, type: .message)
                
                Task { @MainActor in
                    let message = self.viewModel.createNewMessage(
                        ofType: .image,
                        content: imageRepository.imagePath(for: .original)
                    )
                    self.viewModel.handleLocalUpdatesOnMessageCreation(message)
                    await self.viewModel.saveImagesLocally(
                        fromImageRepository: imageRepository,
                        for: message.id
                    )
                    self.createMessageBubble()
                    await self.viewModel.initiateRemoteUpdatesOnMessageCreation(
                        message,
                        imageRepository: imageRepository)
                }
            }
        }
    }
}

//MARK: - GESTURES
extension ChatRoomViewController {
    
    private func addGestureToTableView() {
        let tap = UITapGestureRecognizer(target: self, action: #selector(resignKeyboard))
        tap.cancelsTouchesInView = false
        rootView.tableView.addGestureRecognizer(tap)
    }
    private func addGestureToCloseBtn() {
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(closeInputBarHeaderView))
        rootView.inputBarHeader?.closeInputBarHeaderView?.addGestureRecognizer(tapGesture)
   }
    
    @objc func resignKeyboard() {
        if rootView.messageTextView.isFirstResponder {
            rootView.messageTextView.resignFirstResponder()
        }
    }
    @objc func closeInputBarHeaderView() {
        if rootView.inputBarHeader != nil {
            viewModel.resetCurrentReplyMessageIfNeeded()
            animateInputBarHeaderViewDestruction()
        }
    }
}


//MARK: - TABLE  DELEGATE
extension ChatRoomViewController: UITableViewDelegate
{
    func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView?
    {
        guard !tableView.sk.isSkeletonActive,
              let footerView = tableView.dequeueReusableHeaderFooterView(withIdentifier: ReuseIdentifire.HeaderFooter.footer.identifire) as? FooterSectionView else { return nil }
        
        let dateForSection = viewModel.messageClusters[section].date.formatToYearMonthDayCustomString()
        footerView.setDate(dateText: dateForSection)
        return footerView
    }
    
    func tableView(_ tableView: UITableView, willDisplayFooterView view: UIView, forSection section: Int)
    {
        guard !tableView.sk.isSkeletonActive else {
            view.isHidden = true
            return
        }
//        if isNewSectionAdded && section == 0 {
//            view.alpha = 0.0
//            
//            view.frame = view.frame.offsetBy(dx: view.frame.origin.x, dy: -30)
//            UIView.animate(withDuration: 0.3) {
//                view.frame = view.frame.offsetBy(dx: view.frame.origin.x, dy: 30)
//                view.alpha = 1.0
//            }
//        }
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if viewModel.conversationInitializationStatus == .inProgress {
            return CGFloat((70...120).randomElement()!)
        }
       return  UITableView.automaticDimension
    }
    
    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) 
    {
        guard viewModel.messageClusters.count != 0,
              viewModel.isMessageBatchingInProcess == false,
              didFinishInitialScrollToUnseenIndexPathIfAny
        else {return}
        
        let lastSectionIndex = viewModel.messageClusters.count - 1
        let lastRowIndex = viewModel.messageClusters[lastSectionIndex].items.count - 1
        let isLastCellDisplayed = indexPath.section == lastSectionIndex && indexPath.row == lastRowIndex
        let isFirstCellDisplayed = indexPath.section == 0 && indexPath.row == 0
        
        if isLastCellDisplayed
        {
            updateConversationWithAdditionalMessagesIfNeeded(inAscendingOrder: false)
        }
        else if isFirstCellDisplayed && viewModel.shouldFetchNewMessages
        {
            updateConversationWithAdditionalMessagesIfNeeded(inAscendingOrder: true)
        }
    }
    
    private func updateConversationWithAdditionalMessagesIfNeeded(inAscendingOrder order: Bool)
    {
        print("entered additional update block")
//        didFinishInitialScroll = false
        viewModel.isMessageBatchingInProcess = true
        
        Task { @MainActor [weak self] in
            guard let self = self else {return}
            do {
                /// See Footnote.swift [3]
                try await Task.sleep(for: .seconds(1.2))
                
                if let (newRows, newSections) = try await self.viewModel.handleAdditionalMessageClusterUpdate(inAscendingOrder: order)
                {
                    self.performeTableViewUpdate(with: newRows, sections: newSections)
                    
                    // if all unseen messages are fetched, attach listener to upcoming
                    if order == true && self.viewModel.shouldAttachListenerToUpcomingMessages
                    {
                        print("added listener to upcomming messages")
                        self.viewModel.messageListenerService?.addListenerToUpcomingMessages()
                    }
                }
            } catch {
                print("Could not update conversation with additional messages: \(error)")
            }
//            self.didFinishInitialScroll = true
            print("didFinishInitialScroll")
            try await Task.sleep(for: .seconds(0.4))
            viewModel.isMessageBatchingInProcess = false
        }
    }
    
    private func performeTableViewUpdate(with newRows: [IndexPath], sections: IndexSet?)
    {
        var visibleCell: MessageTableViewCell? = nil
        let currentOffsetY = self.rootView.tableView.contentOffset.y
        
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        
        self.rootView.tableView.performBatchUpdates({
            visibleCell = self.rootView.tableView.visibleCells.first as? MessageTableViewCell
            
            if let sections = sections {
                self.rootView.tableView.insertSections(sections, with: .none)
            }
            if !newRows.isEmpty {
                self.rootView.tableView.insertRows(at: newRows, with: .none)
            }
//            self.shouldIgnoreUnseenMessagesUpdateForTimePeriod = Date()
            self.shouldIgnoreUnseenMessagesUpdate = true
        }, completion: { _ in
            
//            self.shouldIgnoreUnseenMessagesUpdate = true
            if self.rootView.tableView.contentOffset.y < -97.5
            {
                if let visibleCell = visibleCell,
                   let indexPathOfVisibleCell = self.rootView.tableView.indexPath(for: visibleCell)
                {
                    let lastCellRect = self.rootView.tableView.rectForRow(at: indexPathOfVisibleCell)
                    self.rootView.tableView.contentOffset.y = currentOffsetY + lastCellRect.minY
                }
            }
            CATransaction.commit()
        })
    }
    
    /// Context Menu configuration
    ///
    func tableView(_ tableView: UITableView, contextMenuConfigurationForRowAt indexPath: IndexPath, point: CGPoint) -> UIContextMenuConfiguration?
    {
        guard viewModel.shouldHideJoinGroupOption,
              let baseCell = tableView.cellForRow(at: indexPath) else { return nil }
        let identifier = indexPath as NSCopying
        
        let menuBuilder = MessageMenuBuilder(
            viewModel: self.viewModel,
            rootView: self.rootView
        )
        { actionOption, selectedMessageText in
            self.handleContextMenuSelectedAction(
                actionOption: actionOption,
                selectedMessageText: selectedMessageText
            )
        }
        
        if let messageCell = baseCell as? MessageTableViewCell,
           let message = messageCell.cellViewModel.message
        {
            let tapLocationInCell = messageCell.contentView.convert(point, from: tableView)
            guard messageCell.messageContainer.frame.contains(tapLocationInCell) else { return nil }
            
            return UIContextMenuConfiguration(identifier: identifier, previewProvider: nil) { _ in
                return menuBuilder.buildUIMenuForMessageCell(messageCell, message: message)
            }
        }
        else if let eventCell = baseCell as? MessageEventCell,
                let message = eventCell.cellViewModel.message
        {
            let tapLocationInCell = eventCell.contentView.convert(point, from: tableView)
            guard eventCell.messageEventContainer.frame.contains(tapLocationInCell) else { return nil }
            
            return UIContextMenuConfiguration(identifier: identifier, previewProvider: nil) { _ in
                return menuBuilder.buildUIMenuForEventCell(eventCell, message: message)
            }
        }
        return nil
    }
    
    func tableView(_ tableView: UITableView, previewForHighlightingContextMenuWithConfiguration configuration: UIContextMenuConfiguration) -> UITargetedPreview?
    {
        return makeTargetedPreview(for: configuration)
//        return makeConversationMessagePreview(for: configuration, forHighlightingContext: true)
    }

    func tableView(_ tableView: UITableView, previewForDismissingContextMenuWithConfiguration configuration: UIContextMenuConfiguration) -> UITargetedPreview?
    {
        executeAfter(seconds: 0.5) {
            self.isContextMenuPresented = false
        }
//        return makeConversationMessagePreview(for: configuration, forHighlightingContext: false)
        return makeTargetedDismissPreview(for: configuration)
    }
    
    func tableView(_ tableView: UITableView, willDisplayContextMenu configuration: UIContextMenuConfiguration, animator: UIContextMenuInteractionAnimating?)
    {
        if rootView.inputBarBottomConstraint.constant != 0.0 {
            isContextMenuPresented = true
        }
    }
    
//    func tableView(_ tableView: UITableView, willEndContextMenuInteraction configuration: UIContextMenuConfiguration, animator: (any UIContextMenuInteractionAnimating)?)
//    {
//        guard let indexPath = configuration.identifier as? IndexPath,
//              let cell = tableView.cellForRow(at: indexPath) as? MessageTableViewCell else { return }
//    }
    
    private func makeConversationMessagePreview(for configuration: UIContextMenuConfiguration,                                             forHighlightingContext: Bool) -> UITargetedPreview?
    {
        guard let indexPath = configuration.identifier as? IndexPath,
              let cell = rootView.tableView.cellForRow(at: indexPath) as? TargetPreviewable else { return nil }
        
        if forHighlightingContext {
            UIView.animate(withDuration: 0.4) {
                cell.getTargetViewForPreview().backgroundColor = UIColor.purple.withAlphaComponent(0.4)
            }
        } else {
            UIView.animate(withDuration: 0.5) {
                cell.getTargetViewForPreview().backgroundColor = cell.getTargetedPreviewColor()
            }
        }

        let parameter = UIPreviewParameters()
        parameter.backgroundColor = .clear
        
        return UITargetedPreview(view: cell.getTargetViewForPreview(),
                                 parameters: parameter)
    }
    
    private func handleContextMenuSelectedAction(actionOption: InputBarHeaderView.Mode, selectedMessageText text: String?)
    {
        self.rootView.activateInputBarHeaderView(mode: actionOption)
        self.addGestureToCloseBtn()
        self.rootView.messageTextView.becomeFirstResponder()
        self.rootView.inputBarHeader?.setInputBarHeaderMessageText(text)
        self.inputMessageTextViewDelegate.textViewDidChange(self.rootView.messageTextView)
    }
}

//MARK: - SkeletonView animation
extension ChatRoomViewController
{
    private func toggleSkeletonAnimation(_ state: SkeletonAnimationState)
    {
        // Reference: skeletonView requires for estimatedRowHeight to have a value
        // so we set it to work, and disable after,
        // to prevent other glitch related to rows when adding reaction
        switch state {
        case .initiated:
            rootView.tableView.estimatedRowHeight = 50 // read reference
            Utilities.initiateSkeletonAnimation(for: rootView.tableView)
        case .terminated:
            rootView.tableView.estimatedRowHeight = UITableView.automaticDimension // read reference
            Utilities.stopSkeletonAnimation(for: rootView.tableView)
        default: break
        }
    }
}

//MARK: - Targeted Preview creation
extension ChatRoomViewController
{
    func makeTargetedPreview(for configuration: UIContextMenuConfiguration) -> UITargetedPreview?
    {
        guard let indexPath = configuration.identifier as? IndexPath,
              let cell = rootView.tableView.cellForRow(at: indexPath),
              let message: Message = getMessageFromCell(cell) else {
            return nil
        }
        
        let maxSnapshotHeight = TargetedPreviewComponentsSize.calculateMaxSnapshotHeight(from: cell)

        guard let snapshot = cell.contentView.snapshotView(afterScreenUpdates: true) else {
            return nil
        }
        snapshot.frame = CGRect(origin: .zero, size: CGSize(width: cell.bounds.width, height: maxSnapshotHeight))
        
        var reactionPanelView = ReactionPanelView()
        reactionPanelView.onReactionSelection = { [weak self] reactionEmoji in
            self?.viewModel.updateReactionInDataBase(reactionEmoji, from: message)
            let delayInterval = 0.7 // do not modify to lower than 0.7 value (result in animation glitch on reload)
            self?.dismiss(animated: true)
            
            executeAfter(seconds: delayInterval)
            {
                self?.rootView.tableView.reloadRows(at: [indexPath], with: .fade)
            }
        }
        let hostingReactionVC = UIHostingController(rootView: reactionPanelView)
        hostingReactionVC.view.backgroundColor = .clear

        addChild(hostingReactionVC)
        hostingReactionVC.view.translatesAutoresizingMaskIntoConstraints = false

        snapshot.layer.cornerRadius = 10
        snapshot.layer.masksToBounds = true
        snapshot.translatesAutoresizingMaskIntoConstraints = false

        let containerHeight = TargetedPreviewComponentsSize.getSnapshotContainerHeight(snapshot)
        let container = UIView(frame: CGRect(origin: .zero,
                                             size: CGSize(width: cell.bounds.width, height: containerHeight)))
        container.backgroundColor = .clear
        container.addSubview(snapshot)
        container.addSubview(hostingReactionVC.view)

        NSLayoutConstraint.activate([
            hostingReactionVC.view.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 10),
            hostingReactionVC.view.topAnchor.constraint(equalTo: container.topAnchor),
            hostingReactionVC.view.widthAnchor.constraint(equalToConstant: 306),
            hostingReactionVC.view.heightAnchor.constraint(equalToConstant: 45),

            snapshot.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            snapshot.topAnchor.constraint(equalTo: hostingReactionVC.view.bottomAnchor, constant: TargetedPreviewComponentsSize.spaceReactionHeight),
            snapshot.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            snapshot.bottomAnchor.constraint(equalTo: container.bottomAnchor)
        ])

        let heightDifference = container.bounds.height - cell.bounds.height
        let adjustedCenterY = cell.center.y + (heightDifference / 2) // In flipped space, add to go up
        let centerPoint = CGPoint(x: cell.center.x, y: adjustedCenterY)

        let previewTarget = UIPreviewTarget(container: rootView.tableView,
                                          center: centerPoint,
                                          transform: CGAffineTransform(scaleX: 1, y: -1))
        
        let parameters = UIPreviewParameters()
        parameters.backgroundColor = .clear
        parameters.shadowPath = UIBezierPath()
        
        return UITargetedPreview(view: container,
                               parameters: parameters,
                               target: previewTarget)
    }

    func makeTargetedDismissPreview(for configuration: UIContextMenuConfiguration) -> UITargetedPreview?
    {
        guard let indexPath = configuration.identifier as? IndexPath,
              let cell = rootView.tableView.cellForRow(at: indexPath) else {
            return nil
        }
        
        let maxSnapshotHeight = TargetedPreviewComponentsSize.calculateMaxSnapshotHeight(from: cell)
 
        guard let snapshot = cell.contentView.snapshotView(afterScreenUpdates: false) else {
            return nil
        }
        snapshot.frame = CGRect(origin: .zero, size: CGSize(width: cell.bounds.width, height: maxSnapshotHeight))
        
        let containerHeight = TargetedPreviewComponentsSize.getSnapshotContainerHeight(snapshot)
        
        let container = UIView(frame: CGRect(origin: .zero,
                                             size: CGSize(width: cell.bounds.width,
                                                          height: containerHeight)))
        
        container.addSubview(snapshot)
        snapshot.layer.cornerRadius = 10
        snapshot.layer.masksToBounds = true
        snapshot.translatesAutoresizingMaskIntoConstraints = false

        snapshot.leadingAnchor.constraint(equalTo: container.leadingAnchor).isActive = true
        snapshot.trailingAnchor.constraint(equalTo: container.trailingAnchor).isActive = true
        snapshot.heightAnchor.constraint(equalToConstant: snapshot.bounds.height).isActive = true
        snapshot.bottomAnchor.constraint(equalTo: container.bottomAnchor).isActive = true
        
        let heightDifference = container.bounds.height - cell.bounds.height
        let adjustedCenterY = cell.center.y + (heightDifference / 2)
        
        let centerPoint = CGPoint(x: cell.center.x, y: adjustedCenterY)
        let previewTarget = UIPreviewTarget(container: rootView.tableView,
                                           center: centerPoint,
                                           transform: CGAffineTransform(scaleX: 1, y: -1))
        
        let parameters = UIPreviewParameters()
        parameters.backgroundColor = .clear
        parameters.shadowPath = UIBezierPath()
        
        return UITargetedPreview(view: container, parameters: parameters, target: previewTarget)
    }

    func getMessageFromCell(_ cell: UITableViewCell) -> Message?
    {
        if let messageCell = cell as? MessageTableViewCell,
            let cellMessage = messageCell.cellViewModel.message
        {
            return cellMessage
        } else if let eventCell = cell as? MessageEventCell,
                  let cellMessage = eventCell.cellViewModel.message {
            return cellMessage
        } else {
            return nil
        }
    }
}


struct TargetedPreviewComponentsSize
{
    static let reactionHeight: CGFloat = 45.0
    static let spaceReactionHeight: CGFloat = 14.0
    static let menuHeight: CGFloat = 200
    
    static func calculateMaxSnapshotHeight(from view: UIView) -> CGFloat
    {
        return min(view.bounds.height,
                   UIScreen.main.bounds.height -
                   self.reactionHeight -
                   self.spaceReactionHeight -
                   self.menuHeight)
    }
    
    static func getSnapshotContainerHeight(_ snapshot: UIView) -> CGFloat
    {
        return snapshot.bounds.height +
        TargetedPreviewComponentsSize.reactionHeight + TargetedPreviewComponentsSize.spaceReactionHeight
        
    }
}
