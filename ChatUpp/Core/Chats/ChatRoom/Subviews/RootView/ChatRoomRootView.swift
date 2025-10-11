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
import Combine
import SwiftUI

final class ChatRoomRootView: UIView
{
    let contentOffsetSubject: PassthroughSubject = PassthroughSubject<Void, Never>()
    
    private let inputBarViewsTopConstraintConstant: CGFloat = 7.0
    private let inputBarButtonsSize: CGFloat = 31
    
    private(set) var inputBarHeader          : InputBarHeaderView?
    private(set) var inputBarBottomConstraint: NSLayoutConstraint!
    private(set) var textViewHeightConstraint: NSLayoutConstraint!
    private var greetingViewCenterYConstraint: NSLayoutConstraint?

    private(set) var stickerCollectionView: StickersPackCollectionView?
    private var textViewTrailingItem: MessageTextViewTrailingItemView!
    private var textViewTrailingItemView: UIView!
    let trailingItemState = TrailingItemState()
    private var greetingView: GreetingView?
    
    private(set) var inputBarContainer: InputBarContainer = InputBarContainer()
    
    private(set) var unseenMessagesBadge = {
        let badge = UnseenMessagesBadge()
        
        badge.backgroundColor = ColorManager.unseenMessagesBadgeBackgroundColor
        badge.font = UIFont.systemFont(ofSize: 15)
        badge.textColor = .white
        badge.textAlignment = .center
        badge.translatesAutoresizingMaskIntoConstraints = false
        
        return badge
    }()
    
    /// Conversation table view
    lazy private(set) var tableView: UITableView = {
        
        // Bottom of table view has padding due to navigation controller
        let tableView                           = UITableView()
        tableView.transform                     = CGAffineTransform(scaleX: 1, y: -1)
        tableView.backgroundColor               = ColorManager.appBackgroundColor
        tableView.contentInset                  = UIEdgeInsets(top: 0, left: 0, bottom: 60, right: 0)
        tableView.verticalScrollIndicatorInsets = UIEdgeInsets(top: -20, left: 0, bottom: 70, right: 0)
        tableView.separatorStyle                = .none
        tableView.sectionHeaderTopPadding       = 0
        
        // for skeleton animation
        tableView.estimatedRowHeight            = UITableView.automaticDimension
        tableView.rowHeight                     = UITableView.automaticDimension
        tableView.isSkeletonable                = true
        
        tableView.backgroundView = createBackgroundView()
        createBackgroundBlurEffect(for: tableView.backgroundView!)
        
        registerCells(for: tableView)
        
        return tableView
    }()

    private(set) lazy var messageTextView: UITextView = {
        let messageTextView = UITextView()
        let height                                                = inputBarContainer.bounds.height * 0.4
        messageTextView.backgroundColor                           = ColorManager.messageTextFieldBackgroundColor
        messageTextView.layer.cornerRadius                        = 15
        messageTextView.font                                      = UIFont(name: "HelveticaNeue", size: 17)
        messageTextView.textContainerInset                        = UIEdgeInsets(top: height / 6, left: 5, bottom: height / 6, right: 50)
        messageTextView.textColor                                 = ColorManager.textFieldTextColor
        messageTextView.isScrollEnabled                           = true
        messageTextView.textContainer.maximumNumberOfLines        = 0
        messageTextView.translatesAutoresizingMaskIntoConstraints = false
        messageTextView.keyboardAppearance = .dark
        
        return messageTextView
    }()
    
    private(set) var sendMessageButton: UIButton = {
        let sendMessageButton = UIButton()
        sendMessageButton.configuration                             = .filled()
        sendMessageButton.configuration?.image                      = UIImage(systemName: "arrow.up")
        sendMessageButton.configuration?.baseBackgroundColor        = ColorManager.sendMessageButtonBackgroundColor
        sendMessageButton.clipsToBounds                             =  true
        sendMessageButton.translatesAutoresizingMaskIntoConstraints = false
        
        return sendMessageButton
    }()
    
    private(set) var addPictureButton: UIButton = {
        let addPictureButton = UIButton()

        addPictureButton.configuration                             = .plain()
        addPictureButton.configuration?.baseForegroundColor        = ColorManager.tabBarNormalItemsTintColor
        addPictureButton.layer.cornerRadius                        = addPictureButton.frame.size.width / 2.0
        addPictureButton.configuration?.image                      = UIImage(systemName: "photo")
        addPictureButton.clipsToBounds                             = true
        addPictureButton.translatesAutoresizingMaskIntoConstraints = false
        
        return addPictureButton
    }()
    
