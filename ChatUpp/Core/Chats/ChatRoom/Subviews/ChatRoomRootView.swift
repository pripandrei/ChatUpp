//
//  ConversationViewControllerUI.swift
//  ChatUpp
//
//  Created by Andrei Pripa on 11/4/23.
//

import Foundation
import UIKit
import SkeletonView
import YYText
import NVActivityIndicatorView

final class ChatRoomRootView: UIView {
    
    // MARK: - UI Elements
    
    private(set) var inputBarHeader          : InputBarHeaderView?
    private(set) var inputBarBottomConstraint: NSLayoutConstraint!
    private(set) var textViewHeightConstraint: NSLayoutConstraint!
    
//    private(set) var unseenMessagesBadge: UnseenMessagesBadge = UnseenMessagesBadge()

    private(set) var inputBarContainer: InputBarContainer = {
        let inputBarContainer = InputBarContainer()
        inputBarContainer.backgroundColor                           = #colorLiteral(red: 0.1677602232, green: 0.3210971653, blue: 0.4742530584, alpha: 1)
        inputBarContainer.bounds.size.height                        = 80
        inputBarContainer.translatesAutoresizingMaskIntoConstraints = false
        
        return inputBarContainer
    }()
    
    private(set) var unseenMessagesBadge = {
        let badge = UnseenMessagesBadge()
        
        badge.backgroundColor = #colorLiteral(red: 0.08765616736, green: 0.5956842649, blue: 0.6934683476, alpha: 1)
        badge.font = UIFont.systemFont(ofSize: 15)
        badge.textColor = .white
        badge.textAlignment = .center
        badge.translatesAutoresizingMaskIntoConstraints = false
        
        return badge
    }()
    
    /// Conversation table view
    private(set) var tableView: UITableView = {
        
        // Bottom of table view has padding due to navigation controller 
        let tableView                           = UITableView()
        tableView.transform                     = CGAffineTransform(scaleX: 1, y: -1) // Revert table view upside down
        tableView.backgroundColor               = #colorLiteral(red: 0.1411764771, green: 0.3960784376, blue: 0.5647059083, alpha: 1)
        tableView.contentInset                  = UIEdgeInsets(top: 0, left: 0, bottom: 60, right: 0)
        tableView.verticalScrollIndicatorInsets = UIEdgeInsets(top: -20, left: 0, bottom: 70, right: 0)
        tableView.separatorStyle                = .none
        tableView.sectionHeaderTopPadding       = 0
//        tableView.estimatedRowHeight            = UITableView.automaticDimension
        tableView.estimatedRowHeight            = 50
        tableView.rowHeight                     = UITableView.automaticDimension
        tableView.isSkeletonable                = true
        tableView.register(MessageTableViewCell.self, forCellReuseIdentifier: ReuseIdentifire.ConversationTableCell.message.identifire)
        tableView.register(SkeletonViewCell.self, forCellReuseIdentifier: ReuseIdentifire.ConversationTableCell.messageSekeleton.identifire)
        tableView.register(FooterSectionView.self, forHeaderFooterViewReuseIdentifier: ReuseIdentifire.HeaderFooter.footer.identifire)
        tableView.register(UnseenMessagesTitleTableViewCell.self, forCellReuseIdentifier: ReuseIdentifire.ConversationTableCell.unseenTitle.identifire)
        
        return tableView
    }()
    
    private(set) lazy var messageTextView: UITextView = {
        let messageTextView = UITextView()
        let height                                                = inputBarContainer.bounds.height * 0.4
        messageTextView.backgroundColor                           = .systemBlue
        messageTextView.layer.cornerRadius                        = 15
        messageTextView.font                                      = UIFont(name: "HelveticaNeue", size: 17)
        messageTextView.textContainerInset                        = UIEdgeInsets(top: height / 6, left: 5, bottom: height / 6, right: 0)
        messageTextView.textColor                                 = .white
        messageTextView.isScrollEnabled                           = true
        messageTextView.textContainer.maximumNumberOfLines        = 0
        messageTextView.translatesAutoresizingMaskIntoConstraints = false
        
        return messageTextView
    }()
    
