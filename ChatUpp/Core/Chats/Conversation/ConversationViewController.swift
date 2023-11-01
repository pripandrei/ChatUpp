//
//  ConversationViewController.swift
//  ChatUpp
//
//  Created by Andrei Pripa on 10/3/23.

// IMPORTANT: COLLECTION VIEW FLOW LAYOUT IS INVERTED (BOTTOM => TOP),
// THEREFORE, SOME PROPERTIES AND ADJUSTMENTS ARE SET AS BOTTOM => TOP.
// KEEP THIS IN MIND WHENEVER YOU WISH TO ADJUST COLLECTION VIEW FLOW

import UIKit

//MARK: - INVERTED COLLECTION FLOW LAYOUT

final class InvertedCollectionViewFlowLayout: UICollectionViewFlowLayout {
    
    override func layoutAttributesForItem(at indexPath: IndexPath) -> UICollectionViewLayoutAttributes? {
        let attributes = super.layoutAttributesForItem(at: indexPath)
        attributes?.transform = CGAffineTransform(scaleX: 1, y: -1)
        return attributes
    }
    
    override func layoutAttributesForElements(in rect: CGRect) -> [UICollectionViewLayoutAttributes]? {
        let attributesList = super.layoutAttributesForElements(in: rect)
        if let list = attributesList {
            for attribute in list {
                attribute.transform = CGAffineTransform(scaleX: 1, y: -1)
            }
        }
        return attributesList
    }
}

final class ConversationViewController: UIViewController {
    
    weak var coordinatorDelegate: Coordinator?
    private var conversationViewModel: ConversationViewModel!
    private var collectionViewDataSource: ConversationViewDataSource!
    
    private let holderView = UIView()
    private let messageTextView = UITextView()
    private let sendMessageButton = UIButton()
    
    private var holderViewBottomConstraint: NSLayoutConstraint!
    
    private lazy var collectionView: UICollectionView = {
        let collectionViewFlowLayout = InvertedCollectionViewFlowLayout()
        collectionViewFlowLayout.scrollDirection = .vertical
        collectionViewFlowLayout.estimatedItemSize = InvertedCollectionViewFlowLayout.automaticSize
        
        let collectionVC = UICollectionView(frame: CGRect.zero, collectionViewLayout: collectionViewFlowLayout)
        collectionVC.register(ConversationCollectionViewCell.self, forCellWithReuseIdentifier: CellIdentifire.conversationMessageCell)
        collectionVC.delegate = self
        
        collectionViewDataSource = ConversationViewDataSource(conversationViewModel: conversationViewModel)
        collectionViewDataSource.collectionView = collectionVC
        collectionVC.dataSource = collectionViewDataSource
        
        return collectionVC
    }()
    
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
        view.backgroundColor = .white
        setupCoollectionView()
        setupHolderView()
        setupMessageTextView()
        setupSendMessageBtn()
        setTepGesture()
        addKeyboardNotificationObservers()
        setNavigationBarItems()
        setupBinding()
    }
    
