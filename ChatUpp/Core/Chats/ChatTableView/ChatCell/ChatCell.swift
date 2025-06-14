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
import YYText

class ChatCell: UITableViewCell {
    
    private var cellViewModel: ChatCellViewModel!
    private var messageLable = CustomMessageLabel()
    private var nameLabel = UILabel()
    private var profileImage = UIImageView()
    private var dateLable = UILabel()
    private var unreadMessagesBadgeLabel = UnseenMessagesBadge()
    private var onlineStatusCircleView = UIView()
    private var onlineStatusBorderView = UIView()
    private var seenStatusMark: YYLabel = YYLabel()
    
    private var subscriptions = Set<AnyCancellable>()
    
    //MARK: - LIFECYCLE
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        
        self.isSkeletonable = true
        contentView.isSkeletonable = true
        
        let cellBackground = UIView()
        cellBackground.backgroundColor = ColorManager.cellSelectionBackgroundColor
        self.selectedBackgroundView = cellBackground
        self.backgroundColor = .clear
        
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    deinit {
        print("chatCellVM was deinit =====")
    }
    
    override func layoutSubviews()
    {
        super.layoutSubviews()
        profileImage.layer.cornerRadius = profileImage.bounds.width / 2
        onlineStatusCircleView.layer.cornerRadius = onlineStatusCircleView.bounds.width / 2
        onlineStatusBorderView.layer.cornerRadius = onlineStatusBorderView.bounds.width / 2
        
    }
    
    //MARK: - CELL CONFIGURATION
    
    override func prepareForReuse()
    {
        super.prepareForReuse()
        
        self.nameLabel.text = nil
        self.profileImage.image = nil
        self.messageLable.attributedText = nil
        self.dateLable.text = nil
        self.unreadMessagesBadgeLabel.unseenCount = 0
    }
    
    func configure(viewModel: ChatCellViewModel)
    {
        self.cellViewModel = viewModel
        setImage()
        setupBinding()
    }
    
    private func setOnlineStatusActivity() {
        if let activeStatus = cellViewModel.chatUser?.isActive {
            onlineStatusCircleView.isHidden = !activeStatus
            onlineStatusBorderView.isHidden = !activeStatus
        }
    }
    
    private func setUnreadMessageCount(_ count: Int) {
        //        guard let _ = cellViewModel.recentMessage else {return}
        
        unreadMessagesBadgeLabel.backgroundColor = ColorManager.unseenMessagesBadgeBackgroundColor
        
        let shouldShowUnreadCount = count > 0
        unreadMessagesBadgeLabel.isHidden = !shouldShowUnreadCount
        
        if shouldShowUnreadCount {
            unreadMessagesBadgeLabel.text = "\(count)"
        }
    }
    
    private func configureMessageSeenStatus()
    {
        guard let message = cellViewModel.recentMessage else {return}
        
        let isSeen = message.messageSeen ?? (message.seenBy.count > 1)

        let iconSize = isSeen ? CGSize(width: 18, height: 20) : CGSize(width: 20, height: 16)
        let seenStatusIcon = isSeen ? SeenStatusIcon.double.rawValue : SeenStatusIcon.single.rawValue
        guard let seenStatusIconImage = UIImage(named: seenStatusIcon)?
            .withTintColor(ColorManager.actionButtonsTintColor)
            .resize(to: iconSize) else {return}
        
        let imageAttributedString = NSMutableAttributedString.yy_attachmentString(withContent: seenStatusIconImage, contentMode: .center, attachmentSize: seenStatusIconImage.size, alignTo: UIFont(name: "Helvetica", size: 4)!, alignment: .center)
        
        seenStatusMark.attributedText = imageAttributedString
    }
    
    private func configureRecentMessage(_ message: Message?)
    {
        if !cellViewModel.isRecentMessagePresent {
            Utilities.stopSkeletonAnimation(for: self.messageLable, self.dateLable)
            return
        }
        if let message = message
        {
            Utilities.stopSkeletonAnimation(for: self.messageLable,self.dateLable)
            self.messageLable.attributedText = setAttributedText(for: message)
            self.dateLable.text = message.timestamp.formatToHoursAndMinutes()
            
            if cellViewModel.isAuthUserSenderOfRecentMessage
            {
                configureMessageSeenStatus()
            }
        }
    }
    
