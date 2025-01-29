//
//  ConversationViewController.swift
//  ChatUpp
//
//  Created by Andrei Pripa on 10/3/23.

// IMPORTANT: TABLE VIEW IS INVERTED, UPSIDE DOWN (BOTTOM => TOP),
// THEREFORE, SOME PROPERTIES AND ADJUSTMENTS WERE MADE AND SET AS BOTTOM => TOP.
// KEEP THIS IN MIND WHENEVER YOU WISH TO ADJUST TABLE VIEW


import UIKit
import Photos
import PhotosUI
import Combine
import SkeletonView


//MARK: - SCROLL VIEW DELEGATE
extension ChatRoomViewController: UIScrollViewDelegate
{
    func scrollViewDidScroll(_ scrollView: UIScrollView)
    {
        updateMessageSeenStatusIfNeeded()
        isLastCellFullyVisible ? toggleScrollBadgeButtonVisibility(shouldBeHidden: true) : toggleScrollBadgeButtonVisibility(shouldBeHidden: false)

        if shouldAdjustScroll {
            shouldAdjustScroll = false
            self.rootView.tableView.contentOffset.y = tableViewUpdatedContentOffset
        }
    }
    
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
    var shouldAdjustScroll: Bool = false
    var tableViewUpdatedContentOffset: CGFloat = 0.0
    
    weak var coordinatorDelegate :Coordinator?
    private var tableViewDataSource :ConversationTableViewDataSource!
    private var customNavigationBar :ChatRoomNavigationBar!
    private var rootView = ChatRoomRootView()
    private var viewModel: ChatRoomViewModel!
    private var inputMessageTextViewDelegate: InputBarMessageTextViewDelegate!

    private var isContextMenuPresented: Bool = false
    private var isNewSectionAdded: Bool = false
    private var isKeyboardHidden: Bool = true
    private var didFinishInitialScroll: Bool = false
    private var subscriptions = Set<AnyCancellable>()
    private var shouldScrollToFirstCell: Bool = false
    
    private var isLastCellFullyVisible: Bool {
        checkIfLastCellIsFullyVisible()
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
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        cleanUp()
    }
    
    private func scrollToCell(at indexPath: IndexPath)
    {
        guard indexPath.row < self.rootView.tableView.numberOfRows(inSection: indexPath.section) else {return}
        
        let updatedIndex = IndexPath(row: indexPath.row + 1, section: indexPath.section)
        
        self.rootView.tableView.scrollToRow(at: updatedIndex, at: .bottom, animated: false)
    }
    
    deinit {
        print("====ConversationVC Deinit")
    }

    private func setupController()
    {
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
    }
    
    private func refreshTableView() 
    {
        self.toggleSkeletonAnimation(.terminated)
        self.rootView.tableView.reloadData()
        self.view.layoutIfNeeded()
//        let indexPathTest = IndexPath(row: 13, section: 3)
        if let indexPath = self.viewModel.findFirstUnseenMessageIndex() {
            self.scrollToCell(at: indexPath)
        }
        self.didFinishInitialScroll = true

    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        if viewModel.conversationInitializationStatus == .finished {
            finalizeConversationSetup()
        }
    }
    
