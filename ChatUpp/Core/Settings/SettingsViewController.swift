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
    private lazy var collectionView: UICollectionView = makeCollectionView()
    private lazy var dataSource: DataSource = makeDataSource()
    private var collectionViewListHeader: CollectionViewListHeader?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        configureCollectionViewLayout()
        createSnapshot()
        setupBinder()
        Task {
           try await settingsViewModel.fetchUserFromDB()            
        }
//        setUpSignOutBtn()
//        binding()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
//        view.backgroundColor = .white
        navigationController?.setNavigationBarHidden(true, animated: false)
    }
    
//    override func viewWillDisappear(_ animated: Bool) {
//        super.viewWillDisappear(animated)
//        view.backgroundColor = #colorLiteral(red: 0.1411764771, green: 0.3960784376, blue: 0.5647059083, alpha: 1)
////        navigationController?.navigationBar.prefersLargeTitles = true
//        
//        navigationController?.setNavigationBarHidden(false, animated: false)
//    }
    
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

        configuration.separatorConfiguration.color = #colorLiteral(red: 0.6390894651, green: 0.6514347792, blue: 0.6907400489, alpha: 1).withAlphaComponent(0.6)
        let layout = UICollectionViewCompositionalLayout.list(using: configuration)
        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.delegate = self
        
        return collectionView
    }
    
    private func makeDataSource() -> DataSource {
        
        // Cell registration & configuration
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
        
        // Custom Header registration
        let headerRegistration = UICollectionView.SupplementaryRegistration<CollectionViewListHeader>(elementKind: UICollectionView.elementKindSectionHeader) { [weak self] supplementaryView, _, indexPath in
            self?.settingsViewModel.onUserFetch = { imageData, name in
                self?.collectionViewListHeader = supplementaryView
                DispatchQueue.main.async {
//                    AuthenticationManager.shared.modifyAuthUser(name: name)
//                    print(Auth.auth().currentUser?.displayName)
                    
                    supplementaryView.nameLabel.text = name
                    supplementaryView.imageView.image = UIImage(data: imageData)
                }
            }
        }
        
        // Data source initiation
        let dataSource = DataSource(collectionView: collectionView) { collectionView, indexPath, settingsItem in
            let cell =  collectionView.dequeueConfiguredReusableCell(using: cellRegistration, for: indexPath, item: settingsItem)
            return cell
        }
        
        // Supplementary view (Header) initiation
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
        case 0:
            coordinatorDelegate?.pushProfileEditingVC(viewModel: createprofileEditingViewModel())
        case 1: print("item 2")
        case 2: print("item 3")
        case 3: settingsViewModel.signOut()
        default: break
        }
    }
    
    private func createprofileEditingViewModel() -> ProfileEditingViewModel {
        guard let user = settingsViewModel.dbUser else {fatalError("dbUser is missing")}
        
        let name = user.name!
        let phone = user.phoneNumber
        let nickName = user.nickname
        guard let profilePicutre = settingsViewModel.imageData else {fatalError("profilePicutre is missing")}
        
//        guard let name = settingsViewModel.authUser?.name else {fatalError("Auth user is missing!")}
//        let phone = settingsViewModel.authUser?.phoneNumber
//        let nickName: String? = nil
////        let profilePicture =
        var profileVM = ProfileEditingViewModel(name: name, phone: phone, nickName: nickName, profilePicutre: profilePicutre)
        profileVM.userDataToTransferBack = { [weak self] name,phone,nickname,photo in
            guard let self = self else {return}
            
            if let name = name {
                collectionViewListHeader?.nameLabel.text = name
            }
            if let phone = phone {
                collectionViewListHeader?.additionalCredentials.text = phone
            }
            if let nickname = nickname {
                if let text = collectionViewListHeader?.additionalCredentials.text {
                    collectionViewListHeader?.additionalCredentials.text = "\(text) \(nickname)"
                } else {
                    collectionViewListHeader?.additionalCredentials.text = nickname
                }
            }
            if let photo = photo {
                collectionViewListHeader?.imageView.image = UIImage(data: photo)
            }
        }
        return profileVM
    }
}
