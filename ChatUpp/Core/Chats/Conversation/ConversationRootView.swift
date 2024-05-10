//
//  ConversationViewControllerUI.swift
//  ChatUpp
//
//  Created by Andrei Pripa on 11/4/23.
//

import Foundation
import UIKit

final class ConversationRootView: UIView {
    
    private(set) var messageTextViewNumberOfLines  = 1
    private(set) var inputBarContainer             = InputBarContainer()
    private(set) var messageTextView               = UITextView()
    private(set) var sendMessageButton             = UIButton()
    private(set) var addPictureButton              = UIButton()
    private(set) var sendEditMessageButton         = UIButton()
    private(set) var editView                      : EditView?
    private(set) var inputBarBottomConstraint      : NSLayoutConstraint!
    
    var tableViewInitialContentOffset              = CGPoint(x: 0, y: 0)
    lazy var textViewHeightConstraint              = messageTextView.heightAnchor.constraint(equalToConstant: 31)
    
    let tableView: UITableView = {
        let tableView                           = UITableView()
        tableView.backgroundColor               = #colorLiteral(red: 0.1411764771, green: 0.3960784376, blue: 0.5647059083, alpha: 1)
        tableView.transform                     = CGAffineTransform(scaleX: 1, y: -1)
        tableView.contentInset                  = UIEdgeInsets(top: 0, left: 0, bottom: 60, right: 0)
        tableView.verticalScrollIndicatorInsets = UIEdgeInsets(top: -10, left: 0, bottom: 70, right: 0)
        tableView.separatorStyle                = .none
        tableView.sectionHeaderTopPadding       = 0
        tableView.register(ConversationTableViewCell.self, forCellReuseIdentifier: CellIdentifire.conversationMessageCell)
        return tableView
    }()
    
    var tableViewInitialTopInset: CGFloat {
        return isKeyboardShown() ? CGFloat(336) : CGFloat(0)
    }
    
    // MARK: - VIEW LAYOUT SETUP
    
    private func setupLayout() {
        setupTableView()
        setupHolderView()
        setupMessageTextView()
        setupSendMessageBtn()
        setupAddPictureButton()
        setupSendEditMessageButton()
    }

    private func isKeyboardShown() -> Bool {
        return messageTextView.isFirstResponder
    }
    
