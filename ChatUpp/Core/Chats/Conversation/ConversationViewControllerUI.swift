//
//  ConversationViewControllerUI.swift
//  ChatUpp
//
//  Created by Andrei Pripa on 11/4/23.
//

import Foundation
import UIKit

class ConversationViewControllerUI: UIView {
    
    private(set) var messageTextViewNumberOfLines  = 1
    private(set) var containerView                 = ContainerView()
    private(set) var messageTextView               = UITextView()
    private(set) var sendMessageButton             = UIButton()
    private(set) var pictureAddButton              = UIButton()
    private(set) var editMessageButton             = UIButton()
    private(set) var holderViewBottomConstraint    : NSLayoutConstraint!
    
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
        setupEditMessageButton()
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
    
    private(set) var editViewContainer : UIView?
    private(set) var closeEditView     : UIImageView?
    private var editLabel              : UILabel?
    private var editMessageText        : UILabel?
    private var separatorLabel         : UILabel?
    private var editPenIcon            : UIImageView?
    
    private func setupEditView() {
        editViewContainer                  = UIView()
        editViewContainer?.backgroundColor = #colorLiteral(red: 0.1677602232, green: 0.3210971653, blue: 0.4742530584, alpha: 1)
        
        containerView.addSubview(editViewContainer!)
        containerView.sendSubviewToBack(editViewContainer!)
        
        editViewContainer?.translatesAutoresizingMaskIntoConstraints                          = false
        editViewContainer?.trailingAnchor.constraint(equalTo: self.trailingAnchor).isActive   = true
        editViewContainer?.leadingAnchor.constraint(equalTo: self.leadingAnchor).isActive     = true
        editViewContainer?.bottomAnchor.constraint(equalTo: containerView.topAnchor).isActive = true
        
        editeViewContainerHeightConstraint           = editViewContainer?.heightAnchor.constraint(equalToConstant: 45)
        editeViewContainerHeightConstraint?.isActive = true
    }
    
    var editeViewContainerHeightConstraint: NSLayoutConstraint?
    
    private func setupEditLabel() {
        editLabel = UILabel()

        editLabel?.text                                      = "Edit Message"
        editLabel?.textColor                                 = #colorLiteral(red: 0.2392156869, green: 0.6745098233, blue: 0.9686274529, alpha: 1)
        editLabel?.font                                      = UIFont.boldSystemFont(ofSize: 15)
        editLabel?.translatesAutoresizingMaskIntoConstraints = false
        editViewContainer?.addSubview(editLabel!)
        
        editLabel?.topAnchor.constraint(equalTo: editViewContainer!.topAnchor, constant: 8).isActive                             = true
        editLabel?.leadingAnchor.constraint(equalTo: editViewContainer!.leadingAnchor, constant: self.bounds.width / 5).isActive = true
    }
    private func setupEditMessage() {
        editMessageText                                            = UILabel()
        editMessageText?.text                                      = "Test Message here for testing purposes only test test"
        editMessageText?.textColor                                 = .white
        editMessageText?.font                                      = UIFont(name: "Helvetica", size: 13.5)
        editMessageText?.lineBreakMode                             = .byTruncatingTail
        editMessageText?.adjustsFontSizeToFitWidth                 = false
        editMessageText?.translatesAutoresizingMaskIntoConstraints = false
        editViewContainer?.addSubview(editMessageText!)
        
        editMessageText?.topAnchor.constraint(equalTo: editLabel!.topAnchor, constant: 18).isActive                                     = true
        editMessageText?.leadingAnchor.constraint(equalTo: editViewContainer!.leadingAnchor, constant:  self.bounds.width / 5).isActive = true
        editMessageText?.trailingAnchor.constraint(equalTo: editViewContainer!.trailingAnchor, constant: -90).isActive                  = true
    }
    private func setupSeparator() {
        separatorLabel                                            = UILabel()
        separatorLabel?.backgroundColor                           = #colorLiteral(red: 0.2392156869, green: 0.6745098233, blue: 0.9686274529, alpha: 1)
        separatorLabel?.translatesAutoresizingMaskIntoConstraints = false
        editViewContainer?.addSubview(separatorLabel!)
        
        separatorLabel?.topAnchor.constraint(equalTo: editViewContainer!.topAnchor, constant: 10).isActive = true
        separatorLabel?.widthAnchor.constraint(equalToConstant: 3).isActive                                = true
        separatorLabel?.heightAnchor.constraint(equalToConstant: 32).isActive                              = true
        separatorLabel?.leadingAnchor.constraint(equalTo: editViewContainer!.leadingAnchor, constant: self.bounds.width / 6).isActive = true
    }
    
