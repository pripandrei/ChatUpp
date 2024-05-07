//
//  ConversationViewControllerUI.swift
//  ChatUpp
//
//  Created by Andrei Pripa on 11/4/23.
//

import Foundation
import UIKit

class ContainerView: UIView
{
    // since closeImageView frame is not insed it's super view (editViewContainer)
    // we need to override point to return true in case it matches the location of close view
    override func point(inside point: CGPoint, with event: UIEvent?) -> Bool {
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

//class CloseImageView: UIImageView {
//    override func point(inside point: CGPoint, with event: UIEvent?) -> Bool {
//        if super.point(inside: point, with: event) {return true}
//
//        for subview in subviews {
//            let subviewPoint = subview.convert(point, from: self)
//            if subview.point(inside: subviewPoint, with: event) {
//                return true
//            }
//        }
//        return false
//    }
//}

class ConversationViewControllerUI: UIView {
    
    let containerView = ContainerView()
    let messageTextView = UITextView()
    let sendMessageButton = UIButton()
    let pictureAddButton = UIButton()
    let editMessageButton = UIButton()
    
    var messageTextViewNumberOfLines: Int = 1
    var holderViewBottomConstraint: NSLayoutConstraint!
    var tableViewInitialContentOffset = CGPoint(x: 0, y: 0)
    
    let tableView: UITableView = {
        let tableView = UITableView()
        
        // Invert Table View upside down
        tableView.backgroundColor = #colorLiteral(red: 0.1411764771, green: 0.3960784376, blue: 0.5647059083, alpha: 1)
        tableView.transform = CGAffineTransform(scaleX: 1, y: -1)
        tableView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: 60, right: 0)
        tableView.verticalScrollIndicatorInsets = UIEdgeInsets(top: -10, left: 0, bottom: 70, right: 0)
        tableView.separatorStyle = .none
        tableView.register(ConversationTableViewCell.self, forCellReuseIdentifier: CellIdentifire.conversationMessageCell)
        tableView.sectionHeaderTopPadding = 0
        return tableView
    }()
    
    //    convenience init() {
    //        self.init(frame: .zero)
    //        setupLayout()
    //    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupLayout()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - VIEW LAYOUT SETUP
    
    private func isKeyboardShown() -> Bool {
        return messageTextView.isFirstResponder
    }
    
    private func tableViewInitialTopInset() -> CGFloat {
        return isKeyboardShown() ? CGFloat(336) : CGFloat(0)
    }
    
    func setupLayout() {
        setupTableView()
        setupHolderView()
        setupMessageTextView()
        setupSendMessageBtn()
        setupAddPictureButton()
        setupEditMessageButton()
//        setupEditView()
    }
    
    // MARK: - SETUP EDIT VIEW
    
    var editViewContainer: UIView?
    var editLabel: UILabel?
    var editMessageText: UILabel?
    var separatorLabel: UILabel?
    var editPen: UIImageView?
    var closeEditView: UIImageView?
    
    private func setupEditView() {
        editViewContainer = UIView()
        containerView.addSubview(editViewContainer!)
        containerView.sendSubviewToBack(editViewContainer!)
        editViewContainer?.backgroundColor = #colorLiteral(red: 0.1677602232, green: 0.3210971653, blue: 0.4742530584, alpha: 1)
        
        editViewContainer?.translatesAutoresizingMaskIntoConstraints = false
        editViewContainer?.bottomAnchor.constraint(equalTo: containerView.topAnchor).isActive = true
        editViewContainer?.leadingAnchor.constraint(equalTo: self.leadingAnchor).isActive = true
        editViewContainer?.trailingAnchor.constraint(equalTo: self.trailingAnchor).isActive = true
        editeViewContainerHeightConstraint = editViewContainer?.heightAnchor.constraint(equalToConstant: 45)
        editeViewContainerHeightConstraint?.isActive = true
    }
    
    var editeViewContainerHeightConstraint: NSLayoutConstraint?
    
    func setupEditLabel() {
        editLabel = UILabel()
        editViewContainer?.addSubview(editLabel!)

        editLabel?.text = "Edit Message"
        editLabel?.textColor = #colorLiteral(red: 0.2392156869, green: 0.6745098233, blue: 0.9686274529, alpha: 1)
        editLabel?.font = UIFont.boldSystemFont(ofSize: 15)
        
        editLabel?.translatesAutoresizingMaskIntoConstraints = false
        
        editLabel?.topAnchor.constraint(equalTo: editViewContainer!.topAnchor, constant: 8).isActive = true
        editLabel?.leadingAnchor.constraint(equalTo: editViewContainer!.leadingAnchor, constant: self.bounds.width / 5).isActive = true
    }
    func setupEditMessage() {
        editMessageText = UILabel()
        editViewContainer?.addSubview(editMessageText!)
        
        editMessageText?.text = "Test Message here for testing purposes only test test"
        editMessageText?.textColor = .white
        editMessageText?.font = UIFont(name: "Helvetica", size: 13.5)
//            editMessa?geText.numberOfLines = 1
        editMessageText?.lineBreakMode = .byTruncatingTail
        editMessageText?.adjustsFontSizeToFitWidth = false
        
        editMessageText?.translatesAutoresizingMaskIntoConstraints = false
        
        editMessageText?.topAnchor.constraint(equalTo: editLabel!.topAnchor, constant: 18).isActive = true
//        editMessageText?.widthAnchor.constraint(equalToConstant: 100).isActive = true
//        editMessageText?.heightAnchor.constraint(equalToConstant: 10).isActive = true
//        editMessageText?.leadingAnchor.constraint(equalTo: editeViewContainer!.leadingAnchor, constant: 40).isActive = true
        editMessageText?.trailingAnchor.constraint(equalTo: editViewContainer!.trailingAnchor, constant: -90).isActive = true
        editMessageText?.leadingAnchor.constraint(equalTo: editViewContainer!.leadingAnchor, constant:  self.bounds.width / 5).isActive = true
    }
    func setupSeparator() {
        separatorLabel = UILabel()
        editViewContainer?.addSubview(separatorLabel!)
        
        separatorLabel?.backgroundColor = #colorLiteral(red: 0.2392156869, green: 0.6745098233, blue: 0.9686274529, alpha: 1)
        
        separatorLabel?.translatesAutoresizingMaskIntoConstraints = false
        
        separatorLabel?.topAnchor.constraint(equalTo: editViewContainer!.topAnchor, constant: 10).isActive = true
        separatorLabel?.widthAnchor.constraint(equalToConstant: 3).isActive = true
        separatorLabel?.heightAnchor.constraint(equalToConstant: 32).isActive = true
//        separatorLabel?.bottomAnchor.constraint(equalTo: editeViewContainer!.bottomAnchor, constant: -1).isActive = true
        separatorLabel?.leadingAnchor.constraint(equalTo: editViewContainer!.leadingAnchor, constant: self.bounds.width / 6).isActive = true
    }
    
    func setupEditePenIcon() {
        editPen = UIImageView()
        editViewContainer?.addSubview(editPen!)
        editPen?.tintColor = #colorLiteral(red: 0.2392156869, green: 0.6745098233, blue: 0.9686274529, alpha: 1)
        editPen?.image = UIImage(systemName: "pencil")
        
        editPen?.translatesAutoresizingMaskIntoConstraints = false
        editPen?.leadingAnchor.constraint(equalTo: editViewContainer!.leadingAnchor, constant: 20).isActive = true
//        editPen?.centerYAnchor.constraint(equalTo: editeViewContainer!.centerYAnchor, constant: 2).isActive = true
        editPen?.heightAnchor.constraint(equalToConstant: 27).isActive = true
        editPen?.widthAnchor.constraint(equalToConstant: 25).isActive = true
        editPen?.topAnchor.constraint(equalTo: editViewContainer!.topAnchor, constant: 10).isActive = true
    }
    
    func setupCloseButton() {
        closeEditView = UIImageView()
        
        editViewContainer?.addSubview(closeEditView!)
        
        closeEditView?.tintColor = #colorLiteral(red: 0.2392156869, green: 0.6745098233, blue: 0.9686274529, alpha: 1)
//        close?.backgroundColor = #colorLiteral(red: 0.2392156869, green: 0.6745098233, blue: 0.9686274529, alpha: 1)
        closeEditView?.image = UIImage(systemName: "xmark")
        closeEditView?.isUserInteractionEnabled = true
        
        closeEditView?.translatesAutoresizingMaskIntoConstraints = false
        
        closeEditView?.trailingAnchor.constraint(equalTo: editViewContainer!.trailingAnchor, constant: -23).isActive = true
//        closeEditView?.centerYAnchor.constraint(equalTo: editeViewContainer!.centerYAnchor, constant: 2).isActive = true
        closeEditView?.heightAnchor.constraint(equalToConstant: 23).isActive = true
        closeEditView?.widthAnchor.constraint(equalToConstant: 20).isActive = true
        closeEditView?.topAnchor.constraint(equalTo: editViewContainer!.topAnchor, constant: 14).isActive = true
    }
    
    func activateEditView() {
        setupEditView()
        setupEditLabel()
        setupEditMessage()
        setupSeparator()
        setupEditePenIcon()
        setupCloseButton()
        
        editMessageButton.isHidden = false
//        editViewHeightAddedToTableViewContent = true
//        tableView.setContentOffset(CGPoint(x: 0, y: tableView.contentOffset.y - 45), animated: false)
        updateTableViewContentOffset(shouldAddEditViewHeight: false)
        self.layoutIfNeeded()
    }
    func updateTableViewContentOffset(shouldAddEditViewHeight: Bool) {
        let height = shouldAddEditViewHeight ? 45.0 : -45.0
        tableView.setContentOffset(CGPoint(x: 0, y: height + tableView.contentOffset.y), animated: false)
    }
    
    func destroyEditedView() {
       editViewContainer?.subviews.forEach({ view in
           view.removeFromSuperview()
       })
       editViewContainer?.removeFromSuperview()
       editViewContainer = nil
//       editeViewContainer = nil
//       editLabel          = nil
//       editMessageText    = nil
//       separatorLabel     = nil
//       editPen            = nil
//       closeEditView      = nil
   }

    //.////
    
    private func setupAddPictureButton() {
        self.addSubviews(pictureAddButton)
        // frmame size is used only for radius calculation
        pictureAddButton.frame.size = CGSize(width: 35, height: 35)
        pictureAddButton.configuration = .plain()
        pictureAddButton.configuration?.baseForegroundColor = UIColor.purple
        pictureAddButton.layer.cornerRadius = pictureAddButton.frame.size.width / 2.0
        pictureAddButton.configuration?.image = UIImage(systemName: "photo")
        pictureAddButton.clipsToBounds = true
        
        pictureAddButton.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            pictureAddButton.widthAnchor.constraint(equalToConstant: 35),
            pictureAddButton.heightAnchor.constraint(equalToConstant: 35),
            pictureAddButton.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 8),
            pictureAddButton.trailingAnchor.constraint(equalTo: messageTextView.leadingAnchor, constant: -10)
        ])
    }
    
    private func setupTableView() {
        self.addSubview(tableView)
        tableView.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: self.topAnchor),
            tableView.bottomAnchor.constraint(equalTo: self.bottomAnchor),
            tableView.trailingAnchor.constraint(equalTo: self.trailingAnchor),
            tableView.leadingAnchor.constraint(equalTo: self.leadingAnchor)
        ])
    }
    
    private func setupHolderView() {
        self.addSubviews(containerView)
        
        containerView.backgroundColor = #colorLiteral(red: 0.1677602232, green: 0.3210971653, blue: 0.4742530584, alpha: 1)
        containerView.translatesAutoresizingMaskIntoConstraints = false
        containerView.bounds.size.height = 80
        
        self.holderViewBottomConstraint = containerView.bottomAnchor.constraint(equalTo: self.bottomAnchor)
        self.holderViewBottomConstraint.isActive = true
        
        let heightConstraint = containerView.heightAnchor.constraint(equalToConstant: 80)
        heightConstraint.isActive = true
        heightConstraint.priority = .defaultLow
        
        NSLayoutConstraint.activate([
            //            containerView.heightAnchor.constraint(equalToConstant: 80),
            containerView.leadingAnchor.constraint(equalTo: self.leadingAnchor),
            containerView.trailingAnchor.constraint(equalTo: self.trailingAnchor)
        ])
    }
    
    private func setupMessageTextView() {
        containerView.addSubview(messageTextView)
        
        let height = containerView.bounds.height * 0.4
        messageTextView.backgroundColor = .systemBlue
        messageTextView.layer.cornerRadius = 15
        messageTextView.font = UIFont(name: "HelveticaNeue", size: 17)
        messageTextView.textContainerInset = UIEdgeInsets(top: height / 6, left: 5, bottom: height / 6, right: 0)
        messageTextView.textColor = .white
        messageTextView.textContainer.maximumNumberOfLines = 0
        messageTextView.isScrollEnabled = false
        messageTextView.delegate = self
        messageTextView.translatesAutoresizingMaskIntoConstraints = false
        
        //        messageTextView.textContainer.heightTracksTextView = true
        
        //        let heightConstraint = messageTextView.heightAnchor.constraint(equalToConstant: containerView.bounds.height * 0.4)
        //        heightConstraint.isActive = true
        //        heightConstraint.priority = .defaultLow
        
        textViewHeightConstraint.isActive = true
        textViewHeightConstraint.priority = .required
        
        let topConstraint = messageTextView.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 10)
        topConstraint.isActive = true
        //        topHeightConstraint.priority = .defaultLow
        
        NSLayoutConstraint.activate([
            //            messageTextView.heightAnchor.constraint(equalToConstant: containerView.bounds.height * 0.4),
            messageTextView.bottomAnchor.constraint(equalTo: containerView.bottomAnchor, constant: -containerView.bounds.height * 0.45),
            //            messageTextView.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 10),
            messageTextView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -55),
            messageTextView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 55)
        ])
    }
    
    lazy var textViewHeightConstraint = messageTextView.heightAnchor.constraint(equalToConstant: 31)
    
    private func setupSendMessageBtn() {
        containerView.addSubview(sendMessageButton)
        // size is used only for radius calculation
        sendMessageButton.frame.size = CGSize(width: 35, height: 35)
        sendMessageButton.configuration = .filled()
        sendMessageButton.configuration?.baseBackgroundColor = UIColor.purple
        sendMessageButton.layer.cornerRadius = sendMessageButton.frame.size.width / 2.0
        sendMessageButton.configuration?.image = UIImage(systemName: "paperplane.fill")
        sendMessageButton.clipsToBounds =  true
        sendMessageButton.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            sendMessageButton.heightAnchor.constraint(equalToConstant: 35),
            sendMessageButton.widthAnchor.constraint(equalToConstant: 35),
            sendMessageButton.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 8),
            sendMessageButton.leadingAnchor.constraint(equalTo: messageTextView.trailingAnchor, constant: 10),
        ])
    }
    
    func setupEditMessageButton() {
        self.addSubviews(editMessageButton)
        
        editMessageButton.frame.size = CGSize(width: 35, height: 35)
        editMessageButton.configuration = .filled()
        editMessageButton.configuration?.baseBackgroundColor = UIColor.blue
        editMessageButton.layer.cornerRadius = editMessageButton.frame.size.width / 2.0
        editMessageButton.configuration?.image = UIImage(systemName: "checkmark")
        editMessageButton.clipsToBounds =  true
        editMessageButton.isHidden = true
        
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
//    var editViewHeightAddedToTableViewContent: Bool = false
}

