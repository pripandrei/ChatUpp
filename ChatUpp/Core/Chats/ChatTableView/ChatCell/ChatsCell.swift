//
//  ConversationCell.swift
//  ChatUpp
//
//  Created by Andrei Pripa on 9/7/23.
//

import UIKit
import SkeletonView
//import YYText

class ChatsCell: UITableViewCell {
    
    private var messageLable = CustomMessageLabel()
    private var nameLabel = UILabel()
    private var profileImage = UIImageView()
    private var dateLable = UILabel()
    private var cellViewModel: ChatCellViewModel!
    private var unreadMessagesCountLabel = UILabel()
    private var onlineStatusCircleView = UIView()
    
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
        setupUnreadMessagesCountLabel()
        createOnlineStatusView()
//        contentView.backgroundColor = #colorLiteral(red: 0.1411764771, green: 0.3960784376, blue: 0.5647059083, alpha: 1)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    
    deinit {
        print("chatCellVM was deinit =====")
    }
    
    //MARK: - CELL CONFIGURATION
    
    func configure(viewModel: ChatCellViewModel) {
        self.cellViewModel = viewModel
        setupBinding()
        handleImageSetup()
        
        self.onlineStatusCircleView.isHidden = cellViewModel.userActiveStatus.value ? false : true
        
        unreadMessagesCountLabel.isHidden = true
        self.nameLabel.text = cellViewModel.member?.name
        self.dateLable.adjustsFontSizeToFitWidth = true
        
        guard let message = cellViewModel.recentMessage.value else {return}
        self.messageLable.text = message.messageBody
        self.dateLable.text = message.timestamp.formatToHoursAndMinutes()
    
        guard let unreadMessageCount = cellViewModel.unreadMessageCount.value, unreadMessageCount != 0, cellViewModel.authUser.uid != message.senderId else {return}
        unreadMessagesCountLabel.isHidden = false
        self.unreadMessagesCountLabel.text = "\(unreadMessageCount)"
    }
    
