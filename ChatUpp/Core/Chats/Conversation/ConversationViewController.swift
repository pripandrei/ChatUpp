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
        configureTableView()
        setTepGesture()
        addKeyboardNotificationObservers()
        setNavigationBarItems()
//        setupHeader()
    }
    
    func setupHeader() {
        let headerView = DateHeaderLabel()
        
        view.addSubview(headerView)
//        guard let navigationBarBottomConstraint = navigationController?.navigationBar.bottomAnchor else {return}
        
        NSLayoutConstraint.activate([
            headerView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            headerView.topAnchor.constraint(equalTo: view.topAnchor, constant: 100)
        ])
    }
    
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
                guard let indexToScrollTo = indexOfCellToScrollTo else {return}
                self.rootView.tableView.scrollToRow(at: indexToScrollTo, at: .top, animated: false)
                self.updateMessageSeenStatusIfNeeded()
            }
        }
        conversationViewModel.onNewMessageAdded = { [weak self] in
            Task { @MainActor in
                let indexPath = IndexPath(row: 0, section: 0)
                self?.handleContentMessageOffset(with: indexPath, scrollToBottom: false)
            }
        }
        conversationViewModel.messageWasModified = { indexPath in
            Task { @MainActor in
//                let indexPath = IndexPath(item: index, section: 0)
                guard let _ = self.rootView.tableView.cellForRow(at: indexPath) as? ConversationCollectionViewCell else { return }
                self.rootView.tableView.reloadRows(at: [indexPath], with: .none)
            }
        }
    }
    
    //MARK: - KEYBOARD NOTIFICATION OBSERVERS
    private func addKeyboardNotificationObservers() {
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow), name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide), name: UIResponder.keyboardWillHideNotification, object: nil)
    }
    @objc func keyboardWillShow(notification: NSNotification) {
        if let keyboardSize = (notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue {
            if rootView.containerView.frame.origin.y > 760 {
                handleCollectionViewOffSet(usingKeyboardSize: keyboardSize)
                isKeyboardHidden = false
            }
        }
    }
    @objc func keyboardWillHide(notification: NSNotification) {
        if let keyboardSize = (notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue {
            handleCollectionViewOffSet(usingKeyboardSize: keyboardSize)
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
    
    @objc func sendMessageBtnWasTapped() {
        let trimmedString = rootView.messageTextView.text.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmedString.isEmpty {
            rootView.messageTextView.text.removeAll()
            handleMessageBubbleCreation(messageText: trimmedString)
        }
    }
    
    //MARK: - MESSAGE BUBBLE CREATION
    private func handleMessageBubbleCreation(messageText: String = "") {
        let indexPath = IndexPath(row: 0, section: 0)

//        self.conversationViewModel.cellMessageGroups.insert(ConversationViewModel.ConversationMessageGroups(date: Date(), cellViewModels: [ConversationCellViewModel(cellMessage: Message(id: "ewrewr23423424", messageBody: "HEYY!", senderId: "", imagePath: "", timestamp: Date(), messageSeen: false, receivedBy: "", imageSize: nil))]), at: 0)
        
        self.conversationViewModel.createMessageBubble(messageText)
        Task { @MainActor in
            self.handleContentMessageOffset(with: indexPath, scrollToBottom: true)
        }
    }
    
    func tableView(_ tableView: UITableView, willDisplayFooterView view: UIView, forSection section: Int) {
        // Cast the view as UITableViewHeaderFooterView
//        guard let header = view as? UIView else { return }
        if section == 0 {
            // Initial appearance (optional)
            view.alpha = 0.0
            
            // Perform animation
            view.frame = view.frame.offsetBy(dx: view.frame.origin.x, dy: -20)
            UIView.animate(withDuration: 0.2) {
                view.frame = view.frame.offsetBy(dx: view.frame.origin.x, dy: 20)
                view.alpha = 1.0
            }
        }
    }
    //MARK: - MESSAGE BUBBLE LAYOUT
    private func handleContentMessageOffset(with indexPath: IndexPath, scrollToBottom: Bool)
    {
        // We disable insertion animation because we need to both animate
        // insertion of message and scroll to bottom at the same time.
        // If we dont do this, conflict occurs and results in glitches
        // Instead we will animate contentOffset
        
        let currentOffSet = self.rootView.tableView.contentOffset
        let contentIsScrolled = (currentOffSet.y > -390.0 && !isKeyboardHidden) || (currentOffSet.y > -55 && isKeyboardHidden)
        
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
        
        // Schedules scrolling execution in order for proper animation scrolling
        DispatchQueue.main.async {
            if scrollToBottom {
                self.rootView.tableView.scrollToRow(at: indexPath, at: .top, animated: true)
            }
        }
        // Offset collection view content by cells (message) height contentSize
        // without animation, so that cell appears under the textView
        
        guard let cell = self.rootView.tableView.cellForRow(at: indexPath) as? ConversationCollectionViewCell else { return }
        
        cell.frame = cell.frame.offsetBy(dx: cell.frame.origin.x, dy: -20)

        let offSet = CGPoint(x: currentOffSet.x, y: currentOffSet.y + cell.bounds.height)
        self.rootView.tableView.setContentOffset(offSet, animated: false)
    
        // Animate collection content back so that the cell (message) will go up
        UIView.animate(withDuration: 0.2) {
            cell.frame = cell.frame.offsetBy(dx: cell.frame.origin.x, dy: 20)
            self.rootView.tableView.setContentOffset(currentOffSet, animated: false)
//            self.rootView.tableView.layoutIfNeeded()
        }
    }
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        updateMessageSeenStatusIfNeeded()
    }
    
    //MARK: - MESSAGE SEEN STATUS HANDLER
    func updateMessageSeenStatusIfNeeded() {
        guard let visibleIndices = rootView.tableView.indexPathsForVisibleRows else {return}
        
        for indexPath in visibleIndices {
            guard let cell = rootView.tableView.cellForRow(at: indexPath) as? ConversationCollectionViewCell else {
                continue
            }
            if checkIfCellMessageIsCurrentlyVisible(indexPath: indexPath) {
                updateMessageSeenStatus(cell)
                Task { try await conversationViewModel.updateUnreadMessagesCount?() }
            }
        }
    }
    func checkIfCellMessageIsCurrentlyVisible(indexPath: IndexPath) -> Bool {
//        let cellMessage = conversationViewModel.cellViewModels[indexPath.section][indexPath.row].cellMessage
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
    func updateMessageSeenStatus(_ cell: ConversationCollectionViewCell) {
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
    private func handleCollectionViewOffSet(usingKeyboardSize keyboardSize: CGRect) {
        let keyboardHeight = rootView.containerView.frame.origin.y > 760 ? -keyboardSize.height : keyboardSize.height
        let customCollectionViewInset = keyboardHeight < 0 ? abs(keyboardHeight) : 0

        self.rootView.holderViewBottomConstraint.constant = keyboardHeight < 0 ? keyboardHeight : 0

        let currentOffSet = rootView.tableView.contentOffset
        let offSet = CGPoint(x: currentOffSet.x, y: keyboardHeight + currentOffSet.y)

        rootView.tableView.setContentOffset(offSet, animated: false)
        rootView.tableView.contentInset.top = customCollectionViewInset
        rootView.tableView.verticalScrollIndicatorInsets.top = customCollectionViewInset

        // This is ugly but i don't have other solution for canceling cell resizing when keyboard goes down
        // Exaplanation:
        // while trying to use only view.layoutIfNeeded(),
        // cells from top will resize while animate
        // Steps to reproduce:
        // 1.initiate keyboard
        // 2.scroll up
        // 3.dismiss keyboard
        // Result: cells from top will animate while resizing
        // So to ditch this, we use layoutSubviews and layoutIfNeeded

//        if keyboardHeight > 0 {
//            view.layoutSubviews()
//        } else {
            view.layoutIfNeeded()
//        }
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
            translatesAutoresizingMaskIntoConstraints = false // enables auto layout
            font = UIFont.boldSystemFont(ofSize: 14)
            text = "11/2/2003"
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
//        label.text = conversationViewModel.messageGroups[section].date.description
        label.text = conversationViewModel.cellMessageGroups[section].date.description
        label.centerXAnchor.constraint(equalTo: containerView.centerXAnchor).isActive = true
        label.centerXAnchor.constraint(equalTo: containerView.centerXAnchor).isActive = true

        containerView.transform = CGAffineTransform(scaleX: 1, y: -1)
        return containerView
    }

    func tableView(_ tableView: UITableView, shouldHighlightRowAt indexPath: IndexPath) -> Bool {
        false
    }
}