// MARK: - SETUP NAVIGATION BAR ITEMS
final class ConversationCustomNavigationBar {
    
    private let viewController: UIViewController!
    
    init(viewController: UIViewController) {
        self.viewController = viewController
    }
    
    func setupNavigationBarItems(with imageData: Data, memberName: String) {
        let customTitleView = UIView()
        
        if let image = UIImage(data: imageData) {
            let imageView = UIImageView(image: image)
            imageView.contentMode = .scaleAspectFit
            imageView.frame = CGRect(x: 0, y: 0, width: 40, height: 40)
            imageView.layer.cornerRadius = 20
            imageView.clipsToBounds = true
            imageView.center = imageView.convert(CGPoint(x: ((viewController.navigationController?.navigationBar.frame.width)! / 2) - 40, y: 0), from: viewController.view)
            
            customTitleView.addSubview(imageView)
            
            let titleLabel = UILabel()
            titleLabel.frame = CGRect(x: 0, y: 0, width: 200, height: 20)
            titleLabel.text = memberName
            titleLabel.textAlignment = .center
            titleLabel.textColor = UIColor.white
            titleLabel.font =  UIFont(name:"HelveticaNeue-Bold", size: 17)
            //            titleLabel.sizeToFit()
            titleLabel.center = titleLabel.convert(CGPoint(x: 0, y: 0), from: viewController.view)
            customTitleView.addSubview(titleLabel)
            
            viewController.navigationItem.titleView = customTitleView
        }
    }
}

