//
//  ContainerEditView.swift
//  ChatUpp
//
//  Created by Andrei Pripa on 5/9/24.
//

import Foundation
import UIKit

final class EditView: UIView {
    
    var editeViewHeightConstraint: NSLayoutConstraint?
    
    private(set) var closeEditView     : UIImageView?
    private var editLabel              : UILabel?
    private var editMessageText        : UILabel?
    private var separatorLabel         : UILabel?
    private var editPenIcon            : UIImageView?
    
    private func setupSelfHeightConstraint() {
        editeViewHeightConstraint           = heightAnchor.constraint(equalToConstant: 45)
        editeViewHeightConstraint?.isActive = true
    }
    
    
    // MARK: - Setup subviews
    
    func setupSubviews() {
        backgroundColor = #colorLiteral(red: 0.1677602232, green: 0.3210971653, blue: 0.4742530584, alpha: 1)
        setupSelfHeightConstraint()
        
        setupEditLabel()
        setupEditMessage()
        setupSeparator()
        setupEditePenIcon()
        setupCloseButton()
    }
    
    private func setupEditLabel() {
        editLabel = UILabel()
        
        editLabel?.text                                      = "Edit Message"
        editLabel?.textColor                                 = #colorLiteral(red: 0.2392156869, green: 0.6745098233, blue: 0.9686274529, alpha: 1)
        editLabel?.font                                      = UIFont.boldSystemFont(ofSize: 15)
        editLabel?.translatesAutoresizingMaskIntoConstraints = false
        self.addSubview(editLabel!)
        
        editLabel?.topAnchor.constraint(equalTo: self.topAnchor, constant: 8).isActive                                   = true
        editLabel?.leadingAnchor.constraint(equalTo: self.leadingAnchor, constant: superview!.bounds.width / 5).isActive = true
    }
    private func setupEditMessage() {
        editMessageText                                            = UILabel()
        editMessageText?.text                                      = "Test Message here for testing purposes only test test"
        editMessageText?.textColor                                 = .white
        editMessageText?.font                                      = UIFont(name: "Helvetica", size: 13.5)
        editMessageText?.lineBreakMode                             = .byTruncatingTail
        editMessageText?.adjustsFontSizeToFitWidth                 = false
        editMessageText?.translatesAutoresizingMaskIntoConstraints = false
        self.addSubview(editMessageText!)
        
        editMessageText?.topAnchor.constraint(equalTo: editLabel!.topAnchor, constant: 18).isActive                             = true
        editMessageText?.leadingAnchor.constraint(equalTo: self.leadingAnchor, constant:  superview!.bounds.width / 5).isActive = true
        editMessageText?.trailingAnchor.constraint(equalTo: self.trailingAnchor, constant: -90).isActive                        = true
    }
    private func setupSeparator() {
        separatorLabel                                            = UILabel()
        separatorLabel?.backgroundColor                           = #colorLiteral(red: 0.2392156869, green: 0.6745098233, blue: 0.9686274529, alpha: 1)
        separatorLabel?.translatesAutoresizingMaskIntoConstraints = false
        self.addSubview(separatorLabel!)
        
        separatorLabel?.topAnchor.constraint(equalTo: self.topAnchor, constant: 10).isActive                                  = true
        separatorLabel?.widthAnchor.constraint(equalToConstant: 3).isActive                                                   = true
        separatorLabel?.heightAnchor.constraint(equalToConstant: 32).isActive                                                 = true
        separatorLabel?.leadingAnchor.constraint(equalTo: self.leadingAnchor, constant: superview!.bounds.width / 6).isActive = true
    }
    
    private func setupEditePenIcon() {
        editPenIcon                                            = UIImageView()
        editPenIcon?.tintColor                                 = #colorLiteral(red: 0.2392156869, green: 0.6745098233, blue: 0.9686274529, alpha: 1)
        editPenIcon?.image                                     = UIImage(systemName: "pencil")
        editPenIcon?.translatesAutoresizingMaskIntoConstraints = false
        self.addSubview(editPenIcon!)
        
        editPenIcon?.leadingAnchor.constraint(equalTo: self.leadingAnchor, constant: 20).isActive = true
        editPenIcon?.heightAnchor.constraint(equalToConstant: 27).isActive                        = true
        editPenIcon?.widthAnchor.constraint(equalToConstant: 25).isActive                         = true
        editPenIcon?.topAnchor.constraint(equalTo: self.topAnchor, constant: 10).isActive         = true
    }
    
    private func setupCloseButton() {
        closeEditView                                            = UIImageView()
        closeEditView?.tintColor                                 = #colorLiteral(red: 0.2392156869, green: 0.6745098233, blue: 0.9686274529, alpha: 1)
        closeEditView?.image                                     = UIImage(systemName: "xmark")
        closeEditView?.isUserInteractionEnabled                  = true
        closeEditView?.translatesAutoresizingMaskIntoConstraints = false
        self.addSubview(closeEditView!)
        
        closeEditView?.trailingAnchor.constraint(equalTo: self.trailingAnchor, constant: -23).isActive = true
        closeEditView?.topAnchor.constraint(equalTo: self.topAnchor, constant: 14).isActive            = true
        closeEditView?.heightAnchor.constraint(equalToConstant: 23).isActive                           = true
        closeEditView?.widthAnchor.constraint(equalToConstant: 20).isActive                            = true
    }
    
    func removeSubviews() {
        self.subviews.forEach({ view in
            view.removeFromSuperview()
        })
        editLabel       = nil
        editMessageText = nil
        separatorLabel  = nil
        editPenIcon     = nil
        closeEditView   = nil
    }
}
