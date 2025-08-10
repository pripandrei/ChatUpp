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

final class MessageTableViewCell: UITableViewCell
{
    private var messageLayoutConfiguration: MessageLayoutConfiguration!
    
    var handleContentRelayout: (() -> Void)?
    
    private var containerStackViewBottomConstraint: NSLayoutConstraint!
    private var containerStackViewLeadingConstraint: NSLayoutConstraint!
    private var containerStackViewTrailingConstraint: NSLayoutConstraint!
    
    private var messageSenderNameLabel: UILabel?
    private var messageSenderAvatar: UIImageView?
    private var messageComponentsStackView: UIStackView = UIStackView()
    private var messageImageView = UIImageView()
    private var messageTitleLabel: YYLabel?
    private var timeStamp = YYLabel()
    private var subscribers = Set<AnyCancellable>()
    private var maxMessageWidth: CGFloat = 292.0
    
    private(set) var reactionBadgeHostingView: UIView?
    private(set) var containerStackView: UIStackView = UIStackView()
    private(set) var messageContainer = UIView() // remove later
    private(set) var messageLabel = MessageLabel()
    private(set) var seenStatusMark = YYLabel()
    private(set) var editedLabel: UILabel = UILabel()
    private(set) var cellViewModel: MessageCellViewModel!
    
    private lazy var replyMessageLabel: ReplyMessageLabel = {
        let replyMessageLabel = ReplyMessageLabel()
        replyMessageLabel.numberOfLines = 2
        replyMessageLabel.layer.cornerRadius = 4
        replyMessageLabel.clipsToBounds = true
        replyMessageLabel.backgroundColor = ColorManager.replyToMessageBackgroundColor
        replyMessageLabel.rectInset = .init(top: -8, left: -8, bottom: 0, right: -8)
        
        return replyMessageLabel
    }()

    private var messageSenderNameColor: UIColor
    {
        let senderID = cellViewModel.message?.senderId
        return ColorManager.color(for: senderID ?? "12345")
    }
    
    /// - lifecycle
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        
        // Invert cell upside down
        transform = CGAffineTransform(scaleX: 1, y: -1)
        
