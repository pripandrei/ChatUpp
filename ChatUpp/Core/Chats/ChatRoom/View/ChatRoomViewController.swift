//
//  ConversationViewController.swift
//  ChatUpp
//
//  Created by Andrei Pripa on 10/3/23.

// NOTE: The conversation table view is a STANDARD (non-inverted) table:
// index 0 / section 0 is the OLDEST message, the last row is the NEWEST.
// The table is pinned to the whole root view and the input bar overlays its
// bottom edge, so bottom content insets keep the newest message visible.


import UIKit
import SwiftUI
import Photos
import PhotosUI
import Combine
import SkeletonView
import SKPhotoBrowser

final class ChatRoomViewController: UIViewController
{
    weak var coordinatorDelegate :Coordinator?
    
    private var animatedPreviewViews: [UIView] = []
    private var targetedPreview: UITargetedPreview?
    
    private var pendingIndexPathForSeenStatusCheck: IndexPath?
    private var isNetworkPaginationRunning: Bool = false
    
    private var dragableCell: MessageCellDragable?
    private var draggingCellOriginalCenter: CGPoint = .zero
    private var hapticWasInitiated: Bool = false
    
    private var messageImage: UIImage? = nil
    private var shouldIgnoreUnseenMessagesUpdate: Bool = false
    private var lastSeenStatusCheckUpdate: Date = Date()
    
    private var dataSourceManager : ConversationDataSourceManager!
    private var customNavigationBar :ChatRoomNavigationBar!
    private var rootView: ChatRoomRootView!
    private var viewModel: ChatRoomViewModel!
    private var inputMessageTextViewDelegate: InputBarTextViewDelegate!
    private var subscriptions = Set<AnyCancellable>()
    private lazy var alertPresenter: AlertPresenter = .init()

    private var isContextMenuPresented: Bool = false
    private var isKeyboardHidden: Bool = true
    private var didFinishInitialScrollToUnseenIndexPathIfAny: Bool = true
    private var paginateOldMessagesOnInitialChatOpen: Bool = true
    /// set while the animated scroll-to-newest flight is running, so its
    /// completion (`scrollViewDidEndScrollingAnimation`) can re-land the view
    /// on the real bottom edge - see `settleScrollAtNewestMessage`.
    private var isScrollingToNewestMessage: Bool = false
    /// Guards `finalizeConversationSetup()` against a second invocation:
    /// both the debounced `$conversationInitializationStatus` subscription and
    /// `viewDidLayoutSubviews` can observe `.finished`, and re-running would
    /// re-apply the snapshot and re-scroll (the "table shifts back and forth
    /// on chat room open" bug).
    private var didFinalizeConversationSetup: Bool = false
    
    /// Index path of the newest message (last section, last row) in the current table.
    private var newestIndexPath: IndexPath? {
        let lastSection = rootView.tableView.numberOfSections - 1
        guard lastSection >= 0 else { return nil }
        let rows = rootView.tableView.numberOfRows(inSection: lastSection)
        guard rows > 0 else { return nil }
        return IndexPath(row: rows - 1, section: lastSection)
    }
    
    private var isNewestCellFullyVisible: Bool {
        guard let newestIndexPath else { return true }
        return checkIfCellIsFullyVisible(at: newestIndexPath)
    }
    
    private func isNewestIndexPathVisible() -> Bool {
        guard let newestIndexPath else { return false }
        return rootView.tableView.indexPathsForVisibleRows?.contains(newestIndexPath) ?? false
    }
    
    /// Randomized heights the skeleton cells display with while the chat room
    /// waits for remote messages. `heightForRowAt` is re-queried by UIKit on
    /// every layout pass during the opening sequence (frame / safe area /
    /// input bar settling, inset changes), so drawing a fresh random value per
    /// query visibly re-shuffles the skeleton cell sizes right after open -
    /// one height is therefore fixed per row and reused until the skeleton
    /// animation is terminated / re-initiated for the next room.
    private var skeletonRowHeights: [Int: CGFloat] = [:]
    

    lazy private var photoBrowser: SKPhotoBrowserManager = SKPhotoBrowserManager()
    
    //MARK: - Lifecycle
    
    convenience init(conversationViewModel: ChatRoomViewModel) {
        self.init()
        self.viewModel = conversationViewModel
    }
    
    override func loadView()
    {
        let backgroundImage = getBackgroundImage()
        self.rootView = ChatRoomRootView(backgroundImage: backgroundImage)
        view = self.rootView
        inputMessageTextViewDelegate = InputBarTextViewDelegate(view: rootView)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupController()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        if viewModel.conversationInitializationStatus == .finished {
            finalizeConversationSetup()
        }
    }
    
    override func viewWillDisappear(_ animated: Bool)
    {
        super.viewWillDisappear(animated)
        
        terminateAudioSession()
    }
    
    deinit {
        print("ChatRoomVC deinit")
        cleanUp()
    }
    
    private func scrollToCell(at indexPath: IndexPath)
    {
        /// land on the "Unread Messages" divider at the top so the unseen
        /// block below it is visible
        guard indexPath.section < self.rootView.tableView.numberOfSections,
              indexPath.row < self.rootView.tableView.numberOfRows(inSection: indexPath.section)
        else { return }
        
        self.rootView.tableView.scrollToRow(at: indexPath, at: .top, animated: false)
    }

    private func setupController()
    {
        self.performAdditionalSetupForRootView()
        self.configureTableView()
        self.addGestureToTableView()
        self.setNavigationBarItems()
        self.addTargetsToButtons()
        self.addKeyboardNotificationObservers()
        self.setupBinding()
        self.updateTableViewBottomInset(animated: false)
    }
    
    private func performAdditionalSetupForRootView()
    {
        if viewModel.conversation == nil || viewModel.conversation?.recentMessageID == nil
        {
            self.rootView.setupGreetingView()
        }
        self.rootView.setInputBarParametersVisibility(shouldHideJoinButton: viewModel.shouldHideJoinGroupOption)
    }
    
    private func configureTableView()
    {
        self.rootView.tableView.delegate = self
        
        let chatType: ChatType = viewModel.conversation?.isGroup == true ? ._group : ._private
        let layoutProvider: MessageLayoutManager = .init(chatType: chatType,
                                                         sourceProvider: self.viewModel.messageClusterRepository)
        self.dataSourceManager = ConversationDataSourceManager(
            dataProvider: self.viewModel.messageClusterRepository,
            layoutProvider: layoutProvider,
            tableView: self.rootView.tableView
        )
    }
    
    private func addTargetsToButtons() {
        addTargetToSendMessageBtn()
        addTargetToAddPictureBtn()
        addTargetToEditMessageBtn()
        addTargetToScrollToBottomBtn()
        addTargetToJoinGroupBtn()
        addTargetToVoiceRecButton()
    }
    
    private func refreshTableView()
    {
        self.toggleSkeletonAnimation(.terminated)
        self.dataSourceManager.configureSnapshot(animationType: .none)
        self.view.layoutIfNeeded()
        /// the input bar has been laid out by now, so its real height is known
        self.updateTableViewBottomInset(animated: false)
        self.updateTopContentInsetToAnchorContentAtBottom()
    }
    
    private func finalizeConversationSetup()
    {
        /// only ever run once (see note on `didFinalizeConversationSetup`)
        guard !didFinalizeConversationSetup else { return }
        didFinalizeConversationSetup = true
        
        viewModel.resetInitializationStatus()
        
        let unseenIndexPath = viewModel.shouldHideJoinGroupOption == true
        ?
        self.viewModel.findLastUnseenMessageIndexPath() : nil
        
        if let unseenIndexPath {
            viewModel.insertUnseenMessagesTitle(at: unseenIndexPath)
        }
        
        /// Block `willDisplay`-triggered pagination (and the "new message"
        /// entrance animation) until the initial scroll has settled, so data
        /// prepends/appends can't fight the initial scroll positioning.
        /// Applies in BOTH branches - the scroll-to-bottom branch used to leave
        /// the gate open, which let the initial forced pagination prepend
        /// messages mid-scroll and shift the table back and forth.
        self.didFinishInitialScrollToUnseenIndexPathIfAny = false
        
        refreshTableView()
        
        if let unseenIndexPath {
            self.scrollToCell(at: unseenIndexPath)
        } else {
            /// no unseen messages: land on the newest message
            self.scrollToBottom(animated: false, delayed: false)
        }
        
        executeAfter(seconds: 1.0) {
            self.didFinishInitialScrollToUnseenIndexPathIfAny = true
            self.paginateOldMessagesOnInitialChatOpen = false
        }
        
        if viewModel.authParticipantUnreadMessagesCount > 0
        {
            triggerUpdateUnseenMessagesCheck()
        }
        
        toggleSectionHeaderVisibility(isScrollActive: false, withAnimation: false)
    }
    
