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
extension ConversationViewController: UIScrollViewDelegate
{
    func scrollViewDidScroll(_ scrollView: UIScrollView)
    {
        updateMessageSeenStatusIfNeeded()
        if !shouldIgnoreScrollToBottomBtnUpdate {
            updateScrollToBottomBtnIfNeeded()
        }
    }
}

final class ConversationViewController: UIViewController {
    
    weak var coordinatorDelegate :Coordinator?
    private var tableViewDataSource :ConversationViewDataSource!
    private var customNavigationBar :ConversationCustomNavigationBar!
    private var rootView = ConversationRootView()
    private var conversationViewModel :ConversationViewModel!
    private var rootViewTextViewDelegate: ConversationTextViewDelegate!
    
    private var shouldIgnoreScrollToBottomBtnUpdate: Bool = false
    private var isContextMenuPresented: Bool = false
    private var isNewSectionAdded: Bool = false
    private var isKeyboardHidden: Bool = true
    
    private var subscriptions = Set<AnyCancellable>()
    
    //MARK: - Lifecycle
    
    convenience init(conversationViewModel: ConversationViewModel) {
        self.init()
        self.conversationViewModel = conversationViewModel
    }
    
    override func loadView() {
        view = rootView
        rootViewTextViewDelegate = ConversationTextViewDelegate(view: rootView)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupController()
//        conversationViewModel.initiateConversation()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
//
//        guard let indexPath = conversationViewModel.firstUnseenMessageIndex else {return}
//        scrollToCell(at: indexPath)
//        conversationViewModel.firstUnseenMessageIndex = nil
    }
    
