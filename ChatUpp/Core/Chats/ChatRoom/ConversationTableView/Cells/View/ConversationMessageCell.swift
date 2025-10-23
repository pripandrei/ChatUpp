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


final class ConversationMessageCell: UITableViewCell
{
    private var contentContainerViewBottomConstraint: NSLayoutConstraint!
    private var contentContainerViewLeadingConstraint: NSLayoutConstraint!
    private var contentContainerViewTrailingConstraint: NSLayoutConstraint!
    private var messageLayoutConfiguration: MessageLayoutConfiguration!
    
    private(set) var contentContainer: UIView!
    private(set) var reactionBadgeHostingView: UIView?
    private(set) var cellViewModel: MessageCellViewModel!
    
    private var subscribers = Set<AnyCancellable>()
    
    lazy private var messageSenderAvatar: UIImageView = {
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
    }
    
//    deinit
//    {
//        print("ConversationMessageCell deinit")
//    }
    
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
        hostView.view.trailingAnchor.constraint(equalTo: contentContainer.trailingAnchor, constant: -10) :
        hostView.view.leadingAnchor.constraint(equalTo: contentContainer.leadingAnchor, constant: 10)
        
        hostView.view.topAnchor.constraint(equalTo: contentContainer.bottomAnchor, constant: -2).isActive = true
        
        horizontalConstraint.isActive = true
    }
        
    /// - cell configuration
    ///
    func configureCell(using viewModel: MessageCellViewModel,
                       layoutConfiguration: MessageLayoutConfiguration)
    {
        guard let message = viewModel.message,
              let type = viewModel.message?.type else
        {
            assert(false, "message and it's type should be valid at this point")
            return
        }

        cleanupCellContent()
        
        cellViewModel = viewModel
        messageLayoutConfiguration = layoutConfiguration
        
        setupBinding()

        contentContainer?.removeFromSuperview()
        contentContainer = nil
        
        switch type
        {
        case .text, .image, .imageText:
            let imageTextView = TextImageMessageContentView()
            setupContainerView(imageTextView, type: type)
            imageTextView.configure(with: viewModel.messageContainerViewModel!,
                                    layoutConfiguration: layoutConfiguration)
        case .sticker:
            let stickerView = StickerMessageContentView()
            setupContainerView(stickerView, type: .sticker)
            stickerView.configure(with: viewModel.messageContainerViewModel!)
        case .audio:
            let audioView = VoiceMessageContentView()
            setupContainerView(audioView, type: .audio)
            audioView.configure(with: viewModel.messageContainerViewModel!)
        default: break
        }
        
        adjustMessageSide()
        setupSenderAvatar()
        setupReactionView(for: message)
        setContentContainerViewBottomConstraint()
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
    private func setupContainerView(_ view: UIView, type: MessageType)
    {
        self.contentContainer = view
        contentView.addSubview(contentContainer!)
    
        view.translatesAutoresizingMaskIntoConstraints = false
        
        self.contentContainerViewBottomConstraint = view.bottomAnchor.constraint(equalTo: contentView.bottomAnchor)
        self.contentContainerViewBottomConstraint.priority = UILayoutPriority(rawValue: 999)
        self.contentContainerViewBottomConstraint.isActive = true
        
        self.contentContainerViewLeadingConstraint = view.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 0)
        self.contentContainerViewTrailingConstraint = view.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -10)
        
        view.topAnchor.constraint(equalTo: contentView.topAnchor).isActive = true
        
        switch type
        {
        case .imageText, .image, .text:
            view.widthAnchor.constraint(lessThanOrEqualToConstant: TextImageMessageContentView.maxWidth).isActive = true
            view.widthAnchor.constraint(greaterThanOrEqualToConstant: 80).isActive = true
            contentContainer?.backgroundColor = cellViewModel.messageAlignment == .right ?
            ColorManager.outgoingMessageBackgroundColor : ColorManager.incomingMessageBackgroundColor
        case .sticker:
            view.widthAnchor.constraint(equalTo: contentView.widthAnchor, constant: -10).isActive = true
//            view.heightAnchor.constraint(equalToConstant: 170).isActive = true
            contentContainer?.backgroundColor = .clear
        case .audio:
            view.widthAnchor.constraint(lessThanOrEqualToConstant: 200).isActive = true
            contentContainer?.backgroundColor = cellViewModel.messageAlignment == .right ?
            ColorManager.outgoingMessageBackgroundColor : ColorManager.incomingMessageBackgroundColor
        default: break
        }
    }
 
    private func adjustMessageSide()
    {
        let leadingConstant = messageLayoutConfiguration.leadingConstraintConstant
        
        switch cellViewModel.messageAlignment {
        case .right:
            contentContainerViewLeadingConstraint.isActive = false
            contentContainerViewTrailingConstraint.isActive = true
        case .left:
            contentContainerViewTrailingConstraint.isActive = false
            contentContainerViewLeadingConstraint.isActive = true
            contentContainerViewLeadingConstraint.constant = leadingConstant
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
        
        messageSenderAvatar.trailingAnchor.constraint(equalTo: contentContainer.leadingAnchor, constant: -8).isActive = true
        messageSenderAvatar.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -3).isActive = true
        messageSenderAvatar.widthAnchor.constraint(equalToConstant: avatarSize.width).isActive = true
        messageSenderAvatar.heightAnchor.constraint(equalToConstant: avatarSize.height).isActive = true
    }
    
    private func setContentContainerViewBottomConstraint()
    {
        let isReactionsEmpty = cellViewModel.message?.reactions.isEmpty
        self.contentContainerViewBottomConstraint.constant = isReactionsEmpty ?? true ? -3 : -25
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
        return contentContainer ?? UIView()
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

//MARK: - MessageCellDragable protocol implementation
extension ConversationMessageCell: MessageCellDragable
{
    var messageText: String?
    {
        switch cellViewModel.message?.type
        {
        case .image: return "Photo"
        case .sticker: return "Sticker"
        case .text, .imageText: return getFilteredMessageText()
        case .audio: return "Voice Message"
        case .video: return "Video"
        default: return nil
        }
    }
    
    var messageImage: UIImage?
    {
        if let imageData = cellViewModel.messageContainerViewModel?.getImageDataThumbnailFromMessage()
        {
            return UIImage(data: imageData)
        }
        return nil
    }
    
    var messageSenderName: String?
    {
        cellViewModel.messageSender?.name
    }
    
    private func getFilteredMessageText() -> String?
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
}


//MARK: - Message content view type cast
extension ConversationMessageCell
{
    var messageContentView: TextImageMessageContentView?
    {
        return contentContainer as? TextImageMessageContentView
    }
    
    var stickerContentView: StickerMessageContentView?
    {
        return contentContainer as? StickerMessageContentView
    }
}

extension ConversationMessageCell: MessageCellSeenable {}
