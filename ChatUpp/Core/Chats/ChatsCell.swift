//
//  ConversationCell.swift
//  ChatUpp
//
//  Created by Andrei Pripa on 9/7/23.
//

import UIKit

class ChatsCell: UITableViewCell {

    var messageLable = UILabel()
    var nameLabel = UILabel()
    var profileImage = UIImageView()
    var dateLable = UILabel()
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setMessageLable()
        setNameLabel()
        setProfileImage()
        setDateLable()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func configure(viewModel: ChatCellViewModel) {
        messageLable.text = viewModel.message
        nameLabel.text = viewModel.userMame
//        profileImage.image = viewModel.profileImage
        dateLable.text = viewModel.timestamp
    }
    
    private func setMessageLable() {
        self.addSubview(messageLable)
        messageLable.text = "Temporary message here, for testing purposes only."
        messageLable.numberOfLines = 0
//        messageLable.adjustsFontSizeToFitWidth = true
        messageLable.backgroundColor = .green
        configureMessageLableConstraints()
    }
    
    private func configureMessageLableConstraints() {
        messageLable.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            messageLable.topAnchor.constraint(equalTo: self.topAnchor, constant: self.bounds.height * 0.75),
            messageLable.trailingAnchor.constraint(equalTo: self.trailingAnchor, constant: -55),
            messageLable.bottomAnchor.constraint(equalTo: self.bottomAnchor, constant: -5),
            messageLable.leadingAnchor.constraint(equalTo: self.leadingAnchor, constant: 75)
        ])
    }
    
    private func setNameLabel() {
        self.addSubview(nameLabel)
        nameLabel.backgroundColor = .brown
        
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
        profileImage.backgroundColor = .blue
        setProfileImageConstraints()
    }
    
    private func setProfileImageConstraints() {
        profileImage.translatesAutoresizingMaskIntoConstraints = false
    
        NSLayoutConstraint.activate([
            profileImage.topAnchor.constraint(equalTo: self.topAnchor, constant: 5),
            profileImage.trailingAnchor.constraint(equalTo: messageLable.leadingAnchor, constant: -8),
            profileImage.bottomAnchor.constraint(equalTo: self.bottomAnchor, constant: -5),
            profileImage.leadingAnchor.constraint(equalTo: self.leadingAnchor, constant: 10)
        ])
    }
    
    private func setDateLable() {
        self.addSubview(dateLable)
        dateLable.backgroundColor = .cyan
        
        setDateLableConstraints()
    }
    
    private func setDateLableConstraints() {
        dateLable.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            dateLable.topAnchor.constraint(equalTo: self.topAnchor, constant: 5),
            dateLable.trailingAnchor.constraint(equalTo: self.trailingAnchor, constant: -10),
            dateLable.bottomAnchor.constraint(equalTo: self.bottomAnchor, constant: -5),
            dateLable.leadingAnchor.constraint(equalTo: messageLable.trailingAnchor, constant: 6)
        ])
    }
}
