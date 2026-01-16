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
    let cancelRecordingSubject: PassthroughSubject = PassthroughSubject<Void, Never>()
    
    private var sendMessageButtonPropertyAnimator: UIViewPropertyAnimator?
    
    private let inputBarViewsTopConstraintConstant: CGFloat = 7.0
    private let inputBarButtonsSize: CGFloat = 36
    
    private(set) var inputBarHeader          : InputBarHeaderView?
    private(set) var inputBarBottomConstraint: NSLayoutConstraint!
    private(set) var textViewHeightConstraint: NSLayoutConstraint!
    private(set) var textViewLeadingConstraint: NSLayoutConstraint!
    private var greetingViewCenterYConstraint: NSLayoutConstraint?
    private var cancelButtonCenterXConstraint: NSLayoutConstraint?
    private(set) var stickerCollectionViewTopConstraint: NSLayoutConstraint?

    private(set) var stickerCollectionView: StickersPackCollectionView?
    private var textViewTrailingItem: MessageTextViewTrailingItemView!
    private var textViewTrailingItemView: UIView!
    let trailingItemState = TrailingItemState()
    private(set) var greetingView: GreetingView?
    
    private var recordingTimer: Timer?
    private var recCounterLabel: UILabel?
    private var recRedDotView: UIView?
    private var recLabelsStackView: UIStackView?
    private(set) var cancelRecButton: UIButton?
    
    private(set) var inputBarContainer: InputBarContainer = InputBarContainer()
    
    private(set) var unseenMessagesBadge = {
        let badge = UnseenMessagesBadge()
        
        badge.backgroundColor = ColorScheme.unseenMessagesBadgeBackgroundColor
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
        tableView.backgroundColor               = ColorScheme.appBackgroundColor
        tableView.contentInset                  = UIEdgeInsets(top: 0, left: 0, bottom: 75, right: 0)
        tableView.verticalScrollIndicatorInsets = UIEdgeInsets(top: 0, left: 0, bottom: 85, right: 0)
        tableView.separatorStyle                = .none
        tableView.sectionHeaderTopPadding       = 0
        
        // for skeleton animation
        tableView.estimatedRowHeight            = UITableView.automaticDimension
        tableView.rowHeight                     = UITableView.automaticDimension
        tableView.isSkeletonable                = true
        tableView.indicatorStyle                = .white
        
        tableView.backgroundView = createBackgroundView()
        createBackgroundBlurEffect(for: tableView.backgroundView!)
        
        registerCells(for: tableView)
        
        return tableView
    }()

    private(set) lazy var messageTextView: MessageTextView = {
        let messageTextView = MessageTextView()
        
        messageTextView.backgroundColor                           = ColorScheme.messageTextFieldBackgroundColor
        messageTextView.layer.cornerRadius                        = 15
        messageTextView.font                                      = UIFont(name: "HelveticaNeue", size: 17)
        
        let topInset = messageTextView.textContainerInset.top
        let bottomInset = messageTextView.textContainerInset.bottom
        messageTextView.textContainerInset                        = .init(top: topInset,
                                                                          left: 7,
                                                                          bottom: bottomInset,
                                                                          right: 50)
        messageTextView.textColor                                 = ColorScheme.textFieldTextColor
        messageTextView.isScrollEnabled                           = true
        messageTextView.textContainer.maximumNumberOfLines        = 0
        messageTextView.translatesAutoresizingMaskIntoConstraints = false
        messageTextView.keyboardAppearance = .dark
        messageTextView.layer.borderWidth = 0.4
        messageTextView.layer.borderColor = #colorLiteral(red: 0.470990181, green: 0.3475213647, blue: 0.4823801517, alpha: 1).cgColor
        
        return messageTextView
    }()
    
    lazy private(set) var sendMessageButton: UIButton = {
        let sendMessageButton = UIButton()
        sendMessageButton.configuration                             = .filled()
        sendMessageButton.configuration?.image                      = UIImage(systemName: "arrow.up")
        sendMessageButton.configuration?.baseBackgroundColor        = ColorScheme.sendMessageButtonBackgroundColor
        sendMessageButton.clipsToBounds                             = true
        sendMessageButton.isHidden                                  = false
        sendMessageButton.translatesAutoresizingMaskIntoConstraints = false
        return sendMessageButton
    }()
    
    lazy private(set) var voiceRecButton: UIButton = {
        let button = UIButton(type: .custom)
        button.isHidden = true
        var config = UIButton.Configuration.bordered()
       
        // Resize custom image
        let originalImage = UIImage(named: "microphone_for_inputbar")
        let imageSize = inputBarButtonsSize - 12
        let targetSize = CGSize(width: imageSize, height: imageSize)
        let resizedImage = originalImage?.resize(to: targetSize)

        config.image = resizedImage?.withRenderingMode(.alwaysTemplate)
        config.baseForegroundColor = .systemGray
        config.baseBackgroundColor = ColorScheme.messageTextFieldBackgroundColor
        
        config.background.strokeColor = #colorLiteral(red: 0.470990181, green: 0.3475213647, blue: 0.4823801517, alpha: 1)
        config.background.strokeWidth = 0.5
        config.background.cornerRadius = inputBarButtonsSize / 2
        
//        config.contentInsets = .init(top: 5, leading: 5, bottom: 5, trailing: 5)
        button.configuration = config

        button.adjustsImageSizeForAccessibilityContentSizeCategory = false
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    lazy private(set) var addPictureButton: UIButton = {
        let button = UIButton(type: .custom)

        var config = UIButton.Configuration.bordered()
        
        let symbolConfig = UIImage.SymbolConfiguration(pointSize: 16, weight: .medium)
        config.image                      = UIImage(systemName: "plus")?.withConfiguration(symbolConfig)
        button.clipsToBounds                             = true
        
        config.background.strokeColor = #colorLiteral(red: 0.470990181, green: 0.3475213647, blue: 0.4823801517, alpha: 1)
        config.background.strokeWidth = 0.5
        config.background.cornerRadius = inputBarButtonsSize / 2
        
//        config.contentInsets = .init(top: 5, leading: 5, bottom: 5, trailing: 5)
        button.configuration = config

        config.baseForegroundColor = .systemGray
        config.baseBackgroundColor = ColorScheme.messageTextFieldBackgroundColor
        
        button.translatesAutoresizingMaskIntoConstraints = false
        button.adjustsImageSizeForAccessibilityContentSizeCategory = false
        button.configuration                             = config
        
        return button
    }()
    
    private(set) var sendEditMessageButton: UIButton = {
        let sendEditMessageButton = UIButton()
        sendEditMessageButton.configuration                             = .filled()
        sendEditMessageButton.configuration?.image                      = UIImage(systemName: "checkmark")
        sendEditMessageButton.configuration?.baseBackgroundColor        = ColorScheme.sendMessageButtonBackgroundColor
//        sendEditMessageButton.layer.cornerRadius                        = sendEditMessageButton.frame.size.width / 2.0
        sendEditMessageButton.clipsToBounds                             = true
        sendEditMessageButton.isHidden                                  = true
        sendEditMessageButton.translatesAutoresizingMaskIntoConstraints = false
        sendEditMessageButton.adjustsImageSizeForAccessibilityContentSizeCategory = false 
        
        return sendEditMessageButton
    }()
    
    lazy private(set) var scrollBadgeButton: UIButton = {
        let scrollToBottomBtn = UIButton(type: .custom)
        scrollToBottomBtn.configuration  = .bordered()

        let image = UIImage(named: "angle-arrow-down")
        let imageSize = inputBarButtonsSize - 20
        let targetSize = CGSize(width: imageSize, height: imageSize)
        let resizedImage = image?.resize(to: targetSize)

        scrollToBottomBtn.configuration?.image = resizedImage?.withRenderingMode(.alwaysTemplate)
        
        scrollToBottomBtn.configuration?.background.strokeColor = #colorLiteral(red: 0.470990181, green: 0.3475213647, blue: 0.4823801517, alpha: 1)
        scrollToBottomBtn.configuration?.background.strokeWidth = 0.5
        scrollToBottomBtn.configuration?.background.cornerRadius = inputBarButtonsSize / 2
        
        scrollToBottomBtn.configuration?.baseForegroundColor = .systemGray
        scrollToBottomBtn.configuration?.baseBackgroundColor = ColorScheme.messageTextFieldBackgroundColor
        scrollToBottomBtn.translatesAutoresizingMaskIntoConstraints = false

//        scrollToBottomBtn.configuration?.contentInsets = .init(top: 5, leading: 5, bottom: 5, trailing: 5)
        scrollToBottomBtn.layer.opacity = 0.0
        scrollToBottomBtn.adjustsImageSizeForAccessibilityContentSizeCategory = false

        return scrollToBottomBtn
    }()
    
    private(set) lazy var joinChatRoomButton: UIButton = {
        let joinButton = UIButton()
        joinButton.configuration                             = .plain()
        joinButton.configuration?.title                      = "Join"
        joinButton.configuration?.baseForegroundColor        = ColorScheme.actionButtonsTintColor
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
        scrollBadgeButton.heightAnchor.constraint(equalToConstant: inputBarButtonsSize).isActive                                        = true
        scrollBadgeButton.widthAnchor.constraint(equalToConstant: inputBarButtonsSize).isActive                                         = true
    }
    var scrollToBottomBtnBottomConstraint: NSLayoutConstraint!

    // MARK: Internal variables
    var tableViewInitialTopInset: CGFloat
    {
        let keyboardHeight = KeyboardService.shared.keyboardHeight
        return isKeyboardShown() ? CGFloat(keyboardHeight - 30) : CGFloat(0)
    }
    
    // MARK: - LIFECYCLE
    
    let backgroungImage: UIImage
    
    init(backgroundImage: UIImage)
    {
        self.backgroungImage = backgroundImage
        super.init(frame: .zero)
        setupLayout()
    }
    
//    override init(frame: CGRect)
//    {
//        super.init(frame: frame)
//        setupLayout()
//    }
    
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
        print("ChatRoomRootView deinit")
    }

    // MARK: - SETUP CONSTRAINTS
    
    private func setupLayout()
    {
        setupTableViewConstraints()
        setupInputBarContainerConstraints()
        setupMessageTextViewConstraints()
        setupSendMessageBtnConstraints()
        setupAudioRecordButtonConstraints()
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
        let height = isInputBarHeaderRemoved ? 45.0 : -45.0
        
        // Use adjustedContentInset (the REAL effective inset)
        let currentRelativeOffset = tableView.contentOffset.y + tableView.adjustedContentInset.top
        
        tableView.contentInset.top -= height
        tableView.verticalScrollIndicatorInsets.top -= height
        
        let newOffset = currentRelativeOffset - tableView.adjustedContentInset.top
        tableView.setContentOffset(CGPoint(x: 0, y: newOffset), animated: false)
    }
    
    func setTextViewDelegate(to delegate: UITextViewDelegate) {
        messageTextView.delegate = delegate
    }
    
    func setInputBarParametersVisibility(shouldHideJoinButton: Bool, shouldAnimate: Bool = false)
    {
//        joinChatRoomButton.isHidden = shouldHideJoinButton
//        
//        self.messageTextView.layer.opacity = 0.0
//        self.voiceRecButton.layer.opacity = 0.0
//        self.addPictureButton.layer.opacity = 0.0
//        self.textViewTrailingItemView.layer.opacity = 0.0
//        
//        UIView.animate(withDuration: shouldAnimate ? 0.5 : 0.0)
//        {
//            self.messageTextView.isHidden = !shouldHideJoinButton
//            self.voiceRecButton.isHidden = !shouldHideJoinButton
//            self.addPictureButton.isHidden = !shouldHideJoinButton
//            self.textViewTrailingItemView.isHidden = !shouldHideJoinButton
//            
//            self.messageTextView.layer.opacity = 1.0
//            self.voiceRecButton.layer.opacity = 1.0
//            self.addPictureButton.layer.opacity = 1.0
//            self.textViewTrailingItemView.layer.opacity = 1.0
//        }
    }
 
    func toggleVoiceRecButtonVisibility(_ isShown: Bool)
    {
//        sendMessageButtonPropertyAnimator?.stopAnimation(true)
//        sendMessageButtonPropertyAnimator = nil
//        
//        // Determine which buttons to animate
//        let buttonToShow = isShown ? voiceRecButton : sendMessageButton
//        let buttonToHide = isShown ? sendMessageButton : voiceRecButton
//        
//        buttonToShow.isHidden = false
//        buttonToShow.transform = CGAffineTransform(scaleX: 0.01, y: 0.01)
//        
//        sendMessageButtonPropertyAnimator = UIViewPropertyAnimator.runningPropertyAnimator(
//            withDuration: 0.1,
//            delay: 0.0,
//            animations: {
//                buttonToHide.transform = CGAffineTransform(scaleX: 1.2, y: 1.2)
//            },
//            completion: { [weak self] _ in
//                self?.sendMessageButtonPropertyAnimator = UIViewPropertyAnimator.runningPropertyAnimator(
//                    withDuration: 0.2,
//                    delay: 0.0,
//                    animations: {
//                        buttonToHide.transform = CGAffineTransform(scaleX: 0.01, y: 0.01)
//                        buttonToShow.transform = .identity
//                    },
//                    completion: { _ in
//                        buttonToHide.isHidden = true
//                    }
//                )
//            }
//        )
    }
}

