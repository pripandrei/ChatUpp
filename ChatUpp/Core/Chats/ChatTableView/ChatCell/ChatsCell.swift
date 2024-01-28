//
//  ConversationCell.swift
//  ChatUpp
//
//  Created by Andrei Pripa on 9/7/23.
//

import UIKit

class ChatsCell: UITableViewCell {
    
    private var messageLable = UITextView()
    private var nameLabel = UILabel()
    private var profileImage = UIImageView()
    private var dateLable = UILabel()
    private var cellViewModel: ChatCellViewModel!
    
//MARK: - LIFECYCLE
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setMessageLable()
        setNameLabel()
        setProfileImage()
        setDateLable()
        let cellBackground = UIView()
        cellBackground.backgroundColor = #colorLiteral(red: 0.09686327726, green: 0.2637034953, blue: 0.3774781227, alpha: 1)
        self.selectedBackgroundView = cellBackground
        self.backgroundColor = #colorLiteral(red: 0.1411764771, green: 0.3960784376, blue: 0.5647059083, alpha: 1)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

//MARK: - CELL CONFIGURATION
    
    func configure(viewModel: ChatCellViewModel) {
        self.cellViewModel = viewModel
        setupBinding()
        handleImageSetup()
        
        messageLable.text = viewModel.message
        nameLabel.text = viewModel.userMame
        dateLable.adjustsFontSizeToFitWidth = true
        dateLable.text = viewModel.timestamp
    }
    
    private func handleImageSetup()
    {
        guard let imageData = cellViewModel.otherUserProfileImage.value else {
            profileImage.image = nil
            cellViewModel.fetchImageData()
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
//                }
            }
        }
    }
    
//MARK: - UI SETUP
    
    private func setMessageLable() {
        self.addSubview(messageLable)
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
        self.addSubview(nameLabel)
        nameLabel.textColor = #colorLiteral(red: 0.8956019878, green: 1, blue: 1, alpha: 1)
//        nameLabel.font = UIFont.boldSystemFont(ofSize: 16.5)
        nameLabel.font = UIFont(descriptor: .preferredFontDescriptor(withTextStyle: .headline), size: 17)
        
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
        self.addSubview(profileImage)
        profileImage.layer.cornerRadius = self.bounds.size.width * 0.09
        profileImage.clipsToBounds = true
        setProfileImageConstraints()
    }
    
    private func setProfileImageConstraints() {
        profileImage.translatesAutoresizingMaskIntoConstraints = false
    
//        NSLayoutConstraint.activate([
//            profileImage.topAnchor.constraint(equalTo: self.topAnchor, constant: 5),
//            profileImage.trailingAnchor.constraint(equalTo: messageLable.leadingAnchor, constant: -8),
//            profileImage.bottomAnchor.constraint(equalTo: self.bottomAnchor, constant: -5),
//            profileImage.leadingAnchor.constraint(equalTo: self.leadingAnchor, constant: 10)
//        ])
        
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
        self.addSubview(dateLable)

        dateLable.font = UIFont(descriptor: .preferredFontDescriptor(withTextStyle: .title3), size: 14)
        dateLable.textColor = #colorLiteral(red: 0.6390894651, green: 0.6514347792, blue: 0.6907400489, alpha: 1)
        
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