    private func getBackgroundImage() -> UIImage
    {
        if let backgroundKey = Utilities.retrieveSelectedThemeKey(),
           let data = CacheManager.shared.retrieveData(from: "Themes/\(backgroundKey)"),
           let image = UIImage(data: data)
        {
             return image
        }
        return UIImage(named: "chat_background_default_theme") ?? .actions
    }
    
    //MARK: - Bindings
    
    private func setupBinding()
    {
        rootView.onInputBarHeaderHeightChange = { [weak self] in
            self?.updateTableViewBottomInset(animated: true)
        }
        
        AudioSessionManager.shared.$currentRecordingTime
            .sink { [weak self] time in
                let minutes = Int(time) / 60
                let seconds = Int(time) % 60
                let milliseconds = (Int((time - floor(time)) * 1000)) / 10
                
                let timeString = String(format: "%2d:%02d.%02d", minutes, seconds, milliseconds)
                self?.rootView.updateRecCounterLabelText(with: timeString)
            }.store(in: &subscriptions)
        
        Publishers.Merge(
            rootView.cancelRecordingSubject,
            AudioSessionManager.shared.recordCancellationSubject
        )
        .sink { [weak self] _ in
            self?.rootView.destroyVoiceRecUIComponents()
            AudioSessionManager.shared.stopRecording(withAudioRecDeletion: true)
            print("cancelled rec publisher")
        }.store(in: &subscriptions)
        
        inputMessageTextViewDelegate.$isTextViewEmpty
            .dropFirst()
            .sink { [weak self] isEmpty in
                
                // return if input bar currently contains image
                if case .image(_) = self?.rootView.inputBarHeader?.mode { return }
                
                let shouldBeVisible = isEmpty
                self?.rootView.toggleVoiceRecButtonVisibility(shouldBeVisible)
            }.store(in: &subscriptions)
        
        viewModel.messageClusterRepository.$messageClusters
            .receive(on: DispatchQueue.main)
            .sink { [weak self] clusters in
                if !clusters.isEmpty { self?.rootView.removeGreetingViewIfNeeded() }
            }.store(in: &subscriptions)
        
        viewModel.$unseenMessagesCount
//            .debounce(for: 0.3, scheduler: DispatchQueue.main)
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
        
        viewModel.datasourceUpdateType 
            .receive(on: DispatchQueue.main)
            .sink { [weak self] updateType in
                guard let self = self else { return }
                
                var updateType = updateType
                /// while the initial scroll hasn't settled the table must stay
                /// still - incoming (gap-fill) messages simply appear instead
                /// of animating, otherwise the table shifts back and forth
                /// right after chat room open
                if !self.didFinishInitialScrollToUnseenIndexPathIfAny {
                    updateType = .none
                }
                let isUpdateAnimationNone = updateType == .none
                let wasAtBottom = self.isNewestIndexPathVisible()
                    || self.rootView.tableView.indexPathsForVisibleRows?.isEmpty == true
                if isUpdateAnimationNone
                {
                    if !wasAtBottom {
                        updateType = .automatic
                    }
                }
                
                self.dataSourceManager.configureSnapshot(animationType: updateType)
                self.updateTopContentInsetToAnchorContentAtBottom()
                if isUpdateAnimationNone {
                    self.handleNewMessageDisplay()
                }
                
            }.store(in: &subscriptions)
        
        inputMessageTextViewDelegate.lineNumberModificationSubject
            .debounce(for: .seconds(0.1), scheduler: DispatchQueue.main)
            .sink { [weak self] updatedLinesNumber, currentLinesNumber in
                self?.adjustTableViewContent(withUpdatedNumberOfLines: updatedLinesNumber,
                                             currentNumberOfLines: currentLinesNumber)
            }
            .store(in: &subscriptions)
        
        inputMessageTextViewDelegate.textViewDidBeginEditing
            .debounce(for: .seconds(0.2),
                      scheduler: DispatchQueue.main)
            .sink { [weak self] didBegin in
                if didBegin && self?.rootView.stickerCollectionView != nil
                {
                    self?.rootView.showStickerIcon()
                    executeAfter(seconds: 1) {
                        if self?.rootView.trailingItemState.item == .stickerItem
                        {
                            self?.rootView.removeStickerView()
                            self?.updateTableViewBottomInset(animated: true)
                        }
                    }
                }
            }
            .store(in: &subscriptions)
        
        rootView.contentOffsetSubject
            .sink { [weak self] _ in
                guard let self else {return}
                
                if self.rootView.messageTextView.isFirstResponder
                {
                    /// swapping the keyboard for the sticker panel: dismiss the
                    /// keyboard but keep the input bar raised for the panel
                    self.rootView.messageTextView.resignFirstResponder()
                    /// the keyboardWillHide handler skips the layout while the
                    /// sticker panel is attached, so the hidden state must be
                    /// reconciled here (otherwise the keyboard's rise height
                    /// keeps padding the inset after the panel is gone)
                    self.isKeyboardHidden = true
                    self.updateTableLayoutAlongsideStickerPanel(obscuringHeight: self.stickerPanelHeight)
                    {
                        self.rootView.updateInputBarBottomConstraint(toSize: -self.stickerPanelHeight)
                    }
                    return
                }
                
                /// raise the input bar so the sticker panel can fill the space
                /// below it - the in-animation offset shift keeps the table in
                /// sync with the input bar instead of catching up afterwards
                if self.rootView.greetingView != nil
                {
                    self.rootView.toggleGreetingViewPosition(up: true,
                                                             lineLift: self.greetingLineLift)
                }
                self.updateTableLayoutAlongsideStickerPanel(obscuringHeight: self.stickerPanelHeight)
                {
                    self.rootView.updateInputBarBottomConstraint(toSize: -self.stickerPanelHeight)
                }
            }
            .store(in: &subscriptions)
        
        ChatManager.shared.newStickerSubject
            .sink { [weak self] sticker in
                    self?.createStickerMessage(sticker)
            }.store(in: &subscriptions)
    }
    
    //MARK: - Keyboard notification observers
    
