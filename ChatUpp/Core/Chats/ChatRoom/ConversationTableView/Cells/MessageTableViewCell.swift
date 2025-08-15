//
//  CustomCollectionViewCell.swift
//  ChatUpp
//
//  Created by Andrei Pripa on 10/11/23.
//

import UIKit
import YYText
import Combine
import SkeletonView
import SwiftUI
//

final class MessageTableViewCell: UITableViewCell
{
    private var messageLayoutConfiguration: MessageLayoutConfiguration!
    
    var handleContentRelayout: (() -> Void)?
    
    private var containerStackViewBottomConstraint: NSLayoutConstraint!
    private var containerStackViewLeadingConstraint: NSLayoutConstraint!
    private var containerStackViewTrailingConstraint: NSLayoutConstraint!

//    private var messageComponentsStackView: UIStackView = UIStackView()
//    private var messageImageView = UIImageView()
//    private var messageTitleLabel: YYLabel?
//    private var timeStamp = YYLabel()
    private var subscribers = Set<AnyCancellable>()
    private var maxContainerWidth: CGFloat = 292.0
//    private var replyToMessageStack = ReplyToMessageStackView()
    
    private(set) var reactionBadgeHostingView: UIView?
//    private(set) var containerStackView: UIStackView = UIStackView()
    private(set) var containerStackView: MessageContainerView = MessageContainerView()
//    private(set) var messageContainer = UIView() // remove later
//    private(set) var messageLabel = MessageLabel()
//    private(set) var seenStatusMark = YYLabel()
//    private(set) var editedLabel: UILabel = UILabel()
    private(set) var cellViewModel: MessageCellViewModel!
    
//    private lazy var replyMessageLabel: ReplyMessageLabel = {
//        let replyMessageLabel = ReplyMessageLabel()
//        replyMessageLabel.numberOfLines = 2
//        replyMessageLabel.layer.cornerRadius = 4
//        replyMessageLabel.clipsToBounds = true
//        replyMessageLabel.backgroundColor = ColorManager.replyToMessageBackgroundColor
//        replyMessageLabel.rectInset = .init(top: -8, left: -8, bottom: 0, right: -8)
//        
//        return replyMessageLabel
//    }()
    
//    private lazy var messageSenderNameLabel: UILabel = {
//       let senderNameLabel = UILabel()
//        senderNameLabel.numberOfLines = 1
//        senderNameLabel.font = UIFont.systemFont(ofSize: 15, weight: .medium)
//        senderNameLabel.textColor = messageSenderNameColor
//        return senderNameLabel
//    }()

    private var messageSenderAvatar: UIImageView = {
        let senderAvatar = UIImageView()
        senderAvatar.clipsToBounds = true
        senderAvatar.translatesAutoresizingMaskIntoConstraints = false
        return senderAvatar
    }()
    
//    private var messageSenderNameColor: UIColor
//    {
//        let senderID = cellViewModel.message?.senderId
//        return ColorManager.color(for: senderID ?? "12345")
//    }
    
    /// - lifecycle
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        
        // Invert cell upside down
        transform = CGAffineTransform(scaleX: 1, y: -1)
        
