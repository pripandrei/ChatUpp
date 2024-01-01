//
//  ProfileEditingViewController.swift
//  ChatUpp
//
//  Created by Andrei Pripa on 12/30/23.
//

import UIKit

final class ProfileEditingViewController: UIViewController, UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    
    weak var coordinatorDelegate: Coordinator!
    lazy var collectionView = makeCollectionView()
    
    var profileEditingViewModel: ProfileEditingViewModel!
    
    convenience init(viewModel: ProfileEditingViewModel) {
        self.init()
        self.profileEditingViewModel = viewModel
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        
//        view.backgroundColor = #colorLiteral(red: 0.1411764771, green: 0.3960784376, blue: 0.5647059083, alpha: 1)
//        navigationController?.setNavigationBarHidden(true, animated: false)
        
        configureCollectionViewLayout()
        collectionView.register(CustomListCell.self, forCellWithReuseIdentifier: "ListCell")
        collectionView.register(CollectionViewListHeader.self, forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader, withReuseIdentifier: "Header")
        Utilities.adjustNavigationBarAppearance()
        setupNavigationBarItems()
    }
    
    
//    override func viewWillAppear(_ animated: Bool) {
//        super.viewWillAppear(animated)
//        setupNavigationBarItems()
//    }
    func setupNavigationBarItems() {
        navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: .cancel, target: self, action: #selector(closeProfileVC))
        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(closeProfileVC))
//        let img = UIImage(named: "appearance_icon")
    }
    
    @objc func closeProfileVC() {
        coordinatorDelegate.dismissEditProfileVC()
    }
    
    private func makeCollectionView() -> UICollectionView {
        var configuration = UICollectionLayoutListConfiguration(appearance: .insetGrouped)
        configuration.backgroundColor = #colorLiteral(red: 0.1411764771, green: 0.3960784376, blue: 0.5647059083, alpha: 1)
        configuration.headerMode = .supplementary
        
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
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        profileEditingViewModel.items.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "ListCell", for: indexPath) as? CustomListCell else {fatalError("Could not deqeue CustomListCell")}
        
        cell.textField.placeholder = ProfileEditingViewModel.ProfileEditingItemsPlaceholder.allCases[indexPath.item].rawValue
        if  profileEditingViewModel.items[indexPath.item] != nil {
            cell.textField.text = profileEditingViewModel.items[indexPath.item]
        }
        cell.onTextChanged = { text in
            self.profileEditingViewModel.applyTitle(title: text, toItem: indexPath.item)
        }
        return cell
    }
    
    
    func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        guard let headerCell = collectionView.dequeueReusableSupplementaryView(
            ofKind: kind,
            withReuseIdentifier: "Header",
            for: indexPath) as? CollectionViewListHeader
        else {fatalError("Could not deqeue CollectionViewListHeader")}
        
        headerCell.imageView.image = UIImage(named: "1024")
        headerCell.setupNewPhotoConstraints()
        return headerCell
    }
    
}



//MARK: - CUSTOM LIST CELL
class CustomListCell: UICollectionViewListCell, UITextFieldDelegate {
    
    var textField: UITextField!
    
    var onTextChanged: ((String) -> Void)?
    
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
        
        textfield.delegate = self
        textfield.textColor = .black
        textfield.layer.sublayerTransform = CATransform3DMakeTranslation(20, 0, 0)
        self.contentView.addSubview(textfield)
        
//        var placeHolder: [NSAttributedString.Key: Any] = [.foregroundColor: #colorLiteral(red: 0.2549019754, green: 0.2745098174, blue: 0.3019607961, alpha: 1)]
//        let attr = NSAttributedString(string: "", attributes: placeHolder)
//        textfield.attributedPlaceholder = attr
        
        return textfield
    }
    
    
    func textFieldDidEndEditing(_ textField: UITextField) {
        onTextChanged?(textField.text ?? "empty")
    }
    
    
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        print("change")
        return true
    }
}