    private func addKeyboardNotificationObservers()
    {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(keyboardWillShow),
            name: UIResponder.keyboardWillShowNotification,
            object: nil
        )
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(keyboardWillHide),
            name: UIResponder.keyboardWillHideNotification,
            object: nil
        )
    }

    @objc func keyboardWillShow(notification: NSNotification)
    {
        guard (notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue != nil
        else { return }
        
        /// See FootNote.swift [15]
        isKeyboardHidden = false
        
        if rootView.greetingView != nil
        {
            self.rootView.toggleGreetingViewPosition(up: true,
                                                     lineLift: self.greetingLineLift)
        }
        
        updateTableLayoutAlongsideKeyboard(notification) {
            self.rootView.updateInputBarBottomConstraint(toSize: -self.keyboardRiseHeight)
        }
    }
    
    @objc func keyboardWillHide(notification: NSNotification)
    {
        guard (notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue != nil
        else { return }
        guard self.rootView.stickerCollectionView == nil else { return }
        
        isKeyboardHidden = true
        
        if rootView.greetingView != nil
        {
            rootView.toggleGreetingViewPosition(up: false)
        }
        
        updateTableLayoutAlongsideKeyboard(notification) {
            self.rootView.updateInputBarBottomConstraint(toSize: 0)
        }
    }
    
    //MARK: - Private functions
    
    private func cleanUp()
    {
        NotificationCenter.default.removeObserver(self)
        viewModel.removeAllListeners()
        dataSourceManager.cleanup()
        CacheManager.shared.clear()
        ChatRoomSessionManager.activeChatID = nil
        AudioSessionManager.shared.cleanupPlaybackMetaData()
    }
    
    @objc private func dismissInputBarView()
    {
        if rootView.stickerCollectionView != nil
        {
            rootView.showStickerIcon()
            dismissStickerView()
        } else {
            resignKeyboard()
        }
    }
    
    private func resignKeyboard()
    {
        if self.rootView.messageTextView.isFirstResponder {
            self.rootView.messageTextView.resignFirstResponder()
        }
    }
    
    private func dismissStickerView()
    {
        /// the input bar drop and the table's offset shift run inside one
        /// animation (padding already targets 0 while the panel is still
        /// attached), so they move together instead of the table catching up
        /// after the chrome settles
        if rootView.greetingView != nil
        {
            rootView.toggleGreetingViewPosition(up: false)
        }
        self.updateTableLayoutAlongsideStickerPanel(obscuringHeight: 0)
        {
            self.rootView.updateInputBarBottomConstraint(toSize: 0)
            self.rootView.stickerCollectionViewTopConstraint?.constant = 0.0
        } completion: { _ in
            self.rootView.removeStickerView()
        }
    }

    private func animateInputBarHeaderViewDestruction()
    {
        guard let inputBarHeaderView = rootView.inputBarHeader else {return}

        UIView.animate(withDuration: 0.3) {
            self.startInputBarHeaderViewDestruction(inputBarHeaderView)
        } completion: { complition in
            if complition {
                self.endInputBarHeaderViewDestruction()
            }
        }
    }
    
    private func startInputBarHeaderViewDestruction(_ inputBarHeaderView: InputBarHeaderView)
    {
        inputBarHeaderView.inputBarHeightConstraint?.constant = 0
        inputBarHeaderView.subviews.forEach({ view in
            view.layer.opacity = 0.0
        })
        self.rootView.sendEditMessageButton.layer.opacity = 0.0
        
        mainQueue {
            self.inputMessageTextViewDelegate.textViewDidChange(self.rootView.messageTextView)
        }
        
        self.rootView.scrollToBottomBtnBottomConstraint.constant += 45
        self.rootView.layoutIfNeeded()
        self.updateTableViewBottomInset(animated: false)
    }
    
    private func endInputBarHeaderViewDestruction() {
        self.rootView.destroyInputBarHeaderView()
        self.rootView.sendEditMessageButton.isHidden = true
        self.rootView.sendEditMessageButton.layer.opacity = 1.0
        self.rootView.inputBarContainer.pinBlurTopConstraint(to: self.rootView.inputBarContainer)
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

        /// a cell is visible when its bottom edge sits above the input bar top
        let isCellVisible = cellRect.maxY <= inputBarRect.minY
        return isCellVisible ? .visible : .underInputBar
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

        return lastCellRect.maxY <= inputBarRect.minY
    }
    
    private func toggleScrollBadgeButtonVisibility(shouldBeHidden: Bool)
    {
        UIView.animate(withDuration: 0.3) {
            self.rootView.scrollBadgeButton.layer.opacity = shouldBeHidden ? 0.0 : 0.9
        }
    }
    
    private func terminateAudioSession()
    {
        let audioManager = AudioSessionManager.shared
        
        if audioManager.isRecording()
        {
            audioManager.recordCancellationSubject.send(())
        }
        if audioManager.isAudioPlaying
        {
            audioManager.stopPlayback()
        }
    }
}

//MARK: - Handle cell message insertion
extension ChatRoomViewController
{
    @discardableResult
    private func handleNewMessageDisplay() -> Bool
    {
        guard isNewestIndexPathVisible() || rootView.tableView.indexPathsForVisibleRows?.isEmpty == true else { return false }
        
        /// during the initial load window the table must stay still:
        /// a new/gap message just appears and the view simply stays pinned to
        /// the bottom, with no entrance animation or extra animated scroll
        /// (prevents the shift back and forth on chat room open)
        guard didFinishInitialScrollToUnseenIndexPathIfAny else {
            scrollToNewestMessage(animated: false)
            return true
        }
        
        let isNewSectionAdded = viewModel.messageClusterRepository.messageClusters.last?.items.count == 1
        animateNewestCellInsertion(withNewSectionAdded: isNewSectionAdded)
        return true
    }
    
    private func animateNewestCellInsertion(withNewSectionAdded isNewSectionAdded: Bool)
    {
        guard let indexPath = newestIndexPath else { return }
        let tableView = rootView.tableView
        
        tableView.layoutIfNeeded()
        
        guard let cell = tableView.cellForRow(at: indexPath) else { return }
        
        let cellTopInView = tableView.convert(cell.frame, to: rootView).minY
        let slideDistance = max(60, rootView.inputBarContainer.frame.minY - cellTopInView)
        
        cell.transform = CGAffineTransform(translationX: 0, y: slideDistance)
        
        UIView.animate(withDuration: 0.3, delay: 0.1) {
            cell.transform = .identity
        }
        
        executeAfter(seconds: 0.1) {
            self.scrollToNewestMessage(animated: true)
        }
        
        let lastSection = tableView.numberOfSections - 1
        guard isNewSectionAdded,
              let headerView = tableView.headerView(forSection: lastSection) else { return }
        
        headerView.transform = CGAffineTransform(scaleX: 0.1, y: 0.1)
        UIView.animate(withDuration: 0.3, delay: 0.1) {
            headerView.transform = .identity
        }
    }
    
    private func scrollToBottom(animated: Bool = true, delayed: Bool = true)
    {
        if delayed
        {
            executeAfter(seconds: 0.2) {
                self.scrollToNewestMessage(animated: animated)
            }
        } else {
            scrollToNewestMessage(animated: animated)
        }
    }
    
    private func scrollToNewestMessage(animated: Bool)
    {
        let tableView = rootView.tableView
        tableView.layoutIfNeeded()
        
        if animated
        {
            /// the animation target is computed ONCE here, from a content size
            /// that still contains ESTIMATED heights for rows that were skipped
            /// during scrolling (e.g. a block just inserted by a pagination
            /// prepend). While the flight runs, UIKit loads cells and those
            /// rows resolve to their real heights, moving the true bottom
            /// edge - but `setContentOffset` never re-targets. The flight ends
            /// a few messages short of the bottom, so once it completes
            /// (`scrollViewDidEndScrollingAnimation`) the view is re-landed
            /// on the real bottom via `settleScrollAtNewestMessage`.
            isScrollingToNewestMessage = true
            tableView.setContentOffset(CGPoint(x: tableView.contentOffset.x,
                                               y: bottomOffsetY(for: tableView)),
                                       animated: true)
            return
        }
        
        tableView.setContentOffset(CGPoint(x: tableView.contentOffset.x,
                                           y: bottomOffsetY(for: tableView)),
                                   animated: false)
        settleScrollAtNewestMessage()
    }
    
    /// lands precisely on the bottom edge after a direct (non animated)
    /// scroll: self-sizing rows resolve their REAL heights only once they are
    /// laid out at the bottom position, after which the content size changes
    /// and the previously computed offset no longer reaches the true bottom.
    /// Land, lay out and re-land until the position is stable (bounded, so a
    /// pathological estimate mismatch can't spin it forever).
    private func settleScrollAtNewestMessage()
    {
        let tableView = rootView.tableView
        
        var passes = 0
        while passes < 5
        {
            tableView.layoutIfNeeded()
            self.updateTopContentInsetToAnchorContentAtBottom()
            let targetOffsetY = bottomOffsetY(for: tableView)
            if abs(targetOffsetY - tableView.contentOffset.y) <= 0.5 { break }
            
            tableView.setContentOffset(CGPoint(x: tableView.contentOffset.x,
                                               y: targetOffsetY),
                                       animated: false)
            passes += 1
        }
        
        tableView.layoutIfNeeded()
    }
    
    private func bottomOffsetY(for tableView: UITableView) -> CGFloat
    {
        let minOffsetY = -tableView.adjustedContentInset.top
        return max(minOffsetY,
                   tableView.contentSize.height - tableView.bounds.height + tableView.adjustedContentInset.bottom)
    }

    /// When the whole content is shorter than the visible area (no scrolling
    /// needed), chat messages must sit pinned to the BOTTOM, above the input
    /// bar, with the empty space ABOVE them - every new message pushes the
    /// existing ones up, like in any chat.
    /// Implemented as a flexible TOP content inset: with it, the table's
    /// minimum offset coincides exactly with the "at the very bottom" offset
    /// (`bottomOffsetY`), so all of the existing scroll / landing / keyboard
    /// anchoring logic keeps working unchanged.
    private func updateTopContentInsetToAnchorContentAtBottom()
    {
        let tableView = rootView.tableView

        /// what the system (safe area etc.) contributes on top; it must be
        /// restored untouched when the flexible space is not needed
        let systemTopInset = tableView.adjustedContentInset.top - tableView.contentInset.top
        let availableHeight = tableView.bounds.height
            - tableView.adjustedContentInset.bottom
            - systemTopInset
        let contentHeight = tableView.contentSize.height

            let flexibleInset = max(0, availableHeight - contentHeight)

            if tableView.contentInset.top != flexibleInset
            {
                tableView.contentInset.top = flexibleInset
            }
    }

    private func handleRowAndSectionInsertion(with indexPath: IndexPath,
                                              withAnimation: Bool)
    {
        /// See FootNote.swift [5]
        if withAnimation {
            UIView.animate(withDuration: 0.0) {
                if self.viewModel.messageClusterRepository.messageClusters.count > self.rootView.tableView.numberOfSections
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
                if self.viewModel.messageClusterRepository.messageClusters.count > self.rootView.tableView.numberOfSections
                {
                    self.rootView.tableView.insertSections(IndexSet(integer: 0), with: .none)
                } else {
                    self.rootView.tableView.insertRows(at: [indexPath], with: .automatic)
                }
            }
        }
    }
}

//MARK: - Message seen status handler
extension ChatRoomViewController
{
    private func isNewer(_ lhs: IndexPath, than rhs: IndexPath) -> Bool {
        if lhs.section != rhs.section {
            return lhs.section > rhs.section
        }
        return lhs.row > rhs.row
    }

    static var counter = 0
    
    private func updateMessageSeenStatusIfNeeded(_ messageIndexPath: IndexPath)
    {
        if let lastIndexPath = pendingIndexPathForSeenStatusCheck,
           !isNewer(messageIndexPath, than: lastIndexPath) {
            return
        }

        guard messageIndexPath.row < rootView.tableView.numberOfRows(inSection: messageIndexPath.section),
              messageIndexPath.row < viewModel.messageClusterRepository.messageClusters[messageIndexPath.section].items.count,
              !checkIfMessageWasSeen(at: messageIndexPath)
        else {
            return
        }
        
        let unseenMessage =
        viewModel.messageClusterRepository.messageClusters[messageIndexPath.section]
            .items[messageIndexPath.row]
            .message
        
        guard let unseenMessage else { return }
        
        // Update last processed index path
        pendingIndexPathForSeenStatusCheck = messageIndexPath
        
        Task {
            let updateResult = await viewModel.syncMessagesSeenStatus(startFrom: unseenMessage)

            if case .success(let updatedMessagesCount) = updateResult
            {
                await viewModel.updateMessagesUnseenCounter(
                    numberOfUpdatedMessages: updatedMessagesCount,
                    increment: false
                )
                await MainActor.run {
                    if messageIndexPath == self.pendingIndexPathForSeenStatusCheck
                    {
                        self.pendingIndexPathForSeenStatusCheck = nil
                    }
                }
            }
        }
    }

    private func checkIfMessageWasSeen(at indexPath: IndexPath) -> Bool
    {
        let authUserID = viewModel.authUser.uid
         
        // proceed further only if message does not belong to authenticated user
        guard let message = viewModel.messageClusterRepository.messageClusters[indexPath.section].items[indexPath.row].message,
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
extension ChatRoomViewController
{
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
    private func addTargetToVoiceRecButton()
    {
        rootView.voiceRecButton.addTarget(self, action: #selector(beginVoiceRecording), for: .touchUpInside)
    }
    
    private func triggerHapticFeedback(style: UIImpactFeedbackGenerator.FeedbackStyle)
    {
        let haptic = UIImpactFeedbackGenerator(style: style)
        haptic.prepare()
        haptic.impactOccurred()
    }
       
    @objc func beginVoiceRecording()
    {
        triggerHapticFeedback(style: .medium)
        
        executeAfter(seconds: 0.1) /// for haptic to work we need to delay rec start
        {
            PermissionManager.shared.requestMicrophonePermission { granted in
                Task { @MainActor in
                    if granted {
                        self.rootView.setupVoiceRecUIComponents()
                        AudioSessionManager.shared.pause()
                        AudioSessionManager.shared.startRecording()
                    } else
                    {
                        self.alertPresenter.presentPermissionDeniedAlert(from: self, for: .microphone)
                    }
                }
            }
        }
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

    @objc func scrollToBottomBtnWasTapped()
    {
        scrollToNewestMessage(animated: true)
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

    private func clearTextViewInput()
    {
        removeTextViewText()
        inputMessageTextViewDelegate.invalidateTextViewSize()
        callTextViewDidChange()
    }
    
    @objc func sendMessageButtonWasTapped()
    {
        if AudioSessionManager.shared.isRecording() {
            handleAudioMessageSend()
        } else {
            handleComposedMessageSend()
        }
    }

    private func handleAudioMessageSend()
    {
        rootView.destroyVoiceRecUIComponents()
        
        guard let url = AudioSessionManager.shared.getRecordedAudioURL() else {
            AudioSessionManager.shared.stopRecording()
            return
        }
        
        AudioSessionManager.shared.stopRecording()
        
        Task {
            let samples = await viewModel.generateWaveform(from: url)
            viewModel.createVoiceMessage(fromURL: url, withAudioSamples: samples)
            updateUIOnNewMessageCreation(.audio)
        }
    }

    /// - Handle text / image / text + image message sending
    private func handleComposedMessageSend()
    {
        let trimmedText = getTrimmedString()
        let image = messageImage
        messageImage = nil
        
        guard let messageType = determineMessageType(text: trimmedText, image: image) else {
            return
        }
        
        viewModel.ensureConversationExists()
        
        let imageSampleRepo = image.map { ImageSampleRepository(image: $0, type: .message) }
        let media = imageSampleRepo.map { MessageMediaContent.image(path: $0.imagePath(for: .original)) }
        
        let message = viewModel.createMessageLocally(
            ofType: messageType,
            text: trimmedText,
            media: media
        ) 
        
        Task { @MainActor in
            if let repo = imageSampleRepo
            {
                await viewModel.saveImagesLocally(fromImageRepository: repo, for: message.id)
            }
            updateUIOnNewMessageCreation(messageType)
        }
        
        // Start message remote sync
        viewModel.syncMessageWithFirestore(message.freeze(), imageRepository: imageSampleRepo)
    }
 
    func createStickerMessage(_ path: String)
    {
        viewModel.ensureConversationExists()
        
        let media = MessageMediaContent.sticker(path: path)
        let message = viewModel.createMessageLocally(ofType: .sticker,
                                                     text: nil,
                                                     media: media)
        updateUIOnNewMessageCreation(.sticker)
        viewModel.syncMessageWithFirestore(message.freeze(), imageRepository: nil)
    }
    
    private func updateUIOnNewMessageCreation(_ messageType: MessageType)
    {
        /// an empty table (fresh chat, no messages yet) counts as "at the
        /// bottom"; otherwise the first message applies with an animated
        /// insert, and at the resting offset that triggers UIKit's implicit
        /// scroll-to-inserted-cell animation, which lands the message about
        /// mid-screen instead of pinned above the input bar
        /// - See FootNote.swift [16]
        let wasAtBottom = isNewestIndexPathVisible()
            || rootView.tableView.indexPathsForVisibleRows?.isEmpty == true
        dataSourceManager.configureSnapshot(animationType: wasAtBottom ? .none : .automatic)
        let didAnimateInsertion = handleNewMessageDisplay()
        var wasInputBarExpanded = false
        
        switch messageType
        {
        case .text, .imageText:
            /// read before the input bar collapses back to a single line
            wasInputBarExpanded = inputMessageTextViewDelegate.messageTextViewNumberOfLines > 1
            clearTextViewInput()
        default: break
        }
        closeInputBarHeaderView()
        
        if !didAnimateInsertion {
            scrollToBottom()
        } else if wasInputBarExpanded {
            /// the input bar collapse shifted the table by the same delta, which only
            /// keeps the newest message anchored to the bar. The insertion reveal is
            /// applied before that shift, so the table is brought to the bottom once
            /// the shift settles.
            executeAfter(seconds: 0.3) {
                self.scrollToNewestMessage(animated: true)
            }
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
                        self.alertPresenter.presentPermissionDeniedAlert(from: self,
                                                                         for: .camera)
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
    /// Distance the input bar is raised above its resting position while the
    /// keyboard is shown. The keyboard frame includes the bottom safe area,
    /// which the input bar already covers, so that part is subtracted.
    private var keyboardRiseHeight: CGFloat
    {
        guard !isKeyboardHidden else { return 0 }
        return max(0, KeyboardService.shared.keyboardHeight - rootView.safeAreaInsets.bottom)
    }
    
    /// Height of the sticker panel, which replaces the keyboard.
    private var stickerPanelHeight: CGFloat
    {
        return max(0, KeyboardService.shared.keyboardHeight - rootView.safeAreaInsets.bottom)
    }
    
    /// Vertical offset for the greeting view that clears the extra height the
    /// multi-line text view adds to the raised input bar. Each successive line
    /// contributes half of its predecessor's shift - 1st extra line: 1×line
    /// height, 2nd: ½, 3rd: ¼ … - a geometric series capping at 2×. The sum is
    /// symmetric, so removing lines restores the positions line by line.
    private var greetingLineLift: CGFloat
    {
        let extraLines = max(0, inputMessageTextViewDelegate.messageTextViewNumberOfLines - 1)
        let lineHeight = rootView.messageTextView.font?.lineHeight ?? 0
        guard extraLines > 0 else { return 0 }
        let shiftFactor = 2.0 - pow(2.0, CGFloat(1 - extraLines))
        return -(shiftFactor * lineHeight)
    }
    
    /// Extra space currently covering the bottom of the table, below the input bar.
    private var bottomObscuringHeight: CGFloat
    {
        if rootView.stickerCollectionView != nil { return stickerPanelHeight }
        return keyboardRiseHeight
    }
    
    /// Single source of truth for the table's bottom padding.
    /// `inputBarContainer.bounds.height` already grows with the text view
    /// (multi-line input), so it is not added to again here.
    private func tableViewBottomInset(obscuringHeightOverride: CGFloat? = nil) -> CGFloat
    {
        let inputBarHeight = rootView.inputBarContainer.bounds.height
        let editViewHeight = rootView.inputBarHeader?.bounds.height ?? 0
        let obscuringHeight = obscuringHeightOverride ?? bottomObscuringHeight
        
        return inputBarHeight + obscuringHeight + editViewHeight + 4
    }
    
    /// Applies `tableViewBottomInset` to both the content and scroll indicator insets.
    /// `obscuringHeightOverride` decouples the inset from the sticker panel's
    /// attachment state: during the panel's dismiss animation the panel is still
    /// in the view hierarchy, but the bottom padding must already target 0.
    private func updateTableViewBottomInset(animated: Bool, obscuringHeightOverride: CGFloat? = nil)
    {
        let inset = tableViewBottomInset(obscuringHeightOverride: obscuringHeightOverride)
        let applyInset = {
            self.rootView.tableView.contentInset.bottom = inset
            self.rootView.tableView.verticalScrollIndicatorInsets.bottom = inset
        }
        
        guard animated else {
            applyInset()
            self.updateTopContentInsetToAnchorContentAtBottom()
            return
        }
        
        UIView.animate(withDuration: 0.27, delay: 0, options: [.curveEaseInOut]) {
            applyInset()
        }
        
        self.updateTopContentInsetToAnchorContentAtBottom()
    }
    
    /// Applies the input bar position, the table's bottom padding and the table's
    /// content offset inside a single animation that mirrors the keyboard's own
    /// duration and curve, so the table starts and finishes together with it.
    ///
    /// The offset is shifted by the same delta as the bottom padding, exactly as
    /// the pre-inversion `handleTableViewOffset` did. Doing the shift (instead of
    /// scrolling to the bottom) keeps the newest message anchored above the input
    /// bar and makes showing and hiding perfectly symmetric.
    private func updateTableLayoutAlongsideKeyboard(_ notification: NSNotification,
                                                    changes: @escaping () -> Void)
    {
        let tableView = rootView.tableView
        let previousBottomInset = tableView.contentInset.bottom
        /// Captured before the inset changes. Changing the inset makes the scroll
        /// view clamp an out-of-range offset by itself (which happens when the
        /// table sits at the bottom), so the delta must be applied to the offset
        /// from before that clamp, otherwise it is applied twice.
        let previousOffsetY = tableView.contentOffset.y
        let (duration, options) = keyboardAnimationParameters(from: notification)
        
        UIView.animate(withDuration: duration, delay: 0, options: options) {
            changes()
            
            self.updateTableViewBottomInset(animated: false)
            
            let insetDelta = tableView.contentInset.bottom - previousBottomInset
            let minOffsetY = -tableView.adjustedContentInset.top
            let maxOffsetY = max(minOffsetY,
                                 tableView.contentSize.height - tableView.bounds.height + tableView.adjustedContentInset.bottom)
            tableView.contentOffset.y = min(max(previousOffsetY + insetDelta, minOffsetY), maxOffsetY)
            
            self.rootView.layoutIfNeeded()
        }
    }
    
    /// Applies the sticker panel's input bar raise / drop and the resulting
    /// table bottom padding inside a single animation, shifting the content
    /// offset by the same delta. This mirrors `updateTableLayoutAlongsideKeyboard`
    /// for the panel's show / dismiss transitions, which are animated manually
    /// (no keyboard notifications drive them): without the in-animation offset
    /// shift the table only catches up when the animation completes.
    ///
    /// `obscuringHeight` is the padding the panel contributes for the target
    /// layout: panelHeight when the panel fills the space below the input bar,
    /// 0 while it is dismissed. The panel is removed only in the completion,
    /// so the inset must not derive from its (still attached) state mid-flight.
    private func updateTableLayoutAlongsideStickerPanel
    (
        obscuringHeight: CGFloat,
        changes: @escaping () -> Void,
        completion: ((Bool) -> Void)? = nil
    )
    {
        let tableView = rootView.tableView
        let previousBottomInset = tableView.contentInset.bottom
        /// Captured before the inset changes. Changing the inset makes the scroll
        /// view clamp an out-of-range offset by itself (which happens when the
        /// table sits at the bottom), so the delta must be applied to the offset
        /// from before that clamp, otherwise it is applied twice.
        let previousOffsetY = tableView.contentOffset.y
        
        UIView.animate(withDuration: 0.27, delay: 0, options: [.curveEaseInOut])
        {
            changes()
            
            self.updateTableViewBottomInset(animated: false,
                                            obscuringHeightOverride: obscuringHeight)
            
            let insetDelta = tableView.contentInset.bottom - previousBottomInset
            let minOffsetY = -tableView.adjustedContentInset.top
            let maxOffsetY = max(minOffsetY,
                                 tableView.contentSize.height - tableView.bounds.height + tableView.adjustedContentInset.bottom)
            tableView.contentOffset.y = min(max(previousOffsetY + insetDelta, minOffsetY), maxOffsetY)
            
            self.rootView.layoutIfNeeded()
        } completion: { finished in
            completion?(finished)
        }
    }
    
    /// Keyboard notifications carry their own animation duration and curve.
    /// UIKit encodes the curve in the upper 16 bits of `UIView.AnimationOptions`.
    private func keyboardAnimationParameters(from notification: NSNotification)
        -> (duration: TimeInterval, options: UIView.AnimationOptions)
    {
        let info = notification.userInfo
        let reportedDuration = (info?[UIResponder.keyboardAnimationDurationUserInfoKey] as? NSNumber)?.doubleValue
        let rawCurve = (info?[UIResponder.keyboardAnimationCurveUserInfoKey] as? NSNumber)?.uintValue
            ?? UInt(UIView.AnimationCurve.easeInOut.rawValue)
        
        let duration = reportedDuration.flatMap { $0 > 0 ? $0 : nil } ?? 0.25
        let options = UIView.AnimationOptions(rawValue: rawCurve << 16).union(.beginFromCurrentState)
        
        return (duration, options)
    }
    
    private func adjustTableViewContent(withUpdatedNumberOfLines numberOfLines: Int,
                                        currentNumberOfLines: Int)
    {
        let textView = rootView.messageTextView
        let tableView = rootView.tableView
        let numberOfAddedLines = CGFloat(numberOfLines - currentNumberOfLines)
        
        inputMessageTextViewDelegate.updateLinesNumber(numberOfLines)
        
        /// keep the greeting view clear of the input bar growing / shrinking
        /// with each text view line - the 0.1s debounce aligns it with the
        /// moment the text view's own height animation starts, and animating
        /// the absolute offset for the current line count keeps it in sync
        /// with the text view expansion (no drift over successive changes)
        if rootView.greetingView != nil
        {
            rootView.updateGreetingLineLift(self.greetingLineLift)
        }
        
        guard numberOfAddedLines != 0 else { return }
        
        let updatedContentOffset = CGPoint(x: tableView.contentOffset.x,
                                           y: tableView.contentOffset.y + (textView.font!.lineHeight * numberOfAddedLines))
        
        UIView.animate(withDuration: 0.15) {
            self.updateTableViewBottomInset(animated: false)
            tableView.setContentOffset(updatedContentOffset, animated: false)
        }
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
                actionOption: .image(imageThumbnail))
            self.messageImage = photo
        }
    }
}

//MARK: - GESTURES
extension ChatRoomViewController
{
    private func addGestureToTableView()
    {
        let panGesture = UIPanGestureRecognizer(target: self, action: #selector(handleTablePan))
        panGesture.delegate = self
        
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(dismissInputBarView))
        
        tapGesture.delegate = self
        tapGesture.cancelsTouchesInView = false
        
        rootView.tableView.addGestureRecognizer(panGesture)
        rootView.tableView.backgroundView?.addGestureRecognizer(tapGesture)
    }

    private func addGestureToCloseBtn()
    {
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(closeInputBarHeaderView))
        rootView.inputBarHeader?.closeButton?.addGestureRecognizer(tapGesture)
    }
    
    @objc func closeInputBarHeaderView()
    {
        if rootView.inputBarHeader != nil
        {
            if case .image(_) = self.rootView.inputBarHeader?.mode, inputMessageTextViewDelegate.isTextViewEmpty
            {
                rootView.toggleVoiceRecButtonVisibility(true)
            }
            viewModel.resetCurrentReplyMessageIfNeeded()
            animateInputBarHeaderViewDestruction()
        }
    }
}


//MARK: - TABLE DELEGATE
extension ChatRoomViewController: UITableViewDelegate
{
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView?
    {
        /// while the skeleton placeholder rows are up, `messageClusters` is still
        /// empty, so the header must not try to read a section date from it
        guard viewModel.conversationInitializationStatus != .inProgress,
              let headerView = tableView.dequeueReusableHeaderFooterView(withIdentifier: ReuseIdentifire.HeaderFooter.footer.identifire) as? SectionDateHeaderView else { return nil }
        
        let dateForSection = viewModel.messageClusterRepository.messageClusters[section].date.formattedAsRelativeDayLabel()
        headerView.setDate(dateText: dateForSection)
        return headerView
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 50
    }
    
    func tableView(_ tableView: UITableView, willDisplayHeaderView view: UIView, forSection section: Int)
    {
        view.isHidden = viewModel.conversationInitializationStatus == .inProgress
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat
    {
        if viewModel.conversationInitializationStatus == .inProgress {
            if let height = skeletonRowHeights[indexPath.row] {
                return height
            }
            let height = CGFloat((70...120).randomElement()!)
            skeletonRowHeights[indexPath.row] = height
            return height
        }
        
        return  UITableView.automaticDimension
    }
    
    func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat
    {
        /// While the skeleton runs the heights must be EXACT, not estimated:
        /// on every reload UIKit lays cells out with the estimate first and
        /// corrects to the real height right after, which is visible as the
        /// rows briefly "resetting" their size. Since `heightForRowAt` draws
        /// memoized values for skeleton rows, hand the same number to the
        /// estimator (the 90 fallback is a reasonable guess for a row whose
        /// height hasn't been drawn yet).
        if viewModel.conversationInitializationStatus == .inProgress {
            return skeletonRowHeights[indexPath.row] ?? 90
        }

        /// With `estimatedRowHeight = .automatic` every off-screen self-sizing
        /// row is estimated at ~44pt until it is displayed. For sticker
        /// messages that estimate is far off (real height ~191pt), and in
        /// chats whose newest messages are stickers the bottom-most block was
        /// undercounted by roughly one viewport worth of height - the room
        /// opened offset a few messages above the most recent one.
        /// Stickers have a fixed size, so give the table the real number;
        /// all other message types keep the default automatic estimate.
        let clusters = viewModel.messageClusterRepository.messageClusters
        guard indexPath.section < clusters.count,
              indexPath.row < clusters[indexPath.section].items.count,
              let message = clusters[indexPath.section].items[indexPath.row].message,
              message.type == .sticker
        else { return UITableView.automaticDimension }
        
        return StickerMessageCell.fixedRowHeight
    }
    
    func tableView(_ tableView: UITableView,
                   didEndDisplaying cell: UITableViewCell,
                   forRowAt indexPath: IndexPath)
    {
        (cell as? StickerMessageCell)?.setVisible(false)
    }
    
    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath)
    {
        /// sticker rendering is started/stopped purely from willDisplay /
        /// didEndDisplaying (`FrameTicker`), so it MUST run even while the
        /// initial-load gate below is closed, otherwise a sticker visible
        /// right after chat room open is never registered with the frame
        /// ticker and stays blank until it gets recycled by scrolling it
        /// off-screen and back.
        (cell as? StickerMessageCell)?.setVisible(true)
        
        guard !viewModel.messageClusterRepository.messageClusters.isEmpty,
              didFinishInitialScrollToUnseenIndexPathIfAny else { return }
        
        if let newestIndexPath,
           indexPath == newestIndexPath,
           let lastItems = viewModel.messageClusterRepository.messageClusters.last?.items,
           lastItems.count > 1
        {
            let newestSenderId = lastItems[lastItems.count - 1].message?.senderId
            let previousSenderId = lastItems[lastItems.count - 2].message?.senderId
            
            if newestSenderId == previousSenderId
            {
                lastItems[lastItems.count - 2].toggleVisibilityOfSenderAvatar(false)
            }
        }
        
        let groupedClusterItems = viewModel.messageClusterRepository.messageClusters.map { $0.items }
        let totalItems = groupedClusterItems.flatMap { $0 }.count
        
       
        if let globalIndex = globalIndex(for: indexPath,
                                         in: groupedClusterItems)
        {
            /// should be checked based upon the messages total count in chat model (which is missing),
            /// and i dont have time to implemnte it
            let shouldPaginateAnyway: Bool = viewModel.messageClusterRepository.messageClusters.count < 6
            && paginateOldMessagesOnInitialChatOpen
             
            /// ascending order: index 0 is the OLDEST, the last index is the NEWEST.
            /// Both thresholds sit 6 items away from the edge of the list, so the
            /// page is always requested before its edge cell becomes visible.
            if globalIndex >= totalItems - 6 && !viewModel.isLastMessageFromClusterTheMostRecentInChat
            {
                paginateIfNeeded(ascending: true)
                return
            } else if (globalIndex <= 6) || shouldPaginateAnyway
            {
                paginateIfNeeded(ascending: false)
                return
            }
        }
    }
    
    func tableView(_ tableView: UITableView,
                   didSelectRowAt indexPath: IndexPath)
    {
        tableView.deselectRow(at: indexPath, animated: false)
         
        guard let cell = tableView.cellForRow(at: indexPath) as? TargetPreviewable else {return}
        
        if let touchLocation = tableView.panGestureRecognizer.location(in: cell) as CGPoint?
        {
            dismissInputBarView()
            
            if cell.contentContainer.frame.contains(touchLocation)
            {
                guard cell.cellViewModel.message?.imagePath != nil,
                      let messageCell = cell as? TextImageMessageCell
                else {
                    return
                }
                initiatePhotoBrowserPresentation(from: messageCell)
            }
        }
    }
    
    private func initiatePhotoBrowserPresentation(from cell: TextImageMessageCell)
    {
        guard let imageView = cell.messageImageView else {return}
        let items = self.viewModel.mediaItems
        
        let initialIndex = items.firstIndex { $0.imagePath.lastPathComponent == cell.cellViewModel.message?.imagePath }
         
        self.photoBrowser.presentPhotoBrowser(
            on: self,
            usingItems: items,
            initialIndex: initialIndex ?? 0,
            originImageView: imageView
        )
    }
    
    func globalIndex(for indexPath: IndexPath, in groupedData: [[MessageItem]]) -> Int?
    {
        guard indexPath.section < groupedData.count else { return nil }
        
        var index = 0
        for section in 0..<indexPath.section {
            index += groupedData[section].count
        }
        index += indexPath.row
        return index
    }
    
    /// Pagination
    private func paginateIfNeeded(ascending: Bool)
    {
        Task { @MainActor in
            self.viewModel.isLocalPaginationActive = true
            
            if viewModel.paginateAdditionalLocalMessages(ascending: ascending)
            {
                applyPaginationChanges(didPrependMessages: !ascending)
                
                viewModel.isLocalPaginationActive = false
                
                if let startMessage = viewModel.lastPaginatedMessage
                {
                    viewModel.messageListenerService?.addListenerToExistingMessages(
                        startAtMesssage: startMessage,
                        ascending: !ascending,
                        limit: ObjectsPaginationLimit.localMessages)
                }
                return
            }
            
            viewModel.isLocalPaginationActive = false
            if !isNetworkPaginationRunning
            {
                isNetworkPaginationRunning = true
                await viewModel.remoteMessagePaginator?.perform {
                    await preformRemotePagination(ascending: ascending)
                }
            }
        }
    }
    
    /// Applies the current repository contents to the data source without any
    /// visible animation and keeps the scroll position untouched, as if
    /// nothing was inserted. Used by the LOCAL pagination path - the remote
    /// path has its own application (see `preformRemotePagination`), ported
    /// from the pre-inversion code with its CATransaction-based suppression
    /// of UIKit's implicit scroll action.
    /// - the snapshot is applied through an **animated** diffable apply
    ///   wrapped in `UIView.animate(withDuration: 0.0)` - the animation
    ///   collapses to zero, but the update goes through `performBatchUpdates`,
    ///   which spreads its work over the (now 0-duration) animation frames
    ///   and keeps the scroll momentum intact. A non animated apply must NOT
    ///   be used here: it re-builds the content synchronously like
    ///   `reloadData` does and stalls an ongoing scroll for a beat.
    /// - for prepends the offset is shifted by the content size delta right
    ///   after the apply (the batch update inserts the rows synchronously),
    ///   i.e. exactly the height of the rows added above the visible area.
    ///   On the inverted table UIKit kept the visible content anchored on
    ///   its own; on a standard table the correction has to be done here.
    /// - See also FootNote.swift [16]: the 0-duration animation wrapper also
    ///   neutralizes UIKit's implicit "scroll to make the inserted cell
    ///   visible" behavior.
    private func applyPaginationChanges(
        didPrependMessages: Bool,
        completion: (() -> Void)? = nil)
    {
        let tableView = rootView.tableView
        let currentOffsetY = tableView.contentOffset.y
        let previousContentHeight = tableView.contentSize.height
        
        self.shouldIgnoreUnseenMessagesUpdate = true
        
        UIView.animate(withDuration: 0.0)
        {
            self.dataSourceManager.configureSnapshot(animationType: .automatic)
        }
        
        /// the batch update inserts the rows synchronously, so the offset can
        /// be locked in the same tick, before the next frame is rendered
        if didPrependMessages
        {
            tableView.contentOffset.y = currentOffsetY
                + (tableView.contentSize.height - previousContentHeight)
        }
        
        self.updateTopContentInsetToAnchorContentAtBottom()
        
        self.shouldIgnoreUnseenMessagesUpdate = false
        completion?()
    }
    
    private func preformRemotePagination(ascending: Bool) async
    {
        do {
            let direction: PaginationDirection = ascending ?
                .ascending : .descending
            switch try await viewModel.paginateRemoteMessages(direction: direction)
            {
            case .didPaginate:
                await MainActor.run
                {
                    /// Remote pagination landing: port of the pre-inversion
                    /// solution (see commit `eaf4682b`) adapted to the
                    /// standard (non-inverted) table.
                    ///
                    /// Unlike the local path, a remote page arrives while the
                    /// table typically rests at / hovers around its TOP edge
                    /// (the user scrolled up to the oldest local message and
                    /// waited for the fetch). There, on new-row insertion,
                    /// UIKit applies its implicit "animate scrolling to the
                    /// inserted cell" action (See FootNote.swift [16]) and
                    /// `UIView.animate(withDuration: 0.0)` - used by the local
                    /// path - does NOT suppress it reliably in this context;
                    /// only a CATransaction with disabled actions did, which
                    /// is exactly how the old code wrapped the remote apply.
                    ///
                    /// The offset is anchored to the previously visible
                    /// top-most cell and corrected INSIDE the apply
                    /// completion, from its NEW rect - the non-inverted
                    /// equivalent of the old code's
                    /// `offsetTableContentOnPaginationCompletion`, valid for
                    /// any scroll position of a standard table (the old
                    /// `-90.0` guard existed for the overscroll zone of the
                    /// rotated geometry). Computing it in the completion
                    /// makes it land correctly whenever UIKit actually
                    /// commits the batch update.
                    let tableView = self.rootView.tableView
                    let anchorCell = tableView.indexPathsForVisibleRows?.min()
                        .flatMap { tableView.cellForRow(at: $0) }
                    let previousMinY = anchorCell.flatMap { cell -> CGFloat? in
                        guard let indexPath = tableView.indexPath(for: cell) else { return nil }
                        return tableView.rectForRow(at: indexPath).minY
                    }
                    let currentOffsetY = tableView.contentOffset.y
                    /// fallback, used only if the anchor cell gets detached
                    /// during the update (mutually exclusive with the anchor)
                    let previousContentHeight = tableView.contentSize.height
                    
                    CATransaction.begin()
                    CATransaction.setDisableActions(true)
                    
                    self.shouldIgnoreUnseenMessagesUpdate = true
                    
                    self.dataSourceManager.configureSnapshot(
                        animationType: .automatic)
                    {
                        self.shouldIgnoreUnseenMessagesUpdate = false
                        
                        if direction == .descending
                        {
                            if let anchorCell,
                               let previousMinY,
                               let newAnchorIndexPath = tableView.indexPath(for: anchorCell)
                            {
                                let newMinY = tableView.rectForRow(at: newAnchorIndexPath).minY
                                tableView.contentOffset.y = currentOffsetY + (newMinY - previousMinY)
                            }
                            else
                            {
                                tableView.contentOffset.y = currentOffsetY
                                    + (tableView.contentSize.height - previousContentHeight)
                            }
                        }
                        
                        self.updateTopContentInsetToAnchorContentAtBottom()
                        
                        CATransaction.commit()
                        self.isNetworkPaginationRunning = false
                    }
                }
            default:
                self.isNetworkPaginationRunning = false
                break
            }
        } catch {
            print("Could not update conversation with additional messages: \(error)")
            /// otherwise the guard would stay latched and remote pagination
            /// would never be attempted again
            self.isNetworkPaginationRunning = false
        }
    }
}

////MARK: - SCROLL VIEW DELEGATE
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

        /// fire updates every > 0.3 time
        if Date().timeIntervalSince(lastSeenStatusCheckUpdate) > 0.2
        {
            self.lastSeenStatusCheckUpdate = Date()
            
            triggerUpdateUnseenMessagesCheck()
        }

        /// Toggle scrollToBottom badge
        isNewestCellFullyVisible ?
        toggleScrollBadgeButtonVisibility(shouldBeHidden: true)
        :
        toggleScrollBadgeButtonVisibility(shouldBeHidden: false)
    }
    
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView)
    {
        triggerUpdateUnseenMessagesCheck()
        
        toggleSectionHeaderVisibility(isScrollActive: false)
    }
    
    func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool)
    {
        self.lastSeenStatusCheckUpdate = Date()
        
        triggerUpdateUnseenMessagesCheck()

        toggleSectionHeaderVisibility(isScrollActive: decelerate)
    }
    
    func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        /// the user took over the animated scroll flight - no automatic
        /// landing correction should apply anymore
        isScrollingToNewestMessage = false
        
        toggleSectionHeaderVisibility(isScrollActive: true)
    }
    
    func scrollViewDidScrollToTop(_ scrollView: UIScrollView)
    {
        triggerUpdateUnseenMessagesCheck()
    }
    func scrollViewDidEndScrollingAnimation(_ scrollView: UIScrollView)
    {
        /// an animated scroll-to-newest flight just finished; its target was
        /// computed against the (partially estimate-based) content size at
        /// flight start, so re-land on the real bottom edge
        if isScrollingToNewestMessage
        {
            isScrollingToNewestMessage = false
            settleScrollAtNewestMessage()
        }
        
        triggerUpdateUnseenMessagesCheck()
    }
    
    
    private func triggerUpdateUnseenMessagesCheck()
    {
        if viewModel.shouldHideJoinGroupOption
        {
            if let index = findNewestVisibleIndexPath()
            {
                updateMessageSeenStatusIfNeeded(index)
            }
        }
    }
}