    private func setAttributedText(for message: Message) -> NSAttributedString?
    {
        if let imagePath = message.imagePath
        {
            let path = imagePath.replacingOccurrences(of: ".jpg", with: "_small.jpg")
            guard let imageData = CacheManager.shared.retrieveImageData(from: path) else {
                return nil
            }
            return setAttributedImageAttachment(imageData)
        }
        return NSAttributedString(string: message.messageBody)
    }
    
    private func setAttributedImageAttachment(_ imageData: Data) -> NSMutableAttributedString
    {
        let image = UIImage(data: imageData)
        
        let attachment = NSTextAttachment()
        attachment.image = image
        
        let imageSize = CGSize(width: 20, height: 20)
        attachment.bounds = CGRect(origin: .zero, size: imageSize)
        
        return NSMutableAttributedString(attachment: attachment)
    }
    
    //MARK: - Binding
    
    private func setupBinding()
    {
        cellViewModel.imageDataSubject
            .compactMap( { $0 } )
            .receive(on: DispatchQueue.main)
            .sink { [weak self] imageData in
                guard let self = self else {return}
                self.profileImage.image = UIImage(data: imageData)
                Utilities.stopSkeletonAnimation(for: self.profileImage)
            }.store(in: &subscriptions)
        
        cellViewModel.$chatUser
            .receive(on: DispatchQueue.main)
            .sink { member in
                if let member = member {
                    Utilities.stopSkeletonAnimation(for: self.nameLabel)
                    
                    if self.nameLabel.text != member.name {
                        self.nameLabel.text = member.name
                    }
                    self.setOnlineStatusActivity()
                }
            }.store(in: &subscriptions)
        
        cellViewModel.$chat
            .receive(on: DispatchQueue.main)
            .sink { chat in
                if chat.isGroup {
                    Utilities.stopSkeletonAnimation(for: self.nameLabel)
                    self.nameLabel.text = chat.name
                }
//                let imageData = self.cellViewModel.retrieveImageFromCache()
//                self.setImage(imageData)
            }.store(in: &subscriptions)
        
        cellViewModel.$recentMessage
            .receive(on: DispatchQueue.main)
//            .compactMap { $0 }
            .sink { [weak self] message in
                guard let self = self else {return}
                self.configureRecentMessage(message)
            }.store(in: &subscriptions)
        
        cellViewModel.$unreadMessageCount
            .receive(on: DispatchQueue.main)
            .sink { [weak self] count in
                guard let self = self else {return}
                guard let count = count else {return}
                
                Utilities.stopSkeletonAnimation(for: unreadMessagesBadgeLabel)
                setUnreadMessageCount(count)
            }.store(in: &subscriptions)
    }
    
    //MARK: - Image setup
    
    private func setImage()
    {
        guard cellViewModel.profileImageThumbnailPath == nil else
        {
            if let imageData = cellViewModel.retrieveImageFromCache() {
                profileImage.image = UIImage(data: imageData)
                Utilities.stopSkeletonAnimation(for: self.profileImage)
            } else {
                Utilities.initiateSkeletonAnimation(for: self)
            }
            return
        }
        
        self.profileImage.image = cellViewModel.chat.isGroup == true ?
        UIImage(named: "default_group_photo") : UIImage(named: "default_profile_photo")
    }

//    private func setImage(_ imageData: Data? = nil)
//    {
//        Task(priority: .high) { @MainActor in
//            
//            Utilities.stopSkeletonAnimation(for: profileImage)
//            
//            guard let imageData = imageData else {
//                let defaultImageName = cellViewModel.chat.isGroup ? "default_group_photo" : "default_profile_photo"
//                self.profileImage.image = UIImage(named: defaultImageName)
//                return
//            }
//            let image = UIImage(data: imageData)
//            self.profileImage.image = image
//        }
//    }
    
    
}


//MARK: - UI SETUP
extension ChatCell {
    
    private func setupUI()
    {
        setupProfileImage()
        setMessageLable()
        setNameLabel()
        setDateLable()
        setupUnreadMessagesCountLabel()
        createOnlineStatusView()
        setupSeenStatusMark()
//        Utilities.initiateSkeletonAnimation(for: self)
    }
    