    private func handleImageSetup()
    {
        guard let imageData = cellViewModel.memberProfileImage.value else {
            self.profileImage.image = UIImage(named: "default_profile_photo")
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
        
        /// - currently memberProfileImage and onUserModified are called only when member user is deleted
        cellViewModel.memberProfileImage.bind { [weak self, url = cellViewModel.member?.photoUrl] data in
            if let imageData = data {
                self?.setImage(imageData)
            }
        }
        cellViewModel.onUserModified = {
            Task{ @MainActor in
                self.nameLabel.text = self.cellViewModel.member?.name
            }
        }
        
        cellViewModel.recentMessage.bind { [weak self] message in
            if let message = message {
                Task { @MainActor in
                    self?.messageLable.text = message.messageBody
                    self?.dateLable.text = message.timestamp.formatToHoursAndMinutes()
                }
            }
        }
        cellViewModel.unreadMessageCount.bind { [weak self] count in
            guard let self = self else {return}
            guard let count = count else {return}
            Task { @MainActor in
                guard self.cellViewModel.authUser.uid != self.cellViewModel.recentMessage.value?.senderId else {return}
                self.unreadMessagesCountLabel.text = "\(count)"
                if count == 0 {
                    self.unreadMessagesCountLabel.isHidden = true
                    return
                }
                self.unreadMessagesCountLabel.isHidden = false
                self.animateUnreadMessageCounterOnReceive()
            }
        }
        
        /// - update user active status
        cellViewModel.userActiveStatus.bind { isActive in
            if isActive {
                self.onlineStatusCircleView.isHidden = false
                print("Green")
            } else {
                self.onlineStatusCircleView.isHidden = true
                print("Red")
            }
        }
    }
    
    //MARK: - Animate new message counter
    
    func animateUnreadMessageCounterOnReceive() {
        UIView.animate(withDuration: 0.2, animations: {
        }, completion: { _ in
            UIView.animate(withDuration: 0.09, animations: {
                self.unreadMessagesCountLabel.frame = self.unreadMessagesCountLabel.frame.offsetBy(dx: 5, dy: 0)
            }) { _ in
                UIView.animate(withDuration: 0.05, animations: {
                    self.unreadMessagesCountLabel.frame = self.unreadMessagesCountLabel.frame.offsetBy(dx: -10, dy: 0)
                }) { _ in
                    UIView.animate(withDuration: 0.05, animations: {
                        self.unreadMessagesCountLabel.frame = self.unreadMessagesCountLabel.frame.offsetBy(dx: 8, dy: 0)
                    }) { _ in
                        UIView.animate(withDuration: 0.05, animations: {
                            self.unreadMessagesCountLabel.frame = self.unreadMessagesCountLabel.frame.offsetBy(dx: -6, dy: 0)
                        }) { _ in
                            UIView.animate(withDuration: 0.05, animations: {
                                self.unreadMessagesCountLabel.frame = self.unreadMessagesCountLabel.frame.offsetBy(dx: 5, dy: 0)
                            }) { _ in
                                UIView.animate(withDuration: 0.05, animations: {
                                    self.unreadMessagesCountLabel.frame = self.unreadMessagesCountLabel.frame.offsetBy(dx: -3, dy: 0)
                                }) { _ in
                                    UIView.animate(withDuration: 0.05, animations: {
                                        self.unreadMessagesCountLabel.frame = self.unreadMessagesCountLabel.frame.offsetBy(dx: 1, dy: 0)
                                    })
                                }
                            }
                        }
                    }
                }
            }
        })
    }
    
//MARK: - UI SETUP
    
    func createOnlineStatusView() {
        
        contentView.addSubview(onlineStatusCircleView)
        
        onlineStatusCircleView.backgroundColor = #colorLiteral(red: 0.4666666687, green: 0.7647058964, blue: 0.2666666806, alpha: 1)
        onlineStatusCircleView.layer.cornerRadius = 12 / 2
        onlineStatusCircleView.clipsToBounds = true
        onlineStatusCircleView.translatesAutoresizingMaskIntoConstraints = false
        onlineStatusCircleView.isHidden = true
        
        NSLayoutConstraint.activate([
            onlineStatusCircleView.widthAnchor.constraint(equalToConstant: 12),
            onlineStatusCircleView.heightAnchor.constraint(equalToConstant: 12),
//            onlineStatusCircleView.centerXAnchor.constraint(equalTo: self.centerXAnchor),
//            onlineStatusCircleView.centerYAnchor.constraint(equalTo: self.centerYAnchor),
            onlineStatusCircleView.trailingAnchor.constraint(equalTo: profileImage.trailingAnchor, constant: -3),
            onlineStatusCircleView.bottomAnchor.constraint(equalTo: profileImage.bottomAnchor, constant: -3),
        ])
    }
    
    func setupUnreadMessagesCountLabel() {
        contentView.addSubview(unreadMessagesCountLabel)
        
        unreadMessagesCountLabel.textColor = #colorLiteral(red: 0.112982966, green: 0.3117198348, blue: 0.4461967349, alpha: 1)
        unreadMessagesCountLabel.font = UIFont(name: "Helvetica", size: 16)
        unreadMessagesCountLabel.backgroundColor = #colorLiteral(red: 0.3746420145, green: 0.7835513949, blue: 0.7957105041, alpha: 1)
        unreadMessagesCountLabel.layer.cornerRadius = 12
        unreadMessagesCountLabel.textAlignment = .center
        unreadMessagesCountLabel.clipsToBounds = true
        unreadMessagesCountLabel.layer.masksToBounds = true
//        unreadMessagesCountLabel.isHidden = true
        unreadMessagesCountLabel.linesCornerRadius = 8
        unreadMessagesCountLabel.isSkeletonable = true
        unreadMessagesCountLabel.skeletonTextLineHeight = .fixed(25)
        unreadMessagesCountLabel.skeletonPaddingInsets = UIEdgeInsets(top: 0, left: -10, bottom: 0, right: -10)
        
        unreadMessagesCountLabel.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            unreadMessagesCountLabel.trailingAnchor.constraint(equalTo: self.trailingAnchor, constant: -17),
            unreadMessagesCountLabel.bottomAnchor.constraint(equalTo: self.bottomAnchor, constant: -12),
//            unreadMessagesCountLabel.leadingAnchor.constraint(equalTo: messageLable.trailingAnchor, constant: 6),
            unreadMessagesCountLabel.heightAnchor.constraint(equalToConstant: 25),
            unreadMessagesCountLabel.widthAnchor.constraint(equalToConstant: 25),
        ])
    }
    
    private func setMessageLable() {
        contentView.addSubview(messageLable)
        messageLable.font = UIFont(descriptor: .preferredFontDescriptor(withTextStyle: .title2), size: 14)
        messageLable.text = "Temporary message here, for testing purposes only."
        messageLable.textColor = #colorLiteral(red: 0.5970802903, green: 0.5856198668, blue: 0.6014393568, alpha: 1)
        messageLable.backgroundColor = .clear
        messageLable.textAlignment = .left
        messageLable.numberOfLines = 2
        
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
            messageLable.leadingAnchor.constraint(equalTo: self.leadingAnchor, constant: 77),
            messageLable.trailingAnchor.constraint(equalTo: self.trailingAnchor, constant: -55),
            messageLable.heightAnchor.constraint(equalToConstant: 37)
//            messageLable.bottomAnchor.constraint(equalTo: self.bottomAnchor, constant: -8)
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
            nameLabel.topAnchor.constraint(equalTo: self.topAnchor, constant: 7),
            nameLabel.trailingAnchor.constraint(equalTo: self.trailingAnchor, constant: -55),
            nameLabel.bottomAnchor.constraint(equalTo: messageLable.topAnchor, constant: -1),
            nameLabel.leadingAnchor.constraint(equalTo: self.leadingAnchor, constant: 77)
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

extension ChatsCell {
    class CustomMessageLabel: UILabel {
        override func drawText(in rect: CGRect) {
            var targetRect = textRect(forBounds: rect, limitedToNumberOfLines: numberOfLines)
            targetRect.origin.y = 2
            targetRect.origin.x = 2
            super.drawText(in: targetRect)
        }
    }
}

