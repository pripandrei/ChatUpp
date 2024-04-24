//
//  CustomCollectionViewCell.swift
//  ChatUpp
//
//  Created by Andrei Pripa on 10/11/23.
//

import UIKit
import YYText
//import ImageIO
//import AVFoundation

protocol MenuIdentifiable {
    var indexPath: IndexPath {get}
}

extension Array where Element: MenuIdentifiable {
    
}

final class ConversationTableViewCell: UITableViewCell {
    
    enum BubbleMessageSide {
        case left
        case right
    }
    private enum BubbleMessagePadding {
        case initialSpacing
        case incomingMessageRightSpace
        case outgoingMessageRightSapce
        case bottomSpace
        case imageSpace
    }
    
    private enum SeenStatusIcon: String {
        case single = "icons8-done-64-6"
        case double = "icons8-double-tick-48-3"
    }
    
    private var mainCellContainerMaxWidthConstraint: NSLayoutConstraint!
    private var messageContainerLeadingConstraint: NSLayoutConstraint!
    private var messageContainerTrailingConstraint: NSLayoutConstraint!
    
    var mainCellContainer = UIView()
    var messageContainer = YYLabel()
    private var timeStamp = YYLabel()
    var sennStatusMark = YYLabel()
    private var messageImage: UIImage?
    var editedLabel: UILabel?
    var cellViewModel: ConversationCellViewModel!
//    var contextMenuInteraction: MessageContextMenuInteractionHandler!
    
    private var maxMessageWidth: CGFloat {
        return 290.0
    }
    private let cellSpacing = 3.0
    
    private func makeAttributedStringForMessage() -> NSAttributedString {
        return NSAttributedString(string: cellViewModel.cellMessage.messageBody, attributes: [
            .font: UIFont(name: "Helvetica", size: 17)!,
            .foregroundColor: UIColor.white,
            .paragraphStyle: {
                let paragraphStyle = NSMutableParagraphStyle()
                paragraphStyle.alignment = .left
                paragraphStyle.lineBreakMode = .byWordWrapping
                return paragraphStyle
            }()
        ])
    }
    
  
    
    //MARK: - LIFECYCLE
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)

        // Invert cell upside down
        transform = CGAffineTransform(scaleX: 1, y: -1)
        
        backgroundColor = #colorLiteral(red: 0.1411764771, green: 0.3960784376, blue: 0.5647059083, alpha: 1)
//        setupContentViewConstraints()
        setupBackgroundSelectionView()
        setupMainCellContainer()
        setupMessageTextLabel()
        setupSeenStatusMark()
        setupTimestamp()
