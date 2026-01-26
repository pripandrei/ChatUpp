
//  ProfileEditingViewController.swift
//  ChatUpp
//
//  Created by Andrei Pripa on 12/30/23.
//

import UIKit
import Photos
import PhotosUI
import Combine
import CropViewController
import NVActivityIndicatorView

final class ProfileEditingViewController: UIViewController,
                                          UICollectionViewDelegate,
                                          UICollectionViewDataSource,
                                          UICollectionViewDelegateFlowLayout
{
    weak var coordinatorDelegate: Coordinator!
    
    private lazy var collectionView = makeCollectionView()
    private var profileEditingViewModel: ProfileEditingViewModel!
    private var headerCell: ProfileEditingListHeaderCell!
    private var cancellables: Set<AnyCancellable> = Set<AnyCancellable>()
    
    private(set) lazy var activityIndicator: NVActivityIndicatorView = {
        let activityIndicator = NVActivityIndicatorView(frame: CGRect(x: 0, y: 0, width: 40, height: 40),
                                                        type: .circleStrokeSpin,
                                                        color: .link,
                                                        padding: 2)
        activityIndicator.translatesAutoresizingMaskIntoConstraints = false
        return activityIndicator
    }()
    
    convenience init(viewModel: ProfileEditingViewModel) {
        self.init()
        self.profileEditingViewModel = viewModel
        self.setupBinding()
    }

    override func viewDidLoad()
    {
        super.viewDidLoad()
        
//        navigationController?.setNavigationBarHidden(true, animated: false)
        configureCollectionViewLayout()
        registerCells()
        setupNavigationBar()
        setupActivityIndicatorConstraint()
    }
    
    deinit {
//        print("ProfileEditingViewController was deinited")
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
    }
    
    private func setupNavigationBar()
    {
        setupNavigationBarItems()
    }
    
    //MARK: - BINDING
    
    private func setupBinding()
    {
        profileEditingViewModel.$profileDataIsEdited
            .sink { [weak self] isEdited in
                if isEdited == true
                {
                    self?.activityIndicator.stopAnimating()
                    self?.coordinatorDelegate.dismissEditProfileVC()
                }
            }.store(in: &cancellables)
        
    }

    /// Navigation setup
    ///
    private func setupNavigationBarItems()
    {
        navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: .cancel,
                                                           target: self,
                                                           action: #selector(closeProfileVC))
        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .done,
                                                            target: self,
                                                            action: #selector(saveEditedData))
        navigationItem.leftBarButtonItem?.tintColor = ColorScheme.actionButtonsTintColor
        navigationItem.rightBarButtonItem?.tintColor = ColorScheme.actionButtonsTintColor
    }
    
    @objc func closeProfileVC() {
        profileEditingViewModel.triggerUpdate()
        coordinatorDelegate.dismissEditProfileVC()
    }
    
    @objc func saveEditedData()
    {
        activityIndicator.startAnimating()
        profileEditingViewModel.handleProfileDataUpdate()
    }
    
    /// collection view setup
    ///
    private func makeCollectionView() -> UICollectionView
    {
        var configuration = UICollectionLayoutListConfiguration(appearance: .insetGrouped)
        configuration.backgroundColor = ColorScheme.appBackgroundColor
        configuration.headerMode = .supplementary
        configuration.showsSeparators = true
//        configuration.separatorConfiguration.bottomSeparatorVisibility = .visible
        
        
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
    
    private func registerCells() {
        collectionView.register(ProfileEditingListCell.self, forCellWithReuseIdentifier: ReuseIdentifire.ProfileEditingCollectionCell.list.identifire)
        collectionView.register(ProfileEditingListHeaderCell.self, forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader, withReuseIdentifier: ReuseIdentifire.ProfileEditingCollectionCell.header.identifire)
    }
    
    // Loading indicator setup
    
    private func setupActivityIndicatorConstraint()
    {
        view.addSubview(activityIndicator)
        
        NSLayoutConstraint.activate([
            activityIndicator.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            activityIndicator.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])
    }
}

//MARK: - COLLECTION VIEW DATA SOURCE
extension ProfileEditingViewController
{
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        profileEditingViewModel.userDataItems.count
    }
    
    func collectionView(_ collectionView: UICollectionView,
                        cellForItemAt indexPath: IndexPath) -> UICollectionViewCell
    {
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: ReuseIdentifire.ProfileEditingCollectionCell.list.identifire, for: indexPath) as? ProfileEditingListCell else {fatalError("Could not deqeue CustomListCell")}
        
        let placeholder = ProfileEditingViewModel.ProfileEditingItemsPlaceholder.allCases[indexPath.item]
        let textFieldText = profileEditingViewModel.userDataItems[indexPath.item]
        
        cell.configureCell(with: textFieldText, placeholder: placeholder)

        cell.onTextChanged = { [weak self] text in
            self?.profileEditingViewModel.applyTitle(title: text, toItem: indexPath.item)
        }
        return cell
    }

    func collectionView(_ collectionView: UICollectionView,
                        viewForSupplementaryElementOfKind kind: String,
                        at indexPath: IndexPath) -> UICollectionReusableView
    {
        guard let headerCell = collectionView.dequeueReusableSupplementaryView(
            ofKind: kind,
            withReuseIdentifier: ReuseIdentifire.ProfileEditingCollectionCell.header.identifire,
            for: indexPath) as? ProfileEditingListHeaderCell
        else {
            fatalError("Could not deqeue CollectionViewListHeader")
        }
        self.headerCell = headerCell
        headerCell.imageView.image = UIImage(data: profileEditingViewModel.initialProfilePhoto)
        headerCell.setupNewPhotoConstraints()
        addGestureToNewPhotoLabelAndImageView()
        return headerCell
    }
}