    private(set) var sendEditMessageButton: UIButton = {
        let sendEditMessageButton = UIButton()
//        sendEditMessageButton.frame.size                                = CGSize(width: 35, height: 35)
        sendEditMessageButton.configuration                             = .filled()
        sendEditMessageButton.configuration?.image                      = UIImage(systemName: "checkmark")
        sendEditMessageButton.configuration?.baseBackgroundColor        = ColorManager.sendMessageButtonBackgroundColor
//        sendEditMessageButton.layer.cornerRadius                        = sendEditMessageButton.frame.size.width / 2.0
        sendEditMessageButton.clipsToBounds                             = true
        sendEditMessageButton.isHidden                                  = true
        sendEditMessageButton.translatesAutoresizingMaskIntoConstraints = false
        
        return sendEditMessageButton
    }()
    
    lazy private(set) var scrollBadgeButton: UIButton = {
        let scrollToBottomBtn                                       = UIButton()

        scrollToBottomBtn.configuration                             = .plain()
        let image = UIImage(named: "angle-arrow-down")?
            .withTintColor(ColorManager.actionButtonsTintColor)
            .resizeImage(toSize: CGSize(width: 17, height: 15))
        scrollToBottomBtn.configuration?.image = image
        
        scrollToBottomBtn.backgroundColor                           = ColorManager.scrollToBottomButtonBackgroundColor
        scrollToBottomBtn.translatesAutoresizingMaskIntoConstraints = false
        scrollToBottomBtn.layer.borderWidth = 0.25
        scrollToBottomBtn.layer.borderColor = #colorLiteral(red: 0.3582897782, green: 0.31710729, blue: 0.3442819118, alpha: 1)
        scrollToBottomBtn.layer.opacity = 0.0

        return scrollToBottomBtn
    }()
    
    private(set) lazy var joinChatRoomButton: UIButton = {
        let joinButton = UIButton()
        joinButton.configuration                             = .plain()
        joinButton.configuration?.title                      = "Join"
        joinButton.configuration?.baseForegroundColor        = ColorManager.actionButtonsTintColor
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
        scrollBadgeButton.heightAnchor.constraint(equalToConstant: 35).isActive                                        = true
        scrollBadgeButton.widthAnchor.constraint(equalToConstant: 35).isActive                                         = true
    }
    var scrollToBottomBtnBottomConstraint: NSLayoutConstraint!

    // MARK: Internal variables
    var tableViewInitialTopInset: CGFloat
    {
        let keyboardHeight = KeyboardService.shared.keyboardHeight
        return isKeyboardShown() ? CGFloat(keyboardHeight - 30) : CGFloat(0)
    }
    
    // MARK: - LIFECYCLE
    