extension ConversationViewControllerUI: UITextViewDelegate {
    
    private func calculateTextViewFrameSize(_ textView: UITextView) -> CGSize {
        let fixedWidth = textView.frame.size.width
        let newSize = textView.sizeThatFits(CGSize.init(width: fixedWidth, height: CGFloat(MAXFLOAT)))
        return CGSize.init(width: CGFloat(fmaxf(Float(newSize.width), Float(fixedWidth))), height: newSize.height)
    }

    func textViewDidChange(_ textView: UITextView) {

        // because textView height constraint priority is .required
        // new line will not occur and height will not change
        // so we need to calculate height ourselves
        let textViewFrameSize = calculateTextViewFrameSize(textView)

//        self.layoutIfNeeded()

        var numberOfLines = Int(textViewFrameSize.height / textView.font!.lineHeight)

        if numberOfLines > 4 && !self.messageTextView.isScrollEnabled {
            
            // in case user paste text that exceeds 5 lines
            numberOfLines = 5
            let initialTextViewHeight = 31.0
            
            textViewHeightConstraint.constant = initialTextViewHeight + (textView.font!.lineHeight * CGFloat(numberOfLines - 1))
            adjustTableViewContent(using: textView, numberOfLines: numberOfLines)
            self.messageTextView.isScrollEnabled = true
        }
        if numberOfLines <= 4 {
            adjustTableViewContent(using: textView, numberOfLines: numberOfLines)
            textView.isScrollEnabled = false
            self.textViewHeightConstraint.constant = textViewFrameSize.height
        }
    }
    
