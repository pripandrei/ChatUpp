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

final class ConversationViewController: UIViewController, UIScrollViewDelegate {

    weak var coordinatorDelegate :Coordinator?
    private var conversationViewModel :ConversationViewModel!
    private var collectionViewDataSource :ConversationViewDataSource!
    private var customNavigationBar :ConversationCustomNavigationBar!
    private var rootView = ConversationViewControllerUI()
    
    private var isKeyboardHidden: Bool = true
    private var isNewSectionAdded: Bool = false
    private var isContextMenuPresented: Bool = false {
        didSet {
            print("isContextMenuPresented changed")
        }
    }
    
    //MARK: - LIFECYCLE
    convenience init(conversationViewModel: ConversationViewModel) {
        self.init()
        self.conversationViewModel = conversationViewModel
    }
    
    override func loadView() {
        view = rootView
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        setupBinding()
        addTargetToSendMessageBtn()
        addTargetToAddPictureBtn()
        addTargetToEditMessageBtn()
        configureTableView()
        setTepGesture()
        addKeyboardNotificationObservers()
        setNavigationBarItems()
//        setupHeader()
    }
    
//    func setupHeader() {
//        let headerView = DateHeaderLabel()
//
//        view.addSubview(headerView)
//
//        NSLayoutConstraint.activate([
//            headerView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
//            headerView.topAnchor.constraint(equalTo: view.topAnchor, constant: 100)
//        ])
//    }
//
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        cleanUp()
    }
    
    deinit {
        print("====ConversationVC Deinit")
    }
    
    //MARK: - CLEANUP
    
    private func cleanUp() {
        NotificationCenter.default.removeObserver(self)
        conversationViewModel.messageListener?.remove()
        coordinatorDelegate = nil
        conversationViewModel = nil
        collectionViewDataSource = nil
        customNavigationBar = nil
    }
    
    //MARK: - TABLE VIEW CONFITURATION

    private func configureTableView() {
        collectionViewDataSource = ConversationViewDataSource(conversationViewModel: conversationViewModel)
        rootView.tableView.dataSource = collectionViewDataSource
        rootView.tableView.delegate = self
    }
    
    //MARK: - Binding
    private func setupBinding() {
        conversationViewModel.onCellVMLoad = { indexOfCellToScrollTo in
            Task { @MainActor in
                self.rootView.tableView.reloadData()
                print(self.rootView.tableView.contentOffset.y)
                guard let indexToScrollTo = indexOfCellToScrollTo else {return}
                self.rootView.tableView.scrollToRow(at: indexToScrollTo, at: .top, animated: false)
                self.updateMessageSeenStatusIfNeeded()
            }
        }
        conversationViewModel.onNewMessageAdded = { [weak self] in
            Task { @MainActor in
                let indexPath = IndexPath(row: 0, section: 0)
                self?.handleTableViewCellInsertion(with: indexPath, scrollToBottom: false)
            }
        }
        conversationViewModel.messageWasModified = { indexPath, modificationType in
            Task { @MainActor in
                guard let _ = self.rootView.tableView.cellForRow(at: indexPath) as? ConversationTableViewCell else { return }
                
                switch modificationType {
                case "text": self.rootView.tableView.reloadRows(at: [indexPath], with: .left)
                case "seenStatus": self.rootView.tableView.reloadRows(at: [indexPath], with: .none)
                default: break
                }
            }
        }
        conversationViewModel.onMessageRemoved = { [weak self] indexPath in
            Task { @MainActor in
                UIView.transition(with: self!.rootView.tableView, duration: 0.5, options: .transitionCrossDissolve) {
                    self?.rootView.tableView.reloadData()
                }
//                self?.rootView.tableView.reloadSections(IndexSet(integer: indexPath.section), with: .automatic)
            }
        }
    }
    
    //MARK: - KEYBOARD NOTIFICATION OBSERVERS
    private func addKeyboardNotificationObservers() {
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow), name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide), name: UIResponder.keyboardWillHideNotification, object: nil)
    }
    
    
    private func addEditedViewHeightToTableViewContent() {
        guard let heightValueToAdd = rootView.editeView?.bounds.height else {return}
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15, execute: {
            
            if self.isContextMenuPresented {
                self.rootView.tableView.contentInset.top += heightValueToAdd
                self.rootView.tableView.verticalScrollIndicatorInsets.top += heightValueToAdd
            }
            self.rootView.tableView.setContentOffset(CGPoint(x: self.rootView.tableView.contentOffset.x,
                                                             y: self.rootView.tableView.contentOffset.y - heightValueToAdd), animated: true)
            self.isContextMenuPresented = false
        })
    }

    @objc func keyboardWillShow(notification: NSNotification) {
        if let keyboardSize = (notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue {
            if rootView.containerView.frame.origin.y > 580 {
                if isContextMenuPresented {
                    let keyboardHeight = -336.0
                    self.rootView.holderViewBottomConstraint.constant = keyboardHeight
//                    addEditedViewHeightToTableViewContent()
//                    handleTableViewOffSet(usingKeyboardSize: CGRect(origin: CGPoint(), size: CGSize()))
//                    self.isContextMenuPresented = false
                    //                    if self.rootView.editeView != nil {addEditedViewHeightToTableViewContent()}
                    view.layoutIfNeeded()
                } else {
                    handleTableViewOffSet(usingKeyboardSize: keyboardSize)
                }
                isKeyboardHidden = false
            }
            //            addEditedViewHeightToTableViewContent()
        }
    }
    
    @objc func keyboardWillHide(notification: NSNotification) {
//        print("hide keyboard")
        if let keyboardSize = (notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue {
            if !isContextMenuPresented {
//                addEditedViewHeightToTableViewContent()
                handleTableViewOffSet(usingKeyboardSize: keyboardSize)
            } else if isContextMenuPresented {
                self.rootView.holderViewBottomConstraint.constant = 0
                view.layoutIfNeeded()
            }
            isKeyboardHidden = true
        }
    }
    
    //MARK: - SEND MESSAGE BUTTON CONFIGURATION
    private func addTargetToSendMessageBtn() {
        rootView.sendMessageButton.addTarget(self, action: #selector(sendMessageBtnWasTapped), for: .touchUpInside)
    }
    private func addTargetToAddPictureBtn() {
        rootView.pictureAddButton.addTarget(self, action: #selector(pictureAddBtnWasTapped), for: .touchUpInside)
    }
    private func addTargetToEditMessageBtn() {
        rootView.editMessageButton.addTarget(self, action: #selector(editMessageBtnWasTapped), for: .touchUpInside)
    }
    
    @objc func editMessageBtnWasTapped() {
        guard let editedMessage = rootView.messageTextView.text else {return}
        conversationViewModel.shouldEditMessage?(editedMessage)
        rootView.editMessageButton.isHidden = true
        rootView.messageTextView.text.removeAll()
        rootView.textViewDidChange(rootView.messageTextView)
        rootView.messageTextView.resignFirstResponder()
    }
    
    @objc func sendMessageBtnWasTapped() {
        let trimmedString = rootView.messageTextView.text.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmedString.isEmpty {
            rootView.messageTextView.text.removeAll()
 
            rootView.textViewDidChange(rootView.messageTextView)
            handleMessageBubbleCreation(messageText: trimmedString)
        }
    }
    
    //MARK: - MESSAGE BUBBLE CREATION
    private func handleMessageBubbleCreation(messageText: String = "") {
        let indexPath = IndexPath(row: 0, section: 0)
        
//        self.conversationViewModel.cellMessageGroups.insert(ConversationViewModel.ConversationMessageGroups(date: Date(), cellViewModels: [ConversationCellViewModel(cellMessage: Message(id: messageText, messageBody: messageText, senderId: "", imagePath: "", timestamp: Date(), messageSeen: false, receivedBy: "", imageSize: nil))]), at: 0)
        
        self.conversationViewModel.createMessageBubble(messageText)
        Task { @MainActor in
            self.handleTableViewCellInsertion(with: indexPath, scrollToBottom: true)
        }
    }
    
    //MARK: - HANDLE CELL MESSAGE INSERTION
    private func handleTableViewCellInsertion(with indexPath: IndexPath, scrollToBottom: Bool)
    {
        isNewSectionAdded = checkIfNewSectionWasAdded()
        handleRowAndSectionInsertion(with: indexPath, scrollToBottom: scrollToBottom)

        // Schedules scrolling execution in order for proper animation scrolling
        DispatchQueue.main.async {
            if scrollToBottom {self.rootView.tableView.scrollToRow(at: indexPath, at: .top, animated: true)}
        }
        setCellOffset(cellIndexPath: indexPath)
        isNewSectionAdded = false
    }
    
    func handleSectionAnimation() {
        guard let footerView = rootView.tableView.footerView(forSection: 0) else {return}
        
        footerView.alpha = 0.0
        footerView.frame = footerView.frame.offsetBy(dx: footerView.frame.origin.x, dy: -30)
        UIView.animate(withDuration: 0.3) {
            footerView.frame = footerView.frame.offsetBy(dx: footerView.frame.origin.x, dy: 30)
            footerView.alpha = 1.0
        }
    }
    
    func checkIfNewSectionWasAdded() -> Bool {
        if rootView.tableView.numberOfSections < conversationViewModel.cellMessageGroups.count {
            return true
        }
        return false
    }
    
    func handleRowAndSectionInsertion(with indexPath: IndexPath, scrollToBottom: Bool) {
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
//                        self.rootView.tableView.insertRows(at: [indexPath], with: .none)
                    self.rootView.tableView.reloadData()
                }
            }
        }
    }
    
    func setCellOffset(cellIndexPath indexPath: IndexPath) {
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
    
    //MARK: - MESSAGE SEEN STATUS HANDLER
    func updateMessageSeenStatusIfNeeded() {
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
    func checkIfCellMessageIsCurrentlyVisible(indexPath: IndexPath) -> Bool {
        let cellMessage = conversationViewModel.cellMessageGroups[indexPath.section].cellViewModels[indexPath.row].cellMessage
        let authUserID = conversationViewModel.authenticatedUserID
        
        if !cellMessage.messageSeen && cellMessage.senderId != authUserID {
            if let cell = rootView.tableView.cellForRow(at: indexPath) {
                let cellFrame = cell.frame
                let tableRect = rootView.tableView.bounds.offsetBy(dx: 0, dy: 65)
                let isCellFullyVisible = tableRect.contains(cellFrame)
                return isCellFullyVisible
            }
        }
        return false
    }
    func updateMessageSeenStatus(_ cell: ConversationTableViewCell) {
        guard let chatID = conversationViewModel.conversation else {return}
        let messageId = cell.cellViewModel.cellMessage.id
        
        cell.cellViewModel.cellMessage = cell.cellViewModel.cellMessage.updateMessageSeenStatus()
        cell.cellViewModel.updateMessageSeenStatus(messageId, inChat: chatID.id)
    }
    
    //MARK: - PHOTO PICKER
    private func configurePhotoPicker() {
        var configuration = PHPickerConfiguration()
        configuration.selectionLimit = 1
        configuration.filter = .images
        let pickerVC = PHPickerViewController(configuration: configuration)
        pickerVC.delegate = self
        present(pickerVC, animated: true)
    }

    @objc func pictureAddBtnWasTapped() {
        configurePhotoPicker()
    }
}

//MARK: - PHOTO PICKER CONTROLLER DELEGATE
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
    
    private func setTepGesture() {
        let tap = UITapGestureRecognizer(target: self, action: #selector(resignKeyboard))
        rootView.tableView.addGestureRecognizer(tap)
    }
    
    @objc func resignKeyboard() {
        if rootView.messageTextView.isFirstResponder {
            rootView.messageTextView.resignFirstResponder()
        }
    }
}

//MARK: - COLLETION VIEW OFFSET HANDLER
extension ConversationViewController {
    private func handleTableViewOffSet(usingKeyboardSize keyboardSize: CGRect) {
        
        // if number of lines inside textView is bigger than 1, it will expand
        // and origin.y of containerView that holds textView will change
        // so we check if maximum allowed number of line is reached (containerView origin.y will be 584)
        let containerViewYPointWhenMaximumLineNumberReached = 584.0 - 4.0
        let keyboardHeight = rootView.containerView.frame.origin.y > containerViewYPointWhenMaximumLineNumberReached ? -keyboardSize.height : keyboardSize.height
        
        let editViewHeight = rootView.editeView?.bounds.height != nil ? rootView.editeView!.bounds.height : 0
        
        // if there is more than one line, textView height should be added to table view inset
        let textViewHeight = (rootView.messageTextView.font!.lineHeight * CGFloat(rootView.messageTextViewNumberOfLines)) - CGFloat(rootView.messageTextView.font!.lineHeight)
        let customTableViewInset = keyboardHeight < 0 ? abs(keyboardHeight) + textViewHeight + editViewHeight : 0 + textViewHeight + editViewHeight
//        customTableViewInset += editViewHeight
        
        self.rootView.holderViewBottomConstraint.constant = keyboardHeight < 0 ? keyboardHeight : 0
        
        let currentOffSet = rootView.tableView.contentOffset
        let offSet = CGPoint(x: currentOffSet.x, y: keyboardHeight + currentOffSet.y)

        rootView.tableView.contentInset.top = customTableViewInset
        rootView.tableView.setContentOffset(offSet, animated: false)
        rootView.tableView.verticalScrollIndicatorInsets.top = customTableViewInset
        rootView.tableViewInitialContentOffset = offSet
//        addEditedViewHeightToTableViewContent()
        view.layoutSubviews()
//        view.layoutIfNeeded()
    }
}

//MARK: - SETUP NAVIGATION BAR ITEMS

extension ConversationViewController
{
    private func setNavigationBarItems() {
        guard let imageData = conversationViewModel.memberProfileImage else {return}
        let memberName = conversationViewModel.memberName
        
        customNavigationBar = ConversationCustomNavigationBar(viewController: self)
        customNavigationBar.setupNavigationBarItems(with: imageData, memberName: memberName)
    }
}

//MARK: - TABLE VIEW DELEGATE
extension ConversationViewController: UITableViewDelegate
{
    class DateHeaderLabel: UILabel {
        override init(frame: CGRect) {
            super.init(frame: frame)
            
            backgroundColor = #colorLiteral(red: 0.176230222, green: 0.3105865121, blue: 0.4180542529, alpha: 1)
            textColor = .white
            textAlignment = .center
            translatesAutoresizingMaskIntoConstraints = false
            font = UIFont.boldSystemFont(ofSize: 14)
        }

        required init?(coder aDecoder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
        
        override var intrinsicContentSize: CGSize {
            let originalContentSize = super.intrinsicContentSize
            let height = originalContentSize.height + 12
            layer.cornerRadius = height / 2
            layer.masksToBounds = true
            return CGSize(width: originalContentSize.width + 20, height: height)
        }
    }
    
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

    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        updateMessageSeenStatusIfNeeded()
    }
    
    // MARK: - CONTEXT MENU CONFIGURATION
    func tableView(_ tableView: UITableView, contextMenuConfigurationForRowAt indexPath: IndexPath, point: CGPoint) -> UIContextMenuConfiguration? {
        
        guard let cell = tableView.cellForRow(at: indexPath) as? ConversationTableViewCell else {return nil}
        let tapLocationInCell = cell.contentView.convert(point, from: tableView)
        
        if cell.messageContainer.frame.contains(tapLocationInCell) {
            let identifire = indexPath as NSCopying
            return UIContextMenuConfiguration(identifier: identifire, previewProvider: nil, actionProvider: { _ in
                let copyAction = UIAction(title: "Copy", image: UIImage(systemName: "doc.on.doc")) { action in
                    let pastBoard = UIPasteboard.general
                    pastBoard.string = cell.messageContainer.text
                }
                let editAction = UIAction(title: "Edit", image: UIImage(systemName: "pencil.and.scribble")) { action in
                    DispatchQueue.main.async {
                        self.rootView.editMessageButton.isHidden = false
                        if self.rootView.editeView == nil {
                            self.rootView.activateEditView()                            
                        }
                        self.rootView.messageTextView.becomeFirstResponder()
                        self.rootView.messageTextView.text = cell.messageContainer.text
                        self.rootView.textViewDidChange(self.rootView.messageTextView)
//                        self.addEditedViewHeightToTableViewContent()
                        
                        self.conversationViewModel.shouldEditMessage = { edditedMessage in
                            self.conversationViewModel.editMessageTextFromDB(edditedMessage, messageID: cell.cellViewModel.cellMessage.id)
                        }
                    }
                }
                let deleteAction = UIAction(title: "Delete", image: UIImage(systemName: "trash"), attributes: .destructive) { [weak self] action in
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                        self?.conversationViewModel.deleteMessageFromDB(messageID: cell.cellViewModel.cellMessage.id)
                    }
                }
                return UIMenu(title: "", children: [editAction, copyAction, deleteAction])
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
        if rootView.holderViewBottomConstraint.constant != 0.0 {
            isContextMenuPresented = true
        }
    }
    
    private func makeConversationMessagePreview(for configuration: UIContextMenuConfiguration) -> UITargetedPreview? {
        guard let indexPath = configuration.identifier as? IndexPath,
              let cell = rootView.tableView.cellForRow(at: indexPath) as? ConversationTableViewCell else {return nil}
        
        let parameter = UIPreviewParameters()
        parameter.backgroundColor = .clear
        
        let preview = UITargetedPreview(view: cell.messageContainer, parameters: parameter)
        return preview
    }
}