        backgroundColor = .clear
        setupBackgroundSelectionView()
        setupContainerStackView()
        setupMessageLabel()
        setupMessageComponentsStackView()
        setupTimestamp()
        configureMessageImageView()
        setupEditedLabel()
    }
    
    func configureMessageImageView()
    {
        messageLabel.addSubview(messageImageView)
        messageLabel.sendSubviewToBack(messageImageView)
        
        messageImageView.layer.cornerRadius = 15
        messageImageView.clipsToBounds = true
        messageImageView.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            messageImageView.leadingAnchor.constraint(equalTo: messageLabel.leadingAnchor, constant: 2),
            messageImageView.trailingAnchor.constraint(equalTo: messageLabel.trailingAnchor, constant: -2),
            messageImageView.topAnchor.constraint(equalTo: messageLabel.topAnchor, constant: 2),
//            profileImageView.bottomAnchor.constraint(equalTo: messageLabel.bottomAnchor, constant: -2)
        ])
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
                self?.messageSenderAvatar?.image = UIImage(data: imageData)
            }).store(in: &subscribers)
        
        cellViewModel.messageImageDataSubject
            .receive(on: DispatchQueue.main)
            .sink(receiveValue: { [weak self] imageData in
                //                if data == self?.cellViewModel.imageData {
//                self?.messageImage = UIImage(data: imageData)
                guard let image = UIImage(data: imageData) else {return}
                self?.configureMessageImage(image)
                //                }
            }).store(in: &subscribers)
        //
        cellViewModel.$message
            .receive(on: DispatchQueue.main)
            .compactMap({ $0 })
            .sink { [weak self] message in
                if message.isInvalidated { return }
                self?.setupMessageData(with: message)
            }.store(in: &subscribers)
        
        cellViewModel.$referencedMessage
            .receive(on: DispatchQueue.main)
            .dropFirst()
            .sink { [weak self] replyMessage in
                if let replyMessage {
                    self?.updateMessageToReply(replyMessage)
                } else {
                    self?.removeMessageToReplyLabel()
                }
            }.store(in: &subscribers)
    }
    
    private func setupMessageData(with message: Message)
    {
        guard let _ = message.imagePath else {
            messageLabel.attributedText = messageTextLabelLinkSetup(from: message.messageBody)
            handleMessageLayout()
            return
        }
        
        if let imageData = cellViewModel.retrieveImageData()
        {
            guard let image = UIImage(data: imageData) else {return}
            self.configureMessageImage(image)
        } else
        {
            cellViewModel.fetchMessageImageData()
        }
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
        guard let message = viewModel.message else { return }
        
        cleanupCellContent()
        cellViewModel = viewModel
        timeStamp.text = viewModel.timestamp
        messageLayoutConfiguration = layoutConfiguration
        
        if viewModel.messageAlignment == .left
        {
            if layoutConfiguration.shouldShowSenderName {
                setupSenderNameLabel()
            }
            if layoutConfiguration.shouldShowAvatar {
                setupSenderAvatar()
            }
        }
        
        setupMessageToReplyView()
        setContainerStackViewBottomConstraint()
        updateEditedLabel()
        updateStackViewAppearance()
        setupBinding()
        adjustMessageSide()

        setupMessageData(with: message)
        setupReactionView(for: message)
            
//        testMessageTextEdit()
    }
    
    private func removeMessageToReplyLabel()
    {
        executeAfter(seconds: 1.0) {
            self.messageLabel.messageUpdateType = .replyRemoved
            UIView.animate(withDuration: 0.3) {
                self.replyViewTest.alpha = 0
                self.replyViewTest.isHidden = true
                //            self.containerStackView.layoutIfNeeded()
            } completion: { _ in
                self.containerStackView.removeArrangedSubview(self.replyViewTest)
                self.replyViewTest.removeFromSuperview()
                //            self.messageLabel.layoutIfNeeded()
                self.handleMessageLayout()
                UIView.animate(withDuration: 0.2) {
                    //            self.containerStackView.layoutIfNeeded()
                    //
                    self.contentView.layoutIfNeeded()
                    
                }
            }
            self.handleContentRelayout?()
        }
    }
    
    private func updateMessageToReply(_ message: Message)
    {
        guard let messageSenderName = cellViewModel.referencedMessageSenderName else {return}
        executeAfter(seconds: 4.0, block: { [weak self] in
            guard let self else {return}
            let messageText = message.messageBody.isEmpty ? "Photo" : message.messageBody
            let replyLabelText = self.createReplyMessageAttributedText(
                with: messageSenderName,
                messageText: messageText
            )
            let image = message.imagePath == nil ? nil : self.cellViewModel.retrieveReferencedImageData()
            self.replyViewTest.configure(with: replyLabelText, imageData: image)
            
            UIView.animate(withDuration: 0.5) {
                self.contentView.layoutIfNeeded()
            }
        })
    }

    // Custom image view that handles its own sizing
    private class FixedSizeImageView: UIImageView {
        private let fixedSize: CGSize
        
        init(size: CGSize) {
            self.fixedSize = size
            super.init(frame: CGRect(origin: .zero, size: size))
            contentMode = .scaleAspectFill
            clipsToBounds = true
            layer.cornerRadius = 4
        }
        
        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
        
        override var intrinsicContentSize: CGSize {
            return fixedSize
        }
    }
    
    final class TestReplyView: UIView {
        
        class CustomContainerView: UIView
        {
            override init(frame: CGRect) {
                super.init(frame: frame)
                backgroundColor = ColorManager.replyToMessageBackgroundColor
                clipsToBounds = true
                layer.cornerRadius = 4
            }
            
            required init?(coder: NSCoder) {
                fatalError("init(coder:) has not been implemented")
            }
            
            override func draw(_ rect: CGRect) {
                super.draw(rect)
                fillColor(with: .white, width: 5)
            }
            
            private func fillColor(with color: UIColor, width: CGFloat) {
                let stripeRect = CGRect(x: 0, y: 0, width: width, height: bounds.height)
                color.setFill()
                UIRectFill(stripeRect)
            }
        }
        
        let containerView: UIView = CustomContainerView()
        let imageView = UIImageView()
        let messageLabel = UILabel()
        
        override init(frame: CGRect) {
            super.init(frame: frame)
            setupContainerView()
            setupMessageLabel()
        }
        
        required init?(coder: NSCoder) {
            super.init(coder: coder)
            setupContainerView()
            setupMessageLabel()
        }
        
        private func setupContainerView() {
            self.addSubview(containerView)
            
            containerView.translatesAutoresizingMaskIntoConstraints = false
            
            NSLayoutConstraint.activate([
                containerView.topAnchor.constraint(equalTo: self.topAnchor, constant: 7),
                containerView.leadingAnchor.constraint(equalTo: self.leadingAnchor, constant: 7),
                containerView.trailingAnchor.constraint(equalTo: self.trailingAnchor, constant: -7),
                containerView.bottomAnchor.constraint(equalTo: self.bottomAnchor, constant: 0)
            ])
        }
        
        private func setupMessageLabel()
        {
            containerView.addSubview(messageLabel)
            messageLabel.numberOfLines = 2
            messageLabel.layer.cornerRadius = 4
            messageLabel.clipsToBounds = true
            messageLabel.backgroundColor = ColorManager.replyToMessageBackgroundColor
            messageLabel.translatesAutoresizingMaskIntoConstraints = false
            
            NSLayoutConstraint.activate([
                messageLabel.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 5),
                messageLabel.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 15),
                messageLabel.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -5),
                messageLabel.bottomAnchor.constraint(equalTo: containerView.bottomAnchor, constant: -5)
            ])
        }
    }
    
    final class ReplyMessageView2: UIStackView {
            
            // MARK: - Subviews
            private let imageView = FixedSizeImageView(size: CGSize(width: 30, height: 30))
            private let nameLabel = UILabel()
            private let messageLabel = UILabel()
            private let labelsStack = UIStackView()
            
            // MARK: - Stripe
            private var stripeColor: UIColor = .clear
            private var stripeWidth: CGFloat = 0
            
            // MARK: - Init
            init(senderName: String, messageText: String, image: UIImage?) {
                super.init(frame: .zero)
                setupView()
                configure(senderName: senderName, messageText: messageText, image: image)
            }
            
            required init(coder: NSCoder) {
                fatalError("init(coder:) has not been implemented")
            }
            
            // MARK: - Dynamic padding calculation
            private let outerPadding: CGFloat = 14
            private let innerPadding: CGFloat = 10
            
            override var alignmentRectInsets: UIEdgeInsets {
                return UIEdgeInsets(top: -8, left: -8, bottom: 0, right: -8)
            }
            
            private var calculatedLayoutMargins: UIEdgeInsets {
                let alignmentInsets = alignmentRectInsets
                return UIEdgeInsets(
                    top: innerPadding + abs(alignmentInsets.top),
                    left: outerPadding + innerPadding + abs(alignmentInsets.left),
                    bottom: innerPadding + abs(alignmentInsets.bottom),
                    right: outerPadding + innerPadding + abs(alignmentInsets.right)
                )
            }
            
            private func setupView() {
                axis = .horizontal
                alignment = .top
                spacing = 8
                
                // Use dynamically calculated layout margins
                isLayoutMarginsRelativeArrangement = true
                layoutMargins = calculatedLayoutMargins
                
                // Labels
                nameLabel.font = UIFont.boldSystemFont(ofSize: 13)
                nameLabel.textColor = .white
                
                messageLabel.font = UIFont.systemFont(ofSize: 13)
                messageLabel.textColor = .white
                messageLabel.numberOfLines = 0
                
                // Labels stack
                labelsStack.axis = .vertical
                labelsStack.alignment = .leading
                labelsStack.spacing = 2
                labelsStack.addArrangedSubview(nameLabel)
                labelsStack.addArrangedSubview(messageLabel)
                
                // Add views - no constraints needed
                addArrangedSubview(imageView)
                addArrangedSubview(labelsStack)
            }
            
            func configure(senderName: String, messageText: String, image: UIImage?) {
                nameLabel.text = senderName
                messageLabel.text = messageText
                imageView.image = image ?? UIImage(systemName: "star.fill")
            }
            
            func fillColor(with color: UIColor, width: CGFloat) {
                stripeColor = color
                stripeWidth = width
                setNeedsDisplay()
            }
            
            override func draw(_ rect: CGRect) {
                super.draw(rect)
                // Dynamically calculate stripe position based on alignment rect and outer padding
                let alignmentInsets = alignmentRectInsets
                let stripeX = outerPadding + abs(alignmentInsets.left)
                let stripeRect = CGRect(x: stripeX, y: 0, width: stripeWidth, height: bounds.height)
                stripeColor.setFill()
                UIRectFill(stripeRect)
            }
        }

    var replyViewTest = TestReplyStack()
    
    private func setupMessageToReplyView()
    {
        guard let senderName = cellViewModel.referencedMessageSenderName,
              let messageText = cellViewModel.referencedMessage?.messageBody else {
            containerStackView.arrangedSubviews
                .filter { $0 is TestReplyStack }
                .forEach {
                    containerStackView.removeArrangedSubview($0)
                    $0.removeFromSuperview()
                }
            return
        }
        let replyLabelText = messageText.isEmpty ? "Photo" : messageText
        let replyText = createReplyMessageAttributedText(
            with: senderName,
            messageText: replyLabelText
        )
        
        let imageData: Data? = cellViewModel.retrieveReferencedImageData()
        
        //        if let _ = cellViewModel.referencedMessage?.imagePath
        //        {
        //            if let image = cellViewModel.retrieveReferencedImageData() {
        //                imageData = image
        //            } else {
        //                cellViewModel.fetchReferencedMessageImageData()
        //            }
        //        }
        
        replyViewTest.configure(with: replyText, imageData: imageData)
        
        containerStackView.insertArrangedSubview(replyViewTest, at: 0)
        replyViewTest.widthAnchor.constraint(equalTo: containerStackView.widthAnchor).isActive = true
    }
    
    
    final class TestReplyStack: UIStackView
    {
        
        class FixedSizeImageView: UIImageView {
            private let fixedSize: CGSize
            
            init(size: CGSize) {
                self.fixedSize = size
                super.init(frame: .zero)
            }
            
            required init?(coder: NSCoder) {
                fatalError("init(coder:) has not been implemented")
            }
            
            override var intrinsicContentSize: CGSize {
                return fixedSize
            }
        }
        class ReplyInnerStackView: UIStackView
        {
            override func draw(_ rect: CGRect) {
                UIColor.white.setFill()
                let rect = CGRect(x: 0, y: 0, width: 5, height: bounds.height)
                UIRectFill(rect)
            }
            
            override init(frame: CGRect) {
                super.init(frame: frame)
                backgroundColor = ColorManager.replyToMessageBackgroundColor
                axis = .horizontal
                clipsToBounds = true
                layer.cornerRadius = 4
                spacing = 10
                isLayoutMarginsRelativeArrangement = true
                layoutMargins = UIEdgeInsets(top: 5, left: 12, bottom: 5, right: 5)
            }
            
            required init(coder: NSCoder) {
                fatalError("init(coder:) has not been implemented")
            }
        }
        
        private var replyInnerStackView: ReplyInnerStackView = ReplyInnerStackView()
        
        lazy var imageView: FixedSizeImageView = {
            let imageView = FixedSizeImageView(size: CGSize(width: 30, height: 30))
            imageView.contentMode = .scaleAspectFill
            imageView.clipsToBounds = true
            return imageView
        }()
        
        private let messageLabel: UILabel = {
            let label = UILabel()
            label.numberOfLines = 2
            label.clipsToBounds = true
            return label
        }()
        
        override init(frame: CGRect) {
            super.init(frame: frame)
            setupSelf()
        }
        private func setupSelf()
        {
            axis = .vertical
            spacing = 5
            isLayoutMarginsRelativeArrangement = true
            layoutMargins = UIEdgeInsets(top: 7, left: 7, bottom: 0, right: 7)
            
//            imageView.image = UIImage(named: "default_group_photo")
            
            // Set intrinsic content size for the image view
//            imageView.intrinsicContentSize = CGSize(width: 30, height: 30)
            
//            imageView.setContentHuggingPriority(.defaultHigh, for: .horizontal)
//            imageView.setContentHuggingPriority(.defaultHigh, for: .vertical) // Changed to high
//            messageLabel.setContentHuggingPriority(.defaultLow, for: .horizontal)
//            messageLabel.setContentCompressionResistancePriority(.defaultHigh, for: .horizontal)
//
            replyInnerStackView.addArrangedSubview(messageLabel)
//            let innerStack = replyInnerStackView(arrangedSubviews: [messageLabel])
            addArrangedSubview(replyInnerStackView)
        }
        
        func configure(with text: NSAttributedString,
                       imageData: Data? = nil)
        {
            messageLabel.attributedText = text
            
            if let imageData
            {
                imageView.image = UIImage(data: imageData)
                replyInnerStackView.insertArrangedSubview(imageView, at: 0)
            } else {
                imageView.image = nil
                replyInnerStackView.removeArrangedSubview(imageView)
                imageView.removeFromSuperview()
            }
        }
        
        required init(coder: NSCoder) { fatalError() }
    }
    
    