//MARK: - Voice rec setup
extension ChatRoomRootView
{
    func setupVoiceRecUIComponents()
    {
        toggleMessageTextviewInteraction(isDisabled: true)
        createRecLabelsStackView()
        resizeSendMessageButtonWithAnimation(aniamationState: .creation)
        animateRecLabelsStackViewAppearance(animationState: .creation)
        animateRedDotBlink()
        setupCancelRecButton()
        animateCancelButtonAppearnace(animationState: .creation)
        animateTextViewResize(animationState: .creation)
        animateStickerIconVisibility(animationState: .destruction)
    }
    
    func destroyVoiceRecUIComponents()
    {
        resizeSendMessageButtonWithAnimation(aniamationState: .destruction)
        animateCancelButtonAppearnace(animationState: .destruction)
        animateRecLabelsStackViewAppearance(animationState: .destruction)
        animateTextViewResize(animationState: .destruction)
        animateStickerIconVisibility(animationState: .creation)
        
        executeAfter(seconds: 0.4) { [weak self] in
            self?.recLabelsStackView?.arrangedSubviews.forEach { view in
                self?.recLabelsStackView?.removeArrangedSubview(view)
                view.removeFromSuperview()
            }
            self?.recLabelsStackView?.removeFromSuperview()
            self?.cancelRecButton?.removeFromSuperview()
            
            self?.recLabelsStackView = nil
            self?.recCounterLabel = nil
            self?.recRedDotView = nil
            self?.cancelRecButton = nil
        }
        toggleMessageTextviewInteraction(isDisabled: false)
        cancelButtonCenterXConstraint = nil
    }
    
