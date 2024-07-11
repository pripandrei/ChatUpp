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
    var userImageURL: String?
    
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
        if cellViewModel.userName == "Andrei test" {
            print("stop")
        }
        if cellViewModel.userImageURL == nil {
            self.userImage.image = UIImage(named: "default_profile_photo")
            return
        }
        
        if self.userImageURL != cellViewModel.userImageURL {
            self.userImage.image = nil
            self.cellViewModel.fetchImageData()
            self.userImageURL = cellViewModel.userImageURL
        }
    }
    
    private func setupBinding() {
        cellViewModel.userImageData.bind { [weak self, url = cellViewModel.userImageURL] data in
            if let imageData = data
                , url == self?.userImageURL
            {
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


