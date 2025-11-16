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
import SKPhotoBrowser

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
    
    private var dataSourceManager : ConversationDataSourceManager!
    private var customNavigationBar :ChatRoomNavigationBar!
    private var rootView = ChatRoomRootView()
    private var viewModel: ChatRoomViewModel!
    private var inputMessageTextViewDelegate: InputBarTextViewDelegate!
    private var subscriptions = Set<AnyCancellable>()
    private lazy var alertPresenter: AlertPresenter = .init()

    private var isContextMenuPresented: Bool = false
    private var isKeyboardHidden: Bool = true
    private var didFinishInitialScrollToUnseenIndexPathIfAny: Bool = true
    
    private var isLastCellFullyVisible: Bool {
        checkIfCellIsFullyVisible(at: IndexPath(row: 0, section: 0))
    }
    
    lazy private var photoBrowser: SKPhotoBrowserManager = SKPhotoBrowserManager()
    
    //MARK: - Lifecycle
    
    convenience init(conversationViewModel: ChatRoomViewModel) {
        self.init()
        self.viewModel = conversationViewModel
    }
    
    override func loadView() {
        view = rootView
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
        
        let isRecordingActive = AudioSessionManager.shared.isRecording()
        if isRecordingActive
        {
            AudioSessionManager.shared.recordCancellationSubject.send(())
        }
    }
    
    deinit {
//        print("ChatRoomVC deinit")
        cleanUp()
    }
    
    private func scrollToCell(at indexPath: IndexPath)
    {
        guard indexPath.row < self.rootView.tableView.numberOfRows(inSection: indexPath.section) else {return}
        
        let updatedIndex = IndexPath(row: indexPath.row + 1,
                                     section: indexPath.section)
        
        self.rootView.tableView.scrollToRow(at: updatedIndex, at: .bottom, animated: false)
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
    }
    
    private func performAdditionalSetupForRootView()
    {
        if viewModel.conversation == nil
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
                                                         sourceProvider: self.viewModel)
        self.dataSourceManager = ConversationDataSourceManager(
            dataProvider: self.viewModel,
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
    }
    
    private func finalizeConversationSetup()
    {
        viewModel.resetInitializationStatus()
        
        let indexPath = self.viewModel.findLastUnseenMessageIndexPath()
        
        if let indexPath {
            viewModel.insertUnseenMessagesTitle(afterIndexPath: indexPath)
            
            self.didFinishInitialScrollToUnseenIndexPathIfAny = false
            // Delay table view willDisplay cell functionality
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                self.didFinishInitialScrollToUnseenIndexPathIfAny = true
            }
        }
            
        refreshTableView()
        
        if let indexPath {
            self.scrollToCell(at: indexPath)
        }
        
        viewModel.addListeners()
        
        if viewModel.authParticipantUnreadMessagesCount > 0 {
            updateMessageSeenStatusIfNeeded()
        }
    }
    
    //MARK: - Bindings
    
    private func setupBinding()
    {
        AudioSessionManager.shared.$currentRecordingTime
            .sink { time in
                let minutes = Int(time) / 60
                let seconds = Int(time) % 60
                let milliseconds = (Int((time - floor(time)) * 1000)) / 10
                
                let timeString = String(format: "%2d:%02d.%02d", minutes, seconds, milliseconds)
                self.rootView.updateRecCounterLabelText(with: timeString)
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
                let shouldBeVisible = isEmpty
                self?.rootView.toggleVoiceRecButtonVisibility(shouldBeVisible)
            }.store(in: &subscriptions)
        
        viewModel.$messageClusters
            .receive(on: DispatchQueue.main)
            .sink { [weak self] clusters in
                if !clusters.isEmpty { self?.rootView.removeGreetingViewIfNeeded() }
            }.store(in: &subscriptions)
        
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
        
        viewModel.datasourceUpdateType
            .receive(on: DispatchQueue.main)
            .sink { [weak self] updateType in
                guard let self = self else { return }
                
                var updateType = updateType
                let isUpdateAnimationNone = updateType == .none
                if isUpdateAnimationNone
                {
                    if !self.isFirstIndexPathVisible() {
                        updateType = .automatic
                    }
                }
                
                self.dataSourceManager.configureSnapshot(animationType: updateType)
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
                    self.rootView.messageTextView.resignFirstResponder()
                    return
                }
                
                let height = KeyboardService.shared.keyboardHeight
                UIView.animate(withDuration: 0.27) {
                    self.handleTableViewOffset(usingKeyboardHeight: height)
                    self.rootView.layoutIfNeeded()
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
        if let keyboardSize = (notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue
        {
            let height = keyboardSize.height
            
            guard rootView.inputBarContainer.frame.origin.y > 580 else {
                let keyboardHeight = -(height - 30)
                rootView.updateInputBarBottomConstraint(toSize: keyboardHeight)
                return
            } /// first character typed in textField triggers keyboardWillShow, so we perform this check
            
            isKeyboardHidden = false
            
            self.rootView.toggleGreetingViewPosition(up: true)
            
            guard isContextMenuPresented else
            {
                handleTableViewOffset(usingKeyboardHeight: height)
                return
            }
            
            let keyboardHeight = -(height - 30)
            rootView.updateInputBarBottomConstraint(toSize: keyboardHeight)
        }
    }
    
    @objc func keyboardWillHide(notification: NSNotification)
    {
        if let keyboardSize = (notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue
        {
            guard self.rootView.stickerCollectionView == nil else { return }
            isKeyboardHidden = true
            
            self.rootView.toggleGreetingViewPosition(up: false)
            
            guard !isContextMenuPresented else {
                rootView.updateInputBarBottomConstraint(toSize: 0)
                return
            }
            handleTableViewOffset(usingKeyboardHeight: keyboardSize.height)
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
    }
    
    @objc private func dismissInputBarView()
    {
        if rootView.stickerCollectionView != nil
        {
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
        rootView.showStickerIcon()
        UIView.animate(withDuration: 0.27) {
            self.handleTableViewOffset(usingKeyboardHeight: KeyboardService.shared.keyboardHeight)
            self.rootView.layoutIfNeeded()
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
        
        self.rootView.updateTableViewContentAttributes(isInputBarHeaderRemoved: true)
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
}

//MARK: - Handle cell message insertion
extension ChatRoomViewController
{
    private func isFirstIndexPathVisible() -> Bool
    {
        let visibleIndexPaths = rootView.tableView.indexPathsForVisibleRows
        let indexPath = IndexPath(row: 0, section: 0)
        return visibleIndexPaths?.contains(indexPath) ?? false
    }
    
    private func handleNewMessageDisplay()
    {
        let isFirstIndexVisible = isFirstIndexPathVisible()
        let isNewSectionAdded = self.viewModel.messageClusters[0].items.count == 1 ? true : false
        
        if isFirstIndexVisible || rootView.tableView.indexPathsForVisibleRows?.isEmpty == true
        {
            self.animateFirstCellOffset(withNewSectionAdded: isNewSectionAdded)
        }
    }
    
    private func scrollToBottom()
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
            animateFirstCellOffset(withNewSectionAdded: isNewSectionAdded)
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
    
    private func animateFirstCellOffset(withNewSectionAdded isNewSectionAdded: Bool)
    {
        let indexPath = IndexPath(row: 0, section: 0)
        let tableView = self.rootView.tableView
        let currentOffSet = tableView.contentOffset
        
        rootView.tableView.layoutIfNeeded()
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
                viewModel.updateUnseenMessageCounterForAuthUserLocally()
                viewModel.updateFirebaseMessagesSeenStatus(startingFrom: unseenMessage)
                viewModel.updateUnseenMessageCounterForAuthUserRemote()
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
        
        // 1.Create message
        let message = viewModel.createMessageLocally(
            ofType: messageType,
            text: trimmedText,
            media: media
        )
        
        // 2.Update UI immediately
        updateUIOnNewMessageCreation(messageType)
        
        // 3.Handle image cache
        if let repo = imageSampleRepo
        {
            Task { @MainActor in
                await viewModel.saveImagesLocally(fromImageRepository: repo, for: message.id)
            }
        }

        // 4.Start message remote sync
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
        dataSourceManager.configureSnapshot(animationType: isFirstIndexPathVisible() ? .none : .automatic)
        handleNewMessageDisplay()
        
        switch messageType
        {
        case .text, .imageText: clearTextViewInput()
        default: break
        }
        closeInputBarHeaderView()
        scrollToBottom()
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
    private func handleTableViewOffset(usingKeyboardHeight keyboardHeight: CGFloat)
    {
        // if number of lines inside textView is bigger than 1, it will expand
        let maxContainerViewY = 584.0 - 4.0
        var keyboardHeight = keyboardHeight - 30

        keyboardHeight = rootView.inputBarContainer.frame.origin.y > maxContainerViewY ? -keyboardHeight : keyboardHeight
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
            viewModel.resetCurrentReplyMessageIfNeeded() 
            animateInputBarHeaderViewDestruction()
        }
    }
}


//MARK: - TABLE DELEGATE
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
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat
    {
        if viewModel.conversationInitializationStatus == .inProgress {
            return CGFloat((70...120).randomElement()!)
        }
        if viewModel.messageClusters[indexPath.section].items[indexPath.item].message?.type == .sticker
        {
            return 180
        }
        
        return  UITableView.automaticDimension
    }
    
    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath)
    {
        guard !viewModel.messageClusters.isEmpty,
              didFinishInitialScrollToUnseenIndexPathIfAny else { return }
        
        let groupedClusterItems = viewModel.messageClusters.map { $0.items }
        let totalItems = groupedClusterItems.flatMap { $0 }.count
        
        
        if let globalIndex = globalIndex(for: indexPath,
                                         in: groupedClusterItems)
        {
            if globalIndex == 3
            {
                paginateIfNeeded(ascending: true)
            } else if globalIndex == totalItems - 6
            {
                paginateIfNeeded(ascending: false)
            }
        }
    }
    
    func tableView(_ tableView: UITableView,
                   didSelectRowAt indexPath: IndexPath)
    {
        tableView.deselectRow(at: indexPath, animated: false)
        
        guard let cell = tableView.cellForRow(at: indexPath) as? ConversationMessageCell else {return}
        
        if let touchLocation = tableView.panGestureRecognizer.location(in: cell) as CGPoint?
        {
            dismissInputBarView()
            
            if cell.contentContainer.frame.contains(touchLocation)
            {
                if cell.cellViewModel.message?.imagePath != nil
                {
                    initiatePhotoBrowserPresentation(from: cell)
                }
            }
        }
    }
    
    private func initiatePhotoBrowserPresentation(from cell: ConversationMessageCell)
    {
//        let imageView = cell.contentContainer.messageImageView
        guard let imageView = (cell.contentContainer as? TextImageMessageContentView)?.messageImageView else {return}
        let items = self.viewModel.mediaItems
        
        let initialIndex = items.firstIndex { $0.imagePath.lastPathComponent == cell.cellViewModel.message?.imagePath }
         
        self.photoBrowser.presentPhotoBrowser(
            on: self,
            usingItems: items,
            initialIndex: initialIndex ?? 0,
            originImageView: imageView
        )
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
    
    /// Pagination
    private func paginateIfNeeded(ascending: Bool)
    {
        Task { @MainActor in
            self.viewModel.isLocalPaginationActive = true
            
            if viewModel.paginateAdditionalLocalMessages(ascending: ascending)
            {
                UIView.animate(withDuration: 0.0)
                {
                    self.shouldIgnoreUnseenMessagesUpdate = true
                    self.dataSourceManager.configureSnapshot(animationType: .automatic)
                    {
                        self.shouldIgnoreUnseenMessagesUpdate = false
                    }
                }
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
                await viewModel.remoteMessagePaginator?.perform {
                    await preformRemotePagination(ascending: ascending)
                }
            }
            viewModel.isLocalPaginationActive = false
        }
    }
    
    private func offsetTableContentOnPaginationCompletion(
        to contentOffsetY: CGFloat,
        visibleCell: ConversationMessageCell?)
    {
        if self.rootView.tableView.contentOffset.y < -90.0
        {
            if let visibleCell = visibleCell,
               let indexPathOfVisibleCell = self.rootView.tableView.indexPath(for: visibleCell)
            {
                let lastCellRect = self.rootView.tableView.rectForRow(at: indexPathOfVisibleCell)
                self.rootView.tableView.contentOffset.y = contentOffsetY + lastCellRect.minY
            }
        }
    }
    
    private func preformRemotePagination(ascending: Bool) async
    {
        do {
            try await Task.sleep(for: .seconds(1))
            
            let direction: PaginationDirection = ascending ?
                .ascending : .descending
            switch try await viewModel.paginateRemoteMessages(direction: direction)
            {
            case .didPaginate:
                await MainActor.run
                {
                    let visibleCell: ConversationMessageCell? = self.rootView.tableView.visibleCells.first as? ConversationMessageCell
                    let currentOffsetY = self.rootView.tableView.contentOffset.y
                    
                    CATransaction.begin()
                    CATransaction.setDisableActions(true)
                    
                    self.shouldIgnoreUnseenMessagesUpdate = true
                    
                    self.dataSourceManager.configureSnapshot(
                        animationType: .automatic)
                    {
                        self.shouldIgnoreUnseenMessagesUpdate = false

                        self.offsetTableContentOnPaginationCompletion(
                            to: currentOffsetY,
                            visibleCell: visibleCell)
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
        /// See FootNote.swift [16]
        ///
        if self.rootView.tableView.contentOffset.y <= -91
        {
            self.rootView.tableView.contentOffset.y += 0.2
        }
        
        toggleSectionHeaderVisibility(isScrollActive: false)
    }
    
    func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool)
    {
        self.lastSeenStatusCheckUpdate = Date()
        if viewModel.shouldHideJoinGroupOption { updateMessageSeenStatusIfNeeded() }
//        
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
        
        if let messageCell = baseCell as? ConversationMessageCell,
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
            
            if abs(translationX) >= dragTreshhold
            {
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
    //    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer,
    //                           shouldReceive touch: UITouch) -> Bool
    //    {
    //        guard let stickerCollection = rootView.stickerCollectionView else {return true}
    //
    //        let tapLocation = touch.location(in: rootView)
    //
    //        if stickerCollection.frame.contains(tapLocation) || rootView.inputBarContainer.frame.contains(tapLocation)
    ////            || rootView.inputBarHeader?.frame.contains(tapLocation)
    //        {
    //            return false
    //        }
    //        return true
    //    }
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
        if let messageCell = cell as? ConversationMessageCell,
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