//MARK: - ScrollView helper functions
extension ChatRoomViewController
{
    /// find the newest fully visible index path, to update all messages up to it
    ///
    private func findNewestVisibleIndexPath() -> IndexPath?
    {
        if let visibleIndices = rootView.tableView.indexPathsForVisibleRows?.sorted(),
           let lastVisible = visibleIndices.last(where: { checkIfCellIsFullyVisible(at: $0) })
        {
            return lastVisible
        }
        return nil
    }

    private func toggleSectionHeaderVisibility(isScrollActive: Bool, withAnimation: Bool = true)
    {
        /// date pills are real (sticky) section headers now, so they should
        /// always be visible. This also restores opacity in case an older
        /// header view was faded out.
        guard let visibleIndices = rootView.tableView.indexPathsForVisibleRows
        else { return }
        
        for section in Set(visibleIndices.map(\.section))
        {
            rootView.tableView.headerView(forSection: section)?.layer.opacity = 1.0
        }
    }
}


//MARK: Context Menu configuration
extension ChatRoomViewController
{
    func tableView(_ tableView: UITableView,
                   contextMenuConfigurationForRowAt indexPath: IndexPath,
                   point: CGPoint) -> UIContextMenuConfiguration?
    {
        guard viewModel.shouldHideJoinGroupOption,
              let baseCell = tableView.cellForRow(at: indexPath) else { return nil }
        let identifier = indexPath as NSCopying
        
        let menuBuilder = MessageMenuBuilder(
            viewModel: self.viewModel,
            rootView: self.rootView,
            cell: baseCell
        )
        { actionOption in
            self.handleContextMenuSelectedAction(
                actionOption: actionOption
            )
        }
        
        if let messageCell = baseCell as? TargetPreviewable,
           let message = messageCell.cellViewModel.message
        {
            let tapLocationInCell = messageCell.contentView.convert(point, from: tableView)
            guard messageCell.contentContainer.frame.contains(tapLocationInCell) else { return nil }
            
            return UIContextMenuConfiguration(identifier: identifier, previewProvider: nil) { _ in
                return menuBuilder.buildUIMenuForMessage(message: message)
            }
        }
        else if let eventCell = baseCell as? MessageEventCell,
                let message = eventCell.cellViewModel.message
        {
            let tapLocationInCell = eventCell.contentView.convert(point, from: tableView)
            guard eventCell.contentContainer.frame.contains(tapLocationInCell) else { return nil }
            
            return UIContextMenuConfiguration(identifier: identifier, previewProvider: nil) { _ in
                return menuBuilder.buildUIMenuForEvent(message: message)
            }
        }
        return nil
    }
    
