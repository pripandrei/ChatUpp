//
//  SettingsViewController.swift
//  ChatUpp
//
//  Created by Andrei Pripa on 8/29/23.
//

import UIKit
import FirebaseAuth

class SettingsViewController: UIViewController {
    
    weak var coordinatorDelegate: Coordinator?
    
    let settingsViewModel = SettingsViewModel()
    let signOutBtn = UIButton()
//    let tempLabelName: UILabel = UILabel()
    
    let tempCreateChatDocId: UIButton = UIButton()
    
    private lazy var collectionView = makeCollectionView()
    private lazy var dataSource = makeDataSource()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        configureCollectionViewLayout()
        createSnapshot()
        setupBinder()
        
//        setUpSignOutBtn()
//        binding()
        view.backgroundColor = .white
    }
    
    deinit {
        print("Settings ============ deinit")
    }
    

    private func configureTempCreateChatDocIdConstraints() {
        tempCreateChatDocId.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            tempCreateChatDocId.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            tempCreateChatDocId.centerYAnchor.constraint(equalTo: view.centerYAnchor, constant: -250),
            tempCreateChatDocId.heightAnchor.constraint(equalToConstant: 30),
            tempCreateChatDocId.widthAnchor.constraint(equalToConstant: 280)
        ])
    }
    
    

    
//    func binding() {
//        settingsViewModel.setProfileName = { [weak self] name in
////            self?.tempLabelName.text = name
//        }
//    }
    
// MARK: - Binder
    
    func setupBinder() {
        settingsViewModel.userIsSignedOut.bind { [weak self] isSignedOut in
            if isSignedOut == true {
                self?.coordinatorDelegate?.handleSignOut()
            }
        }
    }
    
// MARK: - setup ViewController
    
    func setUpSignOutBtn() {
        view.addSubview(signOutBtn)
        
        signOutBtn.configuration = .filled()
        signOutBtn.configuration?.title = "Sign Out"
        signOutBtn.addTarget(settingsViewModel, action: #selector(settingsViewModel.signOut), for: .touchUpInside)
        signOutBtn.configuration?.buttonSize = .large
        
        setSignOutBtnConstraints()
    }
    
    private func setSignOutBtnConstraints() {
        signOutBtn.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
//            signOutBtn.centerXAnchor.constraint(equalTo: view.centerXAnchor, constant: 10)
            signOutBtn.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            signOutBtn.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])
    }
    
    
    
}


//MARK: - SETTINGS COLLECTION VIEW

extension SettingsViewController {
    
    typealias DataSource = UICollectionViewDiffableDataSource<Int, SettingsItem>
    typealias SnapShot = NSDiffableDataSourceSnapshot<Int, SettingsItem>
    
    private func makeCollectionView() -> UICollectionView {
        var configuration = UICollectionLayoutListConfiguration(appearance: .insetGrouped)
//        configuration.headerMode = .supplementary
        let layout = UICollectionViewCompositionalLayout.list(using: configuration)
        
        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        return collectionView
    }
    
    private func makeDataSource() -> DataSource {
        let cellRegistration = UICollectionView.CellRegistration<UICollectionViewListCell, SettingsItem> { cell, indexPath, settingsItem in
            let settingItem = SettingsItem.itemsData[indexPath.item]
            
            var configuration = cell.defaultContentConfiguration()
            configuration.text = settingItem.name
//            configuration.image = UIImage(named: settingItem.iconName)
            configuration.image = UIImage(systemName: "circle.fill")!
            cell.contentConfiguration = configuration
        }
        
        let dataSource = DataSource(collectionView: collectionView) { collectionView, indexPath, settingsItem in
            return collectionView.dequeueConfiguredReusableCell(using: cellRegistration, for: indexPath, item: settingsItem)
        }
        return dataSource
    }
    
    private func createSnapshot() {
        var snapshot = SnapShot()
        snapshot.appendSections([0])
        snapshot.appendItems(SettingsItem.itemsData)
        dataSource.apply(snapshot)
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


struct SettingsItem: Hashable {
    let name: String
    let iconName: String
    
    static var itemsData = [
        SettingsItem(name: "Edit profile", iconName: "profile_icon"),
        SettingsItem(name: "Switch apperance", iconName: "apperance_icon"),
        SettingsItem(name: "Delete profile", iconName: "delete_profile_icon"),
        SettingsItem(name: "Log out", iconName: "log_out_icon")
    ]
}
