//
//  ConversationCell.swift
//  ChatUpp
//
//  Created by Andrei Pripa on 9/7/23.
//

import UIKit
import SkeletonView
import Combine
import Kingfisher

class ChatsCell: UITableViewCell {
    
    private var cellViewModel: ChatCellViewModel!
    private var messageLable = CustomMessageLabel()
    private var nameLabel = UILabel()
    private var profileImage = UIImageView()
    private var dateLable = UILabel()
    private var unreadMessagesBadgeLabel = UnseenMessagesBadge()
    private var onlineStatusCircleView = UIView()
    
    private var subscriptions = Set<AnyCancellable>()
    
    //MARK: - LIFECYCLE
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        
        self.isSkeletonable = true
        contentView.isSkeletonable = true
        
        let cellBackground = UIView()
        cellBackground.backgroundColor = #colorLiteral(red: 0.09686327726, green: 0.2637034953, blue: 0.3774781227, alpha: 1)
        self.selectedBackgroundView = cellBackground
        self.backgroundColor = #colorLiteral(red: 0.1411764771, green: 0.3960784376, blue: 0.5647059083, alpha: 1)
        
        setupUI()
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
        prepareImage()
    }
    
    private func setOnlineStatusActivity() {
        if let activeStatus = cellViewModel.chatUser?.isActive {
            onlineStatusCircleView.isHidden = !activeStatus
        }
    }
    
    private func setUnreadMessageCount(_ count: Int) {
        //        guard let _ = cellViewModel.recentMessage else {return}
        
        unreadMessagesBadgeLabel.backgroundColor = #colorLiteral(red: 0.3746420145, green: 0.7835513949, blue: 0.7957105041, alpha: 1)
        
        let shouldShowUnreadCount = count > 0
        unreadMessagesBadgeLabel.isHidden = !shouldShowUnreadCount
        
        if shouldShowUnreadCount {
            unreadMessagesBadgeLabel.text = "\(count)"
        }
    }
    
    //MARK: - Binding
    
    private func setupBinding()
    {
        cellViewModel.imageDataUpdateSubject
            .receive(on: DispatchQueue.main)
            .sink { [weak self]_ in
                self?.prepareImage()
            }.store(in: &subscriptions)
        
        cellViewModel.$chatUser
            .receive(on: DispatchQueue.main)
            .sink { member in
                if let member = member {
                    self.stopSkeletonAnimationFor(self.nameLabel)
                    
                    if self.nameLabel.text != member.name {
                        self.nameLabel.text = member.name
                    }
                    self.setOnlineStatusActivity()
                }
            }.store(in: &subscriptions)
        
        cellViewModel.$recentMessage
            .receive(on: DispatchQueue.main)
            .sink { [weak self] message in
                guard let self = self else {return}
                
                if let isPresent = cellViewModel.isRecentMessagePresent, !isPresent {
                    self.stopSkeletonAnimationFor(self.messageLable,self.dateLable)
                    return
                }
                if let message = message {
                    self.stopSkeletonAnimationFor(self.messageLable,self.dateLable)
                    self.messageLable.text = message.messageBody
                    self.dateLable.text = message.timestamp.formatToHoursAndMinutes()
                }
            }.store(in: &subscriptions)
        
        cellViewModel.$unreadMessageCount
            .receive(on: DispatchQueue.main)
            .sink { [weak self] count in
                guard let self = self else {return}
                guard let count = count else {return}
                
                self.stopSkeletonAnimationFor(unreadMessagesBadgeLabel)
                setUnreadMessageCount(count)
            }.store(in: &subscriptions)
    }
    
    //MARK: - Image setup
    
    private func prepareImage()
    {
        guard let member = cellViewModel.chatUser else { return }
        
        if member.photoUrl == nil {
            /// set local/default image
            setImage()
            return
        }
        if let imageData = cellViewModel.retrieveProfileImageFromCache() {
            /// set fetched image
            setImage(imageData)
        }
    }
    
    private func setImage(_ imageData: Data? = nil)
    {
        Task { @MainActor in
            stopSkeletonAnimationFor(profileImage)
            
            guard let imageData = imageData else {
                self.profileImage.image = UIImage(named: "default_profile_photo")
                return
            }
            let image = UIImage(data: imageData)
            self.profileImage.image = image
        }
    }
}