//    private func setupMessageToReplyLabel()
//    {
//        guard let messageSenderName = cellViewModel.referencedMessageSenderName,
//              let messageText = cellViewModel.referencedMessage?.messageBody else
//        {
//            containerStackView.removeArrangedSubview(replyMessageLabel)
//            replyMessageLabel.removeFromSuperview()
//            return
//        }
//        
//        replyMessageLabel.attributedText = createReplyMessageAttributedText(
//            with: messageSenderName,
//            messageText: messageText
//        )
//        
//        if !containerStackView.arrangedSubviews.contains(replyMessageLabel)
//        {
//            containerStackView.insertArrangedSubview(replyMessageLabel, at: 0)
//            replyMessageLabel.widthAnchor.constraint(equalTo: containerStackView.widthAnchor).isActive = true
//        }
//        
//        let image = UIImage(systemName: "star.fill")?.withRenderingMode(.alwaysOriginal)
//        let uiimage = UIImageView(image: image)
//        replyMessageLabel.addSubview(uiimage)
//        uiimage.translatesAutoresizingMaskIntoConstraints = false
//        
//        NSLayoutConstraint.activate([
//            uiimage.leadingAnchor.constraint(equalTo: replyMessageLabel.leadingAnchor, constant: 15),
//            uiimage.topAnchor.constraint(equalTo: replyMessageLabel.topAnchor, constant: replyMessageLabel.textInset.top),
//            uiimage.bottomAnchor.constraint(equalTo: replyMessageLabel.bottomAnchor, constant: -replyMessageLabel.textInset.bottom),
//            uiimage.widthAnchor.constraint(equalToConstant: 30)
//        ])
//    }
 
    private func setupStackViewComponentsColor() {
        timeStamp.textColor = getColorForMessageComponents()
        editedLabel.textColor = getColorForMessageComponents()
    }
    
    private func getColorForMessageComponents() -> UIColor
    {
        var color: UIColor = ColorManager.outgoingMessageComponentsTextColor
        
        if let viewModel = cellViewModel
        {
            if viewModel.message?.type == .image {
                color = .white
            } else {
                color = viewModel.messageAlignment == .left ? ColorManager.incomingMessageComponentsTextColor : ColorManager.outgoingMessageComponentsTextColor
            }
        }
        return color
    }
    
    private func messageTextLabelLinkSetup(from text: String) -> NSAttributedString?
    {
        guard let attributedText = makeAttributedString(for: text) else { return nil }

        if let detector = try? NSDataDetector(types: NSTextCheckingResult.CheckingType.link.rawValue) {
            let matches = detector.matches(in: text, options: [], range: NSRange(location: 0, length: text.utf16.count))

            guard !matches.isEmpty else { return attributedText }

            for match in matches {
                guard let _ = Range(match.range, in: text),
                      let url = match.url else { continue }

                let decorator = YYTextDecoration(style: .single,
                                                 width: 1,
                                                 color: ColorManager.messageLinkColor)
                
                attributedText.yy_setTextUnderline(decorator,
                                                   range: match.range)
                attributedText.yy_setTextHighlight(match.range,
                                                   color: ColorManager.messageLinkColor,
                                                   backgroundColor: #colorLiteral(red: 0.6552016139, green: 0.657288909, blue: 0.7513562441, alpha: 1))
                { _, _, _, _ in
                    UIApplication.shared.open(url)
                }
            }
        }
        return attributedText
    }
    
    private func makeAttributedString(for text: String) -> NSMutableAttributedString?
    {
        let attributes: [NSAttributedString.Key : Any] =
        [
            .font: UIFont(name: "Helvetica", size: 17)!,
            .foregroundColor: UIColor.white,
            .paragraphStyle: {
                let paragraphStyle = NSMutableParagraphStyle()
                paragraphStyle.alignment = .left
                paragraphStyle.lineBreakMode = .byWordWrapping
                return paragraphStyle
            }()
        ]
        return NSMutableAttributedString(string: text, attributes: attributes)
    }
    
    /// - cleanup
    private func cleanupCellContent()
    {
        messageLabel.attributedText = nil
        timeStamp.text = nil
        messageSenderNameLabel?.removeFromSuperview()
        messageSenderNameLabel = nil
//        messageImage = nil
        messageImageView.image = nil
        messageSenderAvatar?.image = nil
        messageSenderAvatar = nil
        seenStatusMark.attributedText = nil
//        editedLabel.text = nil
        messageTitleLabel?.removeFromSuperview()
        messageTitleLabel = nil
//        replyMessageLabel.removeFromSuperview()
        reactionBadgeHostingView?.removeFromSuperview()
        reactionBadgeHostingView = nil
        
//        messageLabel.removeFromSuperview()
        
        applyMessagePadding(strategy: .initial)
        
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
        
        containerStackView.axis = .vertical
        containerStackView.spacing = 4
        containerStackView.layer.cornerRadius = 15
        containerStackView.alignment = .leading
        containerStackView.clipsToBounds = true
        containerStackView.translatesAutoresizingMaskIntoConstraints = false
        
        self.containerStackViewBottomConstraint = containerStackView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor)
        self.containerStackViewBottomConstraint.isActive = true
        containerStackView.topAnchor.constraint(equalTo: contentView.topAnchor).isActive = true
        containerStackView.widthAnchor.constraint(lessThanOrEqualToConstant: maxMessageWidth).isActive = true
        
        containerStackView.widthAnchor.constraint(greaterThanOrEqualToConstant: 80).isActive = true
    }
    
    private func setupMessageLabel()
    {
        containerStackView.addArrangedSubview(messageLabel)
        messageLabel.numberOfLines = 0
        messageLabel.preferredMaxLayoutWidth = maxMessageWidth
        messageLabel.contentMode = .redraw
        messageLabel.layer.cornerRadius = 15
        messageLabel.clipsToBounds = true
    }
    
    private func setupMessageComponentsStackView()
    {
//        self.messageLabel.addSubview(messageComponentsStackView)
        self.containerStackView.addSubview(messageComponentsStackView)
//        self.containerStackView.addSubview(messageComponentsStackView)
        
        messageComponentsStackView.addArrangedSubview(timeStamp)
        messageComponentsStackView.addArrangedSubview(seenStatusMark)
        
        messageComponentsStackView.axis = .horizontal
        messageComponentsStackView.alignment = .center
        messageComponentsStackView.distribution = .equalSpacing
        messageComponentsStackView.spacing = 3
        messageComponentsStackView.clipsToBounds = true
        messageComponentsStackView.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            messageComponentsStackView.trailingAnchor.constraint(equalTo: containerStackView.trailingAnchor, constant: -8),
            messageComponentsStackView.bottomAnchor.constraint(equalTo: containerStackView.bottomAnchor, constant: -5),
//            messageComponentsStackView.heightAnchor.constraint(equalToConstant: 14),
//            messageComponentsStackView.widthAnchor.
            
        ])
    }
    
    private func configureMessageSeenStatus()
    {
        guard let message = cellViewModel.message else {return}
//        if message.type == .text && message.messageBody == "" {return}
        
        let isSeen = message.messageSeen ?? (message.seenBy.count > 1)

        let iconSize = isSeen ? CGSize(width: 16, height: 11) : CGSize(width: 12, height: 13)
        
        let seenIconColor: UIColor = cellViewModel.message?.type == .image ? .white : ColorManager.messageSeenStatusIconColor
        let seenStatusIcon = isSeen ? SeenStatusIcon.double.rawValue : SeenStatusIcon.single.rawValue
        guard let seenStatusIconImage = UIImage(named: seenStatusIcon)?
            .withTintColor(seenIconColor)
            .resize(to: iconSize) else {return}
        
        let imageAttributedString = NSMutableAttributedString.yy_attachmentString(
            withContent: seenStatusIconImage,
            contentMode: .center,
            attachmentSize: seenStatusIconImage.size,
            alignTo: UIFont(name: "Helvetica", size: 14)!,
            alignment: .center)
        
        seenStatusMark.attributedText = imageAttributedString
    }
    
    
    private func updateEditedLabel()
    {
        if cellViewModel.message?.isEdited == true
        {
            editedLabel.text = "edited"
        } else {
            editedLabel.text = nil
        }
    }
    
    private func setupEditedLabel()
    {
        messageComponentsStackView.insertArrangedSubview(editedLabel, at: 0)
        editedLabel.font = UIFont(name: "Helvetica", size: 13)
    }
    
    private func setupTimestamp()
    {
        timeStamp.font = UIFont(name: "HelveticaNeue", size: 13)
    }
    
    private func updateStackViewAppearance()
    {
        let messageType = cellViewModel.message?.type
        if messageType == .image
        {
            messageComponentsStackView.backgroundColor = #colorLiteral(red: 0.121735774, green: 0.1175989285, blue: 0.1221210584, alpha: 1).withAlphaComponent(0.5)
            messageComponentsStackView.isLayoutMarginsRelativeArrangement = true
            messageComponentsStackView.layoutMargins = UIEdgeInsets(top: 3, left: 8, bottom: 3, right: 8)
            messageComponentsStackView.layer.cornerRadius = 12
        } else {
            messageComponentsStackView.backgroundColor = .clear
            messageComponentsStackView.isLayoutMarginsRelativeArrangement = false
            messageComponentsStackView.layoutMargins = .zero
            messageComponentsStackView.layer.cornerRadius = .zero
        }
        
        setupStackViewComponentsColor()
    }
    
    private func adjustMessageSide()
    {
        if containerStackViewLeadingConstraint != nil { containerStackViewLeadingConstraint.isActive = false }
        if containerStackViewTrailingConstraint != nil { containerStackViewTrailingConstraint.isActive = false }
        
        let leadingConstant = messageLayoutConfiguration.leadingConstraintConstant
        
        switch cellViewModel.messageAlignment {
        case .right:
            configureMessageSeenStatus()
            
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

// MARK: - message layout

extension MessageTableViewCell
{
    private func handleMessageLayout()
    {
        createMessageTextLayout()
        let padding = getMessagePaddingStrategy()
        applyMessagePadding(strategy: padding)
    }
    
    private func createMessageTextLayout()
    {
        let textLayout = YYTextLayout(containerSize: CGSize(width: messageLabel.intrinsicContentSize.width, height: messageLabel.intrinsicContentSize.height), text: messageLabel.attributedText!)
        messageLabel.textLayout = textLayout
        applyMessagePadding(strategy: .initial)
    }
    
    /// padding strategy
    ///
    private func getMessagePaddingStrategy() -> TextPaddingStrategy
    {
        let padding = (TextPaddingStrategy.initial.padding.left * 2) + 3.0
        let expectedLineWidth = self.messageLastLineTextWidth + self.messageComponentsWidth
        
        guard expectedLineWidth < (maxMessageWidth - padding) else {
            return .bottom
        }
        
        if expectedLineWidth > self.messageTextBoundingWidth
        {
            let difference = expectedLineWidth - self.messageTextBoundingWidth
            return .trailling(space: difference)
        }
        return .initial
    }
    
    private func applyMessagePadding(strategy paddingStrategy: TextPaddingStrategy)
    {
        messageLabel.textContainerInset = paddingStrategy.padding
        messageLabel.invalidateIntrinsicContentSize()
    }
    
    /// computed properties
    private var messageComponentsWidth: CGFloat
    {
        let sideWidth = cellViewModel.messageAlignment == .right ? seenStatusMark.intrinsicContentSize.width : 0.0
        return timeStamp.intrinsicContentSize.width + sideWidth + editedMessageWidth + 4.0
    }

    private var messageLastLineTextWidth: CGFloat {
        messageLabel.textLayout?.lines.last?.width ?? 0.0
    }

    private var messageTextBoundingWidth: CGFloat {
        return messageLabel.textLayout?.textBoundingRect.width ?? 0.0
    }
    
    private var editedMessageWidth: CGFloat {
        return editedLabel.intrinsicContentSize.width
    }
}

// MARK: - HANDLE IMAGE OF MESSAGE SETUP
extension MessageTableViewCell
{
    private func configureMessageImage(_ image: UIImage)
    {
        let newSize = cellViewModel.getCellAspectRatio(forImageSize: image.size)
        
        resizeImage(image, toSize: newSize)
        let imageAttachementAttributed = getAttributedImageAttachment(size: newSize)
        
        if let messageText = cellViewModel.message?.messageBody, !messageText.isEmpty
        {
            let newLine = "\n"
            let text = "\(newLine)\(messageText))"
            let combinedAttributedString = NSMutableAttributedString()
            combinedAttributedString.append(imageAttachementAttributed)
            guard let messageTextAttribute = messageTextLabelLinkSetup(from: text) else {return}
            combinedAttributedString.append(messageTextAttribute)
            self.messageLabel.attributedText = combinedAttributedString
            handleMessageLayout()
        } else {
            self.messageLabel.attributedText = imageAttachementAttributed
            applyMessagePadding(strategy: .image)
        }
    }

    private func resizeImage(_ image: UIImage, toSize size: CGSize)
    {
        guard let imagePath = cellViewModel.resizedMessageImagePath else {return}
        
        if let image = CacheManager.shared.getCachedImage(forKey: imagePath)
        {
            self.messageImageView.image = image
            return
        }
        
        DispatchQueue.global().async
        {
            guard let image = image.resize(to: size) else {return}
            
            CacheManager.shared.cacheImage(image: image, key: imagePath)
            
            DispatchQueue.main.async {
                self.messageImageView.image = image
            }
        }
    }
    
    private func getAttributedImageAttachment(size: CGSize) -> NSMutableAttributedString
    {
        let imageAttributedString = NSMutableAttributedString.yy_attachmentString(
            withContent: nil,
            contentMode: .center,
            attachmentSize: size,
            alignTo: UIFont(name: "Helvetica", size: 17)!,
            alignment: .center)
        
        return imageAttributedString
//        messageLabel.attributedText = combined
    }
    
    private func makeAttributedString2(for text: String) -> NSMutableAttributedString?
    {
        let attributes: [NSAttributedString.Key : Any] =
        [
            .font: UIFont(name: "Helvetica", size: 17)!,
            .foregroundColor: UIColor.white,
            .paragraphStyle: {
                let paragraphStyle = NSMutableParagraphStyle()
                paragraphStyle.alignment = .left
                paragraphStyle.lineBreakMode = .byWordWrapping
                return paragraphStyle
            }()
        ]
        return NSMutableAttributedString(string: text, attributes: attributes)
    }

    private func convertDataToImage(_ data: Data) -> UIImage? {
        guard let image = UIImage(data: data) else { return nil }
        return image
    }
}

//MARK: - Reply message setup
extension MessageTableViewCell
{
    private func createReplyMessageAttributedText(
        with senderName: String,
        messageText: String
    ) -> NSMutableAttributedString
    {
        let boldAttributeForName: [NSAttributedString.Key: Any] = [
            .font: UIFont.boldSystemFont(ofSize: 13),
            .foregroundColor: UIColor.white
        ]
        let boldAttributeForText: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 13),
            .foregroundColor: UIColor.white
        ]
        let attributedText = NSMutableAttributedString(string: senderName, attributes: boldAttributeForName)
        let replyMessageAttributedText = NSAttributedString(string: " \n\(messageText)", attributes: boldAttributeForText)
        attributedText.append(replyMessageAttributedText)
        
        return attributedText
    }
}

