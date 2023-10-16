//
//  ConversationViewController.swift
//  ChatUpp
//
//  Created by Andrei Pripa on 10/3/23.
//

import UIKit

final class ConversationViewController: UIViewController {
    
    weak var coordinatorDelegate: Coordinator?
    private var conversationViewModel: ConversationViewModel!
    
    private let holderView = UIView()
    private let messageTextField = UITextField()
    
    private var holderViewBottomConstraint: NSLayoutConstraint!
    private var collectionViewBottomConstraint: NSLayoutConstraint!
    
//    private var conversationID: String!
    
    private lazy var collectionView: UICollectionView = {
        let flowLayout = UICollectionViewFlowLayout()
        let collectionVC = UICollectionView(frame: CGRect.zero, collectionViewLayout: flowLayout)
        flowLayout.scrollDirection = .vertical
        collectionVC.register(ConversationCollectionViewCell.self, forCellWithReuseIdentifier: CellIdentifire.conversationMessageCell)
        collectionVC.delegate = self
        collectionVC.dataSource = self
        return collectionVC
    }()
    
//MARK: - LIFECYCLE
    
    convenience init(conversationViewModel: ConversationViewModel) {
        self.init()
        self.conversationViewModel = conversationViewModel
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
        setupCoollectionView()
        setupHolderView()
        setupMessageTextField()
//        setTepGesture()
        addKeyboardNotificationObservers()

        setNavigationBarItem()
    }
    
//    
//    private func setNavigationBarItem2() {
//        navigationItem.title = "Mira"
//
//        guard let imageData = conversationViewModel.imageData, let image = UIImage(data: imageData) else {
//            return
//        }
//
//        let customView = UIView()
//
//        let imageView = UIImageView(image: image)
//        imageView.frame = CGRect(x: -50, y: -20, width: 40, height: 40) // Adjust the position and size as needed
////        imageView.contentMode = .scaleAspectFit
//        imageView.layer.cornerRadius = 20
//        imageView.clipsToBounds = true
//        customView.addSubview(imageView)
////        customView.addSubview(titleLabel)
//
//        let imageBarButtonItem = UIBarButtonItem(customView: customView)
//
//        navigationItem.rightBarButtonItem = imageBarButtonItem
//    }
    
    private func setNavigationBarItem() {
        guard let imageData = conversationViewModel.imageData else {return}
        let customTitleView = UIView()
        
        if let image = UIImage(data: imageData) {
            let imageView = UIImageView(image: image)
            imageView.contentMode = .scaleAspectFit
            imageView.frame = CGRect(x: 0, y: 0, width: 40, height: 40)
            imageView.layer.cornerRadius = 20
            imageView.clipsToBounds = true
            imageView.center = imageView.convert(CGPoint(x: ((navigationController?.navigationBar.frame.width)! / 2) - 40, y: 0), from: view)
            
            customTitleView.addSubview(imageView)
            
            let titleLabel = UILabel()
            titleLabel.frame = CGRect(x: 0, y: 0, width: 200, height: 20)
            titleLabel.text = "Mira was here teererrearerk rkwe lrwrwerwer"
            titleLabel.textColor = UIColor.white
            titleLabel.font =  UIFont(name:"HelveticaNeue-Bold", size: 17)
//            titleLabel.sizeToFit()
            titleLabel.center = titleLabel.convert(CGPoint(x: 0, y: 0), from: view)
            customTitleView.addSubview(titleLabel)

            navigationItem.titleView = customTitleView
        }
    }
    
//MARK: - VIEW CONTROLLER SETUP
    
