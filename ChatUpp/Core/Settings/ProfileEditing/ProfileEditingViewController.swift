//
//  ProfileEditingViewController.swift
//  ChatUpp
//
//  Created by Andrei Pripa on 12/30/23.
//

import UIKit
import Photos
import PhotosUI

final class ProfileEditingViewController: UIViewController, UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    
    weak var coordinatorDelegate: Coordinator!
    lazy var collectionView = makeCollectionView()
    
    var profileEditingViewModel: ProfileEditingViewModel!
    
    var headerCell: ProfileEditingListHeaderCell!
    
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
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        Utilities.setupNavigationBarAppearance()
    }
    
    private func setupNavigationBar() {
        Utilities.clearNavigationBarAppearance()
        setupNavigationBarItems()
    }
    
    //MARK: - BINDING
    
    private func setupBinding() {
        profileEditingViewModel.profileDataIsEdited.bind({ [weak self] isEdited in
            self?.coordinatorDelegate.dismissEditProfileVC()
        })
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
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: ReuseIdentifire.ProfileEditingCollectionCell.list.identifire, for: indexPath) as? ProfileEditingListCell else {fatalError("Could not deqeue CustomListCell")}
        
        cell.textField.placeholder = ProfileEditingViewModel.ProfileEditingItemsPlaceholder.allCases[indexPath.item].rawValue
        if profileEditingViewModel.userDataItems[indexPath.item] != nil {
            cell.textField.text = profileEditingViewModel.userDataItems[indexPath.item]
        }
        cell.onTextChanged = { text in
            self.profileEditingViewModel.applyTitle(title: text, toItem: indexPath.item)
        }
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
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


//MARK: - CUSTOM LIST CELL
class ProfileEditingListCell: UICollectionViewListCell, UITextFieldDelegate {
    
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

    func textField(_ textField: UITextField,
                   shouldChangeCharactersIn range: NSRange,
                   replacementString string: String) -> Bool
    {
        if let text = textField.text as NSString? {
            let updatedText = text.replacingCharacters(in: range, with: string)
            onTextChanged?(updatedText as String)
        }
        return true
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
        
        results.forEach { result in
            result.itemProvider.loadObject(ofClass: UIImage.self) { [weak self] reading, error in
                guard let image = reading as? UIImage, error == nil else {
                    print("Could not read image!")
                    return
                }
                guard let data = image.jpegData(compressionQuality: 0.5) else {return}
                
                self?.profileEditingViewModel.editedProfilePhoto = data
                Task { @MainActor in
                    self?.headerCell.imageView.image = image                    
                }
            }
        }
    }
}