//        setupEditedLabel()
//        contextMenuInteraction = MessageContextMenuInteractionHandler(message: messageContainer)
    }
    
    // implement for proper cell selection highlight when using UIMenuContextConfiguration on tableView
    private func setupBackgroundSelectionView() {
        let selectedView = UIView()
        selectedView.backgroundColor = UIColor.clear
        selectedBackgroundView = selectedView
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    //MARK: - BINDER
    private func setupBinding() {
        cellViewModel.imageData.bind { [weak self] data in
            if data == self?.cellViewModel.imageData.value {
                DispatchQueue.main.async {
                    self?.configureImageAttachment(data: data)
                }
            }
        }
        cellViewModel.isMessageEdited.bind { isEdited in
            if isEdited {
                self.setupEditedLabel()
            }
        }
    }

    //MARK: - CELL PREPARE CLEANUP
    private func cleanupCellContent() {
        messageContainer.attributedText = nil
        timeStamp.text = nil
        timeStamp.backgroundColor = .clear
        messageImage = nil
        sennStatusMark.attributedText = nil
        timeStamp.textContainerInset = .zero
//        editedLabel = nil
        editedLabel?.text = nil
        adjustMessagePadding(.initialSpacing)
        
        // Layout with no animation to hide resizing animation of cells on keyboard show/hide
        // or any other table view content offset change
        UIView.performWithoutAnimation {
            self.contentView.layoutIfNeeded()
        }
    }
    
    //MARK: - CELL DATA CONFIGURATION
    func configureCell(usingViewModel viewModel: ConversationCellViewModel, forSide side: BubbleMessageSide) {
        
        cleanupCellContent()
        
        self.cellViewModel = viewModel
        setupEditedLabel()
        timeStamp.text = viewModel.timestamp
        setupBinding()
        adjustMessageSide(side)

        if viewModel.cellMessage.messageBody != "" {
            messageContainer.attributedText = makeAttributedStringForMessage()
            handleMessageBubbleLayout(forSide: side)
            return
        }
        configureImageAttachment(data: viewModel.imageData.value)
    }
    
    func configureMessageSeenStatus() {
        let iconSize = cellViewModel.cellMessage.messageSeen ? CGSize(width: 15, height: 14) : CGSize(width: 16, height: 12)
        let seenStatusIcon = cellViewModel.cellMessage.messageSeen ? SeenStatusIcon.double.rawValue : SeenStatusIcon.single.rawValue
        guard let seenStatusIconImage = UIImage(named: seenStatusIcon)?.resize(to: iconSize) else {return}

        let imageAttributedString = NSMutableAttributedString.yy_attachmentString(withContent: seenStatusIconImage, contentMode: .center, attachmentSize: seenStatusIconImage.size, alignTo: UIFont(name: "Helvetica", size: 4)!, alignment: .center)
      
        sennStatusMark.attributedText = imageAttributedString
    }
    
// MARK: - UI INITIAL STEUP
    
    private func setupEditedLabel() {
        if cellViewModel.isMessageEdited.value {
            editedLabel = UILabel()
            guard let editedLabel = editedLabel else {return}
            
            messageContainer.addSubviews(editedLabel)
            
            editedLabel.font = UIFont(name: "TimesNewRomanPSMT", size: 13)
            editedLabel.text = "edited"
    //        editedLabel.layer.cornerRadius = 7
    //        editedLabel.clipsToBounds = true
            editedLabel.textColor = #colorLiteral(red: 0.74693048, green: 0.7898075581, blue: 1, alpha: 1)
    //        editedLabel.isHidden = true
            
            editedLabel.translatesAutoresizingMaskIntoConstraints = false
            
            NSLayoutConstraint.activate([
                editedLabel.trailingAnchor.constraint(equalTo: timeStamp.leadingAnchor, constant: -2),
                editedLabel.bottomAnchor.constraint(equalTo: messageContainer.bottomAnchor, constant: -5)
            ])
        }
    }
    
    private func setupSeenStatusMark() {
        messageContainer.addSubview(sennStatusMark)
        
        sennStatusMark.font = UIFont(name: "Helvetica", size: 4)
        sennStatusMark.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            sennStatusMark.trailingAnchor.constraint(equalTo: messageContainer.trailingAnchor, constant: -8),
            sennStatusMark.bottomAnchor.constraint(equalTo: messageContainer.bottomAnchor, constant: -5)
        ])
    }
    
    private func setupTimestamp() {
        messageContainer.addSubview(timeStamp)
        
        timeStamp.font = UIFont(name: "TimesNewRomanPSMT", size: 13)
        timeStamp.layer.cornerRadius = 7
        timeStamp.clipsToBounds = true
        timeStamp.textColor = #colorLiteral(red: 0.74693048, green: 0.7898075581, blue: 1, alpha: 1)
        timeStamp.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            timeStamp.trailingAnchor.constraint(equalTo: sennStatusMark.leadingAnchor, constant: -2),
            timeStamp.bottomAnchor.constraint(equalTo: messageContainer.bottomAnchor, constant: -5)
        ])
    }
    
    private func setupTimestampBackgroundForImage() {
        timeStamp.backgroundColor = .darkGray.withAlphaComponent(0.6)
        timeStamp.textContainerInset = UIEdgeInsets(top: 2, left: 6, bottom: 2, right: 6)
    }
    
    private func setupMainCellContainer() {
        contentView.addSubview(mainCellContainer)
        mainCellContainer.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            mainCellContainer.topAnchor.constraint(equalTo: contentView.topAnchor),
            mainCellContainer.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
            mainCellContainer.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            mainCellContainer.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
        ])
    }
    
    private func setupMessageTextLabel() {
        mainCellContainer.addSubview(messageContainer)

        //TODO: - review implementing a main container for message,timestamp,seenstatus
        
        messageContainer.backgroundColor = .blue
        messageContainer.numberOfLines = 0
        messageContainer.preferredMaxLayoutWidth = maxMessageWidth
        messageContainer.contentMode = .redraw
        messageContainer.layer.cornerRadius = 15
        messageContainer.clipsToBounds = true
        
        messageContainer.translatesAutoresizingMaskIntoConstraints = false
//        widthConstraint = messageContainer.widthAnchor.constraint(equalToConstant: maxMessageWidth)

        NSLayoutConstraint.activate([
//            widthConstraint,
            messageContainer.topAnchor.constraint(equalTo: mainCellContainer.topAnchor),
            messageContainer.bottomAnchor.constraint(equalTo: mainCellContainer.bottomAnchor, constant: -cellSpacing),
//            messageContainer.widthAnchor.constraint(lessThanOrEqualToConstant: maxMessageWidth)
        ])
    }
    
    private func setupContentViewConstraints() {
        contentView.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
           contentView.leadingAnchor.constraint(equalTo: leadingAnchor),
           contentView.trailingAnchor.constraint(equalTo: trailingAnchor),
           contentView.topAnchor.constraint(equalTo: topAnchor),
           contentView.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])
    }
}

