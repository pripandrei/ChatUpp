//
//  ConversationViewController.swift
//  ChatUpp
//
//  Created by Andrei Pripa on 10/3/23.
//

import UIKit

final class ConversationViewController: UIViewController {
    
    weak var coordinatorDelegate: Coordinator?
    private var conversationViewModel: ConversationViewModel!
    private var collectionViewDataSource: ConversationViewDataSource!
    
    private let holderView = UIView()
    private let messageTextView = UITextView()
    private let sendMessageButton = UIButton()
    
    private var holderViewBottomConstraint: NSLayoutConstraint!
    private var collectionViewBottomConstraint: NSLayoutConstraint!
    
    private lazy var collectionView: UICollectionView = {
        let collectionViewFlowLayout = UICollectionViewFlowLayout()
        collectionViewFlowLayout.scrollDirection = .vertical
        collectionViewFlowLayout.estimatedItemSize = UICollectionViewFlowLayout.automaticSize
        
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
//        setTepGesture()
        addKeyboardNotificationObservers()
        setNavigationBarItems()
    }

    
//MARK: - VIEW CONTROLLER SETUP
    
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
        messageTextView.font = .systemFont(ofSize: 18)
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
    
    @objc func sendMessageBtnWasTapped() {
        messageTextView.resignFirstResponder()
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
        
        collectionView.backgroundColor = .link
        
        setCollectionViewConstraints()
    }
    
    private func setCollectionViewConstraints() {
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        
//        collectionViewBottomConstraint = collectionView.bottomAnchor.constraint(equalTo: holderView.topAnchor)
        collectionViewBottomConstraint = collectionView.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -80)
        collectionViewBottomConstraint.isActive = true
        
        NSLayoutConstraint.activate([
            collectionView.topAnchor.constraint(equalTo: view.topAnchor),
//            collectionView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            collectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            collectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor)
        ])
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

extension ConversationViewController: UITextViewDelegate {
    
    func textViewShouldEndEditing(_ textView: UITextView) -> Bool {

        if let bodyMessage = textView.text, !bodyMessage.isEmpty {
            let trimmedString = bodyMessage.trimmingCharacters(in: .whitespaces)
            textView.text?.removeAll()
            Task {
                await conversationViewModel.createMessage(messageBody: trimmedString)
            }
        }
        return true
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
        
        let keyboardHeight = holderView.frame.origin.y > 760 ? -keyboardSize.height : keyboardSize.height
        let customCollectionViewInset = keyboardHeight < 0 ? abs(keyboardHeight) : 0
        
        self.holderViewBottomConstraint.constant = keyboardHeight < 0 ? keyboardHeight : 0

        let currentOffSet = collectionView.contentOffset
        let offSet = CGPoint(x: currentOffSet.x, y: keyboardHeight.invertValue() + currentOffSet.y)
        collectionView.setContentOffset(offSet, animated: false)
        
        let contentInset = UIEdgeInsets(top: 0, left: 0, bottom: customCollectionViewInset, right: 0)
        collectionView.contentInset = contentInset
        collectionView.scrollIndicatorInsets = contentInset
        
        UIView.animate(withDuration: 0.5, delay: 0.0) {
            self.view.layoutIfNeeded()
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