    private func setupEditePenIcon() {
        editPenIcon                                            = UIImageView()
        editPenIcon?.tintColor                                 = #colorLiteral(red: 0.2392156869, green: 0.6745098233, blue: 0.9686274529, alpha: 1)
        editPenIcon?.image                                     = UIImage(systemName: "pencil")
        editPenIcon?.translatesAutoresizingMaskIntoConstraints = false
        editViewContainer?.addSubview(editPenIcon!)
        
        editPenIcon?.leadingAnchor.constraint(equalTo: editViewContainer!.leadingAnchor, constant: 20).isActive = true
        editPenIcon?.heightAnchor.constraint(equalToConstant: 27).isActive                                      = true
        editPenIcon?.widthAnchor.constraint(equalToConstant: 25).isActive                                       = true
        editPenIcon?.topAnchor.constraint(equalTo: editViewContainer!.topAnchor, constant: 10).isActive         = true
    }
    
    private func setupCloseButton() {
        closeEditView                                            = UIImageView()
        closeEditView?.tintColor                                 = #colorLiteral(red: 0.2392156869, green: 0.6745098233, blue: 0.9686274529, alpha: 1)
        closeEditView?.image                                     = UIImage(systemName: "xmark")
        closeEditView?.isUserInteractionEnabled                  = true
        closeEditView?.translatesAutoresizingMaskIntoConstraints = false
        editViewContainer?.addSubview(closeEditView!)
        
        closeEditView?.trailingAnchor.constraint(equalTo: editViewContainer!.trailingAnchor, constant: -23).isActive = true
        closeEditView?.topAnchor.constraint(equalTo: editViewContainer!.topAnchor, constant: 14).isActive            = true
        closeEditView?.heightAnchor.constraint(equalToConstant: 23).isActive                                         = true
        closeEditView?.widthAnchor.constraint(equalToConstant: 20).isActive                                          = true
    }
    
    func activateEditView() {
        setupEditView()
        setupEditLabel()
        setupEditMessage()
        setupSeparator()
        setupEditePenIcon()
        setupCloseButton()
        
        updateTableViewContentOffset(isEditViewRemoved: false)
        editMessageButton.isHidden = false
        self.layoutIfNeeded()
    }
    func updateTableViewContentOffset(isEditViewRemoved: Bool) {
        //because tableview is inverted we should perform operations vice versa
        let height = isEditViewRemoved ? 45.0 : -45.0
        tableView.setContentOffset(CGPoint(x: 0, y: height + tableView.contentOffset.y), animated: false)
    }
    
    func destroyEditedView() {
       editViewContainer?.subviews.forEach({ view in
           view.removeFromSuperview()
       })
       editViewContainer?.removeFromSuperview()
       editViewContainer = nil
       editLabel         = nil
       editMessageText   = nil
       separatorLabel    = nil
       editPenIcon       = nil
       closeEditView     = nil
   }

    private func setupAddPictureButton() {
        self.addSubviews(pictureAddButton)
        // frmame size is used only for radius calculation
        pictureAddButton.frame.size                                = CGSize(width: 35, height: 35)
        pictureAddButton.configuration                             = .plain()
        pictureAddButton.configuration?.baseForegroundColor        = UIColor.purple
        pictureAddButton.layer.cornerRadius                        = pictureAddButton.frame.size.width / 2.0
        pictureAddButton.configuration?.image                      = UIImage(systemName: "photo")
        pictureAddButton.clipsToBounds                             = true
        pictureAddButton.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            pictureAddButton.trailingAnchor.constraint(equalTo: messageTextView.leadingAnchor, constant: -10),
            pictureAddButton.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 8),
            pictureAddButton.heightAnchor.constraint(equalToConstant: 35),
            pictureAddButton.widthAnchor.constraint(equalToConstant: 35),
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
        self.addSubviews(containerView)
        
        containerView.backgroundColor                           = #colorLiteral(red: 0.1677602232, green: 0.3210971653, blue: 0.4742530584, alpha: 1)
        containerView.bounds.size.height                        = 80
        containerView.translatesAutoresizingMaskIntoConstraints = false
        
        holderViewBottomConstraint                              = containerView.bottomAnchor.constraint(equalTo: self.bottomAnchor)
        holderViewBottomConstraint.isActive                     = true
        
        let heightConstraint                                    = containerView.heightAnchor.constraint(equalToConstant: 80)
        heightConstraint.isActive                               = true
        heightConstraint.priority                               = .defaultLow
        