//MARK: - Message Label
class MessageLabel: YYLabel
{
    enum MessageUpdateType {
        case edited
        case replyRemoved
    }
    
    var messageUpdateType: MessageUpdateType?
    
    /// Override to prevent message label text streching or shrinking
    /// when label size changes
    
    override func action(for layer: CALayer, forKey event: String) -> CAAction?
    {
        if messageUpdateType == .edited
        {
            if event == "bounds" || event == "position" {
                return NSNull() // Disables implicit animations for these keys
            }
        }
        return super.action(for: layer, forKey: event)
    }
        
}

//MARK: reply stack view
extension MessageTableViewCell
{

    class ReplyMessageView: UIView {
        
        private let containerStackView: UIStackView = {
            let stackView = UIStackView()
            stackView.axis = .horizontal
            stackView.alignment = .top
            stackView.spacing = 8
            stackView.translatesAutoresizingMaskIntoConstraints = false
            return stackView
        }()
        
        private let imageView: UIImageView = {
            let imageView = UIImageView()
            imageView.contentMode = .scaleAspectFit
            imageView.translatesAutoresizingMaskIntoConstraints = false
            return imageView
        }()
        
        private let textContainerView: UIView = {
            let view = UIView()
            view.translatesAutoresizingMaskIntoConstraints = false
            return view
        }()
        
