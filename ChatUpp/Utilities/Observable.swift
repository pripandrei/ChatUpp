//
//  Observable.swift
//  ChatUpp
//
//  Created by Andrei Pripa on 8/7/23.
//

import Foundation

final class ObservableObject<T> {
    var value: T {
        didSet {
            listiner?(value)
        }
    }

    var listiner: ((T) -> Void)?

    init(_ value: T) {
        self.value = value
    }

    func bind(_ listiner: @escaping((T) -> Void)) {
        self.listiner = listiner
//        listiner(value)
    }
}



















//
//  ConversationViewControllerUI.swift
//  ChatUpp
//
//  Created by Andrei Pripa on 11/4/23.
//

import Foundation
import UIKit

final class ConversationRootView23: UIView {
    
    // MARK: - UI Elements
    
    private(set) var editView                      : EditView?
    private(set) var inputBarBottomConstraint      : NSLayoutConstraint!
    var textViewHeightConstraint                   : NSLayoutConstraint!
    
    private(set) var messageTextViewNumberOfLines  = 1
    var tableViewInitialContentOffset              = CGPoint(x: 0, y: 0)
    
    private(set) var inputBarContainer: InputBarContainer = {
        let inputBarContainer = InputBarContainer()
        inputBarContainer.backgroundColor                           = #colorLiteral(red: 0.1677602232, green: 0.3210971653, blue: 0.4742530584, alpha: 1)
        inputBarContainer.bounds.size.height                        = 80
        inputBarContainer.translatesAutoresizingMaskIntoConstraints = false
        
        return inputBarContainer
    }()
    
    private(set) lazy var messageTextView: UITextView = {
        let messageTextView = UITextView()
        let height                                                = inputBarContainer.bounds.height * 0.4
        messageTextView.backgroundColor                           = .systemBlue
        messageTextView.layer.cornerRadius                        = 15
        messageTextView.font                                      = UIFont(name: "HelveticaNeue", size: 17)
        messageTextView.textContainerInset                        = UIEdgeInsets(top: height / 6, left: 5, bottom: height / 6, right: 0)
        messageTextView.textColor                                 = .white
        messageTextView.isScrollEnabled                           = false
        messageTextView.textContainer.maximumNumberOfLines        = 0
        messageTextView.translatesAutoresizingMaskIntoConstraints = false
        
        return messageTextView
    }()
    
    private(set) var sendMessageButton: UIButton = {
        let sendMessageButton = UIButton()
        // size is used only for radius calculation
        sendMessageButton.frame.size                                = CGSize(width: 35, height: 35)
        sendMessageButton.configuration                             = .filled()
        sendMessageButton.configuration?.image                      = UIImage(systemName: "paperplane.fill")
        sendMessageButton.configuration?.baseBackgroundColor        = UIColor.purple
        sendMessageButton.layer.cornerRadius                        = sendMessageButton.frame.size.width / 2.0
        sendMessageButton.clipsToBounds                             =  true
        sendMessageButton.translatesAutoresizingMaskIntoConstraints = false
        
        return sendMessageButton
    }()
    
    private(set) var addPictureButton: UIButton = {
        let addPictureButton = UIButton()
        // frmame size is used only for radius calculation
        addPictureButton.frame.size                                = CGSize(width: 35, height: 35)
        addPictureButton.configuration                             = .plain()
        addPictureButton.configuration?.baseForegroundColor        = UIColor.purple
        addPictureButton.layer.cornerRadius                        = addPictureButton.frame.size.width / 2.0
        addPictureButton.configuration?.image                      = UIImage(systemName: "photo")
        addPictureButton.clipsToBounds                             = true
        addPictureButton.translatesAutoresizingMaskIntoConstraints = false
        
        return addPictureButton
    }()
    
    private(set) var sendEditMessageButton: UIButton = {
        let sendEditMessageButton = UIButton()
        sendEditMessageButton.frame.size                                = CGSize(width: 35, height: 35)
        sendEditMessageButton.configuration                             = .filled()
        sendEditMessageButton.configuration?.image                      = UIImage(systemName: "checkmark")
        sendEditMessageButton.configuration?.baseBackgroundColor        = UIColor.blue
        sendEditMessageButton.layer.cornerRadius                        = sendEditMessageButton.frame.size.width / 2.0
        sendEditMessageButton.clipsToBounds                             = true
        sendEditMessageButton.isHidden                                  = true
        sendEditMessageButton.translatesAutoresizingMaskIntoConstraints = false
        
        return sendEditMessageButton
    }()
    
    private(set) var tableView: UITableView = {
        let tableView                           = UITableView()
        
        // Revert table view upside down
        tableView.transform                     = CGAffineTransform(scaleX: 1, y: -1)
        
        tableView.backgroundColor               = #colorLiteral(red: 0.1411764771, green: 0.3960784376, blue: 0.5647059083, alpha: 1)
        tableView.contentInset                  = UIEdgeInsets(top: 0, left: 0, bottom: 60, right: 0)
        tableView.verticalScrollIndicatorInsets = UIEdgeInsets(top: -10, left: 0, bottom: 70, right: 0)
        tableView.separatorStyle                = .none
        tableView.sectionHeaderTopPadding       = 0
        tableView.register(ConversationTableViewCell.self, forCellReuseIdentifier: CellIdentifire.conversationMessageCell)
        
        return tableView
    }()
    
    // MARK: - LIFECYCLE
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupLayout()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - VIEW LAYOUT SETUP
    
    private func setupLayout() {
        setupTableViewConstraints()
        setupInputBarContainerConstraints()
        setupMessageTextViewConstraints()
        setupSendMessageBtnConstraints()
        setupAddPictureButtonConstrains()
        setupSendEditMessageButtonConstraints()
    }

