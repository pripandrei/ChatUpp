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


final class ChatRoomViewController: UIViewController
{
    weak var coordinatorDelegate :Coordinator?
    
    private var pendingIndexPathForSeenStatusCheck: IndexPath?
    private var isNetworkPaginationRunning: Bool = false
    
    private var dragableCell: MessageCellDragable?
    private var draggingCellOriginalCenter: CGPoint = .zero
    private var hapticWasInitiated: Bool = false
    
    private var messageImage: UIImage? = nil
    private var shouldIgnoreUnseenMessagesUpdate: Bool = false
    private var lastSeenStatusCheckUpdate: Date = Date()
    
    private var tableViewDataSource :ConversationTableViewDataSource!
    private var customNavigationBar :ChatRoomNavigationBar!
    private var rootView = ChatRoomRootView()
    private var viewModel: ChatRoomViewModel!
    private var inputMessageTextViewDelegate: InputBarMessageTextViewDelegate!
    private var subscriptions = Set<AnyCancellable>()
    private lazy var alertPresenter: AlertPresenter = .init()

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
    
    private var canPassThrough: Bool = false
    
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
//        viewModel.realmService?.updateChatOpenStatusIfNeeded()
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
        
        viewModel.$changedTypesOfRemovedMessages
            .receive(on: DispatchQueue.main)
            .sink { [weak self] changeTypes in
                guard let self = self, !changeTypes.isEmpty else { return }
                self.deleteRows(withChangeTypes: changeTypes)
                viewModel.clearRemovedMessageChanges()
            }.store(in: &subscriptions)
        
    }
    
    private func performBatchUpdateWithMessageChanges(_ changes: Set<MessageChangeType>)
    {
        guard !changes.isEmpty else {return}
        
        var addedIndexPaths: [IndexPath] = []
        var removedPaths: [(IndexPath, Bool)] = []
        var modifiedPaths: [(indexPath: IndexPath, animation: UITableView.RowAnimation)] = []
        
        for change in changes
        {
            switch change
            {
            case .added(let indexPath):
                addedIndexPaths.append(indexPath)
            case .removed(let indexPath, let isLastRowInSection):
                removedPaths.append((indexPath, isLastRowInSection))
            case .modified(let indexPath, let modification):
                modifiedPaths.append((indexPath, modification.animationType))
            }
        }

        let isFirstRow = (addedIndexPaths.first?.row == 0 && addedIndexPaths.first?.section == 0)
        
        if addedIndexPaths.count == 1 && isFirstRow
        {
            handleTableViewCellInsertion(scrollToBottom: false)
            return
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
                    print("enter row reload")
                    let indexPaths = entrie.map { $0.indexPath }
                    self.rootView.tableView.reloadRows(at: indexPaths, with: animation)
                }
            }
        }
        print("finish reloading table view")
    }
    
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
    
    private func startInputBarHeaderViewDestruction(_ inputBarHeaderView: InputBarHeaderView)
    {
        self.rootView.messageTextView.text.removeAll()
        inputBarHeaderView.inputBarHightConstraint?.constant = 0
        inputBarHeaderView.subviews.forEach({ view in
            view.layer.opacity = 0.0
        })
        self.rootView.sendEditMessageButton.layer.opacity = 0.0
        
        mainQueue {
            self.inputMessageTextViewDelegate.textViewDidChange(self.rootView.messageTextView)
        }
        self.rootView.scrollToBottomBtnBottomConstraint.constant += 45
        self.rootView.layoutIfNeeded()
    }
    
    private func endInputBarHeaderViewDestruction() {
        self.rootView.destroyInputBarHeaderView()
        self.rootView.sendEditMessageButton.isHidden = true
        self.rootView.sendEditMessageButton.layer.opacity = 1.0
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
        
        guard let lastCell = table.cellForRow(at: indexPath) as? MessageCellSeenable else {
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
        
        if !emptySections.isEmpty {
            rootView.tableView.deleteSections(IndexSet(emptySections), with: .fade)
        }
    }
    
    private func deleteRows(withChangeTypes types: Set<MessageChangeType>)
    {
        var removedPaths: [(IndexPath, Bool)] = []
        
        for type in types
        {
            switch type
            {
            case .removed(let indexPath, let isLastRowInSection):
                removedPaths.append((indexPath, isLastRowInSection))
            default: break
            }
        }
        
        let indexPathsToRemove = removedPaths.map(\.0)
        let emptySections = Set(removedPaths.compactMap { $0.1 ? $0.0.section : nil })
        
        let visibleSet = Set(self.rootView.tableView.indexPathsForVisibleRows ?? [])
        
        let contains = visibleSet.contains(where: { indexPathsToRemove.contains($0) })

        if contains {
            CATransaction.begin()
            self.rootView.tableView.performBatchUpdates {
                rootView.tableView.deleteRows(at: indexPathsToRemove, with: .fade)
                
                if !emptySections.isEmpty {
                    rootView.tableView.deleteSections(IndexSet(emptySections), with: .fade)
                }
            }
            CATransaction.commit()
        } else {
            UIView.animate(withDuration: 0.0) {
                self.rootView.tableView.performBatchUpdates {
                    self.rootView.tableView.deleteRows(at: indexPathsToRemove, with: .none)
                    
                    if !emptySections.isEmpty {
                        self.rootView.tableView.deleteSections(IndexSet(emptySections), with: .none)
                    }
                }
            }
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
        mainQueue {
            self.handleTableViewCellInsertion(scrollToBottom: true)
        }
    }

    private func handleTableViewCellInsertion(
        with indexPath: IndexPath = IndexPath(row: 0, section: 0),
        scrollToBottom: Bool)
    {
        let isNewSectionAdded = checkIfNewSectionWasAdded()
        let visibleIndexPaths = rootView.tableView.indexPathsForVisibleRows
        let isIndexPathVisible = visibleIndexPaths?.contains(indexPath) ?? false
        
        handleRowAndSectionInsertion(with: indexPath, withAnimation: !isIndexPathVisible)
        if isIndexPathVisible || visibleIndexPaths?.isEmpty == true
        {
            animateCellOffsetOnInsertion(usingCellIndexPath: indexPath,
                                         withNewSectionAdded: isNewSectionAdded)
        }
        
        if scrollToBottom
        {
            executeAfter(seconds: 0.15)
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
        
        // Animate section footer if new section added
        if isNewSectionAdded,
           let footer = tableView.footerView(forSection: 0)
        {
            footer.transform = CGAffineTransform(scaleX: 0.1, y: 0.1)
            UIView.animate(withDuration: 0.3, delay: 0.1) {
                footer.transform = CGAffineTransform(scaleX: 1, y: 1)
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
        guard let indexToProcess = self.pendingIndexPathForSeenStatusCheck
        else { return }
        self.pendingIndexPathForSeenStatusCheck = nil
        
        guard indexToProcess.row < rootView.tableView.numberOfRows(inSection: indexToProcess.section),
              indexToProcess.row < self.viewModel.messageClusters[indexToProcess.section].items.count,
              !checkIfMessageWasSeen(at: indexToProcess)
        else { return }
        
        let unseenMessage = self.viewModel.messageClusters[indexToProcess.section].items[indexToProcess.row].message

        if let unseenMessage
        {
            Task {
                await viewModel.updateRealmMessagesSeenStatus(startingFromMessage: unseenMessage)
                viewModel.updateUnseenMessageCounterLocally()
                viewModel.updateFirebaseMessagesSeenStatus(startingFrom: unseenMessage)
                viewModel.updateUnseenMessageCounterRemote()
            }
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
        rootView.sendMessageButton.addTarget(self, action: #selector(sendMessageButtonWasTapped), for: .touchUpInside)
    }
    private func addTargetToAddPictureBtn() {
        rootView.addPictureButton.addTarget(self, action: #selector(addPicture), for: .touchUpInside)
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
    
    private func determineMessageType(text: String, image: UIImage?) -> MessageType?
    {
        switch (text.isEmpty, image) {
        case (false, .some): return .imageText
        case (false, .none): return .text
        case (true, .some): return .image
        case (true, .none): return nil
        }
    }

    private func clearInputUI() {
        removeTextViewText()
        inputMessageTextViewDelegate.invalidateTextViewSize()
        callTextViewDidChange()
    }
    
    @objc func sendMessageButtonWasTapped()
    {
        Task { @MainActor in
            
            let trimmedText = getTrimmedString()
            let image = self.messageImage
            self.messageImage = nil

            guard let messageType = determineMessageType(text: trimmedText,
                                                         image: image) else
            {
                return // Nothing to send
            }

            let imageRepository = image.map {
                ImageSampleRepository(image: $0, type: .message)
            }

            let message = viewModel.createNewMessage(
                ofType: messageType,
                messageText: trimmedText,
                imagePath: imageRepository?.imagePath(for: .original)
            )
            
            viewModel.createMessageClustersWith([message])
            
            if !viewModel.conversationExists {
                viewModel.setupConversation()
            }

            viewModel.handleLocalUpdatesOnMessageCreation(message)

            clearInputUI()

            if let repository = imageRepository {
                await viewModel.saveImagesLocally(fromImageRepository: repository, for: message.id)
            }

            createMessageBubble()
            closeInputBarHeaderView()
            
            await viewModel.initiateRemoteUpdatesOnMessageCreation(
                message,
                imageRepository: imageRepository
            )
        }
    }

    @objc func addPicture()
    {
        let cameraAvailable = PermissionManager.shared.isCameraAvailable()
        
        alertPresenter.presentImageSourceOptions(from: self,
                                                 cameraAvailable: cameraAvailable)
        {
            PermissionManager.shared.requestCameraPermision() { granted in
                Task { @MainActor in
                    if granted {
                        self.openCamera()
                    } else {
                        self.alertPresenter.presentPermissionDeniedAlert(from: self)
                    }
                }
            }
        } onGallery: {
            Task { @MainActor in
                self.configurePhotoPicker()
            }
        }
    }
    
    private func openCamera()
    {
        let picker = UIImagePickerController()
        picker.delegate = self
        picker.sourceType = .camera
        picker.allowsEditing = true
        picker.cameraCaptureMode = .photo
        present(picker, animated: true)
    }
    
    private func configurePhotoPicker()
    {
        var configuration = PHPickerConfiguration()
        configuration.selectionLimit = 1
        configuration.filter = .images
        let pickerVC = PHPickerViewController(configuration: configuration)
        pickerVC.delegate = self
        present(pickerVC, animated: true)
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

//MARK: - Camera delegate
extension ChatRoomViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate
{
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any])
    {
        picker.dismiss(animated: true)
        
        if let image = info[.editedImage] as? UIImage
        {
            self.preparePhotoForSending(image)
            return
        }
        
        if let image = info[.originalImage] as? UIImage
        {
            self.preparePhotoForSending(image)
        }
    }
}

//MARK: - Photo picker delegate
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
                
                self.preparePhotoForSending(image)
            }
        }
    }
}

//MARK: Selected photo preparation
extension ChatRoomViewController
{
    private func preparePhotoForSending(_ photo: UIImage)
    {
        Task { @MainActor in
            guard let imageThumbnail = await photo.byPreparingThumbnail(ofSize: CGSize(width: 80, height: 80)) else {return}
            self.handleContextMenuSelectedAction(
                actionOption: .image(imageThumbnail),
                selectedMessageText: nil)
            self.messageImage = photo
        }
    }
}

//MARK: - GESTURES
extension ChatRoomViewController {
    
    private func addGestureToTableView() {
        let tap = UITapGestureRecognizer(target: self, action: #selector(resignKeyboard))
        tap.cancelsTouchesInView = false
        rootView.tableView.addGestureRecognizer(tap)
        
        let panGesture = UIPanGestureRecognizer(target: self, action: #selector(handleTablePan))
        panGesture.delegate = self
        rootView.tableView.addGestureRecognizer(panGesture)
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
        
        let dateForSection = viewModel.messageClusters[section].date.formattedAsDayLabel()
        footerView.setDate(dateText: dateForSection)
        return footerView
    }
    
    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return 50
    }
    
    func tableView(_ tableView: UITableView, willDisplayFooterView view: UIView, forSection section: Int)
    {
        guard !tableView.sk.isSkeletonActive else {
            view.isHidden = true
            return
        }
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if viewModel.conversationInitializationStatus == .inProgress {
            return CGFloat((70...120).randomElement()!)
        }
       return  UITableView.automaticDimension
    }
    
    
    func globalIndex(for indexPath: IndexPath, in groupedData: [[ChatRoomViewModel.MessageItem]]) -> Int?
    {
        guard indexPath.section < groupedData.count else { return nil }
        
        var index = 0
        for section in 0..<indexPath.section {
            index += groupedData[section].count
        }
        index += indexPath.row
        return index
    }
    
    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath)
    {
        guard !viewModel.messageClusters.isEmpty,
              didFinishInitialScrollToUnseenIndexPathIfAny else { return }
        
        let groupedClusterItems = viewModel.messageClusters.map { $0.items }
        let totalItems = groupedClusterItems.flatMap { $0 }.count
        
        
        if let globalIndex = globalIndex(for: indexPath, in: groupedClusterItems) {
            if globalIndex == 5
            {
                paginateIfNeeded(ascending: true)
            } else if globalIndex == totalItems - 6
            {
                paginateIfNeeded(ascending: false)
            }
        }
    }
  
    private func paginateIfNeeded(ascending: Bool)
    {
        Task { @MainActor in
            
            self.viewModel.isLocalPaginationActive = true
            
            if let (newRows, newSections) = viewModel.paginateAdditionalLocalMessages(ascending: ascending)
            {
                performeTableViewUpdateOnLocalPagination(
                    withRows: newRows,
                    sections: newSections
                )
                
                viewModel.isLocalPaginationActive = false
                
                if let startMessage = viewModel.lastPaginatedMessage
                {
                    viewModel.messageListenerService?.addListenerToExistingMessagesTest(
                        startAtMesssage: startMessage,
                        ascending: !ascending,
                        limit: ObjectsPaginationLimit.localMessages)
                }
                viewModel.isLocalPaginationActive = false
                return
            }
            
            viewModel.isLocalPaginationActive = false
            if !isNetworkPaginationRunning
            {
                isNetworkPaginationRunning = true
                await viewModel.remoteMessagePaginator.perform {
                    await preformRemotePagination(ascending: ascending)
                }
            }
//            viewModel.isLocalPaginationActive = false
        }
    }
 
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
//        Task { @MainActor in
//            guard let id = self.viewModel.conversation?.id else {return}
//            
//            self.updateRealmSeenToFalse()
//            
//            FirebaseChatService.shared.updateMessageSeenStatusToTrue(fromChatWithID: id)
//        }
    }
    
    func updateRealmSeenToFalse() {
        guard let messages = viewModel.conversation?.conversationMessages else {return}
        
        RealmDataBase.shared.update {
            for message in messages {
                message.messageSeen = false
            }
        }
    }
    
    private func performeTableViewUpdateOnRemotePagination(withRows rows: [IndexPath],
                                                           sections: IndexSet?)
    {
        var visibleCell: MessageTableViewCell? = nil
        let currentOffsetY = self.rootView.tableView.contentOffset.y
        
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        
        self.rootView.tableView.performBatchUpdates({
            visibleCell = self.rootView.tableView.visibleCells.first as? MessageTableViewCell
            
            if let sections {
                self.rootView.tableView.insertSections(sections, with: .none)
            }
            if !rows.isEmpty {
                self.rootView.tableView.insertRows(at: rows, with: .none)
            }
//            self.shouldIgnoreUnseenMessagesUpdateForTimePeriod = Date()
            self.shouldIgnoreUnseenMessagesUpdate = true
        }, completion: { complete in
            self.shouldIgnoreUnseenMessagesUpdate = false
            if self.rootView.tableView.contentOffset.y < -97.5 && complete
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
        
//        rootView.tableView.setContentOffset(CGPoint(x: rootView.tableView.contentOffset.x, y: rootView.tableView.contentOffset.y), animated: false)
        
//        CATransaction.commit()
//        })
    }
    
    private func performeTableViewUpdateOnLocalPagination(withRows rows: [IndexPath],
                                                          sections: IndexSet?)
    {
        UIView.animate(withDuration: 0.0)
        {
            self.rootView.tableView.performBatchUpdates
            {
                if let sections {
                    self.rootView.tableView.insertSections(sections, with: .none)
                }
                if !rows.isEmpty {
                    self.rootView.tableView.insertRows(at: rows, with: .none)
                }
                //            self.shouldIgnoreUnseenMessagesUpdateForTimePeriod = Date()
                self.shouldIgnoreUnseenMessagesUpdate = true
            } completion: { completed in
                self.shouldIgnoreUnseenMessagesUpdate = false
            }
        }
    }
    
    private func preformRemotePagination(ascending: Bool) async
    {
        do {
            try await Task.sleep(for: .seconds(1))
            
            if let (newRows, newSections) = try await viewModel.handleAdditionalMessageClusterUpdate(inAscendingOrder: ascending)
            {
                await MainActor.run {
                    performeTableViewUpdateOnRemotePagination(withRows: newRows,
                                                              sections: newSections)
                    
                    if ascending && viewModel.shouldAttachListenerToUpcomingMessages
                    {
                        viewModel.messageListenerService?.addListenerToUpcomingMessages()
                    }
                }
            }
        } catch {
            print("Could not update conversation with additional messages: \(error)")
        }
        isNetworkPaginationRunning = false
    }
}

//MARK: - SCROLL VIEW DELEGATE
extension ChatRoomViewController: UIScrollViewDelegate
{
    func scrollViewDidScroll(_ scrollView: UIScrollView)
    {
        /// See FootNote.swift [13]
        if shouldIgnoreUnseenMessagesUpdate
        {
            self.pendingIndexPathForSeenStatusCheck = nil
            return
        }
        /// find min index path, to update all descending messages from it
        findMinimalVisibleIndexPath()
        
        /// fire updates every > 0.1 time
        if Date().timeIntervalSince(lastSeenStatusCheckUpdate) > 0.1
        {
            self.lastSeenStatusCheckUpdate = Date()

            if viewModel.shouldHideJoinGroupOption { updateMessageSeenStatusIfNeeded() }
        }

        /// Toggle scrollToBottom badge
        isLastCellFullyVisible ?
        toggleScrollBadgeButtonVisibility(shouldBeHidden: true)
        :
        toggleScrollBadgeButtonVisibility(shouldBeHidden: false)
    }
    
    func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        toggleSectionHeaderVisibility(isScrollActive: true)
    }
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView)
    {
        
        toggleSectionHeaderVisibility(isScrollActive: false)
    }
    
    func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool)
    {
        self.lastSeenStatusCheckUpdate = Date()
        if viewModel.shouldHideJoinGroupOption { updateMessageSeenStatusIfNeeded() }
        
        toggleSectionHeaderVisibility(isScrollActive: decelerate)
    }
}

//MARK: - ScrollView helper functions
extension ChatRoomViewController
{
    private func findMinimalVisibleIndexPath()
    {
        if let visibleIndices = rootView.tableView.indexPathsForVisibleRows?.sorted(),
           let firstVisible = visibleIndices.first(where: { checkIfCellIsFullyVisible(at: $0) })
        {
            
            if let pending = pendingIndexPathForSeenStatusCheck {
                // Pick the first smaller fully visible index if it exists
                if firstVisible < pending {
                    pendingIndexPathForSeenStatusCheck = firstVisible
                }
            } else {
                // No pending → just take the first fully visible
                pendingIndexPathForSeenStatusCheck = firstVisible
            }
        }
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


//MARK: Context Menu configuration
extension ChatRoomViewController
{
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
            guard messageCell.containerStackView.frame.contains(tapLocationInCell) else { return nil }
            
            return UIContextMenuConfiguration(identifier: identifier, previewProvider: nil) { _ in
                return menuBuilder.buildUIMenuForMessage(message: message)
            }
        }
        else if let eventCell = baseCell as? MessageEventCell,
                let message = eventCell.cellViewModel.message
        {
            let tapLocationInCell = eventCell.contentView.convert(point, from: tableView)
            guard eventCell.messageEventContainer.frame.contains(tapLocationInCell) else { return nil }
            
            return UIContextMenuConfiguration(identifier: identifier, previewProvider: nil) { _ in
                return menuBuilder.buildUIMenuForEvent(message: message)
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
    
    private func handleContextMenuSelectedAction(
        actionOption: InputBarHeaderView.Mode,
        selectedMessageText text: String?
    )
    {
        self.rootView.activateInputBarHeaderView(mode: actionOption)
        self.addGestureToCloseBtn()
        self.rootView.messageTextView.becomeFirstResponder()
        self.rootView.inputBarHeader?.setInputBarHeaderSubtitleMessage(text)
        self.inputMessageTextViewDelegate.textViewDidChange(self.rootView.messageTextView)
    }
}


//MARK: Draggable cell
extension ChatRoomViewController: UIGestureRecognizerDelegate
{
    @objc private func handleTablePan(_ gesture: UIPanGestureRecognizer)
    {
        let table = self.rootView.tableView
        let location = gesture.location(in: table)
        let translation = gesture.translation(in: table)
        
        var translationX = translation.x
        let dragTreshhold: CGFloat = 50.0
        let resistanceFactor: CGFloat = 0.30
        
        switch gesture.state
        {
        case .began:
            guard let indexPath = table.indexPathForRow(at: location),
                  let dragableCell = table.cellForRow(at: indexPath) as? MessageCellDragable else {return}
            self.dragableCell = dragableCell
            self.draggingCellOriginalCenter = dragableCell.center
        case .changed:
            guard translation.x < 0 else {return}
            
            let absX = abs(translationX)

            if absX >= dragTreshhold
            {
                let excess = absX - dragTreshhold
                let resitance = excess * resistanceFactor
                translationX = -dragTreshhold - resitance
                if !hapticWasInitiated {
                    let haptic = UIImpactFeedbackGenerator(style: .heavy)
                    haptic.prepare()
                    haptic.impactOccurred()
                    self.hapticWasInitiated = true
                }
            }
            self.dragableCell?.center = CGPoint(
                x: draggingCellOriginalCenter.x + translationX,
                y: draggingCellOriginalCenter.y
            )
        case .cancelled, .ended:
            UIView.animate(withDuration: 0.25) {
                self.dragableCell?.center = self.draggingCellOriginalCenter
            }
            self.hapticWasInitiated = false
            self.handleContextMenuSelectedAction(
                actionOption: .edit(dragableCell?.messageImage),
                selectedMessageText: dragableCell?.messageText
            )
            self.dragableCell = nil
        default: break
        }
    }

    func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool
    {
        guard let panGesture = gestureRecognizer as? UIPanGestureRecognizer else {
            return true
        }
        
        let translation = panGesture.translation(in: rootView.tableView)
        
        // Only allow if horizontal drag is dominant (to avoid interfering with vertical scroll)
        if abs(translation.x) <= abs(translation.y) {
            return false
        }
        
        // Also, check if gesture started on a valid cell
        let location = panGesture.location(in: rootView.tableView)
        guard let indexPath = rootView.tableView.indexPathForRow(at: location),
              let _ = rootView.tableView.cellForRow(at: indexPath) as? MessageCellDragable else {
            return false
        }
        
        return true
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