        backgroundColor = .clear
        setupBackgroundSelectionView()
        setupContainerStackView()
//        setupMessageLabel()
//        setupMessageComponentsStackView()
//        setupTimestamp()
//        configureMessageImageView()
//        setupEditedLabel()
    }
    
    // implement for proper cell selection highlight when using UIMenuContextConfiguration on tableView
    private func setupBackgroundSelectionView()
    {
        let selectedView = UIView()
        selectedView.backgroundColor = UIColor.clear
        selectedBackgroundView = selectedView
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    /// - binding
    ///
    private func setupBinding()
    {
        cellViewModel.senderImageDataSubject
            .receive(on: DispatchQueue.main)
            .sink(receiveValue: { [weak self] imageData in
                self?.messageSenderAvatar.image = UIImage(data: imageData)
            }).store(in: &subscribers)
        
//        cellViewModel.messageImageDataSubject
//            .receive(on: DispatchQueue.main)
//            .sink(receiveValue: { [weak self] imageData in
//                //                if data == self?.cellViewModel.imageData {
////                self?.messageImage = UIImage(data: imageData)
//                guard let image = UIImage(data: imageData) else {return}
//                self?.configureMessageImage(image)
//                //                }
//            }).store(in: &subscribers)
        //
        cellViewModel.$message
            .receive(on: DispatchQueue.main)
            .compactMap({ $0 })
            .sink { [weak self] message in
                if message.isInvalidated { return }
                self?.setupContainerMessageLabel(with: message)
            }.store(in: &subscribers)
        
//        cellViewModel.$referencedMessage
//            .receive(on: DispatchQueue.main)
//            .dropFirst()
//            .sink { [weak self] replyMessage in
//                if let replyMessage {
//                    self?.updateMessageToReply(replyMessage)
//                } else {
//                    self?.removeMessageToReplyLabel()
//                }
//            }.store(in: &subscribers)
    }
    
    func setupContainerMessageLabel(with message: Message)
    {
        if let imageData = cellViewModel.retrieveImageData(),
           let image = UIImage(data: imageData) {
            containerStackView.showImageMessage(image, text: message.messageBody)
        } else if message.imagePath != nil {
            cellViewModel.fetchMessageImageData()
        } else {
            containerStackView.showTextMessage(message.messageBody)
        }
    }
    
//    private func setupMessageLabel(with message: Message)
//    {
//        guard let _ = message.imagePath else {
//            containerStackView.messageLabel.attributedText = messageTextLabelLinkSetup(from: message.messageBody)
//            handleMessageLayout()
//            return
//        }
//        
//        if let imageData = cellViewModel.retrieveImageData()
//        {
//            guard let image = UIImage(data: imageData) else {return}
//            self.configureMessageImage(image)
//        } else
//        {
//            cellViewModel.fetchMessageImageData()
//        }
//    }
    
    func setupReactionView(for message: Message)
    {
        guard !message.reactions.isEmpty else {return}
        
        let reactionVM = ReactionViewModel(message: message)
        let hostView = UIHostingController(rootView: ReactionBadgeView(viewModel: reactionVM))
        
        self.reactionBadgeHostingView = hostView.view
        
        hostView.view.backgroundColor = .clear
        hostView.view.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(hostView.view)
        
        let horizontalConstraint = cellViewModel.messageAlignment == .right ?
        hostView.view.trailingAnchor.constraint(equalTo: containerStackView.trailingAnchor, constant: -10) :
        hostView.view.leadingAnchor.constraint(equalTo: containerStackView.leadingAnchor, constant: 10)
        
        hostView.view.topAnchor.constraint(equalTo: containerStackView.bottomAnchor, constant: -2).isActive = true
        
        horizontalConstraint.isActive = true
    }
        
    /// - cell configuration
    ///
    
    func configureCell(using viewModel: MessageCellViewModel,
                       layoutConfiguration: MessageLayoutConfiguration)
    {
        guard let message = viewModel.message else { return }
        
        cleanupCellContent()
        
        cellViewModel = viewModel
        containerStackView.configure(with: viewModel,
                                     layoutConfiguration: layoutConfiguration)
        
//        containerStackView.timeStamp.text = viewModel.timestamp
        messageLayoutConfiguration = layoutConfiguration

//        setupSenderNameLabel()
        setupSenderAvatar()
        
//        setupMessageToReplyView()
        setContainerStackViewBottomConstraint()
//        updateEditedLabel()
//        updateStackViewComponentsAppearance()
        setupBinding()
        adjustMessageSide()

        setupContainerMessageLabel(with: message)
        setupReactionView(for: message)
            
//        testMessageTextEdit()
    }
    
//    private func removeMessageToReplyLabel()
//    {
//        executeAfter(seconds: 1.0) {
//            self.containerStackView.messageLabel.messageUpdateType = .replyRemoved
//            UIView.animate(withDuration: 0.3) {
//                self.replyToMessageStack.alpha = 0
//                self.replyToMessageStack.isHidden = true
//                //            self.containerStackView.layoutIfNeeded()
//            } completion: { _ in
//                self.containerStackView.removeArrangedSubview(self.replyToMessageStack)
//                self.replyToMessageStack.removeFromSuperview()
//                //            self.messageLabel.layoutIfNeeded()
//                self.handleMessageLayout()
//                UIView.animate(withDuration: 0.2) {
//                    //            self.containerStackView.layoutIfNeeded()
//                    //
//                    self.contentView.layoutIfNeeded()
//                    
//                }
//            }
//            self.handleContentRelayout?()
//        }
//    }
    
//    private func updateMessageToReply(_ message: Message)
//    {
//        guard let messageSenderName = cellViewModel.referencedMessageSenderName else {return}
//        executeAfter(seconds: 4.0, block: { [weak self] in
//            guard let self else {return}
//            let messageText = message.messageBody.isEmpty ? "Photo" : message.messageBody
//            let replyLabelText = self.createReplyMessageAttributedText(
//                with: messageSenderName,
//                messageText: messageText
//            )
//            let image = message.imagePath == nil ? nil : self.cellViewModel.retrieveReferencedImageData()
//            self.replyToMessageStack.configure(with: replyLabelText, imageData: image)
//            
//            UIView.animate(withDuration: 0.5) {
//                self.contentView.layoutIfNeeded()
//            }
//        })
//    }
    
    
    /// - cleanup
    private func cleanupCellContent()
    {
//        containerStackView.cleanupContent()
//        messageLabel.attributedText = nil
//        containerStackView.timeStamp.text = nil
//        messageImageView.image = nil
        messageSenderAvatar.image = nil
//        containerStackView.seenStatusMark.attributedText = nil
        reactionBadgeHostingView?.removeFromSuperview()
        reactionBadgeHostingView = nil
        
//        applyMessagePadding(strategy: .initial)
        
        subscribers.forEach { subscriber in
            subscriber.cancel()
        }
        subscribers.removeAll()
        
        // Layout with no animation to hide resizing animation of cells on keyboard show/hide
        // or any other table view content offset change
        UIView.performWithoutAnimation {
            self.contentView.layoutIfNeeded()
        }
    }
}
    