    private func createOnlineStatusView()
    {
        contentView.addSubview(onlineStatusBorderView)
        onlineStatusBorderView.addSubview(onlineStatusCircleView)
        
        onlineStatusBorderView.backgroundColor = ColorManager.appBackgroundColor
        onlineStatusBorderView.clipsToBounds = true
        onlineStatusBorderView.isHidden = true
        onlineStatusBorderView.translatesAutoresizingMaskIntoConstraints = false
        
        onlineStatusCircleView.backgroundColor = #colorLiteral(red: 0.4666666687, green: 0.7647058964, blue: 0.2666666806, alpha: 1)
        onlineStatusCircleView.clipsToBounds = true
        onlineStatusCircleView.isHidden = true
        onlineStatusCircleView.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            onlineStatusBorderView.widthAnchor.constraint(equalToConstant: 16),
            onlineStatusBorderView.heightAnchor.constraint(equalToConstant: 16),
            onlineStatusBorderView.trailingAnchor.constraint(equalTo: profileImage.trailingAnchor, constant: 2),
            onlineStatusBorderView.bottomAnchor.constraint(equalTo: profileImage.bottomAnchor, constant: -1),
            
            onlineStatusCircleView.widthAnchor.constraint(equalToConstant: 12),
            onlineStatusCircleView.heightAnchor.constraint(equalToConstant: 12),
            onlineStatusCircleView.centerXAnchor.constraint(equalTo: onlineStatusBorderView.centerXAnchor),
            onlineStatusCircleView.centerYAnchor.constraint(equalTo: onlineStatusBorderView.centerYAnchor),
        ])
    }
    
    private func setupUnreadMessagesCountLabel() {
        contentView.addSubview(unreadMessagesBadgeLabel)
        
        unreadMessagesBadgeLabel.textColor = ColorManager.textFieldTextColor
        unreadMessagesBadgeLabel.font = UIFont(name: "Helvetica", size: 17)
        unreadMessagesBadgeLabel.textAlignment = .center
        unreadMessagesBadgeLabel.linesCornerRadius = 8
        unreadMessagesBadgeLabel.isSkeletonable = true
        unreadMessagesBadgeLabel.skeletonTextLineHeight = .fixed(25)
        unreadMessagesBadgeLabel.skeletonPaddingInsets = UIEdgeInsets(top: 0, left: -10, bottom: 0, right: -10)
        
        unreadMessagesBadgeLabel.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            unreadMessagesBadgeLabel.trailingAnchor.constraint(equalTo: self.trailingAnchor, constant: -17),
            unreadMessagesBadgeLabel.bottomAnchor.constraint(equalTo: self.bottomAnchor, constant: -12),
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
            messageLable.leadingAnchor.constraint(equalTo: self.profileImage.trailingAnchor, constant: 10),
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
            nameLabel.trailingAnchor.constraint(equalTo: self.trailingAnchor, constant: -65),
            nameLabel.bottomAnchor.constraint(equalTo: messageLable.topAnchor, constant: -1),
            nameLabel.leadingAnchor.constraint(equalTo: self.profileImage.trailingAnchor, constant: 10)
        ])
    }
    
    private func setupProfileImage()
    {
        contentView.addSubview(profileImage)
//        profileImage.layer.cornerRadius = self.bounds.size.width * 0.09
        profileImage.clipsToBounds = true
        profileImage.isSkeletonable = true
        
        setProfileImageConstraints()
    }
    
    private func setProfileImageConstraints()
    {
        profileImage.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            profileImage.leadingAnchor.constraint(equalTo: self.leadingAnchor, constant: 10),
            profileImage.centerYAnchor.constraint(equalTo: self.centerYAnchor),
            profileImage.topAnchor.constraint(equalTo: self.topAnchor, constant: 7),
            profileImage.bottomAnchor.constraint(equalTo: self.bottomAnchor, constant:  -7),
            profileImage.widthAnchor.constraint(equalTo: profileImage.heightAnchor)
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
    
    private func setupSeenStatusMark()
    {
        contentView.addSubview(seenStatusMark)
        
        seenStatusMark.font = UIFont(name: "Helvetica", size: 8)
        seenStatusMark.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            seenStatusMark.topAnchor.constraint(equalTo: self.topAnchor, constant: 6),
            seenStatusMark.trailingAnchor.constraint(equalTo: dateLable.leadingAnchor, constant: -4),
        ])
    }
}

extension ChatCell {
    class CustomMessageLabel: UILabel {
        override func drawText(in rect: CGRect) {
            var targetRect = textRect(forBounds: rect, limitedToNumberOfLines: numberOfLines)
            targetRect.origin.y = 2
            targetRect.origin.x = 2
            super.drawText(in: targetRect)
        }
    }
}

