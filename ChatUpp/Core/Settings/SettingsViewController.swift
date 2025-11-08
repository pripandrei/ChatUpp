//
//  SettingsViewController.swift
//  ChatUpp
//
//  Created by Andrei Pripa on 8/29/23.
//

import UIKit
import Combine
import SkeletonView

class SettingsViewController: UIViewController, UICollectionViewDelegate
{
    weak var coordinatorDelegate: Coordinator?
    
    private var settingsViewModel: SettingsViewModel!
    private var collectionView: UICollectionView!
    private var dataSource: DataSource!
    private var collectionViewListHeader: ProfileEditingListHeaderCell?
    private var subscribers = Set<AnyCancellable>()
    
    override func viewDidLoad()
    {
        super.viewDidLoad()
        
        self.collectionView = makeCollectionView()
        self.dataSource = makeDataSource()
        self.configureCollectionViewLayout()
        self.createSnapshot()
    }
    
    convenience init() {
        self.init(nibName: nil, bundle: nil)
        self.settingsViewModel = SettingsViewModel()
        self.setupBinder()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: false)
    }

    deinit {
//        print("Settings ============ deinit")
    }
    
// MARK: - Binder
    
    func setupBinder()
    {
        settingsViewModel.isUserSignedOut.bind { [weak self] isSignedOut in
            if isSignedOut == true {
                Task { @MainActor in
                    self?.coordinatorDelegate?.handleSignOut()
                }
            }
        }
        
        settingsViewModel.$profileImageData
            .receive(on: DispatchQueue.main)
            .dropFirst()
            .sink { [weak self] imageData in
                self?.fillSupplementaryViewWithData()
            }.store(in: &subscribers)
    }
    
    // MARK: - DELETION PROVIDER HANDLER
    
    private func handleDeletionProviderPresentation(_ provider: String)
    {
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
    private func configureCollectionViewLayout()
    {
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
        configuration.backgroundColor = ColorManager.appBackgroundColor

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
            configuration.imageProperties.cornerRadius = 7
            configuration.imageProperties.reservedLayoutSize = CGSize(width: 22, height: 22)
            
            var backgroundConfiguration = UIBackgroundConfiguration.listGroupedCell()
            backgroundConfiguration.backgroundColor = ColorManager.listCellBackgroundColor
            
            cell.backgroundConfiguration = backgroundConfiguration
            cell.contentConfiguration = configuration
        }
        
        // Custom Header registration
        let headerRegistration = UICollectionView.SupplementaryRegistration<ProfileEditingListHeaderCell>(elementKind: UICollectionView.elementKindSectionHeader) { [weak self] supplementaryView, _, indexPath in
            
            guard let self = self else {return}
            
            supplementaryView.setupAdditionalCredentialsConstraints()
            self.collectionViewListHeader = supplementaryView
            
            self.toggleSkeletonAnimation(isActive: true)
            
            self.fillSupplementaryViewWithData()
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
    
    private func fillSupplementaryViewWithData()
    {
        guard let user = self.settingsViewModel.user else {return}
        
        collectionViewListHeader?.nameLabel.text = user.name
        collectionViewListHeader?.additionalCredentials.text = "\(user.phoneNumber ?? "") \u{25CF} \(user.nickname ?? "")"
        
        if let image = self.settingsViewModel.profileImageData
        {
            collectionViewListHeader?.imageView.image = UIImage(data: image)
        }
        else {
            collectionViewListHeader?.imageView.image = UIImage(named: "default_profile_photo")
        }
        toggleSkeletonAnimation(isActive: false)
    }
    
    private func createSnapshot() {
        var snapshot = SnapShot()
        snapshot.appendSections([0])
        snapshot.appendItems(SettingsItem.itemsData)
        dataSource.apply(snapshot)
    }
    
    private func toggleSkeletonAnimation(isActive: Bool)
    {
        collectionViewListHeader?.imageView.isSkeletonable = isActive
        collectionViewListHeader?.isSkeletonable = isActive
        
        if isActive {
            collectionViewListHeader?.imageView.showAnimatedGradientSkeleton()
        } else {
            collectionViewListHeader?.imageView.stopAnimating();
            collectionViewListHeader?.imageView.hideSkeleton()
        }
    }
}

//MARK: - COLLECTIONVIEW DELEGATE
extension SettingsViewController
{
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
extension SettingsViewController
{
    private func createProfileDeletionViewModel() -> ProfileDeletionViewModel
    {
        guard let dbUser = settingsViewModel.user else {fatalError("dbUser is missing")}
        return ProfileDeletionViewModel(user: dbUser)
    }
    
    private func createprofileEditingViewModel() -> ProfileEditingViewModel
    {
        guard let user = settingsViewModel.user else {fatalError("dbUser is missing")}
        
        // if imageData is nil, meaning user did not select picture, local default image will be used as profile picture
        guard let profilePicutre = settingsViewModel.profileImageData == nil ? UIImage(named: "default_profile_photo")?.pngData() : settingsViewModel.profileImageData else {fatalError("profilePicutre is missing")}
        let profileVM = ProfileEditingViewModel(user: user, profilePicutre: profilePicutre)
        
        profileVM.$profileDataIsEdited
            .sink { [weak self] isEdited in
                if isEdited == true {
                    self?.settingsViewModel.retrieveDataFromDB()
                }
            }.store(in: &subscribers)
        
        return profileVM
    }
}

//MARK: - Cleanup on sign out
extension SettingsViewController
{
    func cleanup()
    {
        collectionViewListHeader?.imageView.image = nil
        coordinatorDelegate = nil
        dataSource = nil
        collectionView = nil
        settingsViewModel = nil
        collectionViewListHeader = nil
        subscribers = Set()
        self.removeFromParent()
    }
}
