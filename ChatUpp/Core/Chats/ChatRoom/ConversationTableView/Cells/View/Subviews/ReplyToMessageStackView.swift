//
//  ReplyToMessageStackView.swift
//  ChatUpp
//
//  Created by Andrei Pripa on 8/10/25.
//

import UIKit
import YYText

//MARK: Stack view that presents message which was replied to
//
final class ReplyToMessageStackView: UIStackView
{
    private var replyInnerStackView: ReplyInnerStackView = ReplyInnerStackView()
    
    lazy var imageView: FixedSizeImageView = {
        let imageView = FixedSizeImageView(size: CGSize(width: 30, height: 30))
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        return imageView
    }()
    
//    private let senderLabel: UILabel = {
//        let label = UILabel()
//        label.numberOfLines = 1
//        label.lineBreakMode = .byTruncatingTail
//        label.font = .boldSystemFont(ofSize: 13)
//        label.textColor = .white
//        return label
//    }()
//    
//    private let messageTextLabel: UILabel = {
//        let label = UILabel()
//        label.numberOfLines = 1
//        label.lineBreakMode = .byTruncatingTail
//        label.font = .systemFont(ofSize: 13)
//        label.textColor = .white
//        return label
//    }()
    
    private let messageLabel: YYLabel = {
        let label = YYLabel()
        label.numberOfLines = 2
//        label.preferredMaxLayoutWidth = 120
//        label.lineBreakStrategy = .hangulWordPriority
        
//        label.lineBreakMode = .byTruncatingTail
        label.clipsToBounds = true
        return label
    }()
      
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupSelf()
    }
    
    convenience init(margin: UIEdgeInsets)
    {
        self.init(frame: .zero)
        setupSelf(margins: margin)
    }
    
    required init(coder: NSCoder) { fatalError() }
    
    private func setupSelf(margins: UIEdgeInsets = .zero)
    {
        axis = .vertical
        spacing = 5
        isLayoutMarginsRelativeArrangement = true
        layoutMargins = margins
        replyInnerStackView.addArrangedSubview(messageLabel)
//        replyInnerStackView.addArrangedSubview(senderLabel)
//        replyInnerStackView.addArrangedSubview(messageTextLabel)
        addArrangedSubview(replyInnerStackView)
        
        // image should always fit
        imageView.setContentHuggingPriority(.required, for: .horizontal)
        imageView.setContentCompressionResistancePriority(.required, for: .horizontal)

        // Label should be flexible
//        messageLabel.setContentHuggingPriority(.defaultLow, for: .horizontal)
//        messageLabel.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
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
//    
//    func configure(senderName: String, messageText: String, imageData: Data?)
//    {
//        senderLabel.text = senderName
//        messageTextLabel.text = messageText
//
//        if let imageData {
//            imageView.image = UIImage(data: imageData)
//            replyInnerStackView.insertArrangedSubview(imageView, at: 0)
//        } else {
//            imageView.image = nil
//            replyInnerStackView.removeArrangedSubview(imageView)
//            imageView.removeFromSuperview()
//        }
//    }
    
    func setReplyInnerStackColors(background: UIColor, barColor: UIColor)
    {
        replyInnerStackView.backgroundColor = background
        replyInnerStackView.rectFillColor = barColor
    }
}

//MARK: - Inner stack view
extension ReplyToMessageStackView
{
    class ReplyInnerStackView: UIStackView
    {
        var _rectFillColor: UIColor = .white
        var rectFillColor: UIColor = .white
        {
            didSet {
                _rectFillColor = rectFillColor
                setNeedsDisplay()
            }
        }
        
        override func draw(_ rect: CGRect)
        {
            _rectFillColor.setFill()
            let rect = CGRect(x: 0, y: 0, width: 5, height: bounds.height)
            UIRectFill(rect)
        }

        override init(frame: CGRect)
        {
            super.init(frame: frame)
            
            backgroundColor = ColorManager.outgoingReplyToMessageBackgroundColor
            axis = .horizontal
            clipsToBounds = true
            layer.cornerRadius = 4
            spacing = 6
            isLayoutMarginsRelativeArrangement = true
            layoutMargins = UIEdgeInsets(top: 5, left: 10, bottom: 5, right: 5)
        }
        
        required init(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
    }
}

//MARK: - Custom image view that handles its own intrinsic sizing
extension ReplyToMessageStackView
{
    class FixedSizeImageView: UIImageView
    {
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
        
//        let paragraph = NSMutableParagraphStyle()
//        paragraph.lineBreakMode = .byTruncatingTail
        
        let boldAttributeForName: [NSAttributedString.Key: Any] = [
            .font: UIFont.boldSystemFont(ofSize: 13),
            .foregroundColor: UIColor.white,
//            .paragraphStyle: paragraph
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
