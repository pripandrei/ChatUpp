//
//  ConversationViewControllerUI.swift
//  ChatUpp
//
//  Created by Andrei Pripa on 11/4/23.
//

import Foundation
import UIKit

final class ConversationRootView: UIView {
    
    // MARK: - UI Elements
    
    private(set) var editView                : EditView?
    private(set) var inputBarBottomConstraint: NSLayoutConstraint!
    private(set) var textViewHeightConstraint: NSLayoutConstraint!

    private(set) var inputBarContainer: InputBarContainer = {
        let inputBarContainer = InputBarContainer()
        inputBarContainer.backgroundColor                           = #colorLiteral(red: 0.1677602232, green: 0.3210971653, blue: 0.4742530584, alpha: 1)
        inputBarContainer.bounds.size.height                        = 80
        inputBarContainer.translatesAutoresizingMaskIntoConstraints = false
        
        return inputBarContainer
    }()
    
    private(set) var tableView: UITableView = {
        let tableView                           = UITableView()
        tableView.transform                     = CGAffineTransform(scaleX: 1, y: -1) // Revert table view upside down
        tableView.backgroundColor               = #colorLiteral(red: 0.1411764771, green: 0.3960784376, blue: 0.5647059083, alpha: 1)
        tableView.contentInset                  = UIEdgeInsets(top: 0, left: 0, bottom: 60, right: 0)
        tableView.verticalScrollIndicatorInsets = UIEdgeInsets(top: -10, left: 0, bottom: 70, right: 0)
        tableView.separatorStyle                = .none
        tableView.sectionHeaderTopPadding       = 0
        tableView.register(ConversationTableViewCell.self, forCellReuseIdentifier: CellIdentifire.conversationMessageCell)
        
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
        scrollToBottomBtn.clipsToBounds                             = true
        scrollToBottomBtn.backgroundColor                           = #colorLiteral(red: 0.1677602232, green: 0.3210971653, blue: 0.4742530584, alpha: 1)
        scrollToBottomBtn.translatesAutoresizingMaskIntoConstraints = false
        scrollToBottomBtn.layer.borderWidth = 0.25
        scrollToBottomBtn.layer.borderColor = #colorLiteral(red: 0.2599526346, green: 0.5381836295, blue: 0.7432311773, alpha: 1)
//        scrollToBottomBtn.isHidden = true
        scrollToBottomBtn.layer.opacity = 0.0

        return scrollToBottomBtn
    }()
    
//    lazy private(set) var scrollToBottomBtn: UIImageView = {
//        let scrollToBottomBtn                                       = UIImageView()
//        scrollToBottomBtn.bounds.size                               = CGSize(width: 35, height: 35) // size is used only for radius calculation
//        let image = UIImage(systemName: "arrow.down")?.withTintColor(.white, renderingMode: .alwaysOriginal)
////        let image = UIImage(systemName: "arrow.down")?.resizableImage(withCapInsets: UIEdgeInsets(top: 5, left: 5, bottom: 5, right: 5), resizingMode: .tile)
//        let newimage = resizeImage(image: image!, targetSize: CGSize(width: 22, height: 22))
//        scrollToBottomBtn.image = image
//        scrollToBottomBtn.layer.cornerRadius                        = scrollToBottomBtn.bounds.size.width / 2
//        scrollToBottomBtn.clipsToBounds                             = true
//        scrollToBottomBtn.backgroundColor                           = #colorLiteral(red: 0.1677602232, green: 0.3210971653, blue: 0.4742530584, alpha: 1)
//        scrollToBottomBtn.translatesAutoresizingMaskIntoConstraints = false
//        scrollToBottomBtn.layer.borderWidth = 0.25
//        scrollToBottomBtn.layer.borderColor = #colorLiteral(red: 0.2599526346, green: 0.5381836295, blue: 0.7432311773, alpha: 1)
//        scrollToBottomBtn.isUserInteractionEnabled = true
//        scrollToBottomBtn.contentMode = .center
//        return scrollToBottomBtn
//    }()
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
    }
    
    // MARK: Private functions
    
    private func isKeyboardShown() -> Bool {
        return messageTextView.isFirstResponder
    }
    
    // MARK: - Internal functions
    
    func updateTableViewContentOffset(isEditViewRemoved: Bool) {
        //because tableview is inverted we should perform operations vice versa
        let height = isEditViewRemoved ? 45.0 : -45.0
        tableView.setContentOffset(CGPoint(x: 0, y: height + tableView.contentOffset.y), animated: false)
    }
    
    func setTextViewDelegate(to delegate: UITextViewDelegate) {
        messageTextView.delegate = delegate
    }
}

// MARK: - SETUP EDIT VIEW
extension ConversationRootView {
    private func setupEditView() {
        editView = EditView()
        
        setupEditViewConstraints()
        editView!.setupSubviews()
    }
    
    func activateEditView() {
        setupEditView()
        
        updateTableViewContentOffset(isEditViewRemoved: false)
        sendEditMessageButton.isHidden = false
        scrollToBottomBtnBottomConstraint.constant -= 45
        
        self.layoutIfNeeded()
    }
    
    func destroyEditedView() {
        editView?.removeSubviews()
        editView?.removeFromSuperview()
        editView = nil
    }
}

// MARK: - SETUP SUBVIEW'S CONSTRAINTS
extension ConversationRootView {
    
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
    // since closeImageView frame is not inside it's super view (editViewContainer)
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
    
    init(viewController: UIViewController) {
        self.viewController = viewController
    }
    
    func setupNavigationBarItems(with imageData: Data, memberName: String) {
        let customTitleView = UIView()
        
        if let image = UIImage(data: imageData)
        {
            let imageView                = UIImageView(image: image)
            imageView.contentMode        = .scaleAspectFit
            imageView.frame              = CGRect(x: 0, y: 0, width: 40, height: 40)
            imageView.layer.cornerRadius = 20
            imageView.clipsToBounds      = true
            imageView.center             = imageView.convert(CGPoint(x: ((viewController.navigationController?.navigationBar.frame.width)! / 2) - 40, y: 0),
                                                             from: viewController.view)
            customTitleView.addSubview(imageView)
            
            let titleLabel           = UILabel()
            titleLabel.frame         = CGRect(x: 0, y: 0, width: 200, height: 20)
            titleLabel.center        = titleLabel.convert(CGPoint(x: 0, y: 0), from: viewController.view)
            titleLabel.text          = memberName
            titleLabel.textAlignment = .center
            titleLabel.textColor     = UIColor.white
            titleLabel.font          = UIFont(name:"HelveticaNeue-Bold", size: 17)
            customTitleView.addSubview(titleLabel)
            
            viewController.navigationItem.titleView = customTitleView
        }
    }
}