    func tableView(_ tableView: UITableView, previewForHighlightingContextMenuWithConfiguration configuration: UIContextMenuConfiguration) -> UITargetedPreview?
    {
        return makeTargetedPreview(for: configuration)
    }

    func tableView(_ tableView: UITableView, previewForDismissingContextMenuWithConfiguration configuration: UIContextMenuConfiguration) -> UITargetedPreview?
    {
        executeAfter(seconds: 0.5) {
            self.isContextMenuPresented = false
        }
        return makeTargetedDismissPreview(for: configuration)
    }
    
    func tableView(_ tableView: UITableView,
                   willDisplayContextMenu configuration: UIContextMenuConfiguration,
                   animator: UIContextMenuInteractionAnimating?)
    {
        if rootView.inputBarBottomConstraint.constant != 0.0 {
            isContextMenuPresented = true
        }
    }
    
    private func handleContextMenuSelectedAction(
        actionOption: InputBarHeaderView.Mode
    )
    {
        self.rootView.setupInputBarHeaderView(mode: actionOption)
        self.addGestureToCloseBtn()
        self.rootView.messageTextView.becomeFirstResponder()
        self.inputMessageTextViewDelegate.textViewDidChange(self.rootView.messageTextView)
        
        if case .image(_) = actionOption,
           self.rootView.sendMessageButton.isHidden
        {
            self.rootView.toggleVoiceRecButtonVisibility(false)
        }
    }
}


