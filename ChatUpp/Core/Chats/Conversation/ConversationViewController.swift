//
//  ConversationViewController.swift
//  ChatUpp
//
//  Created by Andrei Pripa on 10/3/23.

// IMPORTANT: COLLECTION VIEW FLOW LAYOUT IS INVERTED (BOTTOM => TOP),
// THEREFORE, SOME PROPERTIES AND ADJUSTMENTS WERE MADE AND SET AS BOTTOM => TOP.
// KEEP THIS IN MIND WHENEVER YOU WISH TO ADJUST COLLECTION VIEW FLOW

import UIKit

final class ConversationViewController: UIViewController, UICollectionViewDelegate {
    
    weak var coordinatorDelegate: Coordinator?
    private var conversationViewModel: ConversationViewModel!
    private var collectionViewDataSource: ConversationViewDataSource!
    lazy private var conversationViewControllerUI = ConversationViewControllerUI(viewController: self)
    private var customNavigationBar: ConversationCustomNavigationBar!

    
//MARK: - LIFECYCLE
    
    convenience init(conversationViewModel: ConversationViewModel) {
        self.init()
        self.conversationViewModel = conversationViewModel
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupBinding()
        addTargetToSendMessageBtn()
        conversationViewControllerUI.setupLayout(for: view)
        configureCollectionView()
        setTepGesture()
        addKeyboardNotificationObservers()
        setNavigationBarItems2()
    }
    
    private func configureCollectionView() {
        collectionViewDataSource = ConversationViewDataSource(conversationViewModel: conversationViewModel)
        conversationViewControllerUI.collectionView.dataSource = collectionViewDataSource
        conversationViewControllerUI.collectionView.delegate = self
    }
    
    //MARK: - Binding
    
    private func setupBinding() {
        conversationViewModel.messages.bind { [weak self] messages in
            if !messages.isEmpty {
                DispatchQueue.main.async {
                    self?.conversationViewControllerUI.collectionView.reloadData()
                }
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
            
            if conversationViewControllerUI.holderView.frame.origin.y > 760 {
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
        conversationViewControllerUI.sendMessageButton.addTarget(self, action: #selector(sendMessageBtnWasTapped), for: .touchUpInside)
    }
    
    @objc func sendMessageBtnWasTapped() {
        let trimmedString = conversationViewControllerUI.messageTextView.text.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmedString.isEmpty {
            conversationViewControllerUI.messageTextView.text.removeAll()
            
            let indexPath = IndexPath(item: 0, section: 0)
            conversationViewModel.addNewCreatedMessage(trimmedString)
            handleContentMessageOffset(with: indexPath)
        }
    }

    private func handleContentMessageOffset(with indexPath: IndexPath)
    {
        // We disable insertion animation because we need to both animate
        // insertion of message and scroll to bottom at the same time.
        // If we dont do this, conflict occurs and results in glitches
        // Instead we will animate contentOffset
        UIView.performWithoutAnimation {
            self.conversationViewControllerUI.collectionView.insertItems(at: [indexPath])
        }
        
        // Schedules scrolling execution in order for proper animation scrolling
        DispatchQueue.main.async { self.conversationViewControllerUI.collectionView.scrollToItem(at: indexPath, at: .top, animated: true) }
        
        // Offset collection view conntent by cells (message) height contentSize
        // without animation, so that cell appears under the textView
        guard let cell = conversationViewControllerUI.collectionView.cellForItem(at: indexPath) as? ConversationCollectionViewCell else {return}
        
        let currentOffSet = conversationViewControllerUI.collectionView.contentOffset
        let offSet = CGPoint(x: currentOffSet.x, y: currentOffSet.y + cell.messageContainer.contentSize.height + 10)
        conversationViewControllerUI.collectionView.setContentOffset(offSet, animated: false)
        
        // Animate collection content back so that cell (message) will go up
        UIView.animate(withDuration: 0.3) {
            self.conversationViewControllerUI.collectionView.setContentOffset(offSet, animated: false)
        }
    }
}

//MARK: - GESTURES

extension ConversationViewController {
    
    private func setTepGesture() {
        let tap = UITapGestureRecognizer(target: self, action: #selector(resignKeyboard))
        conversationViewControllerUI.collectionView.addGestureRecognizer(tap)
    }
    
    @objc func resignKeyboard() {
        if conversationViewControllerUI.messageTextView.isFirstResponder {
            conversationViewControllerUI.messageTextView.resignFirstResponder()
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
        
        let keyboardHeight = conversationViewControllerUI.holderView.frame.origin.y > 760 ? -keyboardSize.height : keyboardSize.height
        let customCollectionViewInset = keyboardHeight < 0 ? abs(keyboardHeight) : 0
        

        self.conversationViewControllerUI.holderViewBottomConstraint.constant = keyboardHeight < 0 ? keyboardHeight : 0
        
        let currentOffSet = conversationViewControllerUI.collectionView.contentOffset
        let offSet = CGPoint(x: currentOffSet.x, y: keyboardHeight + currentOffSet.y)
        
        conversationViewControllerUI.collectionView.setContentOffset(offSet, animated: false)
        conversationViewControllerUI.collectionView.contentInset.top = customCollectionViewInset
        conversationViewControllerUI.collectionView.verticalScrollIndicatorInsets.top = customCollectionViewInset
        
        // This is ugly but i don't have other solution for canceling cell resizing when keyboard goes down
        // Exaplanation:
        // while trying to use only view.layoutIfNeeded(),
        // cells from top will resize while animate
        // Steps:
        // 1.initiate keyboard
        // 2.scroll up
        // 3.dismiss keyboard
        // Result: cells from top will animate while resizing

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
//    private func setNavigationBarItems2() {
//        guard let imageData = conversationViewModel.imageData else {return}
//        let memberName = conversationViewModel.memberName
//
//        customNavigationBar = ConversationCustomNavigationBar(viewController: self)
//        customNavigationBar.setupNavigationBarItems(with: imageData, memberName: memberName, using: view)
//    }
    private func setNavigationBarItems2() {
        guard let imageData = conversationViewModel.imageData else {return}
        let memberName = conversationViewModel.memberName

//        customNavigationBar = ConversationCustomNavigationBar(viewController: self)
        conversationViewControllerUI.setNavigationBarItems(with: imageData, memberName: memberName)
    }
}