    override init(frame: CGRect)
    {
        super.init(frame: frame)
        setupLayout()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func layoutSubviews()
    {
        super.layoutSubviews()
        sendMessageButton.layer.cornerRadius = sendMessageButton.bounds.height / 2
        sendEditMessageButton.layer.cornerRadius = sendEditMessageButton.bounds.height / 2
        scrollBadgeButton.layer.cornerRadius = scrollBadgeButton.bounds.size.width / 2
    }
    
    deinit
    {
//        print("ChatRoomRootView deinit")
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
        setupTextViewTrailingItem()
    }
    
    func setupGreetingView()
    {
        self.greetingView = .init()
        addSubview(greetingView!)
        
        greetingView?.translatesAutoresizingMaskIntoConstraints = false
        
        let centerYConstraint = greetingView!.centerYAnchor.constraint(equalTo: centerYAnchor)
        self.greetingViewCenterYConstraint = centerYConstraint
        
        NSLayoutConstraint.activate([
            centerYConstraint,
            greetingView!.centerXAnchor.constraint(equalTo: centerXAnchor),
            greetingView!.widthAnchor.constraint(equalTo: widthAnchor, multiplier: 0.6),
            greetingView!.heightAnchor.constraint(equalTo: greetingView!.widthAnchor),
        ])
    }
    
    func removeGreetingViewIfNeeded()
    {
        guard self.greetingView != nil else {return}
        
        UIView.animate(withDuration: 0.4)
        {
            self.greetingView?.alpha = 0.0
        } completion: { _ in
            self.greetingView?.removeFromSuperview()
            self.greetingView = nil
        }
    }
    
    func removeStickerView()
    {
        stickerCollectionView?.removeFromSuperview()
        stickerCollectionView = nil
    }
    
    func showStickerIcon() {
        trailingItemState.item = .stickerItem
        textViewTrailingItem.isButtonDisabled = true
    }
    
    // MARK: Private functions
    
    private func isKeyboardShown() -> Bool {
        return messageTextView.isFirstResponder
    }
    
    private func registerCells(for tableView: UITableView)
    {
        tableView.register(ConversationMessageCell.self, forCellReuseIdentifier: ReuseIdentifire.ConversationTableCell.message.identifire)
        tableView.register(SkeletonViewCell.self, forCellReuseIdentifier: ReuseIdentifire.ConversationTableCell.messageSekeleton.identifire)
        tableView.register(FooterSectionView.self, forHeaderFooterViewReuseIdentifier: ReuseIdentifire.HeaderFooter.footer.identifire)
        tableView.register(UnseenMessagesTitleTableViewCell.self, forCellReuseIdentifier: ReuseIdentifire.ConversationTableCell.unseenTitle.identifire)
        tableView.register(MessageEventCell.self, forCellReuseIdentifier: ReuseIdentifire.ConversationTableCell.eventMessage.identifire)
    }
    
    // MARK: - Internal functions
    
    func toggleGreetingViewPosition(up: Bool)
    {
        UIView.animate(withDuration: 0.3) {
            self.greetingViewCenterYConstraint?.constant = up ? -130 : 0
        }
    }
    
    func updateInputBarBottomConstraint(toSize size: CGFloat) {
        self.inputBarBottomConstraint.constant = size
        self.layoutIfNeeded()
    }
    
    func updateTableViewContentAttributes(isInputBarHeaderRemoved: Bool)
    {
        //because tableview is inverted we should perform operations vice versa
        let height = isInputBarHeaderRemoved ? 45.0 : -45.0
        tableView.setContentOffset(CGPoint(x: 0, y: height + tableView.contentOffset.y), animated: false)
        tableView.contentInset.top -= height
        tableView.verticalScrollIndicatorInsets.top -= height
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
        self.textViewTrailingItemView.layer.opacity = 0.0
        
        UIView.animate(withDuration: shouldAnimate ? 0.5 : 0.0)
        {
            self.messageTextView.isHidden = !shouldHideJoinButton
            self.sendMessageButton.isHidden = !shouldHideJoinButton
            self.addPictureButton.isHidden = !shouldHideJoinButton
            self.textViewTrailingItemView.isHidden = !shouldHideJoinButton
            
            self.messageTextView.layer.opacity = 1.0
            self.sendMessageButton.layer.opacity = 1.0
            self.addPictureButton.layer.opacity = 1.0
            self.textViewTrailingItemView.layer.opacity = 1.0
        }
    }
}

// MARK: - TextView trailing items
extension ChatRoomRootView
{
    private func setupTextViewTrailingItem()
    {
        self.textViewTrailingItem = MessageTextViewTrailingItemView(trailingItemState: trailingItemState)
        { [weak self] item in
            guard let self else {return}
            switch item
            {
            case .stickerItem:
                guard self.stickerCollectionView == nil else {
                    self.messageTextView.resignFirstResponder()
                    return
                }
                self.initiateStickersViewSetup()
                self.contentOffsetSubject.send()
            case .keyboardItem: self.initiateKeyboardItem()
            }
        }

        let hostingVC = UIHostingController(rootView: self.textViewTrailingItem)
        let tailingView = hostingVC.view!
        self.textViewTrailingItemView = tailingView
        tailingView.backgroundColor = .clear
        
        inputBarContainer.addSubview(tailingView)
        
        tailingView.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            tailingView.trailingAnchor.constraint(equalTo: messageTextView.trailingAnchor, constant: -10),
//            tailingView.centerYAnchor.constraint(equalTo: messageTextView.centerYAnchor),
            tailingView.bottomAnchor.constraint(equalTo: messageTextView.bottomAnchor, constant: -3),
        ])
    }
    
    private func initiateStickersViewSetup()
    {
        let stickerCollectionView = StickersPackCollectionView()
        addSubview(stickerCollectionView)
        self.stickerCollectionView = stickerCollectionView
        
        stickerCollectionView.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            stickerCollectionView.topAnchor.constraint(equalTo: inputBarContainer.bottomAnchor, constant: -25),
//            stickerCollectionView.heightAnchor.constraint(equalToConstant: 700),
            stickerCollectionView.bottomAnchor.constraint(equalTo: self.bottomAnchor),
            stickerCollectionView.trailingAnchor.constraint(equalTo: self.trailingAnchor),
            stickerCollectionView.leadingAnchor.constraint(equalTo: self.leadingAnchor),
        ])
        self.layoutIfNeeded()
    }
    
    private func initiateKeyboardItem()
    {
        messageTextView.becomeFirstResponder()
        executeAfter(seconds: 1) { [weak self] in
            guard self?.messageTextView.isFirstResponder == true else {return}
            self?.removeStickerView()
        }
    }
}

