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

//protocol MessageContentView: UIView {
//    func configure(with message: Message)
//}

final class ConversationMessageCell: UITableViewCell
{
    private var messageLayoutConfiguration: MessageLayoutConfiguration!
    
//    var handleContentRelayout: (() -> Void)?
    
    private var containerStackViewBottomConstraint: NSLayoutConstraint!
    private var containerStackViewLeadingConstraint: NSLayoutConstraint!
    private var containerStackViewTrailingConstraint: NSLayoutConstraint!
    
    private(set) var containerStackView: MessageContainerView = MessageContainerView()
    private(set) var reactionBadgeHostingView: UIView?
    private(set) var cellViewModel: MessageCellViewModel!
    
    private var subscribers = Set<AnyCancellable>()
    
    private var messageSenderAvatar: UIImageView = {
        let senderAvatar = UIImageView()
        senderAvatar.clipsToBounds = true
        senderAvatar.translatesAutoresizingMaskIntoConstraints = false
        return senderAvatar
    }()

    /// - lifecycle
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        
        // Invert cell upside down
        transform = CGAffineTransform(scaleX: 1, y: -1)
        
        backgroundColor = .clear
        setupBackgroundSelectionView()
        setupContainerStackView()
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

    }

    
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
        guard let message = viewModel.message else {
            assert(false, "message should be valid at this point")
            return
        }
        
        cleanupCellContent()
        
        cellViewModel = viewModel
        
        messageLayoutConfiguration = layoutConfiguration
        
        setupSenderAvatar()
        setContainerStackViewBottomConstraint()
        setupBinding()
        adjustMessageSide()

        setupReactionView(for: message)
        containerStackView.configure(with: viewModel.messageContainerViewModel!,
                                     layoutConfiguration: layoutConfiguration)
    }

    /// - cleanup
    private func cleanupCellContent()
    {
        messageSenderAvatar.image = nil
        reactionBadgeHostingView?.removeFromSuperview()
        reactionBadgeHostingView = nil
        
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

extension ConversationMessageCell
{
    private func setupContainerStackView()
    {
        contentView.addSubview(containerStackView)
    
        containerStackView.spacing = 2
        containerStackView.margins = .init(top: 6, left: 10, bottom: 6, right: 10)
        containerStackView.layer.cornerRadius = 15
        containerStackView.clipsToBounds = true
        containerStackView.translatesAutoresizingMaskIntoConstraints = false
        
        self.containerStackViewBottomConstraint = containerStackView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor)
        self.containerStackViewBottomConstraint.isActive = true
        
        self.containerStackViewLeadingConstraint = containerStackView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 0)
        self.containerStackViewTrailingConstraint = containerStackView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -10)
        
        containerStackView.topAnchor.constraint(equalTo: contentView.topAnchor).isActive = true
        containerStackView.widthAnchor.constraint(lessThanOrEqualToConstant: MessageContainerView.maxWidth).isActive = true
        
        containerStackView.widthAnchor.constraint(greaterThanOrEqualToConstant: 80).isActive = true
    }
    
    private func adjustMessageSide()
    {
        let leadingConstant = messageLayoutConfiguration.leadingConstraintConstant
        
        switch cellViewModel.messageAlignment {
        case .right:
//            containerStackView.configureMessageSeenStatus()

            containerStackViewLeadingConstraint.isActive = false
            containerStackViewTrailingConstraint.isActive = true
            containerStackView.backgroundColor = ColorManager.outgoingMessageBackgroundColor
        case .left:
            containerStackViewTrailingConstraint.isActive = false
            containerStackViewLeadingConstraint.isActive = true
            containerStackViewLeadingConstraint.constant = leadingConstant
            containerStackView.backgroundColor = ColorManager.incomingMessageBackgroundColor
        case .center:
            break
        }
    }
}

extension ConversationMessageCell
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

extension ConversationMessageCell: TargetPreviewable
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

extension ConversationMessageCell: MessageCellDragable
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
    
    var messageSenderName: String?
    {
        cellViewModel.messageSender?.name
    }
}

extension ConversationMessageCell: MessageCellSeenable {}