        private let textLabel: UILabel = {
            let label = UILabel()
            label.numberOfLines = 0
            label.translatesAutoresizingMaskIntoConstraints = false
            return label
        }()
        
        // Properties to match ReplyMessageLabel behavior
        private let textInset = UIEdgeInsets(top: 5, left: 10, bottom: 5, right: 8)
        var rectInset: UIEdgeInsets = .zero
        
        override init(frame: CGRect) {
            super.init(frame: frame)
            setupView()
        }
        
        required init?(coder: NSCoder) {
            super.init(coder: coder)
            setupView()
        }
        
        private func setupView() {
            addSubview(containerStackView)
            
            // Add image to stack view
            containerStackView.addArrangedSubview(imageView)
            
            // Add text container to stack view
            containerStackView.addArrangedSubview(textContainerView)
            textContainerView.addSubview(textLabel)
            
            NSLayoutConstraint.activate([
                // Container stack view constraints
                containerStackView.topAnchor.constraint(equalTo: topAnchor),
                containerStackView.leadingAnchor.constraint(equalTo: leadingAnchor),
                containerStackView.trailingAnchor.constraint(equalTo: trailingAnchor),
                containerStackView.bottomAnchor.constraint(equalTo: bottomAnchor),
                
                // Image size constraints
                imageView.widthAnchor.constraint(equalToConstant: 30),
                imageView.heightAnchor.constraint(equalToConstant: 30),
                
                // Text label constraints with insets (matching ReplyMessageLabel)
                textLabel.topAnchor.constraint(equalTo: textContainerView.topAnchor, constant: textInset.top),
                textLabel.leadingAnchor.constraint(equalTo: textContainerView.leadingAnchor, constant: textInset.left),
                textLabel.trailingAnchor.constraint(equalTo: textContainerView.trailingAnchor, constant: -textInset.right),
                textLabel.bottomAnchor.constraint(equalTo: textContainerView.bottomAnchor, constant: -textInset.bottom)
            ])
        }
        