    private func finalizeConversationSetup() {
        viewModel.resetInitializationStatus()
        viewModel.insertUnseenMessagesTitle()
        refreshTableView()
        viewModel.addListeners()
        viewModel.realmService?.updateChatOpenStatusIfNeeded()
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
        
//        viewModel.userListenerService?.$chatUser
//            .receive(on: DispatchQueue.main)
//            .sink { [weak self] user in
//                guard let self = self else {return}
//                
//                if self.customNavigationBar.navigationItemsContainer?.titleLabel.text != user.name {
//                    self.customNavigationBar.navigationItemsContainer?.titleLabel.text = user.name
//                    return
//                }
//                
//                self.customNavigationBar.navigationItemsContainer?.statusLabel.text = user.isActive ?? false ?
//                "Online" : "last seen \(user.lastSeen?.formatToYearMonthDayCustomString() ?? "Recently")"
//            }.store(in: &subscriptions)
//        
        viewModel.$messageChangedTypes
            .debounce(for: .milliseconds(200), scheduler: DispatchQueue.main)
            .sink { [weak self] changeTypes in
                guard let self = self, !changeTypes.isEmpty else {return}
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
        rootView.tableView.performBatchUpdates {
            for changeType in changes
            {
                switch changeType {
                case .modified(let indexPath, let modifiedValue):
                    self.reloadCellRow(at: indexPath, with: modifiedValue.animationType)
                case .added:
                    self.handleTableViewCellInsertion(scrollToBottom: false)
                case .removed(let removedIndex):
                    self.reloadTableWithCrossDissolve(at: removedIndex)
                }
            }
        }
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
        coordinatorDelegate = nil
        viewModel = nil
        tableViewDataSource = nil
        customNavigationBar = nil
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
        customNavigationBar = ChatRoomNavigationBar(viewController: self, viewModel: navBarViewModel)
    }
    
    private func checkIfLastCellIsFullyVisible() -> Bool 
    {
        let table = rootView.tableView
        let lastCellIndexPath = IndexPath(row: 0, section: 0)
        
        /// - data source is not empty and table didn't layed out cells yet, return true
        guard !table.visibleCells.isEmpty else {return true}
        
        guard let lastCell = table.cellForRow(at: lastCellIndexPath) as? ConversationTableViewCell else {
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
        guard let _ = self.rootView.tableView.cellForRow(at: indexPath) as? ConversationTableViewCell else { return }
        self.rootView.tableView.reloadRows(at: [indexPath], with: animation)
    }
    
    private func reloadTableWithCrossDissolve(at indexPath: IndexPath)
    {
        UIView.transition(with: self.rootView.tableView, duration: 0.5, options: .transitionCrossDissolve) {
            //            self.rootView.tableView.reloadData()
            guard self.rootView.tableView.numberOfRows(inSection: 0) != 1 else {
                self.rootView.tableView.deleteSections(IndexSet(integer: 0), with: .fade)
                return
            }
            self.rootView.tableView.deleteRows(at: [indexPath], with: .fade)
        }
    }
}

//MARK: - Handle cell message insertion
extension ChatRoomViewController {
    
    private func createMessageBubble(from messageText: String = "")
    {
        viewModel.manageMessageCreation(messageText)
        
        Task { @MainActor in
            handleTableViewCellInsertion(scrollToBottom: true)
        }
    }
    
    private func handleTableViewCellInsertion(with indexPath: IndexPath = IndexPath(row: 0, section: 0), scrollToBottom: Bool)
    {
        isNewSectionAdded = checkIfNewSectionWasAdded()
        handleRowAndSectionInsertion(with: indexPath, scrollToBottom: scrollToBottom)
        animateCellOffsetOnInsertion(usingCellIndexPath: indexPath)
        
        isNewSectionAdded = false
        shouldScrollToFirstCell = true
    }
    
    private func handleRowAndSectionInsertion(with indexPath: IndexPath, scrollToBottom: Bool) {
        let currentOffSet = self.rootView.tableView.contentOffset
        let contentIsScrolled = (currentOffSet.y > -390.0 && !isKeyboardHidden) || (currentOffSet.y > -55 && isKeyboardHidden)
        
        // We disable insertion animation, in else block, because we need to both
        // animate insertion of message and scroll to bottom at the same time.
        // If we dont do this, conflict occurs and results in glitches
        // Instead we will animate contentOffset
        // This is not the case if table content is scrolled,
        // meaning, cell is not visible
        
        if !scrollToBottom && contentIsScrolled {
            UIView.animate(withDuration: 0.0) {
                self.rootView.tableView.insertRows(at: [indexPath], with: .none)
                self.rootView.tableView.reloadData()
            }
            return
        } else {
            UIView.performWithoutAnimation {
                if self.rootView.tableView.visibleCells.isEmpty {
                    self.rootView.tableView.insertSections(IndexSet(integer: 0), with: .none)
                    self.rootView.tableView.reloadData()
                } else {
                    self.rootView.tableView.reloadData()
                }
            }
        }
    }
    
    private func animateCellOffsetOnInsertion(usingCellIndexPath indexPath: IndexPath)
    {
        let currentOffSet = self.rootView.tableView.contentOffset
        guard let cell = self.rootView.tableView.cellForRow(at: indexPath) as? ConversationTableViewCell else { return }
        
        // Offset collection view content by cells (message) height contentSize
        // without animation, so that cell appears under the textView
        let offSet = CGPoint(x: currentOffSet.x, y: currentOffSet.y + cell.bounds.height)
        self.rootView.tableView.setContentOffset(offSet, animated: false)
        cell.frame.origin.y = -40
        
        // Animate collection content back so that the cell (message) will go up
        UIView.animate(withDuration: 0.3, delay: 0.1) {
            cell.frame.origin.y = 0
            self.rootView.tableView.setContentOffset(currentOffSet, animated: false)
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
    private func updateMessageSeenStatusIfNeeded() {
        guard let visibleIndices = rootView.tableView.indexPathsForVisibleRows else { return }

        for indexPath in visibleIndices {
            guard let cell = rootView.tableView.cellForRow(at: indexPath) as? ConversationTableViewCell,
                  checkIfCellMessageIsCurrentlyVisible(at: indexPath) else {
                continue
            }
            cell.cellViewModel.updateRealmMessageSeenStatus()
            
            Task { @MainActor in
                await viewModel.updateMessageSeenStatus(from: cell.cellViewModel)
                viewModel.updateUnseenMessageCounter(shouldIncrement: false)
            }
        }
    }
    
    private func checkIfCellMessageIsCurrentlyVisible(at indexPath: IndexPath) -> Bool {
        let message = viewModel.messageClusters[indexPath.section].items[indexPath.row].message
        let authUserID = viewModel.authUser.uid
        
        guard message?.messageSeen == false,
              message?.senderId != authUserID,
              let cell = rootView.tableView.cellForRow(at: indexPath) else {
            return false
        }

        let cellFrame = cell.frame
        let tableRect = rootView.tableView.bounds.offsetBy(dx: 0, dy: 65)
        return tableRect.contains(cellFrame)
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
            removeTextViewText()
            inputMessageTextViewDelegate.invalidateTextViewSize()
            callTextViewDidChange()

            if !viewModel.conversationExists { viewModel.setupConversation() }
            
            createMessageBubble(from: trimmedString)
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
                tableView.setContentOffset(CGPoint(x: 0, y: updatedContentOffset), animated: false)
                tableView.verticalScrollIndicatorInsets.top = updatedContentTopInset
                tableView.contentInset.top = updatedContentTopInset
            }
            if self.shouldScrollToFirstCell == true
            {
                self.rootView.tableView.layoutIfNeeded()
                self.rootView.tableView.scrollToRow(at: IndexPath(row: 0, section: 0), at: .top, animated: true)

                self.shouldScrollToFirstCell = false
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
                guard let image = reading as? UIImage, error == nil else {
                    print("Could not read image!")
                    return
                }
                guard let newSize = ImageSample.user.sizeMapping[.original] else {return}
                guard let downsampledImage = image.downsample(toSize: newSize, withCompressionQuality: 0.6).getJpegData() else {return}
                
                let imageSize = MessageImageSize(width: Int(image.size.width), height: Int(image.size.height))
                
                self?.createMessageBubble()
                self?.viewModel.handleImageDrop(imageData: downsampledImage, size: imageSize)
            }
        }
    }
}

//MARK: - GESTURES
extension ChatRoomViewController {
    
    private func addGestureToTableView() {
        let tap = UITapGestureRecognizer(target: self, action: #selector(resignKeyboard))
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
    func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        guard !tableView.sk.isSkeletonActive,
              let footerView = tableView.dequeueReusableHeaderFooterView(withIdentifier: ReuseIdentifire.HeaderFooter.footer.identifire) as? FooterSectionView else { return nil }
        
        let dateForSection = viewModel.messageClusters[section].date.formatToYearMonthDayCustomString()
        footerView.setDate(dateText: dateForSection)
        return footerView
    }
    
    func tableView(_ tableView: UITableView, willDisplayFooterView view: UIView, forSection section: Int) {
        if isNewSectionAdded && section == 0 {
            view.alpha = 0.0
            
            view.frame = view.frame.offsetBy(dx: view.frame.origin.x, dy: -30)
            UIView.animate(withDuration: 0.3) {
                view.frame = view.frame.offsetBy(dx: view.frame.origin.x, dy: 30)
                view.alpha = 1.0
            }
        }
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
              didFinishInitialScroll == true
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
        didFinishInitialScroll = false

        Task { @MainActor [weak self] in
            
            try await Task.sleep(nanoseconds: 500_000_000)
            
            guard let self = self else { return }
            
            if let (newRows, newSections) = try await self.viewModel.handleAdditionalMessageClusterUpdate(inAscendingOrder: order)
            {
                self.performeTableViewUpdate(with: newRows, sections: newSections)
            }
            self.didFinishInitialScroll = true
        }
        
    }
    
    private func performeTableViewUpdate(with newRows: [IndexPath], sections: IndexSet?)
    {
        var visibleCell: ConversationTableViewCell? = nil
        let currentOffsetY = self.rootView.tableView.contentOffset.y
        
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        
        self.rootView.tableView.performBatchUpdates({
            visibleCell = self.rootView.tableView.visibleCells.first as? ConversationTableViewCell
            
            if let sections = sections {
                self.rootView.tableView.insertSections(sections, with: .none)
            }
            if !newRows.isEmpty {
                self.rootView.tableView.insertRows(at: newRows, with: .none)
            }
        }, completion: { _ in
        
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
    
    //MARK: - Context menu configuration
    func tableView(_ tableView: UITableView, contextMenuConfigurationForRowAt indexPath: IndexPath, point: CGPoint) -> UIContextMenuConfiguration? {
        
        guard let cell = tableView.cellForRow(at: indexPath) as? ConversationTableViewCell else {return nil}
        let tapLocationInCell = cell.contentView.convert(point, from: tableView)
        
        if cell.messageBubbleContainer.frame.contains(tapLocationInCell) {
            let identifire = indexPath as NSCopying
            
            return UIContextMenuConfiguration(identifier: identifire, previewProvider: nil, actionProvider: { _ in
                
                let selectedCellMessageText = cell.messageLabel.text
                guard let message = cell.cellViewModel.message else {return nil}
                
                let replyAction = UIAction(title: "Reply", image: UIImage(systemName: "arrowshape.turn.up.left")) { action in
                    DispatchQueue.main.async {
                        let replyMessageId = message.id
                        let replyMessageSenderID = message.senderId
                        let messageSenderName = self.viewModel.getMessageSenderName(usingSenderID: replyMessageSenderID)
                        self.viewModel.currentlyReplyToMessageID = replyMessageId
                        self.handleContextMenuSelectedAction(actionOption: .reply, selectedMessageText: selectedCellMessageText)
                        self.rootView.inputBarHeader?.updateTitleLabel(usingText: messageSenderName)
                    }
                }
            
                let copyAction = UIAction(title: "Copy", image: UIImage(systemName: "doc.on.doc")) { action in
                    let pastBoard = UIPasteboard.general
                    pastBoard.string = cell.messageLabel.text
                }
                
                /// display edit/delete actions only on messages that authenticated user sent
                let messageBelongsToAuthenticatedUser = message.senderId == self.viewModel.authUser.uid
                let attributesForEditAction = messageBelongsToAuthenticatedUser ? [] : UIMenuElement.Attributes.hidden
                let attributesForDeleteAction = messageBelongsToAuthenticatedUser ? .destructive : UIMenuElement.Attributes.hidden
                
                
                let editAction = UIAction(title: "Edit", image: UIImage(systemName: "pencil.and.scribble"), attributes: attributesForEditAction) { action in
                    DispatchQueue.main.async 
                    {
                        self.rootView.messageTextView.text = cell.messageLabel.text
                        self.handleContextMenuSelectedAction(actionOption: .edit, selectedMessageText: selectedCellMessageText)
                        self.viewModel.shouldEditMessage = { [message] edditedMessage in
                            self.viewModel.firestoreService?.editMessageTextFromFirestore(edditedMessage, messageID: message.id)
                        }
                    }
                }
                let deleteAction = UIAction(title: "Delete", image: UIImage(systemName: "trash"), attributes: attributesForDeleteAction) { [weak self] action in
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                        self?.viewModel.firestoreService?.deleteMessageFromFirestore(messageID: message.id)
                    }
                }
                return UIMenu(title: "", children: [replyAction, editAction, copyAction, deleteAction])
            })
        }
        return nil
    }
    
    func tableView(_ tableView: UITableView, previewForHighlightingContextMenuWithConfiguration configuration: UIContextMenuConfiguration) -> UITargetedPreview? {
        return makeConversationMessagePreview(for: configuration)
    }

    func tableView(_ tableView: UITableView, previewForDismissingContextMenuWithConfiguration configuration: UIContextMenuConfiguration) -> UITargetedPreview? {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            self.isContextMenuPresented = false
        }
        return makeConversationMessagePreview(for: configuration)
    }
    
    func tableView(_ tableView: UITableView, willDisplayContextMenu configuration: UIContextMenuConfiguration, animator: UIContextMenuInteractionAnimating?) {
        if rootView.inputBarBottomConstraint.constant != 0.0 {
            isContextMenuPresented = true
        }
    }
    
    private func makeConversationMessagePreview(for configuration: UIContextMenuConfiguration) -> UITargetedPreview? {
        guard let indexPath = configuration.identifier as? IndexPath,
              let cell = rootView.tableView.cellForRow(at: indexPath) as? ConversationTableViewCell else {return nil}
        
        let parameter = UIPreviewParameters()
        parameter.backgroundColor = .clear
        
        let preview = UITargetedPreview(view: cell.messageLabel, parameters: parameter)
        return preview
    }
    
    private func handleContextMenuSelectedAction(actionOption: InputBarHeaderView.Mode, selectedMessageText text: String?) {
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
    private func toggleSkeletonAnimation(_ state: SkeletonAnimationState) {
        switch state {
        case .initiated: initiateSkeletonAnimation()
        case .terminated: terminateSkeletonAnimation()
        default: break
        }
    }
    
    private func initiateSkeletonAnimation() {
        let skeletonAnimationColor = #colorLiteral(red: 0.1411764771, green: 0.3960784376, blue: 0.5647059083, alpha: 1)
        let skeletonItemColor = #colorLiteral(red: 0.4780891538, green: 0.7549679875, blue: 0.8415568471, alpha: 1)
        rootView.tableView.showGradientSkeleton(usingGradient: .init(baseColor: skeletonItemColor, secondaryColor: skeletonAnimationColor), delay: TimeInterval(0), transition: SkeletonTransitionStyle.crossDissolve(0.7))
//        rootView.tableView.contentInset = UIEdgeInsets(top: 60, left: 0, bottom: 0, right: 0)
//        rootView.tableView.showSkeleton()
        
//        rootView.tableView.showAnimatedGradientSkeleton(usingGradient: .init(baseColor: skeletonItemColor, secondaryColor: skeletonAnimationColor))
        //        tableView.showAnimatedGradientSkeleton(usingGradient: .init(baseColor: skeletonItemColor, secondaryColor: skeletonAnimationColor), transition: .crossDissolve(.signalingNaN))
    }
    
    private func terminateSkeletonAnimation() {
        rootView.tableView.stopSkeletonAnimation()
        rootView.tableView.hideSkeleton(transition: SkeletonTransitionStyle.none)
    }
}



















//MARK: - Code not in use :

//        conversationViewModel.$skeletonAnimationState
//            .receive(on: DispatchQueue.main)
//            .sink { [weak self] animationState in
//
//                //TODO: - Return to this block of code and reconsider it
//                guard let self = self, animationState != .none else {return}
//
//                self.toggleSkeletonAnimation(animationState)
////                if let index = conversationViewModel.firstUnseenMessageIndex {  self.scrollToCell(at: index)
////                }
//            }.store(in: &subscriptions)
//
//        conversationViewModel.$firstUnseenMessageIndex
//            .receive(on: DispatchQueue.main)
//            .sink { [weak self] indexOfCellToScrollTo in
//
//                guard let self = self, let indexPath = indexOfCellToScrollTo else {return}
//
//                self.rootView.tableView.reloadData()
//                self.view.layoutIfNeeded()
//                self.scrollToCell(at: indexPath)
//
////                guard let indexToScrollTo = indexOfCellToScrollTo else {return}
////                self.rootView.tableView.scrollToRow(at: indexToScrollTo, at: .top, animated: false)
////                self.updateMessageSeenStatusIfNeeded()
//            }.store(in: &subscriptions)
//
//        conversationViewModel.conversationListenersInitiationSubject
//            .receive(on: DispatchQueue.main)
//            .sink { [weak self] _ in
//                self?.conversationViewModel?.addListeners()
//            }.store(in: &subscriptions)