    private func scrollToCell(at indexPath: IndexPath) 
    {
        guard indexPath.row < rootView.tableView.numberOfRows(inSection: indexPath.section) else {return}
        self.rootView.tableView.scrollToRow(at: indexPath, at: .top, animated: false)
//        let rect = rootView.tableView.rectForRow(at: indexPath)
//        rootView.tableView.contentOffset = CGPoint(x: 0, y: rect.origin.y - rootView.inputBarContainer.bounds.height)
//        conversationViewModel.firstUnseenMessageIndex = nil
    }
    

    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        cleanUp()
    }

    deinit {
        print("====ConversationVC Deinit")
    }

    private func setupController() 
    {
        configureTableView()
        addGestureToTableView()
        setNavigationBarItems()
        addTargetsToButtons()
        addKeyboardNotificationObservers()
        setupBinding()
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
//        guard let indexPath = self.conversationViewModel.findFirstUnseenMessageIndex() else {
//            return
//        }
        let indexPath = IndexPath(row: 10, section: 0)
        self.scrollToCell(at: indexPath)
    }
    
    private func setupBinding()
    {
        conversationViewModel.$conversationInitializationStatus
            .receive(on: DispatchQueue.main)
            .sink { initializationStatus in
                switch initializationStatus {
                case .inProgress: self.toggleSkeletonAnimation(.initiated)
                case .finished:
                    self.refreshTableView()
                    self.conversationViewModel.addListeners()
                default: break
                }
            }.store(in: &subscriptions)
        
        conversationViewModel.$participant
            .receive(on: DispatchQueue.main)
            .sink { [weak self] user in
                guard let self = self else {return}
                
                if self.customNavigationBar.navigationItemsContainer.nameLabel.text != user.name {
                    self.customNavigationBar.navigationItemsContainer.nameLabel.text = user.name
                    return
                }
                
                self.customNavigationBar.navigationItemsContainer.lastSeenLabel.text = user.isActive ?? false ?
                "Online" : "last seen \(user.lastSeen?.formatToYearMonthDayCustomString() ?? "Recently")"
            }.store(in: &subscriptions)
        
        conversationViewModel.$messageChangedType
            .receive(on: DispatchQueue.main)
            .sink { [weak self] changeType in
                guard let self = self else {return}
                
                switch changeType {
                case .modified(let indexPath, let modifiedValue):
                    let animationType = self.getAnimationType(from: modifiedValue)
                    self.reloadCellRow(at: indexPath, with: animationType)
                case .added:
                    self.handleTableViewCellInsertion(scrollToBottom: false)
                case .removed:
                    UIView.transition(with: self.rootView.tableView, duration: 0.5, options: .transitionCrossDissolve) {
                        self.rootView.tableView.reloadData()
                    }
                default: break
                }
            }.store(in: &subscriptions)
    }
    
    //MARK: - Keyboard notification observers
    private func addKeyboardNotificationObservers() {
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow), name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide), name: UIResponder.keyboardWillHideNotification, object: nil)
    }

    @objc func keyboardWillShow(notification: NSNotification) {
        if let keyboardSize = (notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue {
            if rootView.inputBarContainer.frame.origin.y > 580 {
                if isContextMenuPresented {
                    let keyboardHeight = -336.0
                    updateInputBarBottomConstraint(toSize: keyboardHeight)
                } else {
                    handleTableViewOffSet(usingKeyboardSize: keyboardSize)
                }
                isKeyboardHidden = false
            }
        }
    }
    
    @objc func keyboardWillHide(notification: NSNotification) {
        if let keyboardSize = (notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue {
            if !isContextMenuPresented {
                handleTableViewOffSet(usingKeyboardSize: keyboardSize)
            } else if isContextMenuPresented {
                updateInputBarBottomConstraint(toSize: 0)
            }
            isKeyboardHidden = true
        }
    }
    
    //MARK: - Private functions
    
    private func cleanUp() {
        NotificationCenter.default.removeObserver(self)
        conversationViewModel.messageListener?.remove()
        conversationViewModel.userListener?.remove()
        coordinatorDelegate = nil
        conversationViewModel = nil
        tableViewDataSource = nil
        customNavigationBar = nil
    }
    
    private func configureTableView() {
        tableViewDataSource = ConversationViewDataSource(conversationViewModel: conversationViewModel)
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
            self.rootViewTextViewDelegate.textViewDidChange(self.rootView.messageTextView)
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
    private func setNavigationBarItems() {
        let imageData = conversationViewModel.memberProfileImage 
        let member = conversationViewModel.participant
        var memberActiveStatus: String
        
        memberActiveStatus = member.isActive ?? false ?
        "Online" : "last seen \(member.lastSeen?.formatToYearMonthDayCustomString() ?? "Recently")"

        customNavigationBar = ConversationCustomNavigationBar(viewController: self)
        customNavigationBar.setupNavigationBarItems(with: imageData, memberName: member.name ?? "unknow", memberActiveStatus: memberActiveStatus)
    }
    
    /// - Scroll to bottom btn functions
    private func updateScrollToBottomBtnIfNeeded() {
        let lastCellIndexPath = IndexPath(row: 0, section: 0)
        
        /// check if first cell indexPath is visible before proceeding further
        guard let containsIndexPathZero = rootView.tableView.indexPathsForVisibleRows?.contains(where: {$0 == lastCellIndexPath}) else {return}
        guard containsIndexPathZero == true else {return}

        /// activate scrollBottomBtn if first cell is no longer visible or covered with inputBar
        if let lastCell = rootView.tableView.cellForRow(at: lastCellIndexPath) as? ConversationTableViewCell {
            let lastCellRect = rootView.tableView.convert(lastCell.frame, to: rootView.tableView.superview)
            let holderViewRect = rootView.inputBarContainer.frame
            
            if lastCellRect.maxY - 30 > holderViewRect.minY {
                animateScrollToBottomBtn(shouldBeHidden: false)
            } else {
                animateScrollToBottomBtn(shouldBeHidden: true)
            }
        }
    }
    
    private func animateScrollToBottomBtn(shouldBeHidden: Bool) {
        UIView.animate(withDuration: 0.3) {
            self.rootView.scrollToBottomBtn.layer.opacity = shouldBeHidden ? 0.0 : 1.0
        }
    }
    
    private func getAnimationType(from valueModification: MessageValueModification) -> UITableView.RowAnimation {
        switch valueModification {
        case .seenStatus: return .none
        case .text: return .left
        }
    }
    
    private func reloadCellRow(at indexPath: IndexPath, with animation: UITableView.RowAnimation)
    {
        guard let _ = self.rootView.tableView.cellForRow(at: indexPath) as? ConversationTableViewCell else { return }
        self.rootView.tableView.reloadRows(at: [indexPath], with: animation)
    }
}

//MARK: - Handle cell message insertion
extension ConversationViewController {
    
    private func handleMessageBubbleCreation(messageText: String = "")
    {
        self.conversationViewModel.manageMessageCreation(messageText)
        
        Task { @MainActor in
            self.handleTableViewCellInsertion(scrollToBottom: true)
        }
    }
    
    private func handleTableViewCellInsertion(with indexPath: IndexPath = IndexPath(row: 0, section: 0), scrollToBottom: Bool)
    {
        isNewSectionAdded = checkIfNewSectionWasAdded()
        handleRowAndSectionInsertion(with: indexPath, scrollToBottom: scrollToBottom)

        // Schedules scrolling execution in order for proper animation scrolling
        DispatchQueue.main.async {
            if scrollToBottom {self.rootView.tableView.scrollToRow(at: indexPath, at: .top, animated: true)}
        }
        animateCellOffsetOnInsertion(usingCellIndexPath: indexPath)
        isNewSectionAdded = false
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
    
    private func animateCellOffsetOnInsertion(usingCellIndexPath indexPath: IndexPath) {
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
        if rootView.tableView.numberOfSections < conversationViewModel.messageGroups.count {
            return true
        }
        return false
    }
}

//MARK: - Message seen status handler
extension ConversationViewController 
{
    private func updateMessageSeenStatusIfNeeded() {
        guard let visibleIndices = rootView.tableView.indexPathsForVisibleRows else { return }

        for indexPath in visibleIndices {
            guard let cell = rootView.tableView.cellForRow(at: indexPath) as? ConversationTableViewCell,
                  checkIfCellMessageIsCurrentlyVisible(at: indexPath) else {
                continue
            }
            Task { @MainActor in
                
                //realm message seen status update
                cell.cellViewModel.updateRealmMessageSeenStatus()
                //firestore message seen status update
                await conversationViewModel.updateMessageSeenStatus(from: cell.cellViewModel)
                // gets unread messages from firestore and assignes to local count badge
                try await conversationViewModel.updateUnreadMessagesCount?()
            }
        }
    }
    
    private func checkIfCellMessageIsCurrentlyVisible(at indexPath: IndexPath) -> Bool {
        let cellMessage = conversationViewModel.messageGroups[indexPath.section].cellViewModels[indexPath.row].cellMessage
        let authUserID = conversationViewModel.authenticatedUserID
    
        guard !cellMessage.messageSeen, cellMessage.senderId != authUserID,
              let cell = rootView.tableView.cellForRow(at: indexPath) else {
            return false
        }

        let cellFrame = cell.frame
        let tableRect = rootView.tableView.bounds.offsetBy(dx: 0, dy: 65)
        return tableRect.contains(cellFrame)
    }
    
    //    private func handleSectionAnimation() {
    //        guard let footerView = rootView.tableView.footerView(forSection: 0) else {return}
    //
    //        footerView.alpha = 0.0
    //        footerView.frame = footerView.frame.offsetBy(dx: footerView.frame.origin.x, dy: -30)
    //        UIView.animate(withDuration: 0.3) {
    //            footerView.frame = footerView.frame.offsetBy(dx: footerView.frame.origin.x, dy: 30)
    //            footerView.alpha = 1.0
    //        }
    //    }
        
}


//MARK: - VIEW BUTTON'S TARGET'S
extension ConversationViewController {
    
    private func addTargetToScrollToBottomBtn() {
        rootView.scrollToBottomBtn.addTarget(self, action: #selector(scrollToBottomBtnWasTapped), for: .touchUpInside)
    }
    private func addTargetToSendMessageBtn() {
        rootView.sendMessageButton.addTarget(self, action: #selector(sendMessageBtnWasTapped), for: .touchUpInside)
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
        conversationViewModel.shouldEditMessage?(editedMessage)
        rootView.sendEditMessageButton.isHidden = true
        rootView.messageTextView.text.removeAll()
        animateInputBarHeaderViewDestruction()
    }
    
    @objc func sendMessageBtnWasTapped() 
    {
        let trimmedString = getTrimmedString()
        if !trimmedString.isEmpty
        {
            removeTextViewText()
            callTextViewDidChange()
            conversationViewModel.createConversationIfNeeded()
            handleMessageBubbleCreation(messageText: trimmedString)
            closeInputBarHeaderView()
        }
    }

    @objc func pictureAddBtnWasTapped() {
        configurePhotoPicker()
    }
}

//MARK: - Helper functions
extension ConversationViewController
{
    private func getTrimmedString() -> String {
        return rootView.messageTextView.text.trimmingCharacters(in: .whitespacesAndNewlines)
    }
    private func removeTextViewText() {
        rootView.messageTextView.text.removeAll()
    }
    private func callTextViewDidChange() {
        let textView = rootView.messageTextView
        rootViewTextViewDelegate.textViewDidChange(textView)
    }
}

//MARK: - TABLE OFFSET HANDLER
extension ConversationViewController {
    private func handleTableViewOffSet(usingKeyboardSize keyboardSize: CGRect) {
        
        // if number of lines inside textView is bigger than 1, it will expand
        // and origin.y of containerView that holds textView will change
        // so we check if maximum allowed number of line is reached (containerView origin.y will be 584)
        let containerViewYPointWhenMaximumLineNumberReached = 584.0 - 4.0
        let keyboardHeight = rootView.inputBarContainer.frame.origin.y > containerViewYPointWhenMaximumLineNumberReached ? -keyboardSize.height : keyboardSize.height
        let  editViewHeight = rootView.inputBarHeader?.bounds.height != nil ? rootView.inputBarHeader!.bounds.height : 0
        
        // if there is more than one line, textView height should be added to table view inset (max 5 lines allowed)
        let textViewHeight = (rootView.messageTextView.font!.lineHeight * CGFloat(rootViewTextViewDelegate.messageTextViewNumberOfLines)) - CGFloat(rootView.messageTextView.font!.lineHeight)
        
        let customTableViewInset = keyboardHeight < 0 ? abs(keyboardHeight) + textViewHeight + editViewHeight : 0 + textViewHeight + editViewHeight
        let currentOffSet = rootView.tableView.contentOffset
        let offSet = CGPoint(x: currentOffSet.x, y: keyboardHeight + currentOffSet.y)
        
        shouldIgnoreScrollToBottomBtnUpdate = true
        rootView.inputBarBottomConstraint.constant = keyboardHeight < 0 ? keyboardHeight : 0
        rootView.tableView.contentInset.top = customTableViewInset
        rootView.tableView.setContentOffset(offSet, animated: false)
        rootView.tableView.verticalScrollIndicatorInsets.top = customTableViewInset
        shouldIgnoreScrollToBottomBtnUpdate = false
        view.layoutSubviews()
    }
}

//MARK: - PHOTO PICKER CONFIGURATION & DELEGATE
extension ConversationViewController: PHPickerViewControllerDelegate {
    
    func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
        picker.dismiss(animated: true)
        
        results.forEach { result in
            result.itemProvider.loadObject(ofClass: UIImage.self) { [weak self] reading, error in
                guard let image = reading as? UIImage, error == nil else {
                    print("Could not read image!")
                    return
                }
                guard let data = image.jpegData(compressionQuality: 0.5) else {return}
                let imageSize = MessageImageSize(width: Int(image.size.width), height: Int(image.size.height))
                
                self?.handleMessageBubbleCreation()
                self?.conversationViewModel.handleImageDrop(imageData: data, size: imageSize)
            }
        }
    }
}

//MARK: - GESTURES
extension ConversationViewController {
    
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
            conversationViewModel.resetCurrentReplyMessageIfNeeded()
            animateInputBarHeaderViewDestruction()
        }
    }
}


//MARK: - TABLE  DELEGATE
extension ConversationViewController: UITableViewDelegate
{
    func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        guard !tableView.sk.isSkeletonActive else { return nil }
        let label = DateHeaderLabel()
        let containerView = UIView()
        
        containerView.addSubview(label)
        
        let dateForSection = conversationViewModel.messageGroups[section].date
        label.text = dateForSection.formatToYearMonthDayCustomString()
        label.centerXAnchor.constraint(equalTo: containerView.centerXAnchor).isActive = true
        label.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 10).isActive = true
        label.bottomAnchor.constraint(equalTo: containerView.bottomAnchor, constant: -10).isActive = true
        
        containerView.transform = CGAffineTransform(scaleX: 1, y: -1)
        return containerView
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
//        if conversationViewModel.skeletonAnimationState == .initiated {
        if conversationViewModel.conversationInitializationStatus == .inProgress {
            return CGFloat((70...120).randomElement()!)
        }
       return  UITableView.automaticDimension
    }
    
    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
     
        guard conversationViewModel.messageGroups.count != 0 else {return}
        
        let lastSectionIndex = conversationViewModel.messageGroups.count - 1
        let lastRowIndex = conversationViewModel.messageGroups[lastSectionIndex].cellViewModels.count - 1
        let isLastCellDisplayed = indexPath.section == lastSectionIndex && indexPath.row == lastRowIndex
        let isFirstCellDisplayed = indexPath.section == 0 && indexPath.row == 0
        
        if isLastCellDisplayed {
            handleAdditionalMessageGroupUpdate(inAscending: false)
        } else if isFirstCellDisplayed && conversationViewModel.shouldFetchNewMessages && conversationViewModel.ischatOpened {
            handleAdditionalMessageGroupUpdate(inAscending: true)
        }
    }
 
    private func handleAdditionalMessageGroupUpdate(inAscending order: Bool) {
        Task { @MainActor in
            let (newRows, newSections) = try await conversationViewModel.manageAdditionalMessageGroupsCreation(ascending: order)
            self.performeTableViewUpdate(with: newRows, sections: newSections)
        }
    }
    
    private func performeTableViewUpdate(with newRows: [IndexPath], sections: IndexSet?) {
        UIView.performWithoutAnimation {
            self.rootView.tableView.performBatchUpdates {
                if !newRows.isEmpty {
                    self.rootView.tableView.insertRows(at: newRows, with: .automatic)
                }
                if let sections = sections {
                    self.rootView.tableView.insertSections(sections, with: .automatic)
                }
            }
        }
    }
    
    //MARK: - Context menu configuration
    func tableView(_ tableView: UITableView, contextMenuConfigurationForRowAt indexPath: IndexPath, point: CGPoint) -> UIContextMenuConfiguration? {
        
        guard let cell = tableView.cellForRow(at: indexPath) as? ConversationTableViewCell else {return nil}
        let tapLocationInCell = cell.contentView.convert(point, from: tableView)
        
        if cell.messageBubbleContainer.frame.contains(tapLocationInCell) {
            let identifire = indexPath as NSCopying
            
            return UIContextMenuConfiguration(identifier: identifire, previewProvider: nil, actionProvider: { _ in
                
                let selectedCellMessageText = cell.messageLabel.text
                let cellMessage = cell.cellViewModel.cellMessage
                
                let replyAction = UIAction(title: "Reply", image: UIImage(systemName: "arrowshape.turn.up.left")) { action in
                    DispatchQueue.main.async {
                        let replyMessageId = cellMessage.id
                        let replyMessageSenderID = cellMessage.senderId
                        let messageSenderName = self.conversationViewModel.getMessageSenderName(usingSenderID: replyMessageSenderID)
                        self.conversationViewModel.currentlyReplyToMessageID = replyMessageId
                        self.handleContextMenuSelectedAction(actionOption: .reply, selectedMessageText: selectedCellMessageText)
                        self.rootView.inputBarHeader?.updateTitleLabel(usingText: messageSenderName)
                    }
                }
            
                let copyAction = UIAction(title: "Copy", image: UIImage(systemName: "doc.on.doc")) { action in
                    let pastBoard = UIPasteboard.general
                    pastBoard.string = cell.messageLabel.text
                }
                
                /// display edit/delete actions only on messages that authenticated user sent
                let messageBelongsToAuthenticatedUser = cellMessage.senderId == self.conversationViewModel.authenticatedUserID
                let attributesForEditAction = messageBelongsToAuthenticatedUser ? [] : UIMenuElement.Attributes.hidden
                let attributesForDeleteAction = messageBelongsToAuthenticatedUser ? .destructive : UIMenuElement.Attributes.hidden

                let editAction = UIAction(title: "Edit", image: UIImage(systemName: "pencil.and.scribble"), attributes: attributesForEditAction) { action in
                    DispatchQueue.main.async 
                    {
                        self.rootView.messageTextView.text = cell.messageLabel.text
                        self.handleContextMenuSelectedAction(actionOption: .edit, selectedMessageText: selectedCellMessageText)
                        self.conversationViewModel.shouldEditMessage = { [cellMessage] edditedMessage in
                            self.conversationViewModel.editMessageTextFromFirestore(edditedMessage, messageID: cellMessage.id)
                        }
                    }
                }
                let deleteAction = UIAction(title: "Delete", image: UIImage(systemName: "trash"), attributes: attributesForDeleteAction) { [weak self] action in
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                        self?.conversationViewModel.deleteMessageFromFirestore(messageID: cellMessage.id)
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
        self.rootViewTextViewDelegate.textViewDidChange(self.rootView.messageTextView)
    }
}


//MARK: - SkeletonView animation
extension ConversationViewController
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
