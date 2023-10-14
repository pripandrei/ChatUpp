//
//  ConversationViewController.swift
//  ChatUpp
//
//  Created by Andrei Pripa on 10/3/23.
//

import UIKit

class ConversationViewController: UIViewController {
    
    weak var coordinatorDelegate: Coordinator?
    private let conversationViewModel = ConversationViewModel()
    
    private let holderView = UIView()
    private let messageTextField = UITextField()
    
    
    private lazy var collectionView: UICollectionView = {
        let flowLayout = UICollectionViewFlowLayout()
        let collectionVC = UICollectionView(frame: CGRect.zero, collectionViewLayout: flowLayout)
        flowLayout.scrollDirection = .vertical
        collectionVC.register(CustomCollectionViewCell.self, forCellWithReuseIdentifier: Cell.CustomCollectionViewCell)
        collectionVC.delegate = self
        collectionVC.dataSource = self
        return collectionVC
    }()
    
    private var holderViewBottomConstraint: NSLayoutConstraint!
    private var collectionViewBottomConstraint: NSLayoutConstraint!
    private var shoulOffSetCollectionViewContent = true
    
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
        
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow), name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide), name: UIResponder.keyboardWillHideNotification, object: nil)
    }
    
    
    @objc func keyboardWillShow(notification: NSNotification) {
        if let keyboardSize = (notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue {
                if holderView.frame.origin.y > 760 {
//                    holderView.frame.origin.y -= keyboardSize.height
                    self.holderViewBottomConstraint.constant = -keyboardSize.height
                    let currentOffSet = collectionView.contentOffset
                    let offSet = CGPoint(x: currentOffSet.x, y: currentOffSet.y + keyboardSize.height)
                    collectionView.setContentOffset(offSet, animated: false)
                    
                    let contentInset = UIEdgeInsets(top: 0, left: 0, bottom: keyboardSize.height, right: 0)
                    collectionView.contentInset = contentInset
                    collectionView.scrollIndicatorInsets = contentInset

                    UIView.animate(withDuration: 0.5, delay: 0.0) {
                        self.view.layoutIfNeeded()
                    }
                }
            }
    }
    
    @objc func keyboardWillHide(notification: NSNotification) {
        if let keyboardSize = (notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue {
                if holderView.frame.origin.y < 760 {
//                    holderView.frame.origin.y = holderView.frame.origin.y + keyboardSize.height
                    self.holderViewBottomConstraint.constant = 0
                    let currentOffSet = collectionView.contentOffset
                    let offSet = CGPoint(x: currentOffSet.x, y: currentOffSet.y - keyboardSize.height)
                    collectionView.setContentOffset(offSet, animated: false)
                    
//                    let contentInset = UIEdgeInsets(top: 0, left: 0, bottom: keyboardSize.height, right: 0)
                    collectionView.contentInset = UIEdgeInsets()
                    collectionView.scrollIndicatorInsets = UIEdgeInsets()
                    
                    UIView.animate(withDuration: 0.5, delay: 0.0) {
                        self.view.layoutIfNeeded()
                    }
                }
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
        
        collectionView.backgroundColor = .systemPink

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

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: Cell.CustomCollectionViewCell, for: indexPath) as? CustomCollectionViewCell else { fatalError("Could not dequeu custom collection cell") }
        cell.label.text = String(indexPath.row)
        
//        if let lastCell = self.collectionView.visibleCells.last,
//           let indexPath = self.collectionView.indexPath(for: lastCell) {
//            print(indexPath.row)
////            self.collectionView.scrollToItem(at: indexPath, at: .bottom, animated: true)
//        }
        
        return cell
    }
    
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        
        var biggest: Int = 0
        for visible in collectionView.visibleCells {
            let index = collectionView.indexPath(for: visible)
            if index!.row > biggest {
                biggest = index!.row
            }
        }
        print(biggest)
//        if let lastCell = self.collectionView.visibleCells.last,
//           let indexPath = self.collectionView.indexPath(for: lastCell) {
//            print(indexPath.row)
//
//            self.collectionView.scrollToItem(at: indexPath, at: .bottom, animated: true)
//        }
    }
}

//MARK: - COLLECTION VIEW LAYOUT

extension ConversationViewController:  UICollectionViewDelegateFlowLayout {

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: view.bounds.width, height: 80)
    }
}

//MARK: - KEYBOARD UP-DOWN PUSH HANDLER

    // This is pure ugliness but i don't find other ways to preserve collection's view content so that it could be shown/scrolled behind keyboard (you can observe cells content as they go behind the keyboard)

//extension ConversationViewController {
//    @objc func keyboardFrameWillChange(_ notification: Notification) {
//         if let userInfo = notification.userInfo,
//            let keyboardFrame = (userInfo[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue {
//             if shoulOffSetCollectionViewContent {
//                 handleCollcetionContentOffset(keyboardFrame: keyboardFrame)
//                 shoulOffSetCollectionViewContent = false
//             }
//         }
//     }
//
//    @objc func keyboardDidHide(_ notification: Notification) {
//        shoulOffSetCollectionViewContent = true
//
//        if let userInfo = notification.userInfo,
//           let keyboardFrame = (userInfo[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue {
////            handleCollcetionContentOffset(keyboardFrame: keyboardFrame)
//        }
//    }
//
//    func handleCollcetionContentOffset(keyboardFrame: CGRect) {
//        let keyboardOrigin = keyboardFrame.origin
//        let pushDirection = keyboardOrigin.y < UIScreen.main.bounds.height ? 0 : -keyboardFrame.height
//        holderViewBottomConstraint.constant = pushDirection
//        print("KeyboardDirection", pushDirection)
//        let contentInset = UIEdgeInsets(top: 0, left: 0, bottom: pushDirection, right: 0)
////        collectionViewContentInset = contentInset
//        collectionView.contentInset = contentInset
//        collectionView.scrollIndicatorInsets = contentInset
//        // Calculate the current content offset
//        let currentContentOffset = collectionView.contentOffset
//        var yOffset = CGFloat()
//        if keyboardOrigin.y < UIScreen.main.bounds.height {
//            yOffset = currentContentOffset.y + keyboardFrame.height
//        } else {
//            yOffset = currentContentOffset.y - keyboardFrame.height
//        }
//
//        collectionView.setContentOffset(CGPoint(x: currentContentOffset.x, y: yOffset), animated: true)
//
//        UIView.animate(withDuration: 0.5) {
//            self.view.layoutIfNeeded()
//        }
//    }
//}