//MARK: Draggable cell
extension ChatRoomViewController: UIGestureRecognizerDelegate
{
    @objc private func handleTablePan(_ gesture: UIPanGestureRecognizer)
    {
        self.targetedPreview?.view.removeFromSuperview() //  See FootNote.swift [19]
        self.targetedPreview = nil
        
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
                    self.triggerHapticFeedback(style: .heavy)
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
            
            if (translation.x < 0) && (abs(translationX) >= dragTreshhold)
            {
                self.viewModel.currentlyReplyToMessageID = dragableCell?.messageID
                self.handleContextMenuSelectedAction(
                    actionOption: .reply(
                        senderName: dragableCell?.messageSenderName,
                        text: dragableCell?.messageText,
                        image: dragableCell?.messageImage)
                )
            }
            
            self.dragableCell = nil
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

        // Keep the original cell visible but make it transparent during preview
        // This keeps animations running in the background
        cell.alpha = 0.01 // Almost invisible but still rendering
       
        // Create a container that references the cell
        let cellReference = TargetedPreviewContentView(contentView: cell.contentView)
        cellReference.frame = cell.contentView.bounds
        cellReference.layer.cornerRadius = 10
        cellReference.layer.masksToBounds = true
        
        animatedPreviewViews.append(cellReference)
 
        var reactionPanelView = ReactionPanelView()
        reactionPanelView.onReactionSelection = { [weak self] reactionEmoji in
            self?.viewModel.updateReactionInDataBase(reactionEmoji, from: message)
            self?.dismiss(animated: true)
        }
        
        let reactionPanelUIView = UIHostingController(rootView: reactionPanelView).view!
        reactionPanelUIView.backgroundColor = .clear
        reactionPanelUIView.translatesAutoresizingMaskIntoConstraints = false
        
        // Calculate heights
        let cellHeight = cell.bounds.height
        let reactionHeight: CGFloat = ReactionPanelView.panelHeight
        let spacing: CGFloat = TargetedPreviewComponentsSize.spaceReactionHeight
        let totalHeight = reactionHeight + spacing + cellHeight
        
        // Create container
        let container = UIView(frame: CGRect(origin: .zero,
                                             size: CGSize(width: cell.bounds.width, height: totalHeight)))
        container.backgroundColor = .clear
        
        container.addSubview(reactionPanelUIView)
        container.addSubview(cellReference)
        
        cellReference.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            reactionPanelUIView.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 10),
            reactionPanelUIView.topAnchor.constraint(equalTo: container.topAnchor),
            reactionPanelUIView.widthAnchor.constraint(equalToConstant: 306),
            reactionPanelUIView.heightAnchor.constraint(equalToConstant: reactionHeight),
            