    private(set) var sendMessageButton: UIButton = {
        let sendMessageButton = UIButton()
        sendMessageButton.frame.size                                = CGSize(width: 35, height: 35)  // size is used only for radius calculation
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
        addPictureButton.frame.size                                = CGSize(width: 35, height: 35)  // size is used only for radius calculation
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
    
    private(set) var scrollBadgeButton: UIButton = {
        let scrollToBottomBtn                                       = UIButton()
        scrollToBottomBtn.bounds.size                               = CGSize(width: 35, height: 35) // size is used only for radius calculation
        scrollToBottomBtn.configuration                             = .plain()
        scrollToBottomBtn.configuration?.baseBackgroundColor        = #colorLiteral(red: 0.1677602232, green: 0.3210971653, blue: 0.4742530584, alpha: 1)
        scrollToBottomBtn.configuration?.baseForegroundColor        = .white
        scrollToBottomBtn.configuration?.image                      = UIImage(systemName: "arrow.down")
        scrollToBottomBtn.layer.cornerRadius                        = scrollToBottomBtn.bounds.size.width / 2
//        scrollToBottomBtn.clipsToBounds                             = true
        scrollToBottomBtn.backgroundColor                           = #colorLiteral(red: 0.1677602232, green: 0.3210971653, blue: 0.4742530584, alpha: 1)
        scrollToBottomBtn.translatesAutoresizingMaskIntoConstraints = false
        scrollToBottomBtn.layer.borderWidth = 0.25
        scrollToBottomBtn.layer.borderColor = #colorLiteral(red: 0.2599526346, green: 0.5381836295, blue: 0.7432311773, alpha: 1)
//        scrollToBottomBtn.isHidden = true
        scrollToBottomBtn.layer.opacity = 0.0

        return scrollToBottomBtn
    }()
    
    private(set) lazy var joinChatRoomButton: UIButton = {
        let joinButton = UIButton()
        joinButton.configuration                             = .plain()
        joinButton.configuration?.title                      = "Join"
        joinButton.configuration?.baseForegroundColor        = .link
        joinButton.translatesAutoresizingMaskIntoConstraints = false
        
        var attributedTitle = AttributedString("Join")
        attributedTitle.font = UIFont.systemFont(ofSize: 18, weight: .semibold)
        joinButton.configuration?.attributedTitle = attributedTitle
        
        return joinButton
    }()
    
    private(set) lazy var joinActivityIndicator: NVActivityIndicatorView = {
        let activityIndicator = NVActivityIndicatorView(frame: CGRect(x: 0, y: 0, width: 40, height: 40), type: .circleStrokeSpin, color: .link, padding: 2)
        activityIndicator.translatesAutoresizingMaskIntoConstraints = false
        return activityIndicator
    }()
    
    private func setupScrollToBottomBtn() {
        addSubview(scrollBadgeButton)
        
        scrollToBottomBtnBottomConstraint          = scrollBadgeButton.bottomAnchor.constraint(equalTo: inputBarContainer.topAnchor, constant: -10)
        scrollToBottomBtnBottomConstraint.isActive = true
        
        scrollBadgeButton.trailingAnchor.constraint(equalTo: inputBarContainer.trailingAnchor, constant: -10).isActive = true
//        scrollToBottomBtn.bottomAnchor.constraint(equalTo: inputBarContainer.topAnchor, constant: -10).isActive        = true
        scrollBadgeButton.heightAnchor.constraint(equalToConstant: 35).isActive                                        = true
        scrollBadgeButton.widthAnchor.constraint(equalToConstant: 35).isActive                                         = true
    }
    var scrollToBottomBtnBottomConstraint: NSLayoutConstraint!

    // MARK: Internal variables
    var tableViewInitialTopInset: CGFloat {
        return isKeyboardShown() ? CGFloat(336) : CGFloat(0)
    }
    
    // MARK: - LIFECYCLE
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupLayout()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - SETUP CONSTRAINTS
    
    private func setupLayout()
    {
        setupTableViewConstraints()
        setupInputBarContainerConstraints()
        setupMessageTextViewConstraints()
        setupSendMessageBtnConstraints()
        setupAddPictureButtonConstrains()
        setupSendEditMessageButtonConstraints()
        setupScrollToBottomBtn()
        setupUnseenMessageCounterBadgeConstraints()
        setupJoinChatRoomButtonConstraints()
        setupActivityIndicatorConstraint()
//        setupUnseenMessagesBadgeConstraints()
    }
    
    // MARK: Private functions
    
    private func isKeyboardShown() -> Bool {
        return messageTextView.isFirstResponder
    }
    
    // MARK: - Internal functions
    
    func updateTableViewContentOffset(isInputBarHeaderRemoved: Bool) {
        //because tableview is inverted we should perform operations vice versa
        let height = isInputBarHeaderRemoved ? 45.0 : -45.0
        tableView.setContentOffset(CGPoint(x: 0, y: height + tableView.contentOffset.y), animated: false)
    }
    
    func setTextViewDelegate(to delegate: UITextViewDelegate) {
        messageTextView.delegate = delegate
    }
    
    func setInputBarParametersVisibility(shouldHideJoinButton: Bool, shouldAnimate: Bool = false)
    {
        joinChatRoomButton.isHidden = shouldHideJoinButton
        
        self.messageTextView.layer.opacity = 0.0
        self.sendMessageButton.layer.opacity = 0.0
        self.addPictureButton.layer.opacity = 0.0
        
        UIView.animate(withDuration: shouldAnimate ? 0.5 : 0.0)
        {
            self.messageTextView.isHidden = !shouldHideJoinButton
            self.sendMessageButton.isHidden = !shouldHideJoinButton
            self.addPictureButton.isHidden = !shouldHideJoinButton
            
            self.messageTextView.layer.opacity = 1.0
            self.sendMessageButton.layer.opacity = 1.0
            self.addPictureButton.layer.opacity = 1.0
        }
    }
}

// MARK: - SETUP EDIT VIEW
extension ChatRoomRootView 
{
    private func setupInputBarHeaderView(mode: InputBarHeaderView.Mode) {
        destroyinputBarHeaderView()
        inputBarHeader = InputBarHeaderView(mode: mode)
        
        setupInputBarHeaderConstraints()
        inputBarHeader!.setupSubviews()
    }
    
