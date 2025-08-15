//
//  ConversationTableViewHeader.swift
//  ChatUpp
//
//  Created by Andrei Pripa on 5/13/24.
//


import UIKit


//MARK: - Conversation Section header

final class FooterSectionView: UITableViewHeaderFooterView
{
    private var dateLabel: DateFooterLabel!
    
    override init(reuseIdentifier: String?) {
        super.init(reuseIdentifier: reuseIdentifier)
        setupFooterSection()
        setupDateLabel()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupFooterSection() {
//        self.transform = CGAffineTransform(scaleX: 1, y: -1)
        self.backgroundConfiguration = .clear()
    }
    
    private func setupDateLabel() 
    {
        dateLabel = DateFooterLabel()
        contentView.addSubview(dateLabel)
        dateLabel.translatesAutoresizingMaskIntoConstraints = false
        
        dateLabel.centerXAnchor.constraint(equalTo: contentView.centerXAnchor).isActive = true
        dateLabel.centerYAnchor.constraint(equalTo: contentView.centerYAnchor).isActive = true
    }
    
    func setDate(dateText: String) 
    {
        dateLabel.text = dateText
    }
    
}

extension FooterSectionView 
{
    private class DateFooterLabel: UILabel
    {
        override init(frame: CGRect) 
        {
            super.init(frame: frame)
            transform = CGAffineTransform(scaleX: 1, y: -1)
            backgroundColor = ColorManager.messageEventBackgroundColor
            textColor = .white
            textAlignment = .center
            translatesAutoresizingMaskIntoConstraints = false
            font = UIFont.boldSystemFont(ofSize: 13)
        }

        required init?(coder aDecoder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
        
        override var intrinsicContentSize: CGSize 
        {
            let originalContentSize = super.intrinsicContentSize
            let height = originalContentSize.height + 8
            layer.cornerRadius = height / 2
            layer.masksToBounds = true
            return CGSize(width: originalContentSize.width + 15, height: height)
        }
    }
}
