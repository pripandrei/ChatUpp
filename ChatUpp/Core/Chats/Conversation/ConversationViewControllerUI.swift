//
//  ConversationViewControllerUI.swift
//  ChatUpp
//
//  Created by Andrei Pripa on 11/4/23.
//

import Foundation
import UIKit

final class ConversationViewControllerUI: UIView {

    let holderView = UIView()
    let messageTextView = UITextView()
    let sendMessageButton = UIButton()
    
    var viewController: UIViewController!
    
    var holderViewBottomConstraint: NSLayoutConstraint!
    
    lazy var collectionView: UICollectionView = {
        let collectionViewFlowLayout = InvertedCollectionViewFlowLayout()
        collectionViewFlowLayout.scrollDirection = .vertical
        collectionViewFlowLayout.estimatedItemSize = InvertedCollectionViewFlowLayout.automaticSize
        
        let collectionVC = UICollectionView(frame: CGRect.zero, collectionViewLayout: collectionViewFlowLayout)
        collectionVC.register(ConversationCollectionViewCell.self, forCellWithReuseIdentifier: CellIdentifire.conversationMessageCell)
        
        return collectionVC
    }()
    
    convenience init(viewController: UIViewController) {
        self.init(frame: .zero)
        self.viewController = viewController
        setupLayout()
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    
    // MARK: - VIEW LAYOUT SETUP
    
    func setupLayout() {
//        topView = view
        revertCollectionflowLayout()
        setupCollectionView()
        setupHolderView()
        setupMessageTextView()
        setupSendMessageBtn()
    }
    
    private func setupCollectionView() {
        self.addSubview(collectionView)
        collectionView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: 60, right: 0)
        collectionView.backgroundColor = .link
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            collectionView.topAnchor.constraint(equalTo: self.topAnchor),
            collectionView.bottomAnchor.constraint(equalTo: self.bottomAnchor),
            collectionView.trailingAnchor.constraint(equalTo: self.trailingAnchor),
            collectionView.leadingAnchor.constraint(equalTo: self.leadingAnchor)
        ])
    }
    
    private func setupHolderView() {
        self.addSubviews(holderView)
        
        holderView.backgroundColor = .systemIndigo
        holderView.translatesAutoresizingMaskIntoConstraints = false
        holderView.bounds.size.height = 80
        
        self.holderViewBottomConstraint = holderView.bottomAnchor.constraint(equalTo: self.bottomAnchor)
        self.holderViewBottomConstraint.isActive = true
        
        NSLayoutConstraint.activate([
            holderView.heightAnchor.constraint(equalToConstant: 80),
            holderView.trailingAnchor.constraint(equalTo: self.trailingAnchor),
            holderView.leadingAnchor.constraint(equalTo: self.leadingAnchor)
        ])
    }
    
    private func setupMessageTextView() {
        holderView.addSubview(messageTextView)
        
        let height = holderView.bounds.height * 0.4
        messageTextView.backgroundColor = .systemBlue
        messageTextView.layer.cornerRadius = 15
        messageTextView.font = UIFont(name: "HelveticaNeue", size: 17)
        messageTextView.textContainerInset = UIEdgeInsets(top: height / 6, left: 5, bottom: height / 6, right: 0)
        messageTextView.textColor = .white
        messageTextView.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            messageTextView.heightAnchor.constraint(equalToConstant: holderView.bounds.height * 0.4),
            messageTextView.topAnchor.constraint(equalTo: holderView.topAnchor, constant: 10),
            messageTextView.trailingAnchor.constraint(equalTo: holderView.trailingAnchor, constant: -55),
            messageTextView.leadingAnchor.constraint(equalTo: holderView.leadingAnchor, constant: 35)
        ])
    }
    
    private func setupSendMessageBtn() {
        holderView.addSubview(sendMessageButton)
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
            sendMessageButton.topAnchor.constraint(equalTo: holderView.topAnchor, constant: 8),
            sendMessageButton.leadingAnchor.constraint(equalTo: messageTextView.trailingAnchor, constant: 10),
        ])
    }
    
    private func revertCollectionflowLayout() {
        collectionView.transform = CGAffineTransform(scaleX: 1, y: -1)
        collectionView.layoutIfNeeded()
    }
}