    func activateInputBarHeaderView(mode: InputBarHeaderView.Mode) {
        if inputBarHeader == nil {
            updateTableViewContentOffset(isInputBarHeaderRemoved: false)
        }
        scrollToBottomBtnBottomConstraint.constant -= inputBarHeader == nil ? 45 : 0
        sendEditMessageButton.isHidden = !(mode == .edit)
        setupInputBarHeaderView(mode: mode)
        self.layoutIfNeeded()
    }
    
    func destroyinputBarHeaderView() {
        inputBarHeader?.removeSubviews()
        inputBarHeader?.removeFromSuperview()
        inputBarHeader = nil
    }
}

// MARK: - SETUP SUBVIEW'S CONSTRAINTS
extension ChatRoomRootView
{
    private func setupActivityIndicatorConstraint()
    {
        inputBarContainer.addSubview(joinActivityIndicator)
        
        NSLayoutConstraint.activate([
            joinActivityIndicator.centerXAnchor.constraint(equalTo: inputBarContainer.centerXAnchor),
            joinActivityIndicator.topAnchor.constraint(equalTo: inputBarContainer.topAnchor,constant: 10),
        ])
    }
    
    private func setupJoinChatRoomButtonConstraints()
    {
        inputBarContainer.addSubview(joinChatRoomButton)
        
        NSLayoutConstraint.activate([
            joinChatRoomButton.centerXAnchor.constraint(equalTo: inputBarContainer.centerXAnchor),
            joinChatRoomButton.topAnchor.constraint(equalTo: inputBarContainer.topAnchor,constant: 10),
        ])
    }
    
    private func setupUnseenMessageCounterBadgeConstraints()
    {
        scrollBadgeButton.addSubview(unseenMessagesBadge)
        NSLayoutConstraint.activate([
            unseenMessagesBadge.centerXAnchor.constraint(equalTo: scrollBadgeButton.centerXAnchor),
            unseenMessagesBadge.topAnchor.constraint(equalTo: scrollBadgeButton.topAnchor, constant: -10),
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
    
    private func setupInputBarHeaderConstraints() {
        inputBarContainer.addSubview(inputBarHeader!)
        inputBarContainer.sendSubviewToBack(inputBarHeader!)
        
        inputBarHeader!.translatesAutoresizingMaskIntoConstraints                              = false
        inputBarHeader!.leadingAnchor.constraint(equalTo: self.leadingAnchor).isActive         = true
        inputBarHeader!.trailingAnchor.constraint(equalTo: self.trailingAnchor).isActive       = true
        inputBarHeader!.bottomAnchor.constraint(equalTo: inputBarContainer.topAnchor).isActive = true
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

