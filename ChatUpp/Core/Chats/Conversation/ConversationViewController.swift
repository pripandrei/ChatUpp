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

final class ConversationViewController: UIViewController, UICollectionViewDelegate {
    
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
        NotificationCenter.default.removeObserver(self)
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
        conversationViewModel.onCellVMLoad = {
            DispatchQueue.main.async { [weak self] in
                self?.rootView.collectionView.reloadData()
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
            }
        }
    }
    
    @objc func keyboardWillHide(notification: NSNotification) {
        if let keyboardSize = (notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue {
            handleCollectionViewOffSet(usingKeyboardSize: keyboardSize)
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
            self.handleContentMessageOffset(with: indexPath)
        }
    }
    
    private func handleContentMessageOffset(with indexPath: IndexPath)
    {
        // We disable insertion animation because we need to both animate
        // insertion of message and scroll to bottom at the same time.
        // If we dont do this, conflict occurs and results in glitches
        // Instead we will animate contentOffset
        
        UIView.performWithoutAnimation {
            self.rootView.collectionView.insertItems(at: [indexPath])
        }
        
        // Schedules scrolling execution in order for proper animation scrolling
        DispatchQueue.main.async {
            self.rootView.collectionView.scrollToItem(at: indexPath, at: .top, animated: true)
        }
        
        // Offset collection view conntent by cells (message) height contentSize
        // without animation, so that cell appears under the textView
        guard let cell = rootView.collectionView.cellForItem(at: indexPath) as? ConversationCollectionViewCell else {return}
        
        let currentOffSet = rootView.collectionView.contentOffset
        let offSet = CGPoint(x: currentOffSet.x, y: currentOffSet.y + cell.bounds.height + 10)
        
        rootView.collectionView.setContentOffset(offSet, animated: false)
        
        // Animate collection content back so that the cell (message) will go up
        UIView.animate(withDuration: 0.3) {
            self.rootView.collectionView.setContentOffset(currentOffSet, animated: false)
        }
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
                
                self?.handleMessageBubbleCreation()
                
                self?.conversationViewModel.saveImage(data: data, size: image.size)
            }
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

//MARK: - COLLECTION VIEW LAYOUT

extension ConversationViewController: UICollectionViewDelegateFlowLayout {
    
    func collectionView(_ collectionView: UICollectionView,
                        layout collectionViewLayout: UICollectionViewLayout,
                        sizeForItemAt indexPath: IndexPath) -> CGSize
    {
        return CGSize(width: view.bounds.width, height: 0)
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
        
        // This is ugly but i don't have other solution for canceling cell resizing when keyboard goes down
        // Exaplanation:
        // while trying to use only view.layoutIfNeeded(),
        // cells from top will resize while animate
        // Steps:
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