// MARK: - SETUP EDIT VIEW
extension ChatRoomRootView
{
    func setupInputBarHeaderView(mode: InputBarHeaderView.Mode)
    {
        if self.inputBarHeader == nil
        {
            inputBarHeader = InputBarHeaderView(mode: mode)
            setupInputBarHeaderConstraints()
            self.inputBarHeader?.transform = CGAffineTransform(translationX: 0, y: 80)
            self.layoutIfNeeded()
            
            UIView.animate(withDuration: 0.3)
            {
                self.inputBarHeader?.transform = .identity
                self.updateTableViewContentAttributes(isInputBarHeaderRemoved: false)
                self.scrollToBottomBtnBottomConstraint.constant -= 45
                self.layoutIfNeeded()
            }
        } else {
            self.inputBarHeader?.applyMode(mode)
            self.inputBarHeader?.animateComponents(isUpdating: true)
        }
        
        self.sendEditMessageButton.isHidden = !{
            if case .edit = mode { return true }
            return false
        }()
    }
    
    func destroyInputBarHeaderView() {
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
    
    private func setupInputBarHeaderConstraints()
    {
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
            addPictureButton.trailingAnchor.constraint(equalTo: messageTextView.leadingAnchor, constant: -6),
            addPictureButton.topAnchor.constraint(equalTo: inputBarContainer.topAnchor, constant: inputBarViewsTopConstraintConstant),
            addPictureButton.heightAnchor.constraint(equalToConstant: inputBarButtonsSize),
            addPictureButton.widthAnchor.constraint(equalToConstant: inputBarButtonsSize),
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
        
        textViewHeightConstraint          = messageTextView.heightAnchor.constraint(equalToConstant: inputBarButtonsSize)
        textViewHeightConstraint.isActive = true
        textViewHeightConstraint.priority = .required
        
        NSLayoutConstraint.activate([
            messageTextView.bottomAnchor.constraint(equalTo: inputBarContainer.bottomAnchor, constant: -inputBarContainer.bounds.height * 0.52),
            messageTextView.trailingAnchor.constraint(equalTo: inputBarContainer.trailingAnchor, constant: -48),
            messageTextView.leadingAnchor.constraint(equalTo: inputBarContainer.leadingAnchor, constant: 48),
            messageTextView.topAnchor.constraint(equalTo: inputBarContainer.topAnchor, constant: inputBarViewsTopConstraintConstant),
        ])
    }
    
    private func setupSendMessageBtnConstraints() {
        inputBarContainer.addSubview(sendMessageButton)

        NSLayoutConstraint.activate([
            sendMessageButton.leadingAnchor.constraint(equalTo: messageTextView.trailingAnchor, constant: 5),
            sendMessageButton.topAnchor.constraint(equalTo: inputBarContainer.topAnchor, constant: inputBarViewsTopConstraintConstant),
            sendMessageButton.heightAnchor.constraint(equalToConstant: inputBarButtonsSize),
            sendMessageButton.widthAnchor.constraint(equalToConstant: inputBarButtonsSize),
        ])
    }
    
    private func setupSendEditMessageButtonConstraints() {
        self.addSubviews(sendEditMessageButton)
        
        NSLayoutConstraint.activate([
            sendEditMessageButton.leadingAnchor.constraint(equalTo: messageTextView.trailingAnchor, constant: 5),
            sendEditMessageButton.topAnchor.constraint(equalTo: inputBarContainer.topAnchor, constant: inputBarViewsTopConstraintConstant),
            sendEditMessageButton.heightAnchor.constraint(equalToConstant: inputBarButtonsSize),
            sendEditMessageButton.widthAnchor.constraint(equalToConstant: inputBarButtonsSize),
        ])
    }
}

//MARK: - setup table view background
extension ChatRoomRootView
{
    private func createBackgroundView() -> UIView
    {
        let view = UIView()
        let backgroundImageView = UIImageView(image: UIImage(named: "chatRoom_background_3"))
        backgroundImageView.contentMode = .scaleAspectFill
        backgroundImageView.frame = view.bounds
        backgroundImageView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        view.addSubview(backgroundImageView)
        return view
    }
    
    private func createBackgroundBlurEffect(for imageView: UIView)
    {
        let blurEffect = UIBlurEffect(style: .systemMaterialDark)
        let blurEffectView = UIVisualEffectView(effect: blurEffect)
        blurEffectView.alpha = 0.6
//        blurEffectView.layer.opacity = 0.8
        blurEffectView.frame = imageView.bounds
        blurEffectView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        imageView.addSubview(blurEffectView)
    }
}

extension ChatRoomRootView
{
    func resizeImage(_ image: UIImage, to size: CGSize) -> UIImage
    {
        let renderer = UIGraphicsImageRenderer(size: size)
        return renderer.image { _ in
            image.draw(in: CGRect(origin: .zero, size: size))
        }
    }
}
