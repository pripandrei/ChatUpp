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
        
        titleLabel.text = cellViewModel.participant?.name

        if cellViewModel.imageURL == nil {
            self.profileImageView.image = UIImage(named: "default_profile_photo")
            return
        }
        
        if self.imageURL != cellViewModel.imageURL
        {
            self.profileImageView.image = nil
            self.cellViewModel.setImageData()
            self.imageURL = cellViewModel.imageURL
        }
    }
    
    private func setupBinding() {
        cellViewModel.$imageData
            .receive(on: DispatchQueue.main)
            .compactMap { $0 }
            .sink { [weak self, url = cellViewModel.participant?.photoUrl] data in
                if url == self?.imageURL
                {
                    let image = UIImage(data: data)
                    self?.profileImageView.image = image
                }
            }.store(in: &cancellables)
    }
    
    private func setupUserImage() {
        contentView.addSubview(profileImageView)
        
        profileImageView.isSkeletonable = true
        profileImageView.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            profileImageView.leadingAnchor.constraint(equalTo: self.leadingAnchor, constant: 10),
            profileImageView.topAnchor.constraint(equalTo: self.topAnchor, constant: 5),
            profileImageView.bottomAnchor.constraint(equalTo: self.bottomAnchor, constant: -5),
            profileImageView.widthAnchor.constraint(equalToConstant: 45)
        ])
    }
    
    private func setupUserName() {
        contentView.addSubview(titleLabel)
        
        titleLabel.isSkeletonable = true
        titleLabel.skeletonTextLineHeight = .fixed(10)
        titleLabel.skeletonTextNumberOfLines = .custom(3)
        titleLabel.linesCornerRadius = 4
        titleLabel.lastLineFillPercent = 30
        
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