// MARK: - UI INITIAL STEUP

extension MessageTableViewCell
{
    private func setupContainerStackView()
    {
        contentView.addSubview(containerStackView)
        
//        containerStackView.axis = .vertical
//        containerStackView.spacing = 0
        containerStackView.layer.cornerRadius = 15
//        containerStackView.alignment = .leading
        containerStackView.clipsToBounds = true
        containerStackView.translatesAutoresizingMaskIntoConstraints = false
        
        self.containerStackViewBottomConstraint = containerStackView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor)
        self.containerStackViewBottomConstraint.isActive = true
        containerStackView.topAnchor.constraint(equalTo: contentView.topAnchor).isActive = true
        containerStackView.widthAnchor.constraint(lessThanOrEqualToConstant: maxContainerWidth).isActive = true
        
        containerStackView.widthAnchor.constraint(greaterThanOrEqualToConstant: 80).isActive = true
    }
    

    private func adjustMessageSide()
    {
//        if containerStackViewLeadingConstraint != nil { containerStackViewLeadingConstraint.isActive = false }
//        if containerStackViewTrailingConstraint != nil { containerStackViewTrailingConstraint.isActive = false }
        
        containerStackViewLeadingConstraint?.isActive = false
        containerStackViewTrailingConstraint?.isActive = false
        
        let leadingConstant = messageLayoutConfiguration.leadingConstraintConstant
        
        switch cellViewModel.messageAlignment {
        case .right:
            containerStackView.configureMessageSeenStatus()
            
            containerStackViewLeadingConstraint = containerStackView.leadingAnchor.constraint(greaterThanOrEqualTo: contentView.leadingAnchor)
            containerStackViewTrailingConstraint = containerStackView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -10)
            containerStackViewLeadingConstraint.isActive = true
            containerStackViewTrailingConstraint.isActive = true
            containerStackView.backgroundColor = ColorManager.outgoingMessageBackgroundColor
        case .left:
            containerStackViewLeadingConstraint = containerStackView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: leadingConstant)
            containerStackViewTrailingConstraint = containerStackView.trailingAnchor.constraint(lessThanOrEqualTo: contentView.trailingAnchor)
            containerStackViewLeadingConstraint.isActive = true
            containerStackViewTrailingConstraint.isActive = true
            containerStackView.backgroundColor = ColorManager.incomingMessageBackgroundColor
        case .center:
            break
        }
    }
}

