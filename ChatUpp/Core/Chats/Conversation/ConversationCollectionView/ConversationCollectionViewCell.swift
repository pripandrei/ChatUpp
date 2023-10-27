//
//  CustomCollectionViewCell.swift
//  ChatUpp
//
//  Created by Andrei Pripa on 10/11/23.
//

import UIKit

final class ConversationCollectionViewCell: UICollectionViewCell {
    
    let messageBody = PaddingLabel()
    private let leadingEdgeSpacing: CGFloat = 90.0
    private let cellContainerView = UIView()
    private let timeStamp = UILabel()
    
    private var cellContainerMaxWidthConstraint: NSLayoutConstraint!
//    private var messageTrailingConstraint: NSLayoutConstraint!
    private lazy var messageTrailingToTimestampConstraint = NSLayoutConstraint(item: messageBody,
                                                                           attribute: .trailing,
                                                                           relatedBy: .equal,
                                                                           toItem: timeStamp,
                                                                           attribute: .leading,
                                                                           multiplier: 1.0,
                                                                           constant: 0.0)
    
    var customViewMaxWidth: CGFloat? {
        didSet {
            guard let maxWidth = customViewMaxWidth else {return }
            cellContainerMaxWidthConstraint = cellContainerView.widthAnchor.constraint(lessThanOrEqualToConstant: maxWidth - leadingEdgeSpacing)
            cellContainerMaxWidthConstraint.isActive = true
        }
    }
    
    //MARK: - LIFECYCLE
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        //        backgroundColor = .lightGray
        setupContentViewConstraints()
        setupcellContainerView()
        setupMessageUI()
        setupTimestampLabel()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    //MARK: - SETUP UI
    
    private func setupTimestampLabel() {
        cellContainerView.addSubview(timeStamp)
        
        timeStamp.text = "21:45"
        timeStamp.textColor = #colorLiteral(red: 0.3529850841, green: 0.2052503526, blue: 0.187323451, alpha: 1)
        timeStamp.backgroundColor = .orange
        timeStamp.font = UIFont(name: "Helvetica", size: 13)
        timeStamp.sizeToFit()
        
        setupTimestampConstraints()
    }

    
    private func setupcellContainerView() {
        contentView.addSubview(cellContainerView)
        
        cellContainerView.backgroundColor = .green
//        cellContainerView.layer.cornerRadius = 15
//        cellContainerView.clipsToBounds = true
        
        setupCellContainerViewConstraints()
    }
    
    private func setupMessageUI() {
        cellContainerView.addSubview(messageBody)
        
        messageBody.backgroundColor = #colorLiteral(red: 0.6470323801, green: 0.3927372098, blue: 0.3783177137, alpha: 1)
        messageBody.textAlignment = .left
        messageBody.textColor = .white
        messageBody.font = UIFont(name: "TimesNewRoman", size: 18)
//        messageBody.setContentCompressionResistancePriority(.required, for: .vertical)

        messageBody.numberOfLines = 0
//        messageBody.adjustsFontSizeToFitWidth = true
//        messageBody.lineBreakMode = .byWordWrapping
        messageBody.sizeToFit()
//        messageBody.contentMode = .left
        setupMessageConstraints()
    }
    
