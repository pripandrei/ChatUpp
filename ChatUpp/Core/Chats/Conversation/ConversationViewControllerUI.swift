//
//  ConversationViewControllerUI.swift
//  ChatUpp
//
//  Created by Andrei Pripa on 11/4/23.
//

import Foundation
import UIKit

class ConversationViewControllerUI: UIView {
    
    let containerView = UIView()
    let messageTextView = UITextView()
    let sendMessageButton = UIButton()
    let pictureAddButton = UIButton()
    let editMessageButton = UIButton()
    
    var holderViewBottomConstraint: NSLayoutConstraint!
    
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
    
    func setupLayout() {
        setupTableView()
        setupHolderView()
        setupMessageTextView()
        setupSendMessageBtn()
        setupAddPictureButton()
        setupEditMessageButton()
    }
    
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
        messageTextView.translatesAutoresizingMaskIntoConstraints = false
        messageTextView.textContainer.maximumNumberOfLines = 0
        messageTextView.delegate = self
        
        //        messageTextView.textContainer.heightTracksTextView = true
        messageTextView.isScrollEnabled = false
        
        //        let heightConstraint = messageTextView.heightAnchor.constraint(equalToConstant: containerView.bounds.height * 0.4)
        //        heightConstraint.isActive = true
        //        heightConstraint.priority = .defaultLow
        
        textViewHeightConstraint.isActive = true
        textViewHeightConstraint.priority = .defaultLow
        
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
    
    lazy var textViewHeightConstraint = messageTextView.heightAnchor.constraint(equalToConstant: containerView.bounds.height * 0.4)
    
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
    func textViewDidChange(_ textView: UITextView) {
        let numberOfLines = Int(textView.contentSize.height / textView.font!.lineHeight)
        
        if numberOfLines >= 4 && !messageTextView.isScrollEnabled {
            textViewHeightConstraint.constant = textView.contentSize.height
            messageTextView.isScrollEnabled = true
        }
        if numberOfLines <= 3 {
            textViewHeightConstraint.constant = textView.contentSize.height
            textView.layoutIfNeeded()
            textView.isScrollEnabled = false
        }
        print(numberOfLines)
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