extension MessageTableViewCell
{

    private func setupSenderAvatar()
    {
        /// check if chat is group (seen by is not empty in group)
//        guard cellViewModel.message?.seenBy.isEmpty == false else {return}
        
        guard messageLayoutConfiguration.shouldShowAvatar else
        {
            messageSenderAvatar.removeFromSuperview()
            return
        }
    
        if !contentView.contains(messageSenderAvatar)
        {
            contentView.addSubview(messageSenderAvatar)
            setupSenderAvatarConstraints()
        }

        messageSenderAvatar.layer.cornerRadius = (messageLayoutConfiguration.avatarSize?.width ?? 35) / 2
        
        // change to small after implementing storage images add for small
        if let imageData = cellViewModel.retrieveSenderAvatarData(ofSize: "small") {
            messageSenderAvatar.image = UIImage(data: imageData)
        } else {
            messageSenderAvatar.image = UIImage(named: "default_profile_photo")
        }
    }
    
    private func setupSenderAvatarConstraints()
    {
        guard let avatarSize = messageLayoutConfiguration.avatarSize else {return}
        
        messageSenderAvatar.trailingAnchor.constraint(equalTo: containerStackView.leadingAnchor, constant: -8).isActive = true
        messageSenderAvatar.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -3).isActive = true
        messageSenderAvatar.widthAnchor.constraint(equalToConstant: avatarSize.width).isActive = true
        messageSenderAvatar.heightAnchor.constraint(equalToConstant: avatarSize.height).isActive = true
    }
    
    private func setContainerStackViewBottomConstraint()
    {
        let isReactionsEmpty = cellViewModel.message?.reactions.isEmpty
        self.containerStackViewBottomConstraint.constant = isReactionsEmpty ?? true ? -3 : -25
    }
}


enum SeenStatusIcon: String {
//    case single = "icons8-done-64-6"
    case single = "test-cropped-single-checkmark-2"
//    case double = "icons8-double-tick-48-3"
    case double = "test-cropped-double-checkmark"
}

extension MessageTableViewCell: TargetPreviewable
{
    func getTargetViewForPreview() -> UIView
    {
        return containerStackView
    }
    
    func getTargetedPreviewColor() -> UIColor
    {
        switch cellViewModel.messageAlignment {
        case .left: return #colorLiteral(red: 0, green: 0.6150025129, blue: 0.6871898174, alpha: 1)
        case .right: return #colorLiteral(red: 0.7171613574, green: 0.4463854432, blue: 0.351280123, alpha: 1)
        default: return .clear
        }
    }
}


extension MessageTableViewCell: MessageCellDragable
{
    var messageText: String?
    {
        if let text = cellViewModel.message?.messageBody {
            let cleaned = text.replacingOccurrences(
                of: #"^[ \n￼]+"#,
                with: "",
                options: .regularExpression
            )
            return cleaned.isEmpty ? nil : cleaned
        }
        return nil
    }
    
    var messageImage: UIImage?
    {
        return containerStackView.messageImageView.image
    }
}
