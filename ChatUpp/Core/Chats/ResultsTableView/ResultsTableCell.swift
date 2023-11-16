//
//  ResultsTableCell.swift
//  ChatUpp
//
//  Created by Andrei Pripa on 11/9/23.
//

import UIKit
import SkeletonView

final class ResultsTableCell: UITableViewCell {
    
    private var cellViewModel: ResultsCellViewModel!
    var userNameLabel = UILabel()
    var userImage = UIImageView()
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        
        self.isSkeletonable = true
        contentView.isSkeletonable = true
        contentView.backgroundColor = #colorLiteral(red: 0.1411764771, green: 0.3960784376, blue: 0.5647059083, alpha: 1)
        setupUserImage()
        setupUserName()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func configure(viewModel: ResultsCellViewModel) {
        self.cellViewModel = viewModel
        setupBinding()
        
        userNameLabel.text = cellViewModel.userName
        
        guard let imageData = cellViewModel.userImageData.value else {
            cellViewModel.fetchImageData()
            return
        }
        let image = UIImage(data: imageData)
        self.userImage.image = image
    }
    
    private func setupBinding() {
        cellViewModel.userImageData.bind { [weak self] data in
            if let imageData = data {
                let image = UIImage(data: imageData)
                DispatchQueue.main.async {
                    self?.userImage.image = image
                }
            }
        }
    }
    
    private func setupUserImage() {
        contentView.addSubview(userImage)
        
        userImage.isSkeletonable = true
        userImage.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            userImage.leadingAnchor.constraint(equalTo: self.leadingAnchor, constant: 10),
            userImage.topAnchor.constraint(equalTo: self.topAnchor, constant: 5),
            userImage.bottomAnchor.constraint(equalTo: self.bottomAnchor, constant: -5),
            userImage.widthAnchor.constraint(equalToConstant: 45)
        ])
    }
    
    private func setupUserName() {
        contentView.addSubview(userNameLabel)
        
        userNameLabel.isSkeletonable = true
        userNameLabel.skeletonTextLineHeight = .fixed(10)
        userNameLabel.skeletonTextNumberOfLines = .custom(3)
        userNameLabel.linesCornerRadius = 4
        userNameLabel.lastLineFillPercent = 30
//        userNameLabel.skeletonPaddingInsets
//        userNameLabel.backgroundColor = .green
        userNameLabel.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            userNameLabel.centerYAnchor.constraint(equalTo: self.centerYAnchor),
            userNameLabel.leadingAnchor.constraint(equalTo: userImage.trailingAnchor, constant: 10),
            userNameLabel.trailingAnchor.constraint(equalTo: self.trailingAnchor, constant: -10),
        ])
    }
}

// MARK: - RESULTSCELL VIEWMODEL

final class ResultsCellViewModel {
    
    let userName: String
    let userProfileImageLink: String
    var userImageData: ObservableObject<Data?> = ObservableObject(nil)
    
    init(user: String, userProfileImageLink: String) {
        self.userName = user
        self.userProfileImageLink = userProfileImageLink
        fetchImageData()
    }
    
    func fetchImageData() {
        UserManager.shared.getProfileImageData(urlPath: userProfileImageLink) { [weak self] data in
            if let data = data {
                self?.userImageData.value = data
            }
        }
    }
}