    private func setupTimestampConstraints() {
        timeStamp.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
//            timeStamp.heightAnchor.constraint(equalToConstant: 20),
//            timeStamp.widthAnchor.constraint(equalToConstant: 35),
            timeStamp.bottomAnchor.constraint(equalTo: cellContainerView.bottomAnchor),
            timeStamp.trailingAnchor.constraint(equalTo: cellContainerView.trailingAnchor),
        ])
    }
    
    private func setupCellContainerViewConstraints() {
        cellContainerView.translatesAutoresizingMaskIntoConstraints = false
    
        NSLayoutConstraint.activate([
            cellContainerView.topAnchor.constraint(equalTo: contentView.topAnchor),
            cellContainerView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
            cellContainerView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -10),
            cellContainerView.leadingAnchor.constraint(greaterThanOrEqualTo: contentView.leadingAnchor),
        ])
    }
    
    private func setupMessageConstraints() {
        messageBody.translatesAutoresizingMaskIntoConstraints = false
        
//        messageTrailingConstraint = messageBody.trailingAnchor.constraint(equalTo: timeStamp.trailingAnchor)
//        messageTrailingConstraint = messageBody.trailingAnchor.constraint(equalTo: cellContainerView.trailingAnchor)
//        messageTrailingConstraint.isActive = true
        NSLayoutConstraint.activate([
            messageBody.trailingAnchor.constraint(equalTo: cellContainerView.trailingAnchor),
            messageBody.topAnchor.constraint(equalTo: cellContainerView.topAnchor),
            messageBody.bottomAnchor.constraint(equalTo: cellContainerView.bottomAnchor),
            messageBody.leadingAnchor.constraint(greaterThanOrEqualTo: cellContainerView.leadingAnchor),
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
    
    //MARK: - Message layout

    func handleMessageBubbleLayout() {
//
        messageBody.padding.right = 10
        messageBody.padding.bottom = 10
        self.layoutIfNeeded()

        let lastLineString = getMessageLastLine(for: messageBody.text!, in: messageBody)
        let lastLineWidth = lastLineString.getSize().width
        let lastLineWithTimestempWidth = lastLineWidth + timeStamp.bounds.width
        let messageRectWidth = messageBody.textBoundingRect.width
        
        if lastLineWithTimestempWidth > messageRectWidth {
            if lastLineWithTimestempWidth.rounded(.up) < cellContainerMaxWidthConstraint.constant  {
                messageBody.padding.right = timeStamp.bounds.width + 5
               
            } else if lastLineWithTimestempWidth.rounded(.up) > cellContainerMaxWidthConstraint.constant {
                self.messageBody.padding.bottom = 20
            }
        }
    }
    
    private func getMessageLastLine(for text: String, in label: UILabel) -> String {
        let adjustedLabelSize = CGRect(x: 0, y: 0, width: label.intrinsicContentSize.width, height: label.intrinsicContentSize.height + 10)
        
        let attributedText = NSAttributedString(string: text, attributes: [.font: label.font!])
        let framesetter = CTFramesetterCreateWithAttributedString(attributedText)
        
        let path = CGMutablePath()
        path.addRect(adjustedLabelSize)
        
        let frame = CTFramesetterCreateFrame(framesetter, CFRange(location: 0, length: 0), path, nil)
        let lines = CTFrameGetLines(frame) as! [CTLine]
        
        guard let lastLine = lines.last else {return ""}
        
        let range = CTLineGetStringRange(lastLine)
        let start = text.index(text.startIndex, offsetBy: range.location)
        let end = text.index(start, offsetBy: range.length)
        let lineText = String(text[start..<end])
        
        
//        if text == "resources from abuse, such as billing" {
//            print(lineText)
//        }
        return lineText
    }
}


final class PaddingLabel: UILabel {
    
    var padding = UIEdgeInsets(top: 10, left: 10, bottom: 10, right: 10) {didSet { invalidateIntrinsicContentSize() }}
    
    override var intrinsicContentSize: CGSize {
        var contentSize = super.intrinsicContentSize
        contentSize.width += padding.left + padding.right
        contentSize.height += padding.top + padding.bottom
        return contentSize
    }
    
    override func drawText(in rect: CGRect) {
        let paddedRect = rect.inset(by: padding)
        super.drawText(in: paddedRect)
    }
    
    override func textRect(forBounds bounds:CGRect,
                           limitedToNumberOfLines n:Int) -> CGRect {
        let bounds = bounds.inset(by: padding)
        let textRect = super.textRect(forBounds: bounds, limitedToNumberOfLines: 0)
        return textRect
    }
}