    private var tableViewInitialTopInset: CGFloat {
        return isKeyboardShown() ? CGFloat(336) : CGFloat(0)
    }

    private func isKeyboardShown() -> Bool {
        return messageTextView.isFirstResponder
    }
    
    // MARK: - SETUP EDIT VIEW
    
    private func setupEditView() {
        editView = EditView()
        
        setupEditViewConstraints()
        editView!.setupSubviews()
    }
    
    func activateEditView() {
        setupEditView()
        
        updateTableViewContentOffset(isEditViewRemoved: false)
        sendEditMessageButton.isHidden = false
        self.layoutIfNeeded()
    }
    
    func destroyEditedView() {
        editView?.removeSubviews()
        editView?.removeFromSuperview()
        editView = nil
    }
    
    
    
    func updateTableViewContentOffset(isEditViewRemoved: Bool) {
        //because tableview is inverted we should perform operations vice versa
        let height = isEditViewRemoved ? 45.0 : -45.0
        tableView.setContentOffset(CGPoint(x: 0, y: height + tableView.contentOffset.y), animated: false)
    }
    
    func updateTextViewNumberOfLines(_ number: Int) {
        messageTextViewNumberOfLines = number
    }
    func setTextViewDelegate(to delegate: UITextViewDelegate) {
        messageTextView.delegate = delegate
    }
}

// MARK: - SETUP SUBVIEW'S CONSTRAINTS
extension ConversationRootView23 {
    
    private func setupEditViewConstraints() {
        inputBarContainer.addSubview(editView!)
        inputBarContainer.sendSubviewToBack(editView!)
        
        editView!.translatesAutoresizingMaskIntoConstraints                              = false
        editView!.leadingAnchor.constraint(equalTo: self.leadingAnchor).isActive         = true
        editView!.trailingAnchor.constraint(equalTo: self.trailingAnchor).isActive       = true
        editView!.bottomAnchor.constraint(equalTo: inputBarContainer.topAnchor).isActive = true
    }
 
    private func setupAddPictureButtonConstrains() {
        self.addSubviews(addPictureButton)
        
        NSLayoutConstraint.activate([
            addPictureButton.trailingAnchor.constraint(equalTo: messageTextView.leadingAnchor, constant: -10),
            addPictureButton.topAnchor.constraint(equalTo: inputBarContainer.topAnchor, constant: 8),
            addPictureButton.heightAnchor.constraint(equalToConstant: 35),
            addPictureButton.widthAnchor.constraint(equalToConstant: 35),
        ])
    }
    
    private func setupTableViewConstraints() {
        self.addSubview(tableView)
        
        tableView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            tableView.trailingAnchor.constraint(equalTo: self.trailingAnchor),
            tableView.leadingAnchor.constraint(equalTo: self.leadingAnchor),
            tableView.bottomAnchor.constraint(equalTo: self.bottomAnchor),
            tableView.topAnchor.constraint(equalTo:   self.topAnchor),
        ])
    }
    
    private func setupInputBarContainerConstraints() {
        self.addSubviews(inputBarContainer)
        
        inputBarBottomConstraint          = inputBarContainer.bottomAnchor.constraint(equalTo: self.bottomAnchor)
        inputBarBottomConstraint.isActive = true
        
        let heightConstraint              = inputBarContainer.heightAnchor.constraint(equalToConstant: 80)
        heightConstraint.isActive         = true
        heightConstraint.priority         = .defaultLow
        
        NSLayoutConstraint.activate([
            inputBarContainer.leadingAnchor.constraint(equalTo: self.leadingAnchor),
            inputBarContainer.trailingAnchor.constraint(equalTo: self.trailingAnchor)
        ])
    }
    
    private func setupMessageTextViewConstraints() {
        inputBarContainer.addSubview(messageTextView)
        
        textViewHeightConstraint          = messageTextView.heightAnchor.constraint(equalToConstant: 31)
        textViewHeightConstraint.isActive = true
        textViewHeightConstraint.priority = .required
        
        NSLayoutConstraint.activate([
            messageTextView.bottomAnchor.constraint(equalTo: inputBarContainer.bottomAnchor, constant: -inputBarContainer.bounds.height * 0.45),
            messageTextView.trailingAnchor.constraint(equalTo: inputBarContainer.trailingAnchor, constant: -55),
            messageTextView.leadingAnchor.constraint(equalTo: inputBarContainer.leadingAnchor, constant: 55),
            messageTextView.topAnchor.constraint(equalTo: inputBarContainer.topAnchor, constant: 10),
        ])
    }
    
    private func setupSendMessageBtnConstraints() {
        inputBarContainer.addSubview(sendMessageButton)
        // size is used only for radius calculation

        NSLayoutConstraint.activate([
            sendMessageButton.leadingAnchor.constraint(equalTo: messageTextView.trailingAnchor, constant: 10),
            sendMessageButton.topAnchor.constraint(equalTo: inputBarContainer.topAnchor, constant: 8),
            sendMessageButton.heightAnchor.constraint(equalToConstant: 35),
            sendMessageButton.widthAnchor.constraint(equalToConstant: 35),
        ])
    }
    
    private func setupSendEditMessageButtonConstraints() {
        self.addSubviews(sendEditMessageButton)
        
        NSLayoutConstraint.activate([
            sendEditMessageButton.heightAnchor.constraint(equalToConstant: 35),
            sendEditMessageButton.widthAnchor.constraint(equalToConstant: 35),
            sendEditMessageButton.topAnchor.constraint(equalTo: inputBarContainer.topAnchor, constant: 8),
            sendEditMessageButton.leadingAnchor.constraint(equalTo: messageTextView.trailingAnchor, constant: 10),
        ])
    }
}
