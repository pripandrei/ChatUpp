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

final class ConversationViewController: UIViewController, UIScrollViewDelegate {
    
    weak var coordinatorDelegate :Coordinator?
    private var collectionViewDataSource :ConversationViewDataSource!
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
    }
    
    private func setupController() {
        setupBinding()
        setNavigationBarItems()
        configureTableView()
        addKeyboardNotificationObservers()
        addTargetToSendMessageBtn()
        addTargetToAddPictureBtn()
        addTargetToEditMessageBtn()
        addTargetToScrollToBottomBtn()
        addGestureToTableView()
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        cleanUp()
    }
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
//        print( navigationItem.titleView?.subviews.first(where: {$0 is UIImageView}))
    }
    deinit {
        print("====ConversationVC Deinit")
    }

    
    //MARK: - Binding
    private func setupBinding() 
    {
        conversationViewModel.onCellVMLoad = { indexOfCellToScrollTo in
            Task { @MainActor in
                self.rootView.tableView.reloadData()
                guard let indexToScrollTo = indexOfCellToScrollTo else {return}
                self.rootView.tableView.scrollToRow(at: indexToScrollTo, at: .top, animated: false)
                self.updateMessageSeenStatusIfNeeded()
            }
        }
        
        conversationViewModel.$userMember
            .receive(on: DispatchQueue.main)
            .sink { [weak self] user in
                guard let self = self else {return}
                
                if self.customNavigationBar.navigationItemsContainer.nameLabel.text != user.name {
                    self.customNavigationBar.navigationItemsContainer.nameLabel.text = user.name
                    return
                }
                
                self.customNavigationBar.navigationItemsContainer.lastSeenLabel.text = user.isActive ?? false ?
                "Online" : "last seen \(user.lastSeen?.formatToYearMonthDayCustomString() ?? "")"
            }.store(in: &subscriptions)
        
        conversationViewModel.$messageChangedType
            .receive(on: DispatchQueue.main)
            .sink { [weak self] changeType in
                guard let self = self else {return}
            
                switch changeType {
                case .modified(let indexPath, let modifiedValue):
                    let animationType = getAnimationType(from: modifiedValue)
                    reloadCellRow(at: indexPath, with: animationType)
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
//        conversationViewModel.userObserver?.removeAllObservers()
        coordinatorDelegate = nil
        conversationViewModel = nil
        collectionViewDataSource = nil
        customNavigationBar = nil
    }
    
    private func configureTableView() {
        collectionViewDataSource = ConversationViewDataSource(conversationViewModel: conversationViewModel)
        rootView.tableView.dataSource = collectionViewDataSource
        rootView.tableView.delegate = self
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
        let memberName = conversationViewModel.userMember.name!
        var memberActiveStatus: String
        
        memberActiveStatus = conversationViewModel.userMember.isActive ?? false ? "online" : conversationViewModel.userMember.lastSeen!.formatToYearMonthDayCustomString()
        
        customNavigationBar = ConversationCustomNavigationBar(viewController: self)
        customNavigationBar.setupNavigationBarItems(with: imageData, memberName: memberName, memberActiveStatus: memberActiveStatus)
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
        self.conversationViewModel.createMessageBubble(messageText)
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
        if rootView.tableView.numberOfSections < conversationViewModel.cellMessageGroups.count {
            return true
        }
        return false
    }
}

//MARK: - Message seen status handler
extension ConversationViewController {
    private func updateMessageSeenStatusIfNeeded() {
        guard let visibleIndices = rootView.tableView.indexPathsForVisibleRows else {return}
        
        for indexPath in visibleIndices {
            guard let cell = rootView.tableView.cellForRow(at: indexPath) as? ConversationTableViewCell else {
                continue
            }
            if checkIfCellMessageIsCurrentlyVisible(indexPath: indexPath) {
                updateMessageSeenStatus(cell)
                Task { try await conversationViewModel.updateUnreadMessagesCount?() }
            }
        }
    }
    private func checkIfCellMessageIsCurrentlyVisible(indexPath: IndexPath) -> Bool {
        let cellMessage = conversationViewModel.cellMessageGroups[indexPath.section].cellViewModels[indexPath.row].cellMessage
        let authUserID = conversationViewModel.authenticatedUserID
        
        if !cellMessage.messageSeen && cellMessage.senderId != authUserID 
        {
            if let cell = rootView.tableView.cellForRow(at: indexPath)
            {
                let cellFrame = cell.frame
                let tableRect = rootView.tableView.bounds.offsetBy(dx: 0, dy: 65)
                let isCellFullyVisible = tableRect.contains(cellFrame)
                return isCellFullyVisible
            }
        }
        return false
    }
    private func updateMessageSeenStatus(_ cell: ConversationTableViewCell) {
        guard let chatID = conversationViewModel.conversation else {return}
        let messageId = cell.cellViewModel.cellMessage.id
        
        cell.cellViewModel.cellMessage = cell.cellViewModel.cellMessage.updateMessageSeenStatus()
        cell.cellViewModel.updateMessageSeenStatus(messageId, inChat: chatID.id)
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
    
    @objc func sendMessageBtnWasTapped() {
        let trimmedString = rootView.messageTextView.text.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmedString.isEmpty {
            rootView.messageTextView.text.removeAll()
 
            rootViewTextViewDelegate.textViewDidChange(rootView.messageTextView)
            handleMessageBubbleCreation(messageText: trimmedString)
            if rootView.inputBarHeader != nil { closeInputBarHeaderView() }
        }
    }

    @objc func pictureAddBtnWasTapped() {
        configurePhotoPicker()
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
        let editViewHeight = rootView.inputBarHeader?.bounds.height != nil ? rootView.inputBarHeader!.bounds.height : 0
        
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
        conversationViewModel.resetCurrentReplyMessage()
        animateInputBarHeaderViewDestruction()
    }
}

//MARK: - SCROLL VIEW DELEGATE
extension ConversationViewController {
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        updateMessageSeenStatusIfNeeded()
        if !shouldIgnoreScrollToBottomBtnUpdate {
            updateScrollToBottomBtnIfNeeded()
        }
    }
}


//MARK: - TABLE  DELEGATE
extension ConversationViewController: UITableViewDelegate
{
    func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        
        let label = DateHeaderLabel()
        let containerView = UIView()
        
        containerView.addSubview(label)
        
        let dateForSection = conversationViewModel.cellMessageGroups[section].date
        label.text = dateForSection.formatToYearMonthDayCustomString()
        label.centerXAnchor.constraint(equalTo: containerView.centerXAnchor).isActive = true
        label.centerXAnchor.constraint(equalTo: containerView.centerXAnchor).isActive = true
        label.topAnchor.constraint(equalTo: containerView.topAnchor,constant: 10).isActive = true
        label.bottomAnchor.constraint(equalTo: containerView.bottomAnchor,constant: -10).isActive = true
        
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
    
    //MARK: - Context menu configuration
    func tableView(_ tableView: UITableView, contextMenuConfigurationForRowAt indexPath: IndexPath, point: CGPoint) -> UIContextMenuConfiguration? {
        
        guard let cell = tableView.cellForRow(at: indexPath) as? ConversationTableViewCell else {return nil}
        let tapLocationInCell = cell.contentView.convert(point, from: tableView)
        
        if cell.messageBubbleContainer.frame.contains(tapLocationInCell) {
            let identifire = indexPath as NSCopying
            
            return UIContextMenuConfiguration(identifier: identifire, previewProvider: nil, actionProvider: { _ in
                
                let selectedCellMessageText = cell.messageLabel.text
                
                let replyAction = UIAction(title: "Reply", image: UIImage(systemName: "arrowshape.turn.up.left")) { action in
                    DispatchQueue.main.async {
                        let replyMessageId = cell.cellViewModel.cellMessage.id
                        let replyMessageSenderID = cell.cellViewModel.cellMessage.senderId
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
                let messageBelongsToAuthenticatedUser = cell.cellViewModel.cellMessage.senderId == self.conversationViewModel.authenticatedUserID
                let attributesForEditAction = messageBelongsToAuthenticatedUser ? [] : UIMenuElement.Attributes.hidden
                let attributesForDeleteAction = messageBelongsToAuthenticatedUser ? .destructive : UIMenuElement.Attributes.hidden

                let editAction = UIAction(title: "Edit", image: UIImage(systemName: "pencil.and.scribble"), attributes: attributesForEditAction) { action in
                    DispatchQueue.main.async {
                        self.rootView.messageTextView.text = cell.messageLabel.text
                        self.handleContextMenuSelectedAction(actionOption: .edit, selectedMessageText: selectedCellMessageText)
                        self.conversationViewModel.shouldEditMessage = { edditedMessage in
                            self.conversationViewModel.editMessageTextFromDB(edditedMessage, messageID: cell.cellViewModel.cellMessage.id)
                        }
                    }
                }
                let deleteAction = UIAction(title: "Delete", image: UIImage(systemName: "trash"), attributes: attributesForDeleteAction) { [weak self] action in
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                        self?.conversationViewModel.deleteMessageFromDB(messageID: cell.cellViewModel.cellMessage.id)
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