        NSLayoutConstraint.activate([
            containerView.leadingAnchor.constraint(equalTo: self.leadingAnchor),
            containerView.trailingAnchor.constraint(equalTo: self.trailingAnchor)
        ])
    }
    
    private func setupMessageTextView() {
        containerView.addSubview(messageTextView)
        
        let height                                                = containerView.bounds.height * 0.4
        messageTextView.backgroundColor                           = .systemBlue
        messageTextView.layer.cornerRadius                        = 15
        messageTextView.font                                      = UIFont(name: "HelveticaNeue", size: 17)
        messageTextView.textContainerInset                        = UIEdgeInsets(top: height / 6, left: 5, bottom: height / 6, right: 0)
        messageTextView.textColor                                 = .white
        messageTextView.isScrollEnabled                           = false
        messageTextView.delegate                                  = self
        messageTextView.textContainer.maximumNumberOfLines        = 0
        messageTextView.translatesAutoresizingMaskIntoConstraints = false
        
        textViewHeightConstraint.isActive                         = true
        textViewHeightConstraint.priority                         = .required
        
        let topConstraint                                         = messageTextView.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 10)
        topConstraint.isActive                                    = true
        
        NSLayoutConstraint.activate([
            messageTextView.bottomAnchor.constraint(equalTo: containerView.bottomAnchor, constant: -containerView.bounds.height * 0.45),
            messageTextView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 55),
            messageTextView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -55),
        ])
    }
    
    private func setupSendMessageBtn() {
        containerView.addSubview(sendMessageButton)
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
            sendMessageButton.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 8),
            sendMessageButton.heightAnchor.constraint(equalToConstant: 35),
            sendMessageButton.widthAnchor.constraint(equalToConstant: 35),
        ])
    }
    
    private func setupEditMessageButton() {
        self.addSubviews(editMessageButton)
        
        editMessageButton.frame.size                                = CGSize(width: 35, height: 35)
        editMessageButton.configuration                             = .filled()
        editMessageButton.configuration?.image                      = UIImage(systemName: "checkmark")
        editMessageButton.configuration?.baseBackgroundColor        = UIColor.blue
        editMessageButton.layer.cornerRadius                        = editMessageButton.frame.size.width / 2.0
        editMessageButton.clipsToBounds                             =  true
        editMessageButton.isHidden                                  = true
        editMessageButton.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            editMessageButton.heightAnchor.constraint(equalToConstant: 35),
            editMessageButton.widthAnchor.constraint(equalToConstant: 35),
            editMessageButton.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 8),
            editMessageButton.leadingAnchor.constraint(equalTo: messageTextView.trailingAnchor, constant: 10),
        ])
    }
    
    private func revertCollectionflowLayout() {
        tableView.transform = CGAffineTransform(scaleX: 1, y: -1)
        tableView.layoutIfNeeded()
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

extension ConversationViewControllerUI: UITextViewDelegate {
    
    private func calculateTextViewFrameSize(_ textView: UITextView) -> CGSize {
        let fixedWidth = textView.frame.size.width
        let newSize    = textView.sizeThatFits(CGSize.init(width: fixedWidth, height: CGFloat(MAXFLOAT)))
        return CGSize.init(width: CGFloat(fmaxf(Float(newSize.width), Float(fixedWidth))), height: newSize.height)
    }

    func textViewDidChange(_ textView: UITextView)
    {
        // because textView height constraint priority is .required
        // new line will not occur and height will not change
        // so we need to calculate height ourselves
        let textViewFrameSize = calculateTextViewFrameSize(textView)
        var numberOfLines     = Int(textViewFrameSize.height / textView.font!.lineHeight)
        
        if numberOfLines > 4 && !self.messageTextView.isScrollEnabled
        {
            // in case user paste text that exceeds 5 lines
            let initialTextViewHeight = 31.0
            numberOfLines             = 5
            
            self.messageTextView.isScrollEnabled = true
            textViewHeightConstraint.constant    = initialTextViewHeight + (textView.font!.lineHeight * CGFloat(numberOfLines - 1))
            adjustTableViewContent(using: textView, numberOfLines: numberOfLines)
        }
        if numberOfLines <= 4 {
            adjustTableViewContent(using: textView, numberOfLines: numberOfLines)
            self.textViewHeightConstraint.constant = textViewFrameSize.height
            textView.isScrollEnabled               = false
        }
    }
    
    func adjustTableViewContent(using textView: UITextView, numberOfLines: Int) {
        let numberOfAddedLines     = CGFloat(numberOfLines - self.messageTextViewNumberOfLines)
        let editViewHeight         = editViewContainer?.bounds.height != nil ? editViewContainer!.bounds.height : 0
        let updatedContentOffset   = self.tableView.contentOffset.y - (textView.font!.lineHeight * numberOfAddedLines)
        let updatedContentTopInset = tableViewInitialTopInset + (textView.font!.lineHeight * CGFloat((numberOfLines - 1))) + editViewHeight

        UIView.animate(withDuration: 0.15) {
            self.tableView.setContentOffset(CGPoint(x: 0, y: updatedContentOffset), animated: false)
            self.tableView.verticalScrollIndicatorInsets.top = updatedContentTopInset
            self.tableView.contentInset.top                  = updatedContentTopInset
        }
        self.messageTextViewNumberOfLines = numberOfLines
    }
}

// MARK: - Modified container for gesture trigger

class ContainerView: UIView
{
    // since closeImageView frame is not inside it's super view (editViewContainer)
    // we need to override point to return true in case it matches the location of close view
    // so that gesture recognizer get's triggered
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
