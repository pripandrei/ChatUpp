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
        let imageView = FixedSizeImageView(size: CGSize(width: 40, height: 40))
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        return imageView
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
        addArrangedSubview(replyInnerStackView)
        
        // image should always fit
        imageView.setContentHuggingPriority(.required, for: .horizontal)
        imageView.setContentCompressionResistancePriority(.required, for: .horizontal)

        // Label should be flexible
//        messageLabel.setContentHuggingPriority(.defaultLow, for: .horizontal)
//        messageLabel.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
    }
    
    func configure(senderName: String,
                   messageText: String,
                   imageData: Data? = nil)
    {
        replyInnerStackView.senderLabel.text = senderName
        replyInnerStackView.messageLabel.text = messageText

        if let imageData
        {
            imageView.image = UIImage(data: imageData)
            replyInnerStackView.contentStack.insertArrangedSubview(imageView, at: 0)
        } else {
            imageView.image = nil
            replyInnerStackView.contentStack.removeArrangedSubview(imageView)
            imageView.removeFromSuperview()
        }
    }
    
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
        let colorBarWidth: CGFloat = 5
        
        let contentStack: UIStackView = {
            let contentStack = UIStackView()
            contentStack.axis = .horizontal
            contentStack.spacing = 6
            contentStack.alignment = .top
            return contentStack
        }()
        
        let labelsStack: UIStackView = {
            let labelsStack = UIStackView()
            labelsStack.axis = .vertical
            labelsStack.spacing = 2
            return labelsStack
        }()

        let senderLabel: UILabel = {
            let label = UILabel()
            label.font = .systemFont(ofSize: 15, weight: .bold)
            label.textColor = .white
            label.numberOfLines = 1
            label.lineBreakMode = .byTruncatingTail
            return label
        }()
        
        let messageLabel: UILabel = {
            let label = UILabel()
            label.font = .systemFont(ofSize: 15, weight: .medium)
            label.textColor = .white
            label.numberOfLines = 1
            label.lineBreakMode = .byTruncatingTail
            return label
        }()

        var rectFillColor: UIColor = .white
        {
            didSet {
                senderLabel.textColor = rectFillColor.adjust(by: 0.2)
                setNeedsDisplay()
            }
        }

        override func draw(_ rect: CGRect) {
            rectFillColor.setFill()
            UIRectFill(CGRect(x: 0, y: 0, width: colorBarWidth, height: bounds.height))
        }

        override init(frame: CGRect) {
            super.init(frame: frame)

            axis = .horizontal
            clipsToBounds = true
            layer.cornerRadius = 4
            spacing = 6
            isLayoutMarginsRelativeArrangement = true
            layoutMargins = UIEdgeInsets(top: 5, left: 10, bottom: 5, right: 5)
         
            labelsStack.addArrangedSubview(senderLabel)
            labelsStack.addArrangedSubview(messageLabel)
            contentStack.addArrangedSubview(labelsStack)

            addArrangedSubview(contentStack)
        }

        required init(coder: NSCoder) { fatalError() }
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
//
//extension ReplyToMessageStackView
//{
//    func createReplyMessageAttributedText(
//        with senderName: String,
//        messageText: String
//    ) -> NSMutableAttributedString
//    {
//        let boldAttributeForName: [NSAttributedString.Key: Any] = [
//            .font: UIFont.boldSystemFont(ofSize: 13),
//            .foregroundColor: UIColor.white
//        ]
//        let boldAttributeForText: [NSAttributedString.Key: Any] = [
//            .font: UIFont.systemFont(ofSize: 13),
//            .foregroundColor: UIColor.white
//        ]
//        let attributedText = NSMutableAttributedString(string: senderName, attributes: boldAttributeForName)
//        let replyMessageAttributedText = NSAttributedString(string: " \n\(messageText)", attributes: boldAttributeForText)
//        attributedText.append(replyMessageAttributedText)
//        
//        return attributedText
//    }
//}
//



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

