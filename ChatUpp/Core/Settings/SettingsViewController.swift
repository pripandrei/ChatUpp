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
    
    // Initially settingsVC interaction is disabled
    // until user data is fetched
    // This is only when user logs in for the first time
    var shouldEnableInteractionOnSelf = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        configureCollectionViewLayout()
        createSnapshot()
    }
    
    convenience init() {
        self.init(nibName: nil, bundle: nil)
        self.setupBinder()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
//        view.backgroundColor = .white
        navigationController?.setNavigationBarHidden(true, animated: false)
    }

    deinit {
        print("Settings ============ deinit")
    }
    
// MARK: - Binder
    
    func setupBinder() {
        settingsViewModel.userIsSignedOut.bind { [weak self] isSignedOut in
            if isSignedOut == true {
                Task { @MainActor in
                    self?.coordinatorDelegate?.handleSignOut()
                }
            }
        }
        settingsViewModel.onUserFetched = { [weak self] in
            self?.shouldEnableInteractionOnSelf = true
        }
    }
    
    // MARK: - DELETION PROVIDER HANDLER
    
    private func handleDeletionProviderPresentation(_ provider: String) {
        switch provider {
        case "google.com", "password": self.createDeletionAlertController()
        case "phone": self.coordinatorDelegate?.showProfileDeletionVC(viewModel: self.createProfileDeletionViewModel())
        default: break
        }
    }
    
    // MARK: - ALERT CONTROLLER
    
    private func createDeletionAlertController() {
        Task {@MainActor in
            let alert = UIAlertController(title: "Alert", message: "Delete this account? This acction can not be undone!", preferredStyle: .alert)
            let cancel = UIAlertAction(title: "Cancel", style: .cancel)
            let delete = UIAlertAction(title: "Delete", style: .destructive) { _ in
                Task {
                    do {
                        try await self.settingsViewModel.deleteUser()
                        await self.settingsViewModel.signOut()
                    } catch {
                        print("Error while deleting User!: ", error.localizedDescription)
                    }
                }
            }
            alert.addAction(cancel)
            alert.addAction(delete)
            present(alert, animated: true)
        }
    }
}

// MARK: - SETUP COLLECTION VIEW LAYOUT
extension SettingsViewController
{
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
            configuration.image = UIImage(named: settingItem.iconName)
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
            supplementaryView.setupAdditionalCredentialsConstraints()
            self?.collectionViewListHeader = supplementaryView
            
            guard let user = self?.settingsViewModel.dbUser else {return}
            
            supplementaryView.nameLabel.text = user.name
            supplementaryView.additionalCredentials.text = "\(user.phoneNumber ?? "") \u{25CF} \(user.nickname ?? "")"
            if let image = self?.settingsViewModel.imageData {
                supplementaryView.imageView.image = UIImage(data: image)
            } else {
                supplementaryView.imageView.image = UIImage(named: "default_profile_photo")
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
}

//MARK: - COLLECTIONVIEW DELEGATE
extension SettingsViewController {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        collectionView.deselectItem(at: indexPath, animated: true)
        
        switch indexPath.item {
        case 0:
            coordinatorDelegate?.pushProfileEditingVC(viewModel: createprofileEditingViewModel())
        case 1: print("item 2")
        case 2:
            handleDeletionProviderPresentation(settingsViewModel.authProvider)
        case 3: Task { await settingsViewModel.signOut() }
        default: break
        }
    }
}


//MARK: - Settings items ViewModel's
extension SettingsViewController {
    
    private func createProfileDeletionViewModel() -> ProfileDeletionViewModel {
        guard let dbUser = settingsViewModel.dbUser else {fatalError("dbUser is missing")}
        return ProfileDeletionViewModel(dbUser: dbUser)
    }
    
    private func createprofileEditingViewModel() -> ProfileEditingViewModel {
        guard let user = settingsViewModel.dbUser else {fatalError("dbUser is missing")}
        
        // if imageData is nil, meaning user did not select picture, local default image will be used as profile picture
        guard let profilePicutre = settingsViewModel.imageData == nil ? UIImage(named: "default_profile_photo")?.pngData() : settingsViewModel.imageData else {fatalError("profilePicutre is missing")}
        let profileVM = ProfileEditingViewModel(dbUser: user, profilePicutre: profilePicutre)
        
        profileVM.userDataToTransferOnSave = { [weak self] dbUser, photoData in
            guard let self = self else {return}
            
            settingsViewModel.updateUserData(dbUser,photoData)
            
            if let name = dbUser.name {
                self.collectionViewListHeader?.nameLabel.text = name
            }
            if let phone = dbUser.phoneNumber {
                self.collectionViewListHeader?.additionalCredentials.text = phone
            }
            if let nickname = dbUser.nickname {
                if let text = self.collectionViewListHeader?.additionalCredentials.text {
                    self.collectionViewListHeader?.additionalCredentials.text = "\(text) \(nickname)"
                } else {
                    self.collectionViewListHeader?.additionalCredentials.text = nickname
                }
            }
            if let photo = photoData {
                self.collectionViewListHeader?.imageView.image = UIImage(data: photo)
                
            }
        }
        return profileVM
    }
}


//final class SettingsDataSource: UICollectionViewDiffableDataSource<Int, SettingsItem> {
//
//}