    func toggleMessageTextviewInteraction(isDisabled: Bool)
    {
        messageTextView.isInputDisabled = isDisabled
    }
    
    private func animateCancelButtonAppearnace(animationState: AnimationState)
    {
        self.layoutIfNeeded()
        UIView.animate(withDuration: 0.2, delay: 0.0, animations: {
            self.cancelRecButton?.alpha = animationState == .creation ? 1.0 : 0.0
            self.cancelButtonCenterXConstraint?.constant = 20
        })
    }
    
    private func animateStickerIconVisibility(animationState: AnimationState)
    {
        UIView.animate(withDuration: 0.15) {
            self.textViewTrailingItemView.alpha = animationState == .creation ? 1.0 : 0.0
        }
    }
    
    private func animateRecLabelsStackViewAppearance(animationState: AnimationState)
    {
        self.layoutIfNeeded()
        UIView.animate(withDuration: 0.25) {
            self.recLabelsStackView?.alpha = animationState == .creation ? 1.0 : 0.0
        }
    }
    
    private func resizeSendMessageButtonWithAnimation(aniamationState: AnimationState)
    {
        if aniamationState == .creation
        {
            UIView.animate(withDuration: 0.15)
            {
                self.voiceRecButton.transform = CGAffineTransform(scaleX: 0.01, y: 0.01)
                self.sendMessageButton.isHidden = false
                self.sendMessageButton.transform = CGAffineTransform(scaleX: 1.3, y: 1.3)
            } completion: { _ in
                UIView.animate(withDuration: 0.1, delay: 0.0, options: [.curveEaseIn]) {
                    self.sendMessageButton.transform = CGAffineTransform(scaleX: 1.0, y: 1.0)
                } completion: { _ in
                    UIView.animate(withDuration: 0.1, delay: 0.0, options: [.curveEaseOut]) {
                        self.sendMessageButton.transform = CGAffineTransform(scaleX: 1.1, y: 1.1)
                    }
                }
                self.voiceRecButton.isHidden = true
            }
            
            return
        }
        
        self.voiceRecButton.isHidden = false
        
        UIView.animate(withDuration: 0.15)
        {
            self.sendMessageButton.transform = CGAffineTransform(scaleX: 0.01, y: 0.01)
            self.voiceRecButton.transform = .identity
        } completion: { _ in
            self.sendMessageButton.isHidden = true
        }
    }
    