    private func addKeyboardNotificationObservers() {
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow), name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide), name: UIResponder.keyboardWillHideNotification, object: nil)
    }
     
    @objc func keyboardWillShow(notification: NSNotification) {
        if let keyboardSize = (notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue {
            
            if holderView.frame.origin.y > 760 {
                handleCollectionViewOffSet(usingKeyboardSize: keyboardSize)
            }
        }
    }
    
    @objc func keyboardWillHide(notification: NSNotification) {
        if let keyboardSize = (notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue {
            handleCollectionViewOffSet(usingKeyboardSize: keyboardSize)
        }
    }

    private func setupHolderView() {
        view.addSubview(holderView)
        
        holderView.backgroundColor = .systemIndigo
        
        setHolderViewConstraints()
    }
    
    private func setHolderViewConstraints() {
        holderView.translatesAutoresizingMaskIntoConstraints = false
        holderView.bounds.size.height = 80
        
        self.holderViewBottomConstraint = holderView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        self.holderViewBottomConstraint.isActive = true
        
        NSLayoutConstraint.activate([
            holderView.heightAnchor.constraint(equalToConstant: 80),
//            holderView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            holderView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            holderView.leadingAnchor.constraint(equalTo: view.leadingAnchor)
        ])
    }
    
    private func setupMessageTextField() {
        holderView.addSubview(messageTextField)
//        messageTextField.keyboardType = UIKeyboardType.asciiCapableNumberPad
        
        messageTextField.delegate = self
        messageTextField.backgroundColor = .systemBlue
        messageTextField.borderStyle = .roundedRect
        messageTextField.placeholder = "Type Message"
        
        setMessageTextfieldConstraints()

    }
    
    private func setMessageTextfieldConstraints() {
        messageTextField.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            messageTextField.heightAnchor.constraint(equalToConstant: holderView.bounds.height * 0.4),
            messageTextField.topAnchor.constraint(equalTo: holderView.topAnchor, constant: 10),
            messageTextField.trailingAnchor.constraint(equalTo: holderView.trailingAnchor, constant: -25),
            messageTextField.leadingAnchor.constraint(equalTo: holderView.leadingAnchor, constant: 25)
        ])
    }

    private func setupCoollectionView() {
        view.addSubview(collectionView)
        
        collectionView.backgroundColor = .link
        

        setCollectionViewConstraints()
    }
    
    private func setCollectionViewConstraints() {
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        
//        collectionViewBottomConstraint = collectionView.bottomAnchor.constraint(equalTo: holderView.topAnchor)
        collectionViewBottomConstraint = collectionView.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -80)
        collectionViewBottomConstraint.isActive = true
        
        NSLayoutConstraint.activate([
            collectionView.topAnchor.constraint(equalTo: view.topAnchor),
//            collectionView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            collectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            collectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor)
        ])
    }
}

//MARK: - GESTURES

extension ConversationViewController {
    
    private func setTepGesture() {
        let tap = UITapGestureRecognizer(target: self, action: #selector(resignKeyboard))
        collectionView.addGestureRecognizer(tap)
    }
    
    @objc func resignKeyboard() {
        if messageTextField.isFirstResponder {
            messageTextField.resignFirstResponder()
        }
    }
}

//MARK: - TEXTFIELD DELEGATE

extension ConversationViewController: UITextFieldDelegate {
    
    func textFieldShouldBeginEditing(_ textField: UITextField) -> Bool {
        return true
    }
    

    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.text?.removeAll()
        return textField.resignFirstResponder()
    }
}


//MARK: - COLLECTION VIEW DATASOURCE

extension ConversationViewController: UICollectionViewDataSource {
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return 25
    }

    func collectionView(_ collectionView: UICollectionView,
                        cellForItemAt indexPath: IndexPath) -> UICollectionViewCell
    {
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: CellIdentifire.conversationMessageCell, for: indexPath) as? ConversationCollectionViewCell else { fatalError("Could not dequeu custom collection cell") }
        cell.label.text = String(indexPath.row)
        
        return cell
    }
}

//MARK: - COLLECTION VIEW LAYOUT

extension ConversationViewController: UICollectionViewDelegateFlowLayout {
    
    func collectionView(_ collectionView: UICollectionView,
                        layout collectionViewLayout: UICollectionViewLayout,
                        sizeForItemAt indexPath: IndexPath) -> CGSize
    {
        return CGSize(width: view.bounds.width, height: 80)
    }
}

//MARK: - COLLETION VIEW OFFSET HANDLER

extension ConversationViewController {
    
    private func handleCollectionViewOffSet(usingKeyboardSize keyboardSize: CGRect) {
        
        let keyboardHeight = holderView.frame.origin.y > 760 ? -keyboardSize.height : keyboardSize.height
        let customCollectionViewInset = keyboardHeight < 0 ? abs(keyboardHeight) : 0
        
        self.holderViewBottomConstraint.constant = keyboardHeight < 0 ? keyboardHeight : 0

        let currentOffSet = collectionView.contentOffset
        let offSet = CGPoint(x: currentOffSet.x, y: keyboardHeight.invertValue() + currentOffSet.y)
        collectionView.setContentOffset(offSet, animated: false)
        
        let contentInset = UIEdgeInsets(top: 0, left: 0, bottom: customCollectionViewInset, right: 0)
        collectionView.contentInset = contentInset
        collectionView.scrollIndicatorInsets = contentInset
        
        UIView.animate(withDuration: 0.5, delay: 0.0) {
            self.view.layoutIfNeeded()
        }
    }
}

