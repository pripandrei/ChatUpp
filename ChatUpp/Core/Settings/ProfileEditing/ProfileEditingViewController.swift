//
//  ProfileEditingViewController.swift
//  ChatUpp
//
//  Created by Andrei Pripa on 12/30/23.
//

import UIKit

class ProfileEditingViewController: UIViewController, UICollectionViewDelegate, UICollectionViewDataSource {
    
    weak var coordinatorDelegate: Coordinator!

    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = #colorLiteral(red: 0.1411764771, green: 0.3960784376, blue: 0.5647059083, alpha: 1)
        navigationController?.setNavigationBarHidden(true, animated: false)
        
        configureCollectionViewLayout()
        collectionView.register(CustomListCell.self, forCellWithReuseIdentifier: "ListCell")
    }

    
    lazy var collectionView = makeCollectionView()
    
    func makeCollectionView() -> UICollectionView {
        var configuration = UICollectionLayoutListConfiguration(appearance: .insetGrouped)
        configuration.backgroundColor = #colorLiteral(red: 0.1411764771, green: 0.3960784376, blue: 0.5647059083, alpha: 1)
        let layout = UICollectionViewCompositionalLayout.list(using: configuration)
        
        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.delegate = self
        collectionView.dataSource = self
        return collectionView
    }
    
    private func configureCollectionViewLayout() {
        view.addSubview(collectionView)
         
        
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            collectionView.topAnchor.constraint(equalTo: view.topAnchor),
            collectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            collectionView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            collectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor)
        ])
    }
}

//MARK: - COLLECTION VIEW DELEGATE
extension ProfileEditingViewController {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        4
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "ListCell", for: indexPath) as? CustomListCell else {fatalError("Could not deqeue CustomListCell")}
        
        return cell
    }
}

//MARK: - CUSTOM LIST CELL
class CustomListCell: UICollectionViewListCell {
    
    var textField: UITextField!
    
    override func updateConfiguration(using state: UICellConfigurationState) {
        var newConfiguration = UIBackgroundConfiguration.listGroupedCell().updated(for: state)
        let customColor = #colorLiteral(red: 0.1057919934, green: 0.2902272344, blue: 0.4154375792, alpha: 1).withAlphaComponent(0.5)
        newConfiguration.backgroundColor = customColor
        backgroundConfiguration = newConfiguration
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        textField = makeTextField()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func makeTextField() -> UITextField {
        let textfield = UITextField(frame: CGRect(origin: CGPoint.zero, size: CGSize(width: self.bounds.width, height: self.bounds.height)))
    //    textfield.backgroundColor = .carrot.withAlphaComponent(0.3)
        textfield.text = "settingItem.name"
        textfield.placeholder = "test"
        textfield.textColor = .black
        textfield.layer.sublayerTransform = CATransform3DMakeTranslation(20, 0, 0)
        self.contentView.addSubview(textfield)
        return textfield
    }
}

