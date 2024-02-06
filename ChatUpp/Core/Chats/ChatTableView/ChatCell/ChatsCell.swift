//
//  ConversationCell.swift
//  ChatUpp
//
//  Created by Andrei Pripa on 9/7/23.
//

import UIKit
import SkeletonView

class ChatsCell: UITableViewCell {
    
    private var messageLable = UITextView()
    private var nameLabel = UILabel()
    private var profileImage = UIImageView()
    private var dateLable = UILabel()
    private var cellViewModel: ChatCellViewModel!
    
//MARK: - LIFECYCLE
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        
        self.isSkeletonable = true
        contentView.isSkeletonable = true
        
        let cellBackground = UIView()
        cellBackground.backgroundColor = #colorLiteral(red: 0.09686327726, green: 0.2637034953, blue: 0.3774781227, alpha: 1)
        self.selectedBackgroundView = cellBackground
        self.backgroundColor = #colorLiteral(red: 0.1411764771, green: 0.3960784376, blue: 0.5647059083, alpha: 1)
        
        setMessageLable()
        setNameLabel()
        setProfileImage()
        setDateLable()
//        contentView.backgroundColor = #colorLiteral(red: 0.1411764771, green: 0.3960784376, blue: 0.5647059083, alpha: 1)
        
        
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

//MARK: - CELL CONFIGURATION
    
    func configure(viewModel: ChatCellViewModel) {
        self.cellViewModel = viewModel
//        cellViewModel.addListenerToRecentMessage()
        setupBinding()
        handleImageSetup()
        
        self.dateLable.adjustsFontSizeToFitWidth = true
        self.messageLable.text = cellViewModel.recentMessage.value?.messageBody
        self.dateLable.text = cellViewModel.recentMessage.value?.timestamp.formatToHoursAndMinutes()
        self.nameLabel.text = self.cellViewModel.user?.name
        
//        messageLable.text = viewModel.message
//        nameLabel.text = viewModel.user.name
//        dateLable.text = viewModel.timestamp
    }
    
    private func handleImageSetup()
    {
        guard let imageData = cellViewModel.otherUserProfileImage.value else {
//            profileImage.image = nil
//            cellViewModel.fetchImageData()
            return
        }
        setImage(imageData)
    }
    
    private func setImage(_ imageData: Data) {
        let image = UIImage(data: imageData)
        
        DispatchQueue.main.async {
            self.profileImage.image = image
        }
    }
    
//MARK: - BINDING
    
    private func setupBinding() {
        cellViewModel.otherUserProfileImage.bind { [weak self, url = cellViewModel.userProfilePhotoURL] data in
            if let imageData = data {
//                if self?.cellViewModel.userProfilePhotoURL == url {
                    self?.setImage(imageData)
                }
//            }
        }
        cellViewModel.recentMessage.bind { [weak self] message in
            if let message = message {
                Task { @MainActor in
//                    print(self?.nameLabel.text)
//                    print(message.messageBody)
                    self?.messageLable.text = message.messageBody
                    self?.dateLable.text = message.timestamp.formatToHoursAndMinutes()
                }
            }
        }
        cellViewModel.onUserModified = {
            Task{ @MainActor in
                self.nameLabel.text = self.cellViewModel.user?.name
            }
        }
    }
    
//MARK: - UI SETUP
    
    private func setMessageLable() {
        contentView.addSubview(messageLable)
        messageLable.isEditable = false
        messageLable.isScrollEnabled = false
        messageLable.isSelectable = false
        messageLable.font = UIFont(descriptor: .preferredFontDescriptor(withTextStyle: .title2), size: 15)
        messageLable.text = "Temporary message here, for testing purposes only."
        messageLable.textColor = #colorLiteral(red: 0.5970802903, green: 0.5856198668, blue: 0.6014393568, alpha: 1)
        messageLable.textContainer.maximumNumberOfLines = 0
        messageLable.contentInset.top = -5
        messageLable.contentInset.left = -4
        messageLable.backgroundColor = .clear
        messageLable.textAlignment = .left
        
        messageLable.isSkeletonable = true
        messageLable.linesCornerRadius = 4
        messageLable.skeletonTextLineHeight = .fixed(10)
        messageLable.skeletonTextNumberOfLines = .custom(2)
        
        configureMessageLableConstraints()
    }
    
