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

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
        setupCoollectionView()
        setupHolderView()
        setupMessageTextField()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        print(holderView.bounds)
    }
    
    private func setupHolderView() {
        view.addSubview(holderView)
        
        holderView.backgroundColor = .systemIndigo
        
        setHolderViewConstraints()
    }
    
    private func setHolderViewConstraints() {
        holderView.translatesAutoresizingMaskIntoConstraints = false
        holderView.bounds.size.height = 80
        
        NSLayoutConstraint.activate([
            holderView.heightAnchor.constraint(equalToConstant: 80),
            holderView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            holderView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            holderView.leadingAnchor.constraint(equalTo: view.leadingAnchor)
        ])
    }
    
    private func setupMessageTextField() {
        holderView.addSubview(messageTextField)
        
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

extension ConversationViewController: UICollectionViewDataSource {
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        print("s")
        return 10
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
