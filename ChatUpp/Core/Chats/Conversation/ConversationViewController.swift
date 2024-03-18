//
//  ConversationViewController.swift
//  ChatUpp
//
//  Created by Andrei Pripa on 10/3/23.

// IMPORTANT: COLLECTION VIEW FLOW LAYOUT IS INVERTED (BOTTOM => TOP),
// THEREFORE, SOME PROPERTIES AND ADJUSTMENTS WERE MADE AND SET AS BOTTOM => TOP.
// KEEP THIS IN MIND WHENEVER YOU WISH TO ADJUST COLLECTION VIEW FLOW

import UIKit
import Photos
import PhotosUI

final class ConversationViewController: UIViewController, UICollectionViewDelegate, UIScrollViewDelegate {
    

    weak var coordinatorDelegate :Coordinator?
    private var conversationViewModel :ConversationViewModel!
    private var collectionViewDataSource :ConversationViewDataSource!
    private var customNavigationBar :ConversationCustomNavigationBar!
    private var rootView = ConversationViewControllerUI()

    
//MARK: - LIFECYCLE
    
    convenience init(conversationViewModel: ConversationViewModel) {
        self.init()
        self.conversationViewModel = conversationViewModel
    }
    
    deinit {
        print("====ConversationVC Deinit")
    }
    
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
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
        rootView.collectionView.dataSource = collectionViewDataSource
        rootView.collectionView.delegate = self
    }
    
    //MARK: - Binding
    private func setupBinding() {
        conversationViewModel.onCellVMLoad = { indexOfCellToScrollTo in
            DispatchQueue.main.async { [weak self] in
                self?.rootView.collectionView.reloadData()
                guard let indexToScrollTo = indexOfCellToScrollTo else {return}
                self?.rootView.collectionView.scrollToItem(at: indexToScrollTo, at: .top, animated: false)
            }
        }
        
        conversationViewModel.onNewMessageAdded = { [weak self] in
            Task { @MainActor in
                let indexPath = IndexPath(row: 0, section: 0)
                self?.handleContentMessageOffset(with: indexPath, scrollToBottom: false)
//                self?.rootView.collectionView.insertItems(at: [indexPath])
            }
        }
        
        conversationViewModel.messageWasModified = { index in
            Task { @MainActor in
                let indexPath = IndexPath(item: index, section: 0)
                guard let cell = self.rootView.collectionView.cellForItem(at: indexPath) as? ConversationCollectionViewCell else { return }
               print( cell.cellViewModel.cellMessage.messageBody)
                self.rootView.collectionView.reloadItems(at: [indexPath])
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
    private var isKeyboardHidden: Bool = true
    
    private func handleContentMessageOffset(with indexPath: IndexPath, scrollToBottom: Bool)
    {
        // We disable insertion animation because we need to both animate
        // insertion of message and scroll to bottom at the same time.
        // If we dont do this, conflict occurs and results in glitches
        // Instead we will animate contentOffset
        
        let currentOffSet = self.rootView.collectionView.contentOffset
        let contentIsScrolled = (currentOffSet.y > -390.0 && !isKeyboardHidden) || (currentOffSet.y > -55 && isKeyboardHidden)
        
        if !scrollToBottom && contentIsScrolled {
            self.rootView.collectionView.insertItems(at: [indexPath])
            return
        } else {
            UIView.performWithoutAnimation {
                self.rootView.collectionView.insertItems(at: [indexPath])
            }
        }
        
        // Schedules scrolling execution in order for proper animation scrolling
        DispatchQueue.main.async {
            self.rootView.collectionView.scrollToItem(at: indexPath, at: .top, animated: true)
        }
        // Offset collection view content by cells (message) height contentSize
        // without animation, so that cell appears under the textView
        
        guard let cell = self.rootView.collectionView.cellForItem(at: indexPath) as? ConversationCollectionViewCell else { return }
        
        cell.frame = cell.frame.offsetBy(dx: cell.frame.origin.x, dy: -20)
        
        let offSet = CGPoint(x: currentOffSet.x, y: currentOffSet.y + cell.bounds.height)
        self.rootView.collectionView.setContentOffset(offSet, animated: false)
    
        // Animate collection content back so that the cell (message) will go up
        UIView.animate(withDuration: 0.2) {
            cell.frame = cell.frame.offsetBy(dx: cell.frame.origin.x, dy: 20)
            self.rootView.collectionView.setContentOffset(currentOffSet, animated: false)
        }
    }
    
//    func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
//        guard let conversationCell = cell as? ConversationCollectionViewCell else {return}
////        print(cell.cellViewModel.cellMessage.messageBody)
//        for cell in rootView.collectionView.visibleCells {
//            guard let conversationCell = cell as? ConversationCollectionViewCell else {return}
//            if conversationCell.cellViewModel.cellMessage.messageBody == "888" {
//                print("===Body",conversationCell.cellViewModel.cellMessage.messageBody)
//            }
//        }
//        if conversationCell.cellViewModel.cellMessage.messageBody == "888" {
//            print("Visible")
//        }
//    }
//    func scrollViewDidScroll(_ scrollView: UIScrollView) {
//        // Loop through visible cells
//        for cell in rootView.collectionView.visibleCells {
//            guard let conversationCell = cell as? ConversationCollectionViewCell else {return}
//            // Check if the cell is fully visible
//
//            if conversationCell.cellViewModel.cellMessage.messageBody == "888" {
//                print("Este!")
//                let frame = rootView.collectionView.frame.inset(by: UIEdgeInsets(top: 0, left: 0, bottom: rootView.containerView.bounds.height + 50, right: 0))
//
//                let uiview = UIView(frame: frame)
//                rootView.addSubview(uiview)
//                uiview.backgroundColor = .alizarin
//
//                if frame.contains(cell.frame) {
//                    // Do something with the cell that is fully visible
//                    // For example, you can access its indexPath like this:
//                    if let indexPath = rootView.collectionView.indexPath(for: cell) {
//                        print("Cell at indexPath \(indexPath) is fully visible")
//                    }
//                }
//            }
//        }
//    }
    
//    func scrollViewDidScroll(_ scrollView: UIScrollView) {
//        guard let containerViewFrame = rootView.containerView.superview?.convert(rootView.containerView.frame, to: rootView.collectionView) else {
//            return
//        }
//
//        let visibleAreaRect = rootView.collectionView.bounds.inset(by: UIEdgeInsets(top: containerViewFrame.height, left: 0, bottom: 0, right: 0))
//        guard let visibleLayoutAttributes = rootView.collectionView.collectionViewLayout.layoutAttributesForElements(in: visibleAreaRect) else {return }
//
//        for layoutAttributes in visibleLayoutAttributes {
//            guard
//                let cell = rootView.collectionView.cellForItem(at: layoutAttributes.indexPath) as? ConversationCollectionViewCell,
//                !cell.cellViewModel.cellMessage.messageSeen
//            else {
//                continue
//            }
//            print("====",cell.cellViewModel.cellMessage.messageBody)
//            if visibleAreaRect.intersects(layoutAttributes.frame) {
//                // Perform your actions here
//                print("Cell is visible above the container view")
//            }
//        }
//    }
//
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        for cell in rootView.collectionView.visibleCells {
            guard let conversationCell = cell as? ConversationCollectionViewCell else {return}
            
            if checkIfCellMessageIsVisible(cellMessage: conversationCell) {
                updateMessageSeenStatus(conversationCell)
            }
        }
    }
    
    func checkIfCellMessageIsVisible(cellMessage cell: ConversationCollectionViewCell) -> Bool {
        let cellMessage = cell.cellViewModel.cellMessage
        let authUserID = conversationViewModel.authenticatedUserID
        
        if !cellMessage.messageSeen && cellMessage.senderId != authUserID {
            if let indexPath = rootView.collectionView.indexPath(for: cell) {
                let layoutAttribute = rootView.collectionView.layoutAttributesForItem(at: indexPath)
                let cellFrame = layoutAttribute!.frame
                let collectionRect = rootView.collectionView.bounds.offsetBy(dx: 0, dy: 65)
                let isCellFullyVisable = collectionRect.contains(cellFrame)
                return isCellFullyVisable
            }
        }
        return false
    }
    
    func updateMessageSeenStatus(_ cell: ConversationCollectionViewCell) {
        guard let chatID = conversationViewModel.conversation else {return}
        let messageId = cell.cellViewModel.cellMessage.id
        
        cell.cellViewModel.cellMessage = cell.cellViewModel.cellMessage.updateMessageSeenStatus()
        Task {
            try await cell.cellViewModel.updateMessageSeenStatus(messageId, inChat: chatID.id)
        }
    }

    
//    func updateSeenStatus(conversationCell: ConversationCollectionViewCell) {
//        let authUserID = conversationViewModel.authenticatedUserID
//        let cellMessage = conversationCell.cellViewModel.cellMessage
//        if !cellMessage.messageSeen && cellMessage.senderId != authUserID {
//            guard let chatID = conversationViewModel.conversation else {return}
//            let messageID = cellMessage.id
//
//            Task {
//                try await conversationCell.cellViewModel.updateMessageSeenStatus(messageID, inChat: chatID.id)
//            }
//        }
//    }
//    func isCellVisible(cell: UICollectionViewCell, collectionView: UICollectionView, containerView: UIView) -> Bool {
//        let cellRect = collectionView.convert(cell.frame, to: collectionView.superview)
//        let visibleRect = collectionView.convert(collectionView.bounds, to: collectionView.superview)
//        let containerRect = containerView.frame
//
//        // Adjust visibleRect to exclude the area covered by the bottom container view
//        let adjustedVisibleRect = CGRect(x: visibleRect.origin.x,
//                                         y: visibleRect.origin.y + navigationController!.navigationBar.frame.height + 40,
//                                         width: visibleRect.width,
//                                         height: visibleRect.height - containerRect.height - navigationController!.navigationBar.frame.height)
//
//        return cellRect.intersects(adjustedVisibleRect)
//    }
//
//    func scrollViewDidScroll(_ scrollView: UIScrollView) {
//        if let visibleCells = rootView.collectionView.visibleCells as? [ConversationCollectionViewCell] {
//            for cell in visibleCells {
//                if cell.cellViewModel.cellMessage.messageBody == "9876" {
//                    if isCellVisible(cell: cell, collectionView: rootView.collectionView, containerView: rootView.containerView) {
//                        print("It is visible")
//                        // The cell is visible above the bottom container view
//                        // Add your logic here
//                    }
//                }
//            }
//        }
//    }
    
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
        rootView.collectionView.addGestureRecognizer(tap)
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
        
        let currentOffSet = rootView.collectionView.contentOffset
        let offSet = CGPoint(x: currentOffSet.x, y: keyboardHeight + currentOffSet.y)
        
        rootView.collectionView.setContentOffset(offSet, animated: false)
        rootView.collectionView.contentInset.top = customCollectionViewInset
        rootView.collectionView.verticalScrollIndicatorInsets.top = customCollectionViewInset
        
        print("CurrentContentOffSet: ", currentOffSet)
        print("Updated ContentOffSet: ", rootView.collectionView.contentOffset)
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

        if keyboardHeight > 0 {
            view.layoutSubviews()
        } else {
            view.layoutIfNeeded()
        }
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
