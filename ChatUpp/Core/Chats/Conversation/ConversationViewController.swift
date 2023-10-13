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

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
        setupCoollectionView()
        setupHolderView()
        setupMessageTextField()
        setTepGesture()
        
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardFrameWillChange(_:)), name: UIResponder.keyboardWillChangeFrameNotification, object: nil)
    }
    
    private func setTepGesture() {
        let tap = UITapGestureRecognizer(target: self, action: #selector(resignKeyboard))
        collectionView.addGestureRecognizer(tap)
    }
    
    @objc func resignKeyboard() {
        if messageTextField.isFirstResponder {
            messageTextField.resignFirstResponder()
        }
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    @objc func keyboardFrameWillChange(_ notification: Notification) {
        if let userInfo = notification.userInfo,
           let keyboardFrame = (userInfo[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue {
            let keyboardOrigin = keyboardFrame.origin
            
            self.holderViewBottomConstraint.constant = keyboardOrigin.y < UIScreen.main.bounds.height ? -keyboardFrame.height : 0
            
            UIView.animate(withDuration: 0.5) {
                self.view.layoutIfNeeded()
            }
//            holderViewBottomConstraint.constant = keyboardOrigin.y < UIScreen.main.bounds.height ? -keyboardFrame.height : 0
//            holderView.frame.origin = CGPoint(x: 0.0, y: keyboardOrigin.y - holderView.frame.height)
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

        collectionView.backgroundColor = .brown

        setCollectionViewConstraints()
    }
    
    private func setCollectionViewConstraints() {
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            collectionView.topAnchor.constraint(equalTo: view.topAnchor),
            collectionView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            collectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            collectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor)
        ])
    }
}

extension ConversationViewController: UITextFieldDelegate {
    
    func textFieldShouldBeginEditing(_ textField: UITextField) -> Bool {
//        holderView.translatesAutoresizingMaskIntoConstraints = true
        return true
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesBegan(touches, with: event)
        print("Asd")
        view.endEditing(true)
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
//        holderView.translatesAutoresizingMaskIntoConstraints = false
        return textField.resignFirstResponder()
    }
}

extension ConversationViewController: UICollectionViewDataSource {
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return 0
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: Cell.CustomCollectionViewCell, for: indexPath) as? CustomCollectionViewCell else { fatalError("Could not dequeu custom collection cell") }
        
        return cell
    }
}


extension ConversationViewController:  UICollectionViewDelegateFlowLayout {

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: 90, height: 60)
    }
}