    private func animateRedDotBlink()
    {
        recRedDotView?.alpha = 1.0
        
        UIView.animate(withDuration: 0.5, delay: 0.3, options: [.repeat, .autoreverse])
        {
            self.recRedDotView?.alpha = 0.0
        }
    }
    
    private func animateTextViewResize(animationState: AnimationState)
    {
        UIView.animate(withDuration: 0.3, delay: 0.0, options: [.curveEaseOut])
        {
            self.textViewLeadingConstraint.constant = animationState == .creation ? 8 : 48
            self.addPictureButton.transform = animationState == .creation ? .init(translationX: -30, y: 0.0) : .identity
            self.layoutIfNeeded()
        }
    }
    
    private func createRecLabelsStackView()
    {
        self.recLabelsStackView = UIStackView()
        recLabelsStackView?.axis = .horizontal
        recLabelsStackView?.spacing = 5
        recLabelsStackView?.translatesAutoresizingMaskIntoConstraints = false
        
        self.recRedDotView = makeRecRedDotView()
        self.recCounterLabel = makeRecCounterLabel()
        
        recLabelsStackView?.addArrangedSubview(self.recRedDotView!)
        recLabelsStackView?.addArrangedSubview(self.recCounterLabel!)
        recLabelsStackView?.alpha = 0.0
        
        inputBarContainer.addSubview(recLabelsStackView!)
        
        NSLayoutConstraint.activate([
            recLabelsStackView!.leadingAnchor.constraint(equalTo: messageTextView.leadingAnchor, constant: 15),
            recLabelsStackView!.centerYAnchor.constraint(equalTo: messageTextView.centerYAnchor),
        ])
    }
    