// MARK: - MESSAGE BUBBLE LAYOUT HANDLER
extension ConversationTableViewCell
{
    func handleMessageBubbleLayout(forSide side: BubbleMessageSide) {
        createMessageTextLayout()
    
        guard let lastLineMessageWidth = getMessageLastLineSize() else {return}
        guard let numberOfMessageLines = messageContainer.textLayout?.lines.count else {return}
        
        let padding: CGFloat = 20.0
        let timestampWidth: CGFloat = timeStamp.intrinsicContentSize.width
        let seenStatusMarkWidth: CGFloat = 24.0
        
        let widthForSide = side == .right ? seenStatusMarkWidth : 0
        
        var lastLineMessageAndTimestampWidth = (lastLineMessageWidth + timestampWidth + widthForSide) + padding + editedMessageWidth()
        let messageRectWidth = messageContainer.intrinsicContentSize.width
        
        if lastLineMessageAndTimestampWidth > maxMessageWidth  {
            adjustMessagePadding(.bottomSpace)
            return
        }
        if lastLineMessageAndTimestampWidth <= maxMessageWidth {
            if numberOfMessageLines == 1 {
                side == .right ? adjustMessagePadding(.incomingMessageRightSpace) : adjustMessagePadding(.outgoingMessageRightSapce)
            } else if lastLineMessageAndTimestampWidth > messageRectWidth {
                let difference = lastLineMessageAndTimestampWidth - messageRectWidth
                messageContainer.textContainerInset.right = difference + padding / 2
            }
        }
    }
    
    func createMessageTextLayout() {
        let textLayout = YYTextLayout(containerSize: CGSize(width: messageContainer.intrinsicContentSize.width, height: messageContainer.intrinsicContentSize.height), text: messageContainer.attributedText!)
        messageContainer.textLayout = textLayout
        adjustMessagePadding(.initialSpacing)
    }
    
    func getMessageLastLineSize() -> CGFloat? {
        if let lastLine = messageContainer.textLayout?.lines.last {
            return lastLine.lineWidth
        }
        return nil
    }
    
    // MARK: - MESSAGE BUBBLE CONSTRAINTS
    func adjustMessageSide(_ side: BubbleMessageSide) {
        if messageContainerLeadingConstraint != nil { messageContainerLeadingConstraint.isActive = false }
        if messageContainerTrailingConstraint != nil { messageContainerTrailingConstraint.isActive = false }

        switch side {
        case .right:
            configureMessageSeenStatus()
            
            messageContainerLeadingConstraint = messageContainer.leadingAnchor.constraint(greaterThanOrEqualTo: mainCellContainer.leadingAnchor)
            messageContainerTrailingConstraint = messageContainer.trailingAnchor.constraint(equalTo: mainCellContainer.trailingAnchor, constant: -10)
            messageContainerLeadingConstraint.isActive = true
            messageContainerTrailingConstraint.isActive = true
            messageContainer.backgroundColor = #colorLiteral(red: 0.7171613574, green: 0.4463854432, blue: 0.351280123, alpha: 1)
        case .left:
            messageContainerLeadingConstraint = messageContainer.leadingAnchor.constraint(equalTo: mainCellContainer.leadingAnchor, constant: 10)
            messageContainerTrailingConstraint = messageContainer.trailingAnchor.constraint(lessThanOrEqualTo: mainCellContainer.trailingAnchor)
            messageContainerLeadingConstraint.isActive = true
            messageContainerTrailingConstraint.isActive = true
            messageContainer.backgroundColor = #colorLiteral(red: 0, green: 0.6150025129, blue: 0.6871898174, alpha: 1)
        }
    }
    // MARK: - MESSAGE BUBBLE PADDING
    private func adjustMessagePadding(_ messagePadding: BubbleMessagePadding) {
        switch messagePadding {
        case .initialSpacing: messageContainer.textContainerInset = UIEdgeInsets(top: 6, left: 10, bottom: 6, right: 10)
        case .incomingMessageRightSpace: messageContainer.textContainerInset = UIEdgeInsets(top: 6, left: 10, bottom: 6, right: timeStamp.intrinsicContentSize.width + sennStatusMark.intrinsicContentSize.width + 15 + editedMessageWidth())
        case .outgoingMessageRightSapce: messageContainer.textContainerInset = UIEdgeInsets(top: 6, left: 10, bottom: 6, right: timeStamp.intrinsicContentSize.width + 15 + editedMessageWidth())
        case .bottomSpace: messageContainer.textContainerInset = UIEdgeInsets(top: 6, left: 10, bottom: 20, right: 10)
        case .imageSpace: messageContainer.textContainerInset = UIEdgeInsets(top: 2, left: 2, bottom: 2, right: 2)
        }
        messageContainer.invalidateIntrinsicContentSize()
    }
    