        override func draw(_ rect: CGRect) {
            super.draw(rect)
            
            // Draw the white line on the left side (matching ReplyMessageLabel behavior)
            let lineWidth: CGFloat = 5
            let topRect = CGRect(
                x: 0,
                y: 0,
                width: lineWidth,
                height: self.bounds.height
            )
            UIColor.white.setFill()
            UIRectFill(topRect)
        }
        
        override var intrinsicContentSize: CGSize {
            let imageWidth: CGFloat = 30
            let spacing: CGFloat = 8
            let textIntrinsicSize = textLabel.intrinsicContentSize
            
            var contentSize = CGSize.zero
            
            // Width: image + spacing + text + insets
            contentSize.width = imageWidth + spacing + textIntrinsicSize.width + textInset.left + textInset.right
            
            // Height: max of image height and text height + insets
            let textHeight = textIntrinsicSize.height + textInset.top + textInset.bottom
            let imageHeight: CGFloat = 30
            contentSize.height = max(imageHeight, textHeight)
            
            // Compensate for alignment rect insets
            contentSize.height -= rectInset.top + rectInset.bottom
            contentSize.width -= rectInset.left + rectInset.right
            
            return contentSize
        }
        
        override var alignmentRectInsets: UIEdgeInsets {
            return rectInset
        }
        
