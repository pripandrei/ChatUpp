//
//  CustomCollectionViewCell.swift
//  ChatUpp
//
//  Created by Andrei Pripa on 10/11/23.
//

import UIKit

class ConversationCollectionViewCell: UICollectionViewCell {
    
    let messageBody = UILabel()
    private let leadingEdgeSpacing: CGFloat = 90.0
    private let cellContainerView = UIView()
    private let timeStamp = UILabel()
    
    private var cellContainerMaxWidthConstraint: NSLayoutConstraint!
    private var messageTrailingConstraint: NSLayoutConstraint!
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
        contentView.addSubview(cellContainerView)
        setupCellContainerViewConstraints()
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
//        timeStamp.backgroundColor = .orange
        timeStamp.font = UIFont(name: "Helvetica", size: 13)
        timeStamp.sizeToFit()
        
        setupTimestampConstraints()
    }
    
    private func setupMessageUI() {
        cellContainerView.addSubview(messageBody)
        
        cellContainerView.backgroundColor = .green
        
        messageBody.backgroundColor = #colorLiteral(red: 0.6470323801, green: 0.3927372098, blue: 0.3783177137, alpha: 1)
        messageBody.textAlignment = .left
        messageBody.textColor = .white
        messageBody.font = UIFont(name: "HelveticaNeue", size: 18)
        messageBody.layer.cornerRadius = 15
        messageBody.setContentCompressionResistancePriority(.required, for: .vertical)
        messageBody.numberOfLines = 0
//        messageBody.sizeToFit()
        setupMessageConstraints()
    }
    
    private func setupTimestampConstraints() {
        timeStamp.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            timeStamp.bottomAnchor.constraint(equalTo: cellContainerView.bottomAnchor),
            timeStamp.trailingAnchor.constraint(equalTo: cellContainerView.trailingAnchor),
        ])
    }
    
    private func setupCellContainerViewConstraints() {
        cellContainerView.translatesAutoresizingMaskIntoConstraints = false
    
        NSLayoutConstraint.activate([
            cellContainerView.topAnchor.constraint(equalTo: topAnchor),
            cellContainerView.bottomAnchor.constraint(equalTo: bottomAnchor),
            cellContainerView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -10),
        ])
    }
    
    private func setupMessageConstraints() {
        messageBody.translatesAutoresizingMaskIntoConstraints = false
        
        messageTrailingConstraint = messageBody.trailingAnchor.constraint(equalTo: cellContainerView.trailingAnchor)
        messageTrailingConstraint.isActive = true
        NSLayoutConstraint.activate([
            messageBody.bottomAnchor.constraint(equalTo: cellContainerView.bottomAnchor),
            messageBody.topAnchor.constraint(equalTo: cellContainerView.topAnchor),
            messageBody.leadingAnchor.constraint(equalTo: cellContainerView.leadingAnchor),
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
        self.layoutIfNeeded()

        let lastLineString = getMessageLastLine(for: messageBody.text!, in: messageBody)
        let lastLineWidth = lastLineString.getSize().width
        let lastLineWithTimestempWidth = lastLineWidth + timeStamp.bounds.width
        let messageRectWidth = messageBody.textBoundingRect.width

        messageTrailingConstraint.isActive = true
        messageTrailingToTimestampConstraint.isActive = false
        
        if lastLineWithTimestempWidth > messageRectWidth {
            if lastLineWithTimestempWidth.rounded(.up) < cellContainerMaxWidthConstraint.constant  {
                messageTrailingConstraint.isActive = false
                messageTrailingToTimestampConstraint.isActive = true
//                layoutIfNeeded()
            } else {
                let textWithNewLine = messageBody.text! + "\n"
                messageBody.text = textWithNewLine
            }
        }
    }
    
    private func getMessageLastLine(for text: String, in label: UILabel) -> String {
        let adjustedLabelSize = CGRect(x: 0, y: 0, width: label.textBoundingRect.width, height: label.textBoundingRect.height + 10)
        
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
        
        return lineText
    }
}