//MARK: - COLLECTION VIEW DELEGATE
extension ProfileEditingViewController
{
    func collectionView(_ collectionView: UICollectionView,
                        didSelectItemAt indexPath: IndexPath)
    {
        collectionView.deselectItem(at: indexPath, animated: true)
        let nickname = profileEditingViewModel.userNickname
        
        guard let cell = collectionView.cellForItem(at: indexPath) as? ProfileEditingListCell else {return}
        let onUpdate = { [weak self] (updatedNickname: String) in
            cell.textField.text = updatedNickname
            self?.profileEditingViewModel.updateUsername(updatedNickname)
        }
        coordinatorDelegate.showNicknameUpdateScreen(nickname, updateCompletion: onUpdate)
    }
}


// MARK: - PHOTO PICKER

extension ProfileEditingViewController: PHPickerViewControllerDelegate {
    
    func addGestureToNewPhotoLabelAndImageView()
    {
        let labeTap = UITapGestureRecognizer(target: self, action: #selector(initiatePhotoPicker))
        let imageTap = UITapGestureRecognizer(target: self, action: #selector(initiatePhotoPicker))
        headerCell.newPhotoLabel.addGestureRecognizer(labeTap)
        headerCell.imageView.addGestureRecognizer(imageTap)
    }
    
    @objc func initiatePhotoPicker() {
        configurePhotoPicker()
    }
    
    private func configurePhotoPicker() {
        var configuration = PHPickerConfiguration()
        configuration.selectionLimit = 1
        configuration.filter = .images
        let pickerVC = PHPickerViewController(configuration: configuration)
        pickerVC.delegate = self
        present(pickerVC, animated: true)
    }
    
    func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
        picker.dismiss(animated: true)
        
        results.first?.itemProvider.loadObject(ofClass: UIImage.self) { image, error in
            guard error == nil else {return}
            guard let image = image as? UIImage else {return}
            
            Task { @MainActor in
                self.presentCropViewController(image: image)
            }
        }
    }
    
    private func presentCropViewController(image: UIImage)
    {
        let cropVC = CropViewController(croppingStyle: .circular, image: image)
        cropVC.delegate = self
        cropVC.aspectRatioLockEnabled = true
        cropVC.resetAspectRatioEnabled = false
        cropVC.toolbar.clampButtonHidden = true
        
        present(cropVC, animated: true)
    }
}

extension ProfileEditingViewController: CropViewControllerDelegate
{
    func cropViewController(_ cropViewController: CropViewController,
                            didCropToImage image: UIImage,
                            withRect cropRect: CGRect,
                            angle: Int)
    {
//        let downsampledImage = downsampleImage(image)
        let imageSampleRepo = ImageSampleRepository(image: image, type: .user)
        if let mediumSampleImageData = imageSampleRepo.samples[.original] {
            self.headerCell.imageView.image = UIImage(data: mediumSampleImageData)
        }
        self.profileEditingViewModel.updateImageRepository(repository: imageSampleRepo)
        cropViewController.dismiss(animated: true)
    }
}
