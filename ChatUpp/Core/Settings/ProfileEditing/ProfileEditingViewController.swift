//
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

final class ProfileEditingViewController: UIViewController, UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    
    weak var coordinatorDelegate: Coordinator!
    
    private lazy var collectionView = makeCollectionView()
    private var profileEditingViewModel: ProfileEditingViewModel!
    private var headerCell: ProfileEditingListHeaderCell!
    private var cancellables: Set<AnyCancellable> = Set<AnyCancellable>()
    
    convenience init(viewModel: ProfileEditingViewModel) {
        self.init()
        self.profileEditingViewModel = viewModel
        self.setupBinding()
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        
//        view.backgroundColor = #colorLiteral(red: 0.1411764771, green: 0.3960784376, blue: 0.5647059083, alpha: 1)
//        navigationController?.setNavigationBarHidden(true, animated: false)
        
        configureCollectionViewLayout()
        registerCells()
        setupNavigationBar()
    }
    
    deinit {
        print("ProfileEditingViewController was deinited")
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        Utilities.setupNavigationBarAppearance()
    }
    
    private func setupNavigationBar() {
        Utilities.clearNavigationBarAppearance()
        setupNavigationBarItems()
    }
    
    //MARK: - BINDING
    
    private func setupBinding()
    {
        profileEditingViewModel.$profileDataIsEdited
            .sink { [weak self] isEdited in
                if isEdited == true {
                    self?.coordinatorDelegate.dismissEditProfileVC()
                }
            }.store(in: &cancellables)
        
    }

    private func setupNavigationBarItems() {
        navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: .cancel, target: self, action: #selector(closeProfileVC))
        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(saveEditedData))
    }
    
    @objc func closeProfileVC() {
        coordinatorDelegate.dismissEditProfileVC()
    }
    
    @objc func saveEditedData() {
        profileEditingViewModel.handleProfileDataUpdate()
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
    
    private func registerCells() {
        collectionView.register(ProfileEditingListCell.self, forCellWithReuseIdentifier: ReuseIdentifire.ProfileEditingCollectionCell.list.identifire)
        collectionView.register(ProfileEditingListHeaderCell.self, forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader, withReuseIdentifier: ReuseIdentifire.ProfileEditingCollectionCell.header.identifire)
    }
}

//MARK: - COLLECTION VIEW DELEGATE
extension ProfileEditingViewController {
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        profileEditingViewModel.userDataItems.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell
    {
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: ReuseIdentifire.ProfileEditingCollectionCell.list.identifire, for: indexPath) as? ProfileEditingListCell else {fatalError("Could not deqeue CustomListCell")}
        
        cell.textField.placeholder = ProfileEditingViewModel.ProfileEditingItemsPlaceholder.allCases[indexPath.item].rawValue
        
        if profileEditingViewModel.userDataItems[indexPath.item] != nil {
            cell.textField.text = profileEditingViewModel.userDataItems[indexPath.item]
        }
        
        cell.onTextChanged = { [weak self] text in
            self?.profileEditingViewModel.applyTitle(title: text, toItem: indexPath.item)
        }
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView
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
        addGestureToNewPhotoLabel()
        return headerCell
    }
}


// MARK: - PHOTO PICKER

extension ProfileEditingViewController: PHPickerViewControllerDelegate {
    
    func addGestureToNewPhotoLabel() {
        headerCell.newPhotoLabel.isUserInteractionEnabled = true
        let tap = UITapGestureRecognizer(target: self, action: #selector(initiatePhotoPicker))
        headerCell.newPhotoLabel.addGestureRecognizer(tap)
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
//    
    private func updateImage(_ image: UIImage)
    {
        self.profileEditingViewModel.updateProfilePhotoData(image.getJpegData())
        self.headerCell.imageView.image = image
    }
    
    private func downsampleImage(_ image: UIImage) -> UIImage
    {
        let newSize = ImageSample.user.sizeMapping[.original]!
        return image.downsample(toSize: newSize, withCompressionQuality: 0.6)
    }
}

extension ProfileEditingViewController: CropViewControllerDelegate
{
    func cropViewController(_ cropViewController: CropViewController, didCropToImage image: UIImage, withRect cropRect: CGRect, angle: Int)
    {
        let downsampledImage = downsampleImage(image)
        updateImage(downsampledImage)
        cropViewController.dismiss(animated: true)
    }
}
