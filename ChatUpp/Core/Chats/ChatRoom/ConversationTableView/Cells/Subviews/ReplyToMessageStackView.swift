//
//  ReplyToMessageStackView.swift
//  ChatUpp
//
//  Created by Andrei Pripa on 8/10/25.
//

import UIKit


//MARK: Stack view that presents message which was replied to

final class ReplyToMessageStackView: UIStackView
{
    // Custom image view that handles its own intrinsic sizing
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


/// NOT IN USE CURRENTLY
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

extension ReplyMessageLabel
{
    func createReplyMessageAttributedText(
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

extension ReplyToMessageStackView
{
    func createReplyMessageAttributedText(
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
