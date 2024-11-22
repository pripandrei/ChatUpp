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

final class ConversationRootView: UIView {
    
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
        tableView.register(ConversationTableViewCell.self, forCellReuseIdentifier: ReuseIdentifire.ConversationTableCell.message.identifire)
        tableView.register(SkeletonViewCell.self, forCellReuseIdentifier: ReuseIdentifire.ConversationTableCell.messageSekeleton.identifire)
        tableView.register(FooterSectionView.self, forHeaderFooterViewReuseIdentifier: ReuseIdentifire.HeaderFooter.footer.identifire)
        tableView.register(ConversationTableViewTitleCell.self, forCellReuseIdentifier: ReuseIdentifire.ConversationTableCell.unseenTitle.identifire)
        
        
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "cell")
        
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
        messageTextView.isScrollEnabled                           = false
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
    
    private(set) var scrollToBottomBtn: UIButton = {
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
    
    private func setupScrollToBottomBtn() {
        addSubview(scrollToBottomBtn)
        
        scrollToBottomBtnBottomConstraint = scrollToBottomBtn.bottomAnchor.constraint(equalTo: inputBarContainer.topAnchor, constant: -10)
        scrollToBottomBtnBottomConstraint.isActive = true
        
        scrollToBottomBtn.trailingAnchor.constraint(equalTo: inputBarContainer.trailingAnchor, constant: -10).isActive = true
//        scrollToBottomBtn.bottomAnchor.constraint(equalTo: inputBarContainer.topAnchor, constant: -10).isActive        = true
        scrollToBottomBtn.heightAnchor.constraint(equalToConstant: 35).isActive                                        = true
        scrollToBottomBtn.widthAnchor.constraint(equalToConstant: 35).isActive                                         = true
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
    
    private func setupLayout() {
        setupTableViewConstraints()
        setupInputBarContainerConstraints()
        setupMessageTextViewConstraints()
        setupSendMessageBtnConstraints()
        setupAddPictureButtonConstrains()
        setupSendEditMessageButtonConstraints()
        setupScrollToBottomBtn()
        setupUnseenMessageCounterBadgeConstraints()
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
}

// MARK: - SETUP EDIT VIEW
extension ConversationRootView 
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
extension ConversationRootView
{
    private func setupUnseenMessageCounterBadgeConstraints() 
    {
        scrollToBottomBtn.addSubview(unseenMessagesBadge)
        NSLayoutConstraint.activate([
            unseenMessagesBadge.centerXAnchor.constraint(equalTo: scrollToBottomBtn.centerXAnchor),
            unseenMessagesBadge.topAnchor.constraint(equalTo: scrollToBottomBtn.topAnchor, constant: -10),
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

// MARK: - Modified container for gesture trigger
final class InputBarContainer: UIView
{
    // since closeImageView frame is not inside it's super view (inputBarContainer)
    // gesture recognizer attached to it will not get triggered
    // so we need to override point to return true in case it matches the location in coordinate of closeImageView
    
    override func point(inside point: CGPoint, with event: UIEvent?) -> Bool
    {
        if super.point(inside: point, with: event) {return true}
        
        for subview in subviews {
            let subviewPoint = subview.convert(point, from: self)
            if subview.point(inside: subviewPoint, with: event) {
                return true
            }
        }
        return false
    }
}

// MARK: - SETUP NAVIGATION BAR ITEMS
final class ConversationCustomNavigationBar {
    
    private let viewController: UIViewController!
    var navigationItemsContainer: NavigationTitleContainer!
    
    init(viewController: UIViewController) {
        self.viewController = viewController
    }
    
    func setupNavigationBarItems(with imageData: Data?, memberName: String, memberActiveStatus: String) {
        
        guard let image = (imageData != nil) ? UIImage(data: imageData!) : UIImage(named: "default_profile_photo") else {return}
        navigationItemsContainer = NavigationTitleContainer(name: memberName, lastSeen: memberActiveStatus, image: image)
        
        let imageView = NavigationProfileImageView(image: image)
        let barButtonItem = UIBarButtonItem(customView: imageView)
        
        viewController.navigationItem.rightBarButtonItem = barButtonItem
        viewController.navigationItem.titleView = navigationItemsContainer
    }
}

//MARK: - Navigation items conteiner view

extension ConversationCustomNavigationBar 
{
    final class NavigationTitleContainer: UIView {
        let nameLabel: UILabel
        let lastSeenLabel: UILabel
        
        private var temporaryDimmView: UIView!
        private var temporaryImageView: UIView!
        
        init(name: String, lastSeen: String, image: UIImage) {
            nameLabel = UILabel()
            lastSeenLabel = UILabel()
            
            super.init(frame: .zero)
            
            setupViews(name: name, lastSeen: lastSeen)
        }
        
        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
        
        private func setupViews(name: String, lastSeen: String) {
            nameLabel.text = name
            nameLabel.textColor = .white
            nameLabel.font = UIFont(name:"HelveticaNeue-Bold", size: 17)
            nameLabel.textAlignment = .center
            
            lastSeenLabel.text = lastSeen == "online" ? lastSeen : "last seen \(lastSeen)"
            lastSeenLabel.font = UIFont(name:"HelveticaNeue", size: 13)
            lastSeenLabel.textColor = .white

            let stackView = UIStackView(arrangedSubviews: [nameLabel, lastSeenLabel])
            
            stackView.axis = .vertical
            stackView.alignment = .center
//            stackView.distribution = .fillEqually
            
            stackView.translatesAutoresizingMaskIntoConstraints = false
            addSubview(stackView)
            
            NSLayoutConstraint.activate([
                stackView.topAnchor.constraint(equalTo: topAnchor),
                stackView.bottomAnchor.constraint(equalTo: bottomAnchor),
                stackView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 0),
                stackView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: 0),
                widthAnchor.constraint(equalToConstant: 200)
            ])
        }
    }
    
    class NavigationProfileImageView: UIImageView {
        
        private var temporaryDimmView:  UIView!
        private var temporaryImageView: UIView!
        private var initialImageFrame:  CGRect!
        private let profileImageSize:   CGFloat = 38
        
        override init(image: UIImage?) {
            super.init(image: image)
            setupSelf()
        }
        
        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
        
        private func setupSelf() {
            let tapGesture = UITapGestureRecognizer(target: self, action: #selector(animateProfileImage))
            addGestureRecognizer(tapGesture)

            contentMode                               = .scaleToFill
            layer.cornerRadius                        = profileImageSize / 2
            clipsToBounds                             = true
            translatesAutoresizingMaskIntoConstraints = false
            
            widthAnchor.constraint(equalToConstant: profileImageSize).isActive  = true
            heightAnchor.constraint(equalToConstant: profileImageSize).isActive = true
        }
        
        @objc func animateProfileImage() {
            guard let window                      = window else { return }
            temporaryDimmView                     = setupTemporaryDimmView(withFrame: window.frame)
            temporaryImageView                    = setupTemporaryImageView()
            
            self.isHidden = true
            UIView.animate(withDuration: 0.5, animations: {
                self.temporaryImageView.center    = window.center
                self.temporaryImageView.transform = CGAffineTransform(scaleX: 8, y: 8)
                self.temporaryDimmView.alpha      = 1
            })
        }
        
        private func setupTemporaryImageView() -> UIView {
            initialImageFrame                    = self.convert(self.bounds, to: window)
            
            let animatedImageView                = UIImageView(frame: initialImageFrame)
            animatedImageView.image              = self.image
            animatedImageView.layer.cornerRadius = profileImageSize / 2
            animatedImageView.contentMode        = .scaleToFill
            animatedImageView.clipsToBounds      = true
            window?.addSubview(animatedImageView)
            
            return animatedImageView
        }
        
        private func setupTemporaryDimmView(withFrame frame: CGRect) -> UIView {
            let dimmView             = UIView(frame: frame)
//            dimmView.backgroundColor = .black
            dimmView.alpha           = 0
            window?.addSubview(dimmView)
            
            let blurEffect = UIBlurEffect(style: .systemThickMaterialDark)
            let blurEffectView = UIVisualEffectView(effect: blurEffect)
            blurEffectView.frame = dimmView.bounds
            dimmView.addSubview(blurEffectView)
            
            let tapGesture           = UITapGestureRecognizer(target: self, action: #selector(dismissProfileImage))
            dimmView.addGestureRecognizer(tapGesture)
            
            return dimmView
        }
        
        @objc func dismissProfileImage(_ sender: UITapGestureRecognizer) {
            UIView.animate(withDuration: 0.5) {
                self.temporaryDimmView.alpha        = 0
                self.temporaryImageView.transform.a = 1
                self.temporaryImageView.transform.d = 1
                self.temporaryImageView.frame       = self.initialImageFrame
            } completion: { _ in
                self.temporaryDimmView.removeFromSuperview()
                self.temporaryImageView.removeFromSuperview()
                self.temporaryDimmView  = nil
                self.temporaryImageView = nil
                self.isHidden           = false
            }
        }
    }
}