        func configure(with senderName: String, messageText: String, image: UIImage? = nil) {
            // Set the image
            imageView.image = image ?? UIImage(systemName: "star.fill")
            
            // Create attributed text for name and message
            let attributedText = NSMutableAttributedString()
            
            // Add sender name
            let nameAttributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.boldSystemFont(ofSize: 13),
                .foregroundColor: UIColor.white
            ]
            attributedText.append(NSAttributedString(string: senderName, attributes: nameAttributes))
            
            // Add message text
            let messageAttributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 13),
                .foregroundColor: UIColor.white
            ]
            attributedText.append(NSAttributedString(string: "\n\(messageText)", attributes: messageAttributes))
            
            textLabel.attributedText = attributedText
            
            // Trigger layout update
            invalidateIntrinsicContentSize()
            setNeedsLayout()
        }
    }

    // Usage example:
    /*
    let replyView = ReplyMessageView()
    replyView.configure(with: "John Doe", messageText: "This is a reply message", image: yourImage)

    // Add to your view hierarchy
    parentView.addSubview(replyView)
    replyView.translatesAutoresizingMaskIntoConstraints = false
    NSLayoutConstraint.activate([
        replyView.leadingAnchor.constraint(equalTo: parentView.leadingAnchor),
        replyView.trailingAnchor.constraint(equalTo: parentView.trailingAnchor),
        replyView.topAnchor.constraint(equalTo: parentView.topAnchor)
    ])
    */
    final class ReplyStackView: UIStackView
    {
        private let textInset = UIEdgeInsets(top: 5, left: 10, bottom: 5, right: 8)
        var rectInset: UIEdgeInsets = .zero
        
        override var intrinsicContentSize: CGSize
        {
            var contentSize = super.intrinsicContentSize
            // Add text insets
            contentSize.height += textInset.top + textInset.bottom
            contentSize.width += textInset.left + textInset.right
            
            // Compensate for alignment rect insets (subtract negative values = add positive)
            contentSize.height -= rectInset.top + rectInset.bottom
            contentSize.width -= rectInset.left + rectInset.right
            
            return contentSize
        }
        
        override var alignmentRectInsets: UIEdgeInsets {
            return rectInset
        }
        
        
        override func draw(_ rect: CGRect) {
            super.draw(rect)
            self.fillColor(with: .white, width: 5)
        }
        
        private func fillColor(with color: UIColor, width: CGFloat) {
            let topRect = CGRect(
                x: 0,
                y: 0,
                width: width,
                height: self.bounds.height
            )
            color.setFill()
            UIRectFill(topRect)
        }
    }
}

//MARK: - Reply message label
extension MessageTableViewCell
{
    /// Customized reply message to simplify left side indentation color fill and text inset
    ///
    class ReplyMessageLabel: UILabel
    {
        let textInset = UIEdgeInsets(top: 5, left: 40, bottom: 5, right: 8)
        var rectInset: UIEdgeInsets = .zero
        
        override var intrinsicContentSize: CGSize
        {
            var contentSize = super.intrinsicContentSize
            // Add text insets
            contentSize.height += textInset.top + textInset.bottom
            contentSize.width += textInset.left + textInset.right
            
            // Compensate for alignment rect insets (subtract negative values = add positive)
            contentSize.height -= rectInset.top + rectInset.bottom
            contentSize.width -= rectInset.left + rectInset.right
            
            return contentSize
        }
        
        override func drawText(in rect: CGRect) {
            super.drawText(in: rect.inset(by: textInset))
        }
        
        override var alignmentRectInsets: UIEdgeInsets {
            return rectInset
        }
        
        override func draw(_ rect: CGRect) {
            super.draw(rect)
            self.fillColor(with: .white, width: 5)
        }
        
        private func fillColor(with color: UIColor, width: CGFloat) {
            let topRect = CGRect(
                x: 0,
                y: 0,
                width: width,
                height: self.bounds.height
            )
            color.setFill()
            UIRectFill(topRect)
        }
    }
}


//MARK: - message layout for group

extension MessageTableViewCell
{
    private func setupSenderNameLabel()
    {
        if messageSenderNameLabel == nil {
            messageSenderNameLabel = UILabel()
            messageContainer.addSubview(messageSenderNameLabel!)
        }
        
        messageSenderNameLabel?.text = cellViewModel.messageSender?.name
        messageSenderNameLabel?.font = UIFont.systemFont(ofSize: 15, weight: .medium)
        messageSenderNameLabel?.textColor = messageSenderNameColor
        messageSenderNameLabel?.numberOfLines = 1
        messageSenderNameLabel?.translatesAutoresizingMaskIntoConstraints = false
        setupSenderNameLabelConstraints()
    }
     
