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
//        collectionView.layoutIfNeeded()
//        collectionView.reloadData()
    }
    
    func setupCoollectionView() {
        view.addSubview(collectionView)

        collectionView.backgroundColor = .brown

        setCollectionViewConstraints()
    }
    
    func setCollectionViewConstraints() {
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
        return 5
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: Cell.CustomCollectionViewCell, for: indexPath) as? CustomCollectionViewCell else { fatalError("Could not dequeu custom collection cell") }
        
        return cell
    }
}


extension ConversationViewController:  UICollectionViewDelegateFlowLayout {

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        print("Flow")
        return CGSize(width: 90, height: 60)
    }
}