    // MARK: - LIFECYCLE
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupLayout()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - SETUP EDIT VIEW
    
//    private(set) var editViewContainer : UIView?
//    private(set) var closeEditView     : UIImageView?
//    private var editLabel              : UILabel?
//    private var editMessageText        : UILabel?
//    private var separatorLabel         : UILabel?
//    private var editPenIcon            : UIImageView?
//
//    private func setupEditView() {
//        editViewContainer                  = UIView()
//        editViewContainer?.backgroundColor = #colorLiteral(red: 0.1677602232, green: 0.3210971653, blue: 0.4742530584, alpha: 1)
//
//        inputBarContainer.addSubview(editViewContainer!)
//        inputBarContainer.sendSubviewToBack(editViewContainer!)
//
//        editViewContainer?.translatesAutoresizingMaskIntoConstraints                          = false
//        editViewContainer?.trailingAnchor.constraint(equalTo: self.trailingAnchor).isActive   = true
//        editViewContainer?.leadingAnchor.constraint(equalTo: self.leadingAnchor).isActive     = true
//        editViewContainer?.bottomAnchor.constraint(equalTo: inputBarContainer.topAnchor).isActive = true
//
//        editeViewContainerHeightConstraint           = editViewContainer?.heightAnchor.constraint(equalToConstant: 45)
//        editeViewContainerHeightConstraint?.isActive = true
//    }
//
//    var editeViewContainerHeightConstraint: NSLayoutConstraint?
//
//    private func setupEditLabel() {
//        editLabel = UILabel()
//
//        editLabel?.text                                      = "Edit Message"
//        editLabel?.textColor                                 = #colorLiteral(red: 0.2392156869, green: 0.6745098233, blue: 0.9686274529, alpha: 1)
//        editLabel?.font                                      = UIFont.boldSystemFont(ofSize: 15)
//        editLabel?.translatesAutoresizingMaskIntoConstraints = false
//        editViewContainer?.addSubview(editLabel!)
//
//        editLabel?.topAnchor.constraint(equalTo: editViewContainer!.topAnchor, constant: 8).isActive                             = true
//        editLabel?.leadingAnchor.constraint(equalTo: editViewContainer!.leadingAnchor, constant: self.bounds.width / 5).isActive = true
//    }
//    private func setupEditMessage() {
//        editMessageText                                            = UILabel()
//        editMessageText?.text                                      = "Test Message here for testing purposes only test test"
//        editMessageText?.textColor                                 = .white
//        editMessageText?.font                                      = UIFont(name: "Helvetica", size: 13.5)
//        editMessageText?.lineBreakMode                             = .byTruncatingTail
//        editMessageText?.adjustsFontSizeToFitWidth                 = false
//        editMessageText?.translatesAutoresizingMaskIntoConstraints = false
//        editViewContainer?.addSubview(editMessageText!)
//
//        editMessageText?.topAnchor.constraint(equalTo: editLabel!.topAnchor, constant: 18).isActive                                     = true
//        editMessageText?.leadingAnchor.constraint(equalTo: editViewContainer!.leadingAnchor, constant:  self.bounds.width / 5).isActive = true
//        editMessageText?.trailingAnchor.constraint(equalTo: editViewContainer!.trailingAnchor, constant: -90).isActive                  = true
//    }
//    private func setupSeparator() {
//        separatorLabel                                            = UILabel()
//        separatorLabel?.backgroundColor                           = #colorLiteral(red: 0.2392156869, green: 0.6745098233, blue: 0.9686274529, alpha: 1)
//        separatorLabel?.translatesAutoresizingMaskIntoConstraints = false
//        editViewContainer?.addSubview(separatorLabel!)
//
//        separatorLabel?.topAnchor.constraint(equalTo: editViewContainer!.topAnchor, constant: 10).isActive = true
//        separatorLabel?.widthAnchor.constraint(equalToConstant: 3).isActive                                = true
//        separatorLabel?.heightAnchor.constraint(equalToConstant: 32).isActive                              = true
//        separatorLabel?.leadingAnchor.constraint(equalTo: editViewContainer!.leadingAnchor, constant: self.bounds.width / 6).isActive = true
//    }
//
//    private func setupEditePenIcon() {
//        editPenIcon                                            = UIImageView()
//        editPenIcon?.tintColor                                 = #colorLiteral(red: 0.2392156869, green: 0.6745098233, blue: 0.9686274529, alpha: 1)
//        editPenIcon?.image                                     = UIImage(systemName: "pencil")
//        editPenIcon?.translatesAutoresizingMaskIntoConstraints = false
//        editViewContainer?.addSubview(editPenIcon!)
//
//        editPenIcon?.leadingAnchor.constraint(equalTo: editViewContainer!.leadingAnchor, constant: 20).isActive = true
//        editPenIcon?.heightAnchor.constraint(equalToConstant: 27).isActive                                      = true
//        editPenIcon?.widthAnchor.constraint(equalToConstant: 25).isActive                                       = true
//        editPenIcon?.topAnchor.constraint(equalTo: editViewContainer!.topAnchor, constant: 10).isActive         = true
//    }
//
//    private func setupCloseButton() {
//        closeEditView                                            = UIImageView()
//        closeEditView?.tintColor                                 = #colorLiteral(red: 0.2392156869, green: 0.6745098233, blue: 0.9686274529, alpha: 1)
//        closeEditView?.image                                     = UIImage(systemName: "xmark")
//        closeEditView?.isUserInteractionEnabled                  = true
//        closeEditView?.translatesAutoresizingMaskIntoConstraints = false
//        editViewContainer?.addSubview(closeEditView!)
//
//        closeEditView?.trailingAnchor.constraint(equalTo: editViewContainer!.trailingAnchor, constant: -23).isActive = true
//        closeEditView?.topAnchor.constraint(equalTo: editViewContainer!.topAnchor, constant: 14).isActive            = true
//        closeEditView?.heightAnchor.constraint(equalToConstant: 23).isActive                                         = true
//        closeEditView?.widthAnchor.constraint(equalToConstant: 20).isActive                                          = true
//    }
//
////    func activateEditView() {
////        setupEditView()
////        setupEditLabel()
////        setupEditMessage()
////        setupSeparator()
////        setupEditePenIcon()
////        setupCloseButton()
////
////        updateTableViewContentOffset(isEditViewRemoved: false)
////        sendEditMessageButton.isHidden = false
////        self.layoutIfNeeded()
////    }
    