    func makeRecRedDotView() -> UIView
    {
        let dot = UIView()
        dot.translatesAutoresizingMaskIntoConstraints = false
        dot.backgroundColor = .red
        dot.layer.cornerRadius = 5  // half of 10

        NSLayoutConstraint.activate([
            dot.widthAnchor.constraint(equalToConstant: 10),
            dot.heightAnchor.constraint(equalToConstant: 10)
        ])

        return dot
    }
    
    func makeRecCounterLabel() -> UILabel
    {
        let label = UILabel()
        label.numberOfLines = 1
        label.text = "00:00"
        label.font = UIFont.systemFont(ofSize: 14, weight: .medium)
        label.textColor = .white
        
        return label
    }
    
    private func setupCancelRecButton()
    {
        self.cancelRecButton = UIButton(type: .custom)
        self.cancelRecButton?.setTitle("Cancel", for: .normal)
        self.cancelRecButton?.titleLabel?.font = .systemFont(ofSize: 16, weight: .medium)
        self.cancelRecButton?.setTitleColor(ColorScheme.actionButtonsTintColor, for: .normal)
        self.cancelRecButton?.translatesAutoresizingMaskIntoConstraints = false
        self.cancelRecButton?.addTarget(self, action: #selector(cancelVoiceRecording), for: .touchUpInside)
        self.cancelRecButton?.alpha = 0.0
        
        inputBarContainer.addSubview(cancelRecButton!)
        
        self.cancelButtonCenterXConstraint = self.cancelRecButton!.centerXAnchor.constraint(
            equalTo: messageTextView.centerXAnchor,
            constant: 100
        )
        cancelButtonCenterXConstraint?.isActive = true
        
        NSLayoutConstraint.activate([
            self.cancelRecButton!.centerYAnchor.constraint(equalTo: messageTextView.centerYAnchor),
        ])
    }
    
    @objc func cancelVoiceRecording()
    {
        self.cancelRecordingSubject.send()
    }
    
    func updateRecCounterLabelText(with time: String)
    {
        recCounterLabel?.text = time
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
            tailingView.centerYAnchor.constraint(equalTo: messageTextView.centerYAnchor),
//            tailingView.bottomAnchor.constraint(equalTo: messageTextView.bottomAnchor, constant: -3),
        ])
    }
    
    private func initiateStickersViewSetup()
    {
        let stickerCollectionView = StickersPackCollectionView()
        addSubview(stickerCollectionView)
        self.stickerCollectionView = stickerCollectionView
        
        stickerCollectionView.translatesAutoresizingMaskIntoConstraints = false
        
        self.stickerCollectionViewTopConstraint = stickerCollectionView.topAnchor.constraint(equalTo: inputBarContainer.bottomAnchor, constant: -25)
        
        NSLayoutConstraint.activate([
            stickerCollectionViewTopConstraint!,
            stickerCollectionView.bottomAnchor.constraint(equalTo: self.bottomAnchor, constant: 3),
            stickerCollectionView.trailingAnchor.constraint(equalTo: self.trailingAnchor, constant: 1),
            stickerCollectionView.leadingAnchor.constraint(equalTo: self.leadingAnchor, constant: -1),
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
            inputBarHeader?.transform = CGAffineTransform(translationX: 0, y: 80)
            self.layoutIfNeeded()
            
            UIView.animate(withDuration: 0.3)
            {
                self.inputBarContainer.pinBlurTopConstraint(to: self.inputBarHeader!)
                self.inputBarHeader?.transform = .identity
                self.updateTableViewContentAttributes(isInputBarHeaderRemoved: false)
                self.scrollToBottomBtnBottomConstraint.constant -= 45
                self.layoutIfNeeded()
            }
        } else {
            self.inputBarHeader?.applyMode(mode)
            self.inputBarHeader?.animateComponents(isUpdating: true)
            if !mode.isImage && messageTextView.text.isEmpty && voiceRecButton.isHidden
            {
                toggleVoiceRecButtonVisibility(true)
            }
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
//        inputBarContainer.sendSubviewToBack(inputBarHeader!)
        inputBarContainer.bringSubviewToFront(inputBarHeader!)
        
        inputBarHeader!.translatesAutoresizingMaskIntoConstraints                              = false
        inputBarHeader!.leadingAnchor.constraint(equalTo: self.leadingAnchor).isActive         = true
        inputBarHeader!.trailingAnchor.constraint(equalTo: self.trailingAnchor).isActive       = true
        inputBarHeader!.bottomAnchor.constraint(equalTo: inputBarContainer.topAnchor).isActive = true
    }
    
    private func setupAddPictureButtonConstrains()
    {
        self.addSubviews(addPictureButton)
        
        NSLayoutConstraint.activate([
            addPictureButton.trailingAnchor.constraint(equalTo: messageTextView.leadingAnchor,
                                                       constant: -6),
            addPictureButton.topAnchor.constraint(equalTo: inputBarContainer.topAnchor,
                                                  constant: inputBarViewsTopConstraintConstant),
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
            tableView.topAnchor.constraint(equalTo: self.topAnchor),
        ])
    }
    
    private func setupMessageTextViewConstraints()
    {
        inputBarContainer.addSubview(messageTextView)
        
        textViewHeightConstraint           = messageTextView.heightAnchor.constraint(equalToConstant: inputBarButtonsSize )
        textViewHeightConstraint.isActive  = true
        textViewHeightConstraint.priority  = .required
        textViewLeadingConstraint          = messageTextView.leadingAnchor.constraint(equalTo: inputBarContainer.leadingAnchor, constant: 48)
        textViewLeadingConstraint.isActive = true
        
        NSLayoutConstraint.activate([
            messageTextView.bottomAnchor.constraint(equalTo: inputBarContainer.bottomAnchor, constant: -inputBarContainer.bounds.height * 0.52),
//            messageTextView.heightAnchor.constraint(equalToConstant: inputBarButtonsSize),
//            messageTextView.widthAnchor.constraint(equalToConstant: inputBarButtonsSize),
            messageTextView.trailingAnchor.constraint(equalTo: inputBarContainer.trailingAnchor, constant: -50),
//            messageTextView.leadingAnchor.constraint(equalTo: inputBarContainer.leadingAnchor, constant: 48),
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
    
    private func setupAudioRecordButtonConstraints()
    {
        inputBarContainer.addSubview(voiceRecButton)
        
        NSLayoutConstraint.activate([
            voiceRecButton.leadingAnchor.constraint(equalTo: messageTextView.trailingAnchor, constant: 5),
            voiceRecButton.topAnchor.constraint(equalTo: inputBarContainer.topAnchor, constant: inputBarViewsTopConstraintConstant),
            voiceRecButton.heightAnchor.constraint(equalToConstant: inputBarButtonsSize),
            voiceRecButton.widthAnchor.constraint(equalToConstant: inputBarButtonsSize),
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
//        let backgroundImageView = UIImageView(image: UIImage(named: "chat_background_theme_1"))
        let backgroundImageView = UIImageView(image: backgroungImage)
        backgroundImageView.contentMode = .scaleAspectFill
        backgroundImageView.frame = view.bounds
        backgroundImageView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        backgroundImageView.transform = CGAffineTransform(scaleX: 1, y: -1)
        view.addSubview(backgroundImageView)
        return view
    }
    
    private func createBackgroundBlurEffect(for imageView: UIView)
    {
        let blurEffect = UIBlurEffect(style: .systemMaterialDark)
        let blurEffectView = UIVisualEffectView(effect: blurEffect)
        blurEffectView.alpha = 0.2
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


enum AnimationState
{
    case creation
    case destruction
}
