//
//  ConversationTableViewHeader.swift
//  ChatUpp
//
//  Created by Andrei Pripa on 5/13/24.
//


import UIKit


//MARK: - Section header label
class DateHeaderLabel: UILabel {
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        backgroundColor = #colorLiteral(red: 0.176230222, green: 0.3105865121, blue: 0.4180542529, alpha: 1)
        textColor = .white
        textAlignment = .center
        translatesAutoresizingMaskIntoConstraints = false
        font = UIFont.boldSystemFont(ofSize: 14)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override var intrinsicContentSize: CGSize {
        let originalContentSize = super.intrinsicContentSize
        let height = originalContentSize.height + 12
        layer.cornerRadius = height / 2
        layer.masksToBounds = true
        return CGSize(width: originalContentSize.width + 20, height: height)
    }
}
