//
//  ResultsTableCell.swift
//  ChatUpp
//
//  Created by Andrei Pripa on 11/9/23.
//

import UIKit
import SkeletonView
import Combine

final class ResultsTableCell: UITableViewCell {
    
    private var cellViewModel: ResultsCellViewModel!
    var titleLabel = UILabel()
    var profileImageView = UIImageView()
    var imageURL: String?
    private var cancellables = Set<AnyCancellable>()
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        
        self.isSkeletonable = true
        contentView.isSkeletonable = true
        contentView.backgroundColor = ColorScheme.appBackgroundColor
        setupUserImage()
        setupUserName()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func configure(viewModel: ResultsCellViewModel)
    {
        self.cellViewModel = viewModel
        setupBinding()
        titleLabel.text = cellViewModel.titleName
        self.profileImageView.image = nil
        setImage()
    }
    
    private func setImage()
    {
        if cellViewModel.imageURL != nil
        {
            cellViewModel.setImageData()
        } else {
            self.profileImageView.image = cellViewModel.chat?.isGroup == true ? UIImage(named: "default_group_photo") : UIImage(named: "default_profile_photo")
        }
    }
    
   private func setupBinding() {
        cellViewModel.$imageData
            .receive(on: DispatchQueue.main)
            .compactMap { $0 }
            .sink { [weak self, url = cellViewModel.imageURL] data in
//                print("URL: ", url)
//                if url == self?.imageURL
//                {
                    let image = UIImage(data: data)
                    self?.profileImageView.image = image
//                }
            }.store(in: &cancellables)
    }
    
    private func setupUserImage() {
        contentView.addSubview(profileImageView)
        
        profileImageView.isSkeletonable = true
        profileImageView.clipsToBounds = true
        profileImageView.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            profileImageView.leadingAnchor.constraint(equalTo: self.leadingAnchor, constant: 10),
            profileImageView.topAnchor.constraint(equalTo: self.topAnchor, constant: 5),
            profileImageView.bottomAnchor.constraint(equalTo: self.bottomAnchor, constant: -5),
            profileImageView.widthAnchor.constraint(equalTo: profileImageView.heightAnchor)
        ])
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        profileImageView.layer.cornerRadius = profileImageView.frame.height / 2
    }
    
    private func setupUserName()
    {
        contentView.addSubview(titleLabel)
        
        titleLabel.isSkeletonable = true
        titleLabel.skeletonTextLineHeight = .fixed(10)
        titleLabel.skeletonTextNumberOfLines = .custom(3)
        titleLabel.linesCornerRadius = 4
        titleLabel.lastLineFillPercent = 30
        titleLabel.textColor = ColorScheme.textFieldTextColor
        titleLabel.font = .systemFont(ofSize: 17, weight: .bold)
        
//        userNameLabel.skeletonPaddingInsets
//        userNameLabel.backgroundColor = .green
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            titleLabel.centerYAnchor.constraint(equalTo: self.centerYAnchor),
            titleLabel.leadingAnchor.constraint(equalTo: profileImageView.trailingAnchor, constant: 10),
            titleLabel.trailingAnchor.constraint(equalTo: self.trailingAnchor, constant: -10),
        ])
    }
}