// MARK: - SETUP NAVIGATION BAR ITEMS

extension ConversationViewControllerUI {
    func setNavigationBarItems(with imageData: Data, memberName: String) {
        let customTitleView = UIView()
        
        if let image = UIImage(data: imageData) {
            let imageView = UIImageView(image: image)
            imageView.contentMode = .scaleAspectFit
            imageView.frame = CGRect(x: 0, y: 0, width: 40, height: 40)
            imageView.layer.cornerRadius = 20
            imageView.clipsToBounds = true
            imageView.center = imageView.convert(CGPoint(x: ((viewController.navigationController!.navigationBar.frame.width) / 2) - 40, y: 0), from: self)
            
            customTitleView.addSubview(imageView)
            
            let titleLabel = UILabel()
            titleLabel.frame = CGRect(x: 0, y: 0, width: 200, height: 20)
            titleLabel.text = memberName
            titleLabel.textAlignment = .center
            titleLabel.textColor = UIColor.white
            titleLabel.font =  UIFont(name:"HelveticaNeue-Bold", size: 17)
            //            titleLabel.sizeToFit()
            titleLabel.center = titleLabel.convert(CGPoint(x: 0, y: 0), from: self)
            customTitleView.addSubview(titleLabel)
            
            viewController.navigationItem.titleView = customTitleView
        }
    }
}

//MARK: - INVERTED COLLECTION FLOW
final class InvertedCollectionViewFlowLayout: UICollectionViewFlowLayout {
    
    override func layoutAttributesForItem(at indexPath: IndexPath) -> UICollectionViewLayoutAttributes? {
        let attributes = super.layoutAttributesForItem(at: indexPath)
        attributes?.transform = CGAffineTransform(scaleX: 1, y: -1)
        return attributes
    }
    
    override func layoutAttributesForElements(in rect: CGRect) -> [UICollectionViewLayoutAttributes]? {
        let attributesList = super.layoutAttributesForElements(in: rect)
        if let list = attributesList {
            for attribute in list {
                attribute.transform = CGAffineTransform(scaleX: 1, y: -1)
            }
        }
        return attributesList
    }
}

//final class ConversationCustomNavigationBar {
//
//    let viewController: UIViewController!
//
//    init(viewController: UIViewController) {
//        self.viewController = viewController
//    }
//
//    func setupNavigationBarItems(with imageData: Data, memberName: String, using view: UIView) {
//        let customTitleView = UIView()
//
//        if let image = UIImage(data: imageData) {
//            let imageView = UIImageView(image: image)
//            imageView.contentMode = .scaleAspectFit
//            imageView.frame = CGRect(x: 0, y: 0, width: 40, height: 40)
//            imageView.layer.cornerRadius = 20
//            imageView.clipsToBounds = true
//            imageView.center = imageView.convert(CGPoint(x: ((viewController.navigationController?.navigationBar.frame.width)! / 2) - 40, y: 0), from: view)
//
//            customTitleView.addSubview(imageView)
//
//            let titleLabel = UILabel()
//            titleLabel.frame = CGRect(x: 0, y: 0, width: 200, height: 20)
//            titleLabel.text = memberName
//            titleLabel.textAlignment = .center
//            titleLabel.textColor = UIColor.white
//            titleLabel.font =  UIFont(name:"HelveticaNeue-Bold", size: 17)
//            //            titleLabel.sizeToFit()
//            titleLabel.center = titleLabel.convert(CGPoint(x: 0, y: 0), from: view)
//            customTitleView.addSubview(titleLabel)
//
//            viewController.navigationItem.titleView = customTitleView
//        }
//    }
//}
