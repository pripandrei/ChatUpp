//
//  ContainerEditView.swift
//  ChatUpp
//
//  Created by Andrei Pripa on 5/9/24.
//

import Foundation
import UIKit

/// View that appears above inputBarContainer when reply/edit action option on a message is selected

final class InputBarHeaderView: UIView {
    
    enum Mode {
        case edit
        case reply
    }
    
    var editeViewHeightConstraint: NSLayoutConstraint?
    private var mode: Mode?
    
    private(set) var closeInputBarHeaderView : UIImageView?
    private var titleLabel                   : UILabel?
    private var messageText                  : UILabel?
    private var separatorLabel               : UILabel?
    private var symbolIcon                   : UIImageView?
    
    convenience init(mode: Mode) {
        self.init()
        self.mode = mode
    }
    
    private func setupSelfHeightConstraint() {
        editeViewHeightConstraint           = heightAnchor.constraint(equalToConstant: 45)
        editeViewHeightConstraint?.isActive = true
    }
    
    // MARK: - Setup subviews
    
    func setupSubviews() {
        backgroundColor = ColorManager.inputBarMessageContainerBackgroundColor
        setupSelfHeightConstraint()
        
        setupEditLabel()
        setupEditMessage()
        setupSeparator()
        setupEditePenIcon()
        setupCloseButton()
    }
    
    func setInputBarHeaderMessageText(_ text: String?) {
        messageText?.text = text
    }
    
    func updateTitleLabel(usingText text: String?) {
        if let currentText = titleLabel?.text, let text = text {
            titleLabel?.text = currentText + text
        }
    }
    
    private func setupEditLabel() {
        titleLabel = UILabel()
        
        titleLabel?.text                                      = mode == .edit ? "Edit Message" : "Reply to "
        titleLabel?.textColor                                 = ColorManager.actionButtonsTintColor
        titleLabel?.font                                      = UIFont.boldSystemFont(ofSize: 15)
        titleLabel?.translatesAutoresizingMaskIntoConstraints = false
        self.addSubview(titleLabel!)
        
        titleLabel?.topAnchor.constraint(equalTo: self.topAnchor, constant: 8).isActive                                   = true
        titleLabel?.leadingAnchor.constraint(equalTo: self.leadingAnchor, constant: superview!.bounds.width / 5).isActive = true
    }
    private func setupEditMessage() {
        messageText                                            = UILabel()
        messageText?.textColor                                 = .white
        messageText?.font                                      = UIFont(name: "Helvetica", size: 13.5)
        messageText?.lineBreakMode                             = .byTruncatingTail
        messageText?.adjustsFontSizeToFitWidth                 = false
        messageText?.translatesAutoresizingMaskIntoConstraints = false
        self.addSubview(messageText!)
        
        messageText?.topAnchor.constraint(equalTo: titleLabel!.topAnchor, constant: 18).isActive                             = true
        messageText?.leadingAnchor.constraint(equalTo: self.leadingAnchor, constant:  superview!.bounds.width / 5).isActive = true
        messageText?.trailingAnchor.constraint(equalTo: self.trailingAnchor, constant: -90).isActive                        = true
    }
    private func setupSeparator() {
        separatorLabel                                            = UILabel()
        separatorLabel?.backgroundColor                           = ColorManager.actionButtonsTintColor
        separatorLabel?.translatesAutoresizingMaskIntoConstraints = false
        self.addSubview(separatorLabel!)
        
        separatorLabel?.topAnchor.constraint(equalTo: self.topAnchor, constant: 10).isActive                                  = true
        separatorLabel?.widthAnchor.constraint(equalToConstant: 3).isActive                                                   = true
        separatorLabel?.heightAnchor.constraint(equalToConstant: 32).isActive                                                 = true
        separatorLabel?.leadingAnchor.constraint(equalTo: self.leadingAnchor, constant: superview!.bounds.width / 6).isActive = true
    }
    
    private func setupEditePenIcon() {
        symbolIcon                                            = UIImageView()
        symbolIcon?.tintColor                                 = ColorManager.actionButtonsTintColor
        symbolIcon?.image                                     = mode == .edit ? UIImage(systemName: "pencil") : UIImage(systemName: "arrowshape.turn.up.left")
        symbolIcon?.translatesAutoresizingMaskIntoConstraints = false
        self.addSubview(symbolIcon!)
        
        symbolIcon?.leadingAnchor.constraint(equalTo: self.leadingAnchor, constant: 20).isActive = true
        symbolIcon?.heightAnchor.constraint(equalToConstant: 27).isActive                        = true
        symbolIcon?.widthAnchor.constraint(equalToConstant: 25).isActive                         = true
        symbolIcon?.topAnchor.constraint(equalTo: self.topAnchor, constant: 10).isActive         = true
    }
    
    private func setupCloseButton() {
        closeInputBarHeaderView                                            = UIImageView()
        closeInputBarHeaderView?.tintColor                                 = ColorManager.actionButtonsTintColor
        closeInputBarHeaderView?.image                                     = UIImage(systemName: "xmark")
        closeInputBarHeaderView?.isUserInteractionEnabled                  = true
        closeInputBarHeaderView?.translatesAutoresizingMaskIntoConstraints = false
        self.addSubview(closeInputBarHeaderView!)
        
        closeInputBarHeaderView?.trailingAnchor.constraint(equalTo: self.trailingAnchor, constant: -23).isActive = true
        closeInputBarHeaderView?.topAnchor.constraint(equalTo: self.topAnchor, constant: 14).isActive            = true
        closeInputBarHeaderView?.heightAnchor.constraint(equalToConstant: 23).isActive                           = true
        closeInputBarHeaderView?.widthAnchor.constraint(equalToConstant: 20).isActive                            = true
    }
    
    func removeSubviews() {
        self.subviews.forEach({ view in
            view.removeFromSuperview()
        })
        titleLabel              = nil
        messageText             = nil
        separatorLabel          = nil
        symbolIcon              = nil
        closeInputBarHeaderView = nil
    }
}