    func adjustTableViewContent(using textView: UITextView, numberOfLines: Int) {
        let numberOfAddedLines     = CGFloat(numberOfLines - self.messageTextViewNumberOfLines)
        let editViewHeight         = editViewContainer?.bounds.height != nil ? editViewContainer!.bounds.height : 0
        var updatedContentOffset   = self.tableView.contentOffset.y - (textView.font!.lineHeight * numberOfAddedLines)
        
//        // Add height only once when editedView first shows
//        if editViewHeightAddedToTableViewContent {
//            updatedContentOffset -= editViewHeight
//            editViewHeightAddedToTableViewContent = false
//        }
        let updatedContentTopInset = tableViewInitialTopInset() + (textView.font!.lineHeight * CGFloat((numberOfLines - 1))) + editViewHeight

        UIView.animate(withDuration: 0.15) {
            self.tableView.setContentOffset(CGPoint(x: 0, y: updatedContentOffset), animated: false)
            self.tableView.contentInset.top = updatedContentTopInset
            self.tableView.verticalScrollIndicatorInsets.top = updatedContentTopInset
        }
        self.messageTextViewNumberOfLines = numberOfLines
    }
}

//MARK: - INVERTED COLLECTION FLOW
//final class InvertedCollectionViewFlowLayout: UICollectionViewCompositionalLayout {
//
//    override func layoutAttributesForItem(at indexPath: IndexPath) -> UICollectionViewLayoutAttributes? {
//        let attributes = super.layoutAttributesForItem(at: indexPath)
//        attributes?.transform = CGAffineTransform(scaleX: 1, y: -1)
//        return attributes
//    }
//
//    override func layoutAttributesForElements(in rect: CGRect) -> [UICollectionViewLayoutAttributes]? {
//        let attributesList = super.layoutAttributesForElements(in: rect)
//        if let list = attributesList {
//            for attribute in list {
//                attribute.transform = CGAffineTransform(scaleX: 1, y: -1)
//            }
//        }
//        return attributesList
//    }
//}

//    let collectionView: UICollectionView = {
//        let layout = InvertedCollectionViewFlowLayout { (section, environment) -> NSCollectionLayoutSection? in
//
//            let itemSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0), heightDimension: .estimated(5))
//            let item = NSCollectionLayoutItem(layoutSize: itemSize)
//
////            let groupSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0), heightDimension: .estimated(100))
//            let group = NSCollectionLayoutGroup.vertical(layoutSize: itemSize, subitems: [item])
//
//            let section = NSCollectionLayoutSection(group: group)
////            section.contentInsets = NSDirectionalEdgeInsets(top: -10, leading: 10, bottom: 70, trailing: 10)
//            //            section.contentInsets.top = .init(-10)
//            section.interGroupSpacing = 3
//            return section
//        }
//        layout.configuration.scrollDirection = .vertical
//
//        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
////        collectionView.backgroundColor = .brown
//        collectionView.translatesAutoresizingMaskIntoConstraints = false
//
//        collectionView.register(ConversationCollectionViewCell.self, forCellWithReuseIdentifier: CellIdentifire.conversationMessageCell)
//        collectionView.verticalScrollIndicatorInsets = UIEdgeInsets(top: -10, left: 0, bottom: 70, right: 0)
//
//        return collectionView
//    }()