//MARK: - Skeleton animation handler
extension ChatsCell {
    private func stopSkeletonAnimationFor(_ views: UIView...) {
        for view in views {
            view.stopSkeletonAnimation()
            view.hideSkeleton(transition: .none)
        }
    }
    private func initiateSkeletonAnimation() {
        let skeletonAnimationColor = #colorLiteral(red: 0.1411764771, green: 0.3960784376, blue: 0.5647059083, alpha: 1)
        let skeletonItemColor = #colorLiteral(red: 0.4780891538, green: 0.7549679875, blue: 0.8415568471, alpha: 1)
        showGradientSkeleton(usingGradient: .init(baseColor: skeletonItemColor, secondaryColor: skeletonAnimationColor), delay: TimeInterval(0), transition: SkeletonTransitionStyle.crossDissolve(0.7))
        
        //        tableView.showAnimatedGradientSkeleton(usingGradient: .init(baseColor: skeletonItemColor, secondaryColor: skeletonAnimationColor), transition: .crossDissolve(.signalingNaN))
    }
}

//MARK: - UI SETUP
extension ChatsCell {
    
    private func setupUI() {
        setMessageLable()
        setNameLabel()
        setProfileImage()
        setDateLable()
        setupUnreadMessagesCountLabel()
        createOnlineStatusView()
        initiateSkeletonAnimation()
    }
    
    private func createOnlineStatusView() {
        
        contentView.addSubview(onlineStatusCircleView)
        
        onlineStatusCircleView.backgroundColor = #colorLiteral(red: 0.4666666687, green: 0.7647058964, blue: 0.2666666806, alpha: 1)
        onlineStatusCircleView.layer.cornerRadius = 12 / 2
        onlineStatusCircleView.clipsToBounds = true
        onlineStatusCircleView.translatesAutoresizingMaskIntoConstraints = false
        onlineStatusCircleView.isHidden = true
        
        NSLayoutConstraint.activate([
            onlineStatusCircleView.widthAnchor.constraint(equalToConstant: 12),
            onlineStatusCircleView.heightAnchor.constraint(equalToConstant: 12),
            onlineStatusCircleView.trailingAnchor.constraint(equalTo: profileImage.trailingAnchor, constant: -3),
            onlineStatusCircleView.bottomAnchor.constraint(equalTo: profileImage.bottomAnchor, constant: -3),
        ])
    }
    
    private func setupUnreadMessagesCountLabel() {
        contentView.addSubview(unreadMessagesBadgeLabel)
        
        unreadMessagesBadgeLabel.textColor = #colorLiteral(red: 0.112982966, green: 0.3117198348, blue: 0.4461967349, alpha: 1)
        unreadMessagesBadgeLabel.font = UIFont(name: "Helvetica", size: 16)
        //        unreadMessagesCountLabel.backgroundColor = #colorLiteral(red: 0.3746420145, green: 0.7835513949, blue: 0.7957105041, alpha: 1)
        //        unreadMessagesCountLabel.layer.cornerRadius = 12
        unreadMessagesBadgeLabel.textAlignment = .center
        //        unreadMessagesCountLabel.clipsToBounds = true
        //        unreadMessagesCountLabel.layer.masksToBounds = true
        unreadMessagesBadgeLabel.linesCornerRadius = 8
        unreadMessagesBadgeLabel.isSkeletonable = true
        unreadMessagesBadgeLabel.skeletonTextLineHeight = .fixed(25)
        unreadMessagesBadgeLabel.skeletonPaddingInsets = UIEdgeInsets(top: 0, left: -10, bottom: 0, right: -10)
        
        unreadMessagesBadgeLabel.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            unreadMessagesBadgeLabel.trailingAnchor.constraint(equalTo: self.trailingAnchor, constant: -17),
            unreadMessagesBadgeLabel.bottomAnchor.constraint(equalTo: self.bottomAnchor, constant: -12),
            //            unreadMessagesCountLabel.heightAnchor.constraint(equalToConstant: 25),
            //            unreadMessagesCountLabel.widthAnchor.constraint(equalToConstant: 25),
        ])
    }
    
    private func setMessageLable() {
        contentView.addSubview(messageLable)
        messageLable.font = UIFont(descriptor: .preferredFontDescriptor(withTextStyle: .title2), size: 14)
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
        ])
    }
    
    private func setNameLabel() {
        contentView.addSubview(nameLabel)
        nameLabel.textColor = #colorLiteral(red: 0.8956019878, green: 1, blue: 1, alpha: 1)
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
            profileImage.widthAnchor.constraint(equalTo: profileImage.heightAnchor),
            profileImage.heightAnchor.constraint(equalTo: self.widthAnchor, multiplier: 0.15)
        ])
    }
    
    private func setDateLable() {
        contentView.addSubview(dateLable)
        
        dateLable.font = UIFont(descriptor: .preferredFontDescriptor(withTextStyle: .title3), size: 14)
        dateLable.textColor = #colorLiteral(red: 0.6390894651, green: 0.6514347792, blue: 0.6907400489, alpha: 1)
        dateLable.adjustsFontSizeToFitWidth = true
        
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

