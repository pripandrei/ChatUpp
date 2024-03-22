//
//  ConversationViewController.swift
//  ChatUpp
//
//  Created by Andrei Pripa on 10/3/23.

// IMPORTANT: TABLE VIEW FLOW LAYOUT IS INVERTED (BOTTOM => TOP),
// THEREFORE, SOME PROPERTIES AND ADJUSTMENTS WERE MADE AND SET AS BOTTOM => TOP.
// KEEP THIS IN MIND WHENEVER YOU WISH TO ADJUST COLLECTION VIEW FLOW

import UIKit
import Photos
import PhotosUI

final class ConversationViewController: UIViewController, UITableViewDelegate, UIScrollViewDelegate {

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
    
    deinit {
        print("====ConversationVC Deinit")
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        cleanUp()
    }
    
    private func cleanUp() {
        NotificationCenter.default.removeObserver(self)
        conversationViewModel.messageListener?.remove()
        coordinatorDelegate = nil
        conversationViewModel = nil
        collectionViewDataSource = nil
        customNavigationBar = nil
    }
    
    override func loadView() {
        view = rootView
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupBinding()
        addTargetToSendMessageBtn()
        addTargetToAddPictureBtn()
        configureCollectionView()
        setTepGesture()
        addKeyboardNotificationObservers()
        setNavigationBarItems()
    }

    private func configureCollectionView() {
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
                self.handleMessagesUpdateIfNeeded()
            }
        }
        
        conversationViewModel.onNewMessageAdded = { [weak self] in
            Task { @MainActor in
                let indexPath = IndexPath(row: 0, section: 0)
                self?.handleContentMessageOffset(with: indexPath, scrollToBottom: false)
            }
        }
        
        conversationViewModel.messageWasModified = { index in
            Task { @MainActor in
                let indexPath = IndexPath(item: index, section: 0)
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
                handleCollectionViewOffSet(usingKeyboardSize: keyboardSize, willShow: true)
                isKeyboardHidden = false
            }
        }
    }
    
    @objc func keyboardWillHide(notification: NSNotification) {
        if let keyboardSize = (notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue {
            handleCollectionViewOffSet(usingKeyboardSize: keyboardSize, willShow: false)
            isKeyboardHidden = true
        }
    }
    
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
    
    private func handleMessageBubbleCreation(messageText: String = "") {
        let indexPath = IndexPath(item: 0, section: 0)
        
        self.conversationViewModel.createMessageBubble(messageText)
        Task { @MainActor in
            self.handleContentMessageOffset(with: indexPath, scrollToBottom: true)
        }
    }
    
    private func handleContentMessageOffset(with indexPath: IndexPath, scrollToBottom: Bool)
    {
        // We disable insertion animation because we need to both animate
        // insertion of message and scroll to bottom at the same time.
        // If we dont do this, conflict occurs and results in glitches
        // Instead we will animate contentOffset
        
        let currentOffSet = self.rootView.tableView.contentOffset
        let contentIsScrolled = (currentOffSet.y > -390.0 && !isKeyboardHidden) || (currentOffSet.y > -55 && isKeyboardHidden)
        
        if !scrollToBottom && contentIsScrolled {
            self.rootView.tableView.insertRows(at: [indexPath], with: .none)
            return
        } else {
            UIView.performWithoutAnimation {
                self.rootView.tableView.insertRows(at: [indexPath], with: .none)
            }
        }
        
        // Schedules scrolling execution in order for proper animation scrolling
        DispatchQueue.main.async {
            self.rootView.tableView.scrollToRow(at: indexPath, at: .top, animated: true)
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
        }
    }
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        handleMessagesUpdateIfNeeded()
    }

    func handleMessagesUpdateIfNeeded() {
        guard let visibleIndices = rootView.tableView.indexPathsForVisibleRows else {return}
        
        for indexPath in visibleIndices {
            guard let cell = rootView.tableView.cellForRow(at: indexPath) as? ConversationCollectionViewCell else {
                continue
            }
            if checkIfCellMessageIsVisible(indexPath: indexPath) {
                updateMessageSeenStatus(cell)
                Task { try await conversationViewModel.updateUnreadMessagesCount?() }
            }
        }
    }
    
    func checkIfCellMessageIsVisible(indexPath: IndexPath) -> Bool {
        let cellMessage = conversationViewModel.cellViewModels[indexPath.item].cellMessage
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

extension UIImage {
    func getAspectRatio() -> CGSize {
        let (equalWidth, equalHeight) = (250,250)
        
        let preferredWidth: Double = 300
        let preferredHeight: Double = 350

        let aspectRatioForWidth = Double(self.size.width) / Double(self.size.height)
        let aspectRatioForHeight = Double(self.size.height) / Double(self.size.width)

        if self.size.width > self.size.height {
            let newHeight = preferredWidth / aspectRatioForWidth
            return CGSize(width: preferredWidth, height: newHeight)
        } else if self.size.height > self.size.width {
            let newWidth = preferredHeight / aspectRatioForHeight
            return CGSize(width: newWidth, height: preferredHeight)
        } else {
            return CGSize(width: equalWidth, height: equalHeight)
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
    
    private func handleCollectionViewOffSet(usingKeyboardSize keyboardSize: CGRect, willShow: Bool) {
        
        var content = self.rootView.tableView.contentOffset
//        content.y = willShow ? content.y + 300 : content.y - 300
        if willShow {
            content.y += 300
        } else {
            content.y -= 300
        }
        
        UIView.animate(withDuration: 3.0) {
            self.rootView.tableView.setContentOffset(content, animated: false)
//            self.view.layoutSubviews()
//            self.rootView.tableView.layoutIfNeeded()
        }
    }
    
//    private func handleCollectionViewOffSet(usingKeyboardSize keyboardSize: CGRect) {
//        let keyboardHeight = rootView.containerView.frame.origin.y > 760 ? -keyboardSize.height : keyboardSize.height
//        let customCollectionViewInset = keyboardHeight < 0 ? abs(keyboardHeight) : 0
//
//        self.rootView.holderViewBottomConstraint.constant = keyboardHeight < 0 ? keyboardHeight : 0
//
//        let currentOffSet = rootView.tableView.contentOffset
//        let offSet = CGPoint(x: currentOffSet.x, y: keyboardHeight + currentOffSet.y)
//
//        rootView.tableView.setContentOffset(offSet, animated: false)
//        rootView.tableView.contentInset.top = customCollectionViewInset
//        rootView.tableView.verticalScrollIndicatorInsets.top = customCollectionViewInset
//
//        // This is ugly but i don't have other solution for canceling cell resizing when keyboard goes down
//        // Exaplanation:
//        // while trying to use only view.layoutIfNeeded(),
//        // cells from top will resize while animate
//        // Steps to reproduce:
//        // 1.initiate keyboard
//        // 2.scroll up
//        // 3.dismiss keyboard
//        // Result: cells from top will animate while resizing
//        // So to ditch this, we use layoutSubviews and layoutIfNeeded
//
//        if keyboardHeight > 0 {
//            view.layoutSubviews()
//        } else {
//            view.layoutIfNeeded()
//        }
//    }
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