    private func configureMessageLableConstraints() {
        messageLable.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            messageLable.topAnchor.constraint(equalTo: self.topAnchor, constant: self.bounds.height * 0.60),
            messageLable.trailingAnchor.constraint(equalTo: self.trailingAnchor, constant: -55),
            messageLable.bottomAnchor.constraint(equalTo: self.bottomAnchor, constant: -5),
            messageLable.leadingAnchor.constraint(equalTo: self.leadingAnchor, constant: 75)
        ])
    }
    
    private func setNameLabel() {
        contentView.addSubview(nameLabel)
        nameLabel.textColor = #colorLiteral(red: 0.8956019878, green: 1, blue: 1, alpha: 1)
//        nameLabel.font = UIFont.boldSystemFont(ofSize: 16.5)
        nameLabel.font = UIFont(descriptor: .preferredFontDescriptor(withTextStyle: .headline), size: 17)
        
        nameLabel.isSkeletonable = true
        nameLabel.linesCornerRadius = 4
        nameLabel.skeletonTextLineHeight = .fixed(10)
        nameLabel.skeletonTextNumberOfLines = .custom(1)
        
        setNameLableConstraints()
    }
    
    private func setNameLableConstraints() {
        nameLabel.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            nameLabel.topAnchor.constraint(equalTo: self.topAnchor, constant: 5),
            nameLabel.trailingAnchor.constraint(equalTo: self.trailingAnchor, constant: -55),
            nameLabel.bottomAnchor.constraint(equalTo: messageLable.topAnchor, constant: -1),
            nameLabel.leadingAnchor.constraint(equalTo: self.leadingAnchor, constant: 75)
        ])
    }
    
    private func setProfileImage() {
        contentView.addSubview(profileImage)
        profileImage.layer.cornerRadius = self.bounds.size.width * 0.09
        profileImage.clipsToBounds = true
        profileImage.isSkeletonable = true
        
        setProfileImageConstraints()
    }
    
    private func setProfileImageConstraints() {
        profileImage.translatesAutoresizingMaskIntoConstraints = false
    
        NSLayoutConstraint.activate([
            profileImage.leadingAnchor.constraint(equalTo: self.leadingAnchor, constant: 10),
            profileImage.centerYAnchor.constraint(equalTo: self.centerYAnchor),
                   // Set a fixed width and height for the label (circular shape)
            profileImage.widthAnchor.constraint(equalTo: profileImage.heightAnchor),
                   // Ensure the label's width and height are equal
            profileImage.heightAnchor.constraint(equalTo: self.widthAnchor, multiplier: 0.15)
        ])
    }
    
    private func setDateLable() {
        contentView.addSubview(dateLable)

        dateLable.font = UIFont(descriptor: .preferredFontDescriptor(withTextStyle: .title3), size: 14)
        dateLable.textColor = #colorLiteral(red: 0.6390894651, green: 0.6514347792, blue: 0.6907400489, alpha: 1)
        
        dateLable.isSkeletonable = true
        dateLable.linesCornerRadius = 4
        dateLable.skeletonTextLineHeight = .fixed(10)
        dateLable.skeletonTextNumberOfLines = .custom(1)
        
        setDateLableConstraints()
    }
    
    private func setDateLableConstraints() {
        dateLable.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            dateLable.topAnchor.constraint(equalTo: self.topAnchor, constant: 8),
            dateLable.trailingAnchor.constraint(equalTo: self.trailingAnchor, constant: -10),
//            dateLable.bottomAnchor.constraint(equalTo: self.bottomAnchor, constant: -5),
            dateLable.leadingAnchor.constraint(equalTo: messageLable.trailingAnchor, constant: 6),
            dateLable.heightAnchor.constraint(equalTo: self.heightAnchor, multiplier: 0.25)
        ])
    }
}