    private func editedMessageWidth() -> Double {
        guard let editedLabel = editedLabel else {return 0}
        return editedLabel.intrinsicContentSize.width
    }
}

// MARK: - HANDLE IMAGE OF MESSAGE SETUP
extension ConversationTableViewCell {
    
    private func configureImageAttachment(data: Data?) {
        if let imageData = data, let image = convertDataToImage(imageData) {
            messageImage = image
        } else {
            messageImage = UIImage()
            cellViewModel.fetchImageData()
        }
        if let cellImageSize = cellViewModel.cellMessage.imageSize {
            let cgSize = CGSize(width: cellImageSize.width, height: cellImageSize.height)
            let testSize = cellViewModel.getCellAspectRatio(forImageSize: cgSize)
            messageImage = messageImage?.resize(to: CGSize(width: testSize.width, height: testSize.height)).roundedCornerImage(with: 12)
        }
        let imageAttributedString = NSMutableAttributedString.yy_attachmentString(withContent: messageImage, contentMode: .center, attachmentSize: messageImage!.size, alignTo: UIFont(name: "Helvetica", size: 17)!, alignment: .center)
        
        messageContainer.attributedText = imageAttributedString
        setupTimestampBackgroundForImage()
        adjustMessagePadding(.imageSpace)
    }
    
    private func convertDataToImage(_ data: Data) -> UIImage? {
        guard let image = UIImage(data: data) else { return nil }
        return image
    }
}
// NOT IN USE
//MARK:- CONTEXT MENU CONFIGURATION DELEGATE CLASS
final class MessageContextMenuInteractionHandler: NSObject, UIContextMenuInteractionDelegate {
    
    private var messageYYLabel: YYLabel!
    
    init(message: YYLabel) {
        self.messageYYLabel = message
        super.init()
        setupContextMenuInteraction()
    }

    func contextMenuInteraction(_ interaction: UIContextMenuInteraction, configuration: UIContextMenuConfiguration, highlightPreviewForItemWithIdentifier identifier: NSCopying) -> UITargetedPreview? {
        let parameter = UIPreviewParameters()
        parameter.backgroundColor = .clear
        
        let preview = UITargetedPreview(view: messageYYLabel, parameters: parameter)
        return preview
    }
    
    func contextMenuInteraction(_ interaction: UIContextMenuInteraction, configurationForMenuAtLocation location: CGPoint) -> UIContextMenuConfiguration? {
        let contextMenuConfiguration = UIContextMenuConfiguration(identifier: nil, previewProvider: nil, actionProvider: { suggestedAction in
            let copyAction = UIAction(title: "Copy", image: UIImage(systemName: "doc.on.doc")) { action in
                let pastBoard = UIPasteboard.general
                pastBoard.string = self.messageYYLabel.text
            }
            let editAction = UIAction(title: "Edit", image: UIImage(systemName: "pencil.and.scribble")) { action in
                print("delete")
            }
            let deleteAction = UIAction(title: "Delete", image: UIImage(systemName: "trash"), attributes: .destructive) { action in
                print("delete")
            }
            return UIMenu(title: "", children: [editAction, copyAction, deleteAction])
        })
        return contextMenuConfiguration
    }
    
    private func setupContextMenuInteraction() {
        let contextMenuInteraction = UIContextMenuInteraction(delegate: self)
        messageYYLabel.addInteraction(contextMenuInteraction)
    }
}