    private func setupSenderNameLabelConstraints()
    {
        guard let messageSenderNameLabel = messageSenderNameLabel else { return }
        
        messageSenderNameLabel.topAnchor.constraint(equalTo: messageContainer.topAnchor, constant: 5).isActive = true
        messageSenderNameLabel.leadingAnchor.constraint(equalTo: messageContainer.leadingAnchor, constant: 10).isActive = true
        messageSenderNameLabel.widthAnchor.constraint(lessThanOrEqualTo: messageContainer.widthAnchor, multiplier: 0.80).isActive = true
    }
    
    private func setupSenderAvatar()
    {
        if messageSenderAvatar == nil {
            messageSenderAvatar = UIImageView()
            messageContainer.addSubview(messageSenderAvatar!)
        }
        messageSenderAvatar?.layer.cornerRadius = (messageLayoutConfiguration.avatarSize?.width ?? 35) / 2
        messageSenderAvatar?.clipsToBounds = true
        messageSenderAvatar?.translatesAutoresizingMaskIntoConstraints = false
        setupSenderAvatarConstraints()
        
        //TODO: medium should be removed
        
//        if let imageData = cellViewModel.retrieveSenderAvatarData(ofSize: "medium") {
//            messageSenderAvatar?.image = UIImage(data: imageData)
//            return
//        }
//        
//        cellViewModel.fetchSenderAvatartImageData() //fetch medium size image
        
        if let imageData = cellViewModel.retrieveSenderAvatarData(ofSize: "small") {
            messageSenderAvatar?.image = UIImage(data: imageData)
        }
    }
    
    private func setupSenderAvatarConstraints()
    {
        guard let messageSenderAvatar = messageSenderAvatar,
              let avatarSize = messageLayoutConfiguration.avatarSize else {return}

        messageSenderAvatar.trailingAnchor.constraint(equalTo: messageContainer.leadingAnchor, constant: -8).isActive = true
        messageSenderAvatar.widthAnchor.constraint(equalToConstant: avatarSize.width).isActive = true
        messageSenderAvatar.heightAnchor.constraint(equalToConstant: avatarSize.height).isActive = true
        messageSenderAvatar.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -3).isActive = true
    }
    
    private func setContainerStackViewBottomConstraint()
    {
        let isReactionsEmpty = cellViewModel.message?.reactions.isEmpty
        self.containerStackViewBottomConstraint.constant = isReactionsEmpty ?? true ? -3 : -25
    }
}

//MARK: - conversation cell enums
extension MessageTableViewCell
{
    enum TextPaddingStrategy
    {
        case initial
        case bottom
        case trailling(space: CGFloat)
        case image
        
        var padding: UIEdgeInsets
        {
            switch self {
            case .image: return UIEdgeInsets(top: 2, left: 2, bottom: 2, right: 2)
            case .bottom: return UIEdgeInsets(top: 6, left: 10, bottom: 20, right: 10)
            case .initial: return UIEdgeInsets(top: 6, left: 10, bottom: 6, right: 10)
            case .trailling (let space): return UIEdgeInsets(top: 6, left: 10, bottom: 6, right: space + 10 + 3.0)
            }
        }
    }
}

enum SeenStatusIcon: String {
//    case single = "icons8-done-64-6"
    case single = "test-cropped-single-checkmark-2"
//    case double = "icons8-double-tick-48-3"
    case double = "test-cropped-double-checkmark"
}


struct MessageLayoutConfiguration {
    let shouldShowSenderName: Bool
    let shouldShowAvatar: Bool
    let avatarSize: CGSize?
    let leadingConstraintConstant: CGFloat
}

extension MessageLayoutConfiguration
{
    func withUpdatedAvatar(_ shouldShow: Bool) -> MessageLayoutConfiguration
    {
        return MessageLayoutConfiguration(shouldShowSenderName: shouldShowSenderName,
                                          shouldShowAvatar: shouldShow,
                                          avatarSize: avatarSize,
                                          leadingConstraintConstant: leadingConstraintConstant)
    }
    
    func withUpdatedSenderName(_ shouldShow: Bool) -> MessageLayoutConfiguration
    {
        return MessageLayoutConfiguration(shouldShowSenderName: shouldShow,
                                          shouldShowAvatar: shouldShowAvatar,
                                          avatarSize: avatarSize,
                                          leadingConstraintConstant: leadingConstraintConstant)
    }
    
}

enum ChatType
{
    case _private
    case _group
    
    var messageLayoutConfiguration: MessageLayoutConfiguration
    {
        switch self {
        case ._private:
            return MessageLayoutConfiguration(shouldShowSenderName: false,
                                              shouldShowAvatar: false,
                                              avatarSize: nil,
                                              leadingConstraintConstant: 10)
        case ._group:
            return MessageLayoutConfiguration(shouldShowSenderName: true,
                                              shouldShowAvatar: false, // Adjusted dynamically
                                              avatarSize: CGSize(width: 35, height: 35),
                                              leadingConstraintConstant: 52)
        }
    }
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

// MARK: Message edit animation
extension MessageTableViewCell
{
    private func testMessageTextEdit()
    {
        if messageLabel.attributedText?.string == "Pedro pascal Hi there Pedro pascal Hi there Pedro pascal Hi there Pedro pascal Hi there Pedro pascal with on this"
        {
            executeAfter(seconds: 3.0, block: {
                self.messageLabel.messageUpdateType = .edited
                self.messageLabel.attributedText = self.messageTextLabelLinkSetup(from: "Pedro pascal")

                self.handleMessageLayout()

                UIView.animate(withDuration: 0.3) {
                    self.contentView.layoutIfNeeded()
                }
                self.handleContentRelayout?()
            })
        }
    }
}