    func activateEditView() {
        setupEditView()
        
        updateTableViewContentOffset(isEditViewRemoved: false)
        sendEditMessageButton.isHidden = false
        self.layoutIfNeeded()
    }
    
    private func setupEditView() {
        editView = EditView()
        inputBarContainer.addSubview(editView!)
        inputBarContainer.sendSubviewToBack(editView!)
        
        editView!.translatesAutoresizingMaskIntoConstraints                              = false
        editView!.leadingAnchor.constraint(equalTo: self.leadingAnchor).isActive         = true
        editView!.trailingAnchor.constraint(equalTo: self.trailingAnchor).isActive       = true
        editView!.bottomAnchor.constraint(equalTo: inputBarContainer.topAnchor).isActive = true
        
        editView!.setupSubviews()
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

    private func setupAddPictureButton() {
        self.addSubviews(addPictureButton)
        // frmame size is used only for radius calculation
        addPictureButton.frame.size                                = CGSize(width: 35, height: 35)
        addPictureButton.configuration                             = .plain()
        addPictureButton.configuration?.baseForegroundColor        = UIColor.purple
        addPictureButton.layer.cornerRadius                        = addPictureButton.frame.size.width / 2.0
        addPictureButton.configuration?.image                      = UIImage(systemName: "photo")
        addPictureButton.clipsToBounds                             = true
        addPictureButton.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            addPictureButton.trailingAnchor.constraint(equalTo: messageTextView.leadingAnchor, constant: -10),
            addPictureButton.topAnchor.constraint(equalTo: inputBarContainer.topAnchor, constant: 8),
            addPictureButton.heightAnchor.constraint(equalToConstant: 35),
            addPictureButton.widthAnchor.constraint(equalToConstant: 35),
        ])
    }
    
    private func setupTableView() {
        self.addSubview(tableView)
        
        tableView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            tableView.trailingAnchor.constraint(equalTo: self.trailingAnchor),
            tableView.leadingAnchor.constraint(equalTo: self.leadingAnchor),
            tableView.bottomAnchor.constraint(equalTo: self.bottomAnchor),
            tableView.topAnchor.constraint(equalTo:   self.topAnchor),
        ])
    }
    
    private func setupHolderView() {
        self.addSubviews(inputBarContainer)
        
        inputBarContainer.backgroundColor                           = #colorLiteral(red: 0.1677602232, green: 0.3210971653, blue: 0.4742530584, alpha: 1)
        inputBarContainer.bounds.size.height                        = 80
        inputBarContainer.translatesAutoresizingMaskIntoConstraints = false
        
        inputBarBottomConstraint                              = inputBarContainer.bottomAnchor.constraint(equalTo: self.bottomAnchor)
        inputBarBottomConstraint.isActive                     = true
        
        let heightConstraint                                    = inputBarContainer.heightAnchor.constraint(equalToConstant: 80)
        heightConstraint.isActive                               = true
        heightConstraint.priority                               = .defaultLow
        
        NSLayoutConstraint.activate([
            inputBarContainer.leadingAnchor.constraint(equalTo: self.leadingAnchor),
            inputBarContainer.trailingAnchor.constraint(equalTo: self.trailingAnchor)
        ])
    }
    
    private func setupMessageTextView() {
        inputBarContainer.addSubview(messageTextView)
        
        let height                                                = inputBarContainer.bounds.height * 0.4
        messageTextView.backgroundColor                           = .systemBlue
        messageTextView.layer.cornerRadius                        = 15
        messageTextView.font                                      = UIFont(name: "HelveticaNeue", size: 17)
        messageTextView.textContainerInset                        = UIEdgeInsets(top: height / 6, left: 5, bottom: height / 6, right: 0)
        messageTextView.textColor                                 = .white
        messageTextView.isScrollEnabled                           = false
        messageTextView.textContainer.maximumNumberOfLines        = 0
        messageTextView.translatesAutoresizingMaskIntoConstraints = false
        
////        let messageTextViewHeightConstraint                       = messageTextView.heightAnchor.constraint(equalToConstant: 31)
////        messageTextViewHeightConstraint.priority                  = .required

        textViewHeightConstraint.isActive                         = true
        textViewHeightConstraint.priority                         = .required
        
        NSLayoutConstraint.activate([
            messageTextView.bottomAnchor.constraint(equalTo: inputBarContainer.bottomAnchor, constant: -inputBarContainer.bounds.height * 0.45),
            messageTextView.trailingAnchor.constraint(equalTo: inputBarContainer.trailingAnchor, constant: -55),
            messageTextView.leadingAnchor.constraint(equalTo: inputBarContainer.leadingAnchor, constant: 55),
            messageTextView.topAnchor.constraint(equalTo: inputBarContainer.topAnchor, constant: 10),
        ])
    }
    
    private func setupSendMessageBtn() {
        inputBarContainer.addSubview(sendMessageButton)
        // size is used only for radius calculation
        sendMessageButton.frame.size                                = CGSize(width: 35, height: 35)
        sendMessageButton.configuration                             = .filled()
        sendMessageButton.configuration?.image                      = UIImage(systemName: "paperplane.fill")
        sendMessageButton.configuration?.baseBackgroundColor        = UIColor.purple
        sendMessageButton.layer.cornerRadius                        = sendMessageButton.frame.size.width / 2.0
        sendMessageButton.clipsToBounds                             =  true
        sendMessageButton.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            sendMessageButton.leadingAnchor.constraint(equalTo: messageTextView.trailingAnchor, constant: 10),
            sendMessageButton.topAnchor.constraint(equalTo: inputBarContainer.topAnchor, constant: 8),
            sendMessageButton.heightAnchor.constraint(equalToConstant: 35),
            sendMessageButton.widthAnchor.constraint(equalToConstant: 35),
        ])
    }
    
    private func setupSendEditMessageButton() {
        self.addSubviews(sendEditMessageButton)
        
        sendEditMessageButton.frame.size                                = CGSize(width: 35, height: 35)
        sendEditMessageButton.configuration                             = .filled()
        sendEditMessageButton.configuration?.image                      = UIImage(systemName: "checkmark")
        sendEditMessageButton.configuration?.baseBackgroundColor        = UIColor.blue
        sendEditMessageButton.layer.cornerRadius                        = sendEditMessageButton.frame.size.width / 2.0
        sendEditMessageButton.clipsToBounds                             =  true
        sendEditMessageButton.isHidden                                  = true
        sendEditMessageButton.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            sendEditMessageButton.heightAnchor.constraint(equalToConstant: 35),
            sendEditMessageButton.widthAnchor.constraint(equalToConstant: 35),
            sendEditMessageButton.topAnchor.constraint(equalTo: inputBarContainer.topAnchor, constant: 8),
            sendEditMessageButton.leadingAnchor.constraint(equalTo: messageTextView.trailingAnchor, constant: 10),
        ])
    }
    
    private func revertCollectionflowLayout() {
        tableView.transform = CGAffineTransform(scaleX: 1, y: -1)
        tableView.layoutIfNeeded()
    }
    func updateNumberOfLines(_ number: Int) {
        messageTextViewNumberOfLines = number
    }
    func setTextViewDelegate(to delegate: UITextViewDelegate) {
        messageTextView.delegate = delegate
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


