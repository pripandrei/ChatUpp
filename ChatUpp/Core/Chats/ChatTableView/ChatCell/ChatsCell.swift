//
//  ConversationCell.swift
//  ChatUpp
//
//  Created by Andrei Pripa on 9/7/23.
//

import UIKit
import SkeletonView
import Combine
//import YYText

class ChatsCell: UITableViewCell {
    
    private var messageLable = CustomMessageLabel()
    private var nameLabel = UILabel()
    private var profileImage = UIImageView()
    private var dateLable = UILabel()
    private var cellViewModel: ChatCellViewModel!
    private var unreadMessagesCountLabel = UILabel()
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
        
        setMessageLable()
        setNameLabel()
        setProfileImage()
        setDateLable()
        setupUnreadMessagesCountLabel()
        createOnlineStatusView()
        initiateSkeletonAnimation()
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
        setOnlineStatusActivity()
        
        nameLabel.text = cellViewModel.member?.name
        
        if let message = cellViewModel.recentMessage {
            messageLable.text = message.messageBody
            dateLable.text = message.timestamp.formatToHoursAndMinutes()
            setUnreadMessageCount(message)
        } else {
            unreadMessagesCountLabel.isHidden = true
        }
    }
    
    private func setOnlineStatusActivity() {
        if cellViewModel.member?.name == "Vadim" {
            print("stop")
        }
        if let activeStatus = cellViewModel.member?.isActive {
            onlineStatusCircleView.isHidden = !activeStatus
        }
    }
    
    private func setUnreadMessageCount(_ message: Message) {
        let shouldShowUnreadCount = cellViewModel.authUser.uid != message.senderId && cellViewModel.unreadMessageCount > 0
        unreadMessagesCountLabel.isHidden = !shouldShowUnreadCount
        
        if shouldShowUnreadCount {
            unreadMessagesCountLabel.text = "\(cellViewModel.unreadMessageCount)"
        }
    }

    //MARK: - Binding
    
    private func setupBinding()
    {
        cellViewModel.$memberProfileImage
            .dropFirst()
            .receive(on: DispatchQueue.main)
            .sink { [weak self, url = cellViewModel.member?.photoUrl] imageData in
                guard let self = self else {return}
                
                self.stopSkeletonAnimationFor(self.profileImage)
                self.setImage(imageData)
            }.store(in: &subscriptions)
        
        cellViewModel.$member
            .receive(on: DispatchQueue.main)
            .dropFirst()
            .sink { member in
                if let member = member {
                    
//                    print("self Cell: active",self.cellViewModel.member?.isActive)
//                    print("member",member.isActive)
//                    print("====")
                    self.stopSkeletonAnimationFor(self.nameLabel)
                    
                    if self.nameLabel.text != member.name {
                        self.nameLabel.text = member.name
                    }
//                    if let status = member.isActive {
//                        self.onlineStatusCircleView.isHidden = !status
//                    }
                    self.setOnlineStatusActivity()
                }
            }.store(in: &subscriptions)
        
        cellViewModel.$recentMessage
            .receive(on: DispatchQueue.main)
            .sink { [weak self] message in
                if let message = message {
                    guard let self = self else {return}
                    
                    self.stopSkeletonAnimationFor(self.messageLable,self.dateLable)
                    
                    self.messageLable.text = message.messageBody
                    self.dateLable.text = message.timestamp.formatToHoursAndMinutes()
                }
            }.store(in: &subscriptions)
        
        cellViewModel.$unreadMessageCount
            .receive(on: DispatchQueue.main)
            .sink { [weak self] count in
                guard let self = self else {return}
                self.stopSkeletonAnimationFor(unreadMessagesCountLabel)
//                guard let count = count else {return}
                guard self.cellViewModel.authUser.uid != self.cellViewModel.recentMessage?.senderId else {return}
                
                self.unreadMessagesCountLabel.text = "\(count)"
                if count == 0 {
                    self.unreadMessagesCountLabel.isHidden = true
                    return
                }
                self.unreadMessagesCountLabel.isHidden = false
                //                self.animateUnreadMessageCounterOnReceive()
            }.store(in: &subscriptions)
    }
    
    //MARK: - Image setup
    
    private func handleImageSetup() {
        if cellViewModel.member?.name == "Mira later" {
            print("mira")
        }
        guard let member = cellViewModel.member else { return }
        
        if member.photoUrl == nil {
            /// set local image
            setImage()
            return
        }
        
        if let imageData = cellViewModel.memberProfileImage {
            /// set fetched image
            setImage(imageData)
        }
    }
    
    private func setImage(_ imageData: Data? = nil) {
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
        unreadMessagesCountLabel.linesCornerRadius = 8
        unreadMessagesCountLabel.isSkeletonable = true
        unreadMessagesCountLabel.skeletonTextLineHeight = .fixed(25)
        unreadMessagesCountLabel.skeletonPaddingInsets = UIEdgeInsets(top: 0, left: -10, bottom: 0, right: -10)
        
        unreadMessagesCountLabel.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            unreadMessagesCountLabel.trailingAnchor.constraint(equalTo: self.trailingAnchor, constant: -17),
            unreadMessagesCountLabel.bottomAnchor.constraint(equalTo: self.bottomAnchor, constant: -12),
            unreadMessagesCountLabel.heightAnchor.constraint(equalToConstant: 25),
            unreadMessagesCountLabel.widthAnchor.constraint(equalToConstant: 25),
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