//MARK: - KEYBOARD NOTIFICATION OBSERVERS
    
    private func addKeyboardNotificationObservers() {
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow), name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide), name: UIResponder.keyboardWillHideNotification, object: nil)
    }
     
    @objc func keyboardWillShow(notification: NSNotification) {
        if let keyboardSize = (notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue {
            
            if holderView.frame.origin.y > 760 {
                handleCollectionViewOffSet(usingKeyboardSize: keyboardSize)
            }
        }
    }
    
    @objc func keyboardWillHide(notification: NSNotification) {
        if let keyboardSize = (notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue {
            handleCollectionViewOffSet(usingKeyboardSize: keyboardSize)
        }
    }
    
//MARK: - UI SETUP

    private func setupHolderView() {
        view.addSubview(holderView)
        
        holderView.backgroundColor = .systemIndigo
        setHolderViewConstraints()
    }
    
    private func setHolderViewConstraints() {
        holderView.translatesAutoresizingMaskIntoConstraints = false
        holderView.bounds.size.height = 80
        
        self.holderViewBottomConstraint = holderView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        self.holderViewBottomConstraint.isActive = true
        
        NSLayoutConstraint.activate([
            holderView.heightAnchor.constraint(equalToConstant: 80),
            holderView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            holderView.leadingAnchor.constraint(equalTo: view.leadingAnchor)
        ])
    }
    
    private func setupMessageTextView() {
        holderView.addSubview(messageTextView)
        
        let height = holderView.bounds.height * 0.4
        messageTextView.delegate = self
        messageTextView.backgroundColor = .systemBlue
        messageTextView.layer.cornerRadius = 15
        messageTextView.font = UIFont(name: "HelveticaNeue", size: 17)
        messageTextView.textContainerInset = UIEdgeInsets(top: height / 6, left: 5, bottom: height / 6, right: 0)
        messageTextView.textColor = .white

        setMessageTextViewConstraints()
    }
    
    private func setMessageTextViewConstraints() {
        messageTextView.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            messageTextView.heightAnchor.constraint(equalToConstant: holderView.bounds.height * 0.4),
            messageTextView.topAnchor.constraint(equalTo: holderView.topAnchor, constant: 10),
            messageTextView.trailingAnchor.constraint(equalTo: holderView.trailingAnchor, constant: -55),
            messageTextView.leadingAnchor.constraint(equalTo: holderView.leadingAnchor, constant: 35)
        ])
    }
    
    private func setupSendMessageBtn() {
        holderView.addSubview(sendMessageButton)
        // size is used only for radius calculation
        sendMessageButton.frame.size = CGSize(width: 35, height: 35)
        
        sendMessageButton.configuration = .filled()
        sendMessageButton.configuration?.baseBackgroundColor = UIColor.purple
        sendMessageButton.layer.cornerRadius = sendMessageButton.frame.size.width / 2.0
        sendMessageButton.configuration?.image = UIImage(systemName: "paperplane.fill")
        sendMessageButton.clipsToBounds =  true
        
        sendMessageButton.addTarget(self, action: #selector(sendMessageBtnWasTapped), for: .touchUpInside)

        setupSendMessageBtnConstraints()
    }
    
    private func setupSendMessageBtnConstraints() {
        
        sendMessageButton.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            sendMessageButton.heightAnchor.constraint(equalToConstant: 35),
            sendMessageButton.widthAnchor.constraint(equalToConstant: 35),
            sendMessageButton.topAnchor.constraint(equalTo: holderView.topAnchor, constant: 8),
            sendMessageButton.leadingAnchor.constraint(equalTo: messageTextView.trailingAnchor, constant: 10),
        ])
    }

    private func setupCoollectionView() {
        view.addSubview(collectionView)
        
        collectionView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: 60, right: 0)
        collectionView.backgroundColor = .link
        
        setCollectionViewConstraints()
    }
    
    private func setCollectionViewConstraints() {
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            collectionView.topAnchor.constraint(equalTo: view.topAnchor),
            collectionView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            collectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            collectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor)
        ])
    }
    
    @objc func sendMessageBtnWasTapped() {
        let trimmedString = messageTextView.text.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmedString.isEmpty {
            messageTextView.text.removeAll()
            Task {
                await conversationViewModel.createMessage(messageBody: trimmedString)
            }
        }
        self.scrollToBottom(withAnimation: true)
    }
    
    private func setupBinding() {
        conversationViewModel.messages.bind { [weak self] messages in
            guard let self = self else {return}
            if !messages.isEmpty {
                DispatchQueue.main.async {
                    self.collectionView.reloadData()
                    self.revertCollectionflowLayout()
                }
            }
        }
    }
    
    private func revertCollectionflowLayout() {
        collectionView.transform = CGAffineTransform(scaleX: 1, y: -1)
        collectionView.layoutIfNeeded()
    }

    private func scrollToBottom(withAnimation: Bool) {
        let indexPath = IndexPath(item: self.conversationViewModel.messages.value.startIndex, section: 0)
        self.collectionView.scrollToItem(at: indexPath, at: .top, animated: withAnimation)
        collectionView.layoutIfNeeded()
    }
}

//MARK: - GESTURES

extension ConversationViewController {
    
    private func setTepGesture() {
        let tap = UITapGestureRecognizer(target: self, action: #selector(resignKeyboard))
        collectionView.addGestureRecognizer(tap)
    }
    
    @objc func resignKeyboard() {
        if messageTextView.isFirstResponder {
            messageTextView.resignFirstResponder()
        }
    }
}

//MARK: - TEXTFIELD DELEGATE

extension ConversationViewController: UITextViewDelegate {}

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
        
        let keyboardHeight = holderView.frame.origin.y > 760 ? -keyboardSize.height : keyboardSize.height
        let customCollectionViewInset = keyboardHeight < 0 ? abs(keyboardHeight) : 0
        
        self.holderViewBottomConstraint.constant = keyboardHeight < 0 ? keyboardHeight : 0
        
        let currentOffSet = collectionView.contentOffset
        let offSet = CGPoint(x: currentOffSet.x, y: keyboardHeight + currentOffSet.y)
        
        collectionView.setContentOffset(offSet, animated: false)
        collectionView.contentInset.top = customCollectionViewInset
        collectionView.verticalScrollIndicatorInsets.top = customCollectionViewInset
        
        // This is ugly but i don't have other solution for canceling cell resizing when keyboard goes down
        // Exaplanation:
        // use only view.layoutIfNeeded()  for any cases
//           1.initiate keyboard
//           2.scroll up
//           3.dismiss keyboard
//           Result: cells from top will animate while resizing
        
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
        guard let imageData = conversationViewModel.imageData else {return}
        let customTitleView = UIView()
        
        if let image = UIImage(data: imageData) {
            let imageView = UIImageView(image: image)
            imageView.contentMode = .scaleAspectFit
            imageView.frame = CGRect(x: 0, y: 0, width: 40, height: 40)
            imageView.layer.cornerRadius = 20
            imageView.clipsToBounds = true
            imageView.center = imageView.convert(CGPoint(x: ((navigationController?.navigationBar.frame.width)! / 2) - 40, y: 0), from: view)
            
            customTitleView.addSubview(imageView)
            
            let titleLabel = UILabel()
            titleLabel.frame = CGRect(x: 0, y: 0, width: 200, height: 20)
            titleLabel.text = conversationViewModel.memberName
            titleLabel.textAlignment = .center
            titleLabel.textColor = UIColor.white
            titleLabel.font =  UIFont(name:"HelveticaNeue-Bold", size: 17)
//            titleLabel.sizeToFit()
            titleLabel.center = titleLabel.convert(CGPoint(x: 0, y: 0), from: view)
            customTitleView.addSubview(titleLabel)

            navigationItem.titleView = customTitleView
        }
    }
}

