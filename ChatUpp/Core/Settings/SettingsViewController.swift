//
//  SettingsViewController.swift
//  ChatUpp
//
//  Created by Andrei Pripa on 8/29/23.
//

import UIKit
import FirebaseAuth

class SettingsViewController: UIViewController, UICollectionViewDelegate {
    
    weak var coordinatorDelegate: Coordinator?
    
    private let settingsViewModel = SettingsViewModel()
    
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
    
// MARK: - Binder
    
    func setupBinder() {
        settingsViewModel.userIsSignedOut.bind { [weak self] isSignedOut in
            if isSignedOut == true {
                self?.coordinatorDelegate?.handleSignOut()
            }
        }
    }
    
    //    func binding() {
    //        settingsViewModel.setProfileName = { [weak self] name in
    ////            self?.tempLabelName.text = name
    //        }
    //    }
}

// MARK: - SETUP UI
extension SettingsViewController {
    
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

//MARK: - SETTINGS COLLECTION VIEW
extension SettingsViewController {
    
    typealias DataSource = UICollectionViewDiffableDataSource<Int, SettingsItem>
    typealias SnapShot = NSDiffableDataSourceSnapshot<Int, SettingsItem>
    
    private func makeCollectionView() -> UICollectionView {
        var configuration = UICollectionLayoutListConfiguration(appearance: .insetGrouped)
        
        configuration.headerMode = .supplementary
        configuration.backgroundColor = #colorLiteral(red: 0.1411764771, green: 0.3960784376, blue: 0.5647059083, alpha: 1)
//        configuration.backgroundColor = #colorLiteral(red: 0.1585061252, green: 0.4498263001, blue: 0.643848896, alpha: 1)
//        configuration.showsSeparators = false
        configuration.separatorConfiguration.color = #colorLiteral(red: 0.6390894651, green: 0.6514347792, blue: 0.6907400489, alpha: 1).withAlphaComponent(0.6)
        let layout = UICollectionViewCompositionalLayout.list(using: configuration)
        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.delegate = self
        
        
        return collectionView
    }
    
    private func makeDataSource() -> DataSource {
        let cellRegistration = UICollectionView.CellRegistration<UICollectionViewListCell, SettingsItem> { cell, indexPath, settingsItem in
            let settingItem = SettingsItem.itemsData[indexPath.item]
            
            var configuration = UIListContentConfiguration.cell()
            configuration.text = settingItem.name
            configuration.image = UIImage(named: settingItem.iconName)!
            configuration.textProperties.color = .white
            configuration.imageProperties.cornerRadius = 5
            configuration.imageProperties.reservedLayoutSize = CGSize(width: 22, height: 22)
            
            var backgroundConfiguration = UIBackgroundConfiguration.listGroupedCell()
            backgroundConfiguration.backgroundColor = #colorLiteral(red: 0.1057919934, green: 0.2902272344, blue: 0.4154375792, alpha: 1).withAlphaComponent(0.5)
            
            cell.backgroundConfiguration = backgroundConfiguration
            cell.contentConfiguration = configuration
        }
        
//        let headerRegistration = UICollectionView.SupplementaryRegistration<CustomHeader2>(elementKind: UICollectionView.elementKindSectionHeader) { supplementaryView, elementKind, indexPath in
//
//            // Create a custom configuration instance
//            var contentConfiguration = UIListContentConfiguration.cell()
//
//            // Set up the configuration for vertical image and text arrangement
//            contentConfiguration.imageProperties.maximumSize = CGSize(width: 100, height: 100) // Set your image size
//            contentConfiguration.imageProperties.reservedLayoutSize = CGSize(width: 100, height: 100) // Reserve space for the image
//
//            contentConfiguration.image = UIImage(named: "1024")
//            // Set the text properties
//            contentConfiguration.text = "Your Text"
//            contentConfiguration.textProperties.numberOfLines = 0 // Allow multiple lines for the text
//            contentConfiguration.textProperties.alignment = .center // Center align the text
//
//            supplementaryView.contentConfiguration = contentConfiguration
//        }
        
        let headerRegistration = UICollectionView.SupplementaryRegistration<CustomHeader>(elementKind: UICollectionView.elementKindSectionHeader) { supplementaryView, _, indexPath in
            supplementaryView.imageView.image = UIImage(named: "1024")
            supplementaryView.textLabel.text = "Andrei Pripa"
        }
        
        let dataSource = DataSource(collectionView: collectionView) { collectionView, indexPath, settingsItem in
            return collectionView.dequeueConfiguredReusableCell(using: cellRegistration, for: indexPath, item: settingsItem)
        }
        
        dataSource.supplementaryViewProvider = { collectionView, elementKind, indexPath in
            collectionView.dequeueConfiguredReusableSupplementary(using: headerRegistration, for: indexPath)
            
        }
        
        return dataSource
    }
    
    private func createSnapshot() {
        var snapshot = SnapShot()
        snapshot.appendSections([0])
        snapshot.appendItems(SettingsItem.itemsData)
        dataSource.apply(snapshot)
    }
    
    //MARK: - DELEGATE
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        collectionView.deselectItem(at: indexPath, animated: true)
        
        switch indexPath.item {
        case 0:  print("item 1")
        case 1:  print("item 2")
        case 2: print("item 3")
        case 3: settingsViewModel.signOut()
        default: break
        }
    }

}


struct SettingsItem: Hashable {
    let name: String
    let iconName: String
    
    static var itemsData = [
        SettingsItem(name: "Edit profile", iconName: "edit_profile_icon"),
        SettingsItem(name: "Switch appearance", iconName: "appearance_icon"),
        SettingsItem(name: "Delete profile", iconName: "delete_profile_icon"),
        SettingsItem(name: "Log out", iconName: "log_out_icon")
    ]
}


class CustomHeader: UICollectionViewListCell {

    let imageView: UIImageView = {
        let imageView = UIImageView()
        imageView.layer.cornerRadius = 10
        imageView.clipsToBounds = true
        imageView.translatesAutoresizingMaskIntoConstraints = false
        return imageView
    }()
    
    let textLabel: UILabel = {
        let name = UILabel()
//        name.text = "Andrei Pripa"
        name.textAlignment = .center
        name.textColor = .white
        name.font = UIFont(name: "Helvetica", size: 25)
        name.translatesAutoresizingMaskIntoConstraints = false
        return name
    }()

   override init(frame: CGRect) {
    super.init(frame: frame)
       addSubview(imageView)
       addSubview(textLabel)
      
       NSLayoutConstraint.activate([
        imageView.topAnchor.constraint(equalTo: topAnchor, constant: 10),
        imageView.heightAnchor.constraint(equalToConstant: 110),
        imageView.widthAnchor.constraint(equalToConstant: 110),
        imageView.centerXAnchor.constraint(equalTo: centerXAnchor),
 
        textLabel.topAnchor.constraint(equalTo: imageView.bottomAnchor, constant: 8),
        textLabel.leadingAnchor.constraint(equalTo: leadingAnchor),
        textLabel.trailingAnchor.constraint(equalTo: trailingAnchor),
        textLabel.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -20)
       ])
   }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