            cellReference.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            cellReference.topAnchor.constraint(equalTo: reactionPanelUIView.bottomAnchor, constant: spacing),
            cellReference.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            cellReference.heightAnchor.constraint(equalToConstant: cellHeight),
            cellReference.bottomAnchor.constraint(equalTo: container.bottomAnchor)
        ])
        
        let heightDifference = totalHeight - cellHeight
        let adjustedCenterY = cell.center.y - (heightDifference / 2)
        let centerPoint = CGPoint(x: cell.center.x, y: adjustedCenterY)
        
        let previewTarget = UIPreviewTarget(container: rootView.tableView,
                                          center: centerPoint,
                                          transform: .identity)
        
        let parameters = UIPreviewParameters()
        parameters.backgroundColor = .clear
        parameters.shadowPath = UIBezierPath()
        
        let targetedPreview = UITargetedPreview(view: container,
                               parameters: parameters,
                               target: previewTarget)
        self.targetedPreview = targetedPreview // See FootNote.swift [19]
        return targetedPreview
    }

    func makeTargetedDismissPreview(for configuration: UIContextMenuConfiguration) -> UITargetedPreview?
    {
        guard let indexPath = configuration.identifier as? IndexPath,
              let cell = rootView.tableView.cellForRow(at: indexPath) else {
            return nil
        }
        
        let maxSnapshotHeight = TargetedPreviewComponentsSize.calculateMaxSnapshotHeight(from: cell)
 
        let previewsCount = self.animatedPreviewViews.count
        guard previewsCount > 0 else { return nil }
        let snapshot = animatedPreviewViews[previewsCount - 1]
        
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
        let adjustedCenterY = cell.center.y - (heightDifference / 2)
        
        let centerPoint = CGPoint(x: cell.center.x, y: adjustedCenterY)
        let previewTarget = UIPreviewTarget(container: rootView.tableView,
                                           center: centerPoint,
                                           transform: .identity)
        
        let parameters = UIPreviewParameters()
        parameters.backgroundColor = .clear
        parameters.shadowPath = UIBezierPath()
        
        return UITargetedPreview(view: container, parameters: parameters, target: previewTarget)
    }
    
    func tableView(_ tableView: UITableView,
                   willEndContextMenuInteraction configuration: UIContextMenuConfiguration,
                   animator: UIContextMenuInteractionAnimating?
    )
    {
        animator?.addCompletion { [weak self] in
            guard let self,
                  let indexPath = configuration.identifier as? IndexPath,
                  let cell = tableView.cellForRow(at: indexPath) else
            {
                return
            }
            
            // Restore cell visibility after animation completes
            cell.alpha = 1
            
            executeAfter(seconds: 1.0)
            {
                if let view = self.animatedPreviewViews.first as? TargetedPreviewContentView
                {
                    view.cleanup()
                    self.animatedPreviewViews.first?.removeFromSuperview()
                    self.animatedPreviewViews.remove(at: 0)
                }
            }
        }
    }

    func getMessageFromCell(_ cell: UITableViewCell) -> Message?
    {
        if let messageCell = cell as? TargetPreviewable,
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


//MARK: - Gesture delegate
extension ChatRoomViewController
{
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


//MARK: - SkeletonView animation
extension ChatRoomViewController
{
    private func toggleSkeletonAnimation(_ state: SkeletonAnimationState)
    {
        switch state {
        case .initiated:
            /// a fresh set of stable random heights for the coming skeleton rows
            skeletonRowHeights.removeAll()
            rootView.tableView.estimatedRowHeight = 50 /// See FootNote.swift [17]
            /// The skeleton rows are ordinary diffable items now (see
            /// `ConversationDataSourceManager.setSkeletonDisplay`). SkeletonView's
            /// data-source wrapper used to reload the whole table on every
            /// trait-collection pass and re-dequeue reuse-pool cells into
            /// different rows, which made the bars visibly "reset" their sizes.
            dataSourceManager.setSkeletonDisplay(displayed: true)
            /// the wrapper used to lock interaction while it owned the table
            rootView.tableView.isScrollEnabled = false
            rootView.tableView.isUserInteractionEnabled = false
        case .terminated:
            rootView.tableView.estimatedRowHeight = UITableView.automaticDimension /// See FootNote.swift [17]
            dataSourceManager.setSkeletonDisplay(displayed: false)
            rootView.tableView.isScrollEnabled = true
            rootView.tableView.isUserInteractionEnabled = true
            skeletonRowHeights.removeAll()
        default: break
        }
    }
}

extension ChatRoomViewController
{
    enum CellVisibilityStatus {
        case visible
        case underInputBar
        case offScreen
    }
}
