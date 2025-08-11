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
    
    enum Mode: Equatable
    {
        case edit(UIImage?)
        case reply(UIImage?)
        case image(UIImage)
        
        var labelText: String? {
            switch self {
            case .edit:
                return "Edit Message"
            case .reply:
                return "Reply to "
            case .image:
                return "Attached image"
            }
        }
        
        var symbolImage: UIImage? {
            switch self {
            case .edit:
                return UIImage(systemName: "pencil")
            case .reply:
                return UIImage(systemName: "arrowshape.turn.up.left")
            case .image:
                return UIImage(systemName: "photo.on.rectangle.angled.fill")
            }
        }
    }
   
    var inputBarHightConstraint: NSLayoutConstraint?
    var textInfoStackViewLeadingConstraint: NSLayoutConstraint?
    private var mode: Mode?
    
    private(set) var closeInputBarHeaderView : UIImageView?
    private var titleLabel                   : UILabel?
    private var subtitleMessageLabel                  : UILabel?
    private var separatorLabel               : UILabel?
    private var symbolIcon                   : UIImageView?
    private var imageThumbnail               : UIImageView?
    private var textInfoStackView            : UIStackView?
    
    convenience init(mode: Mode) {
        self.init()
        self.mode = mode
    }
    
    private func setupSelfHeightConstraint() {
        inputBarHightConstraint           = heightAnchor.constraint(equalToConstant: 45)
        inputBarHightConstraint?.isActive = true
    }
    
    // MARK: - Setup subviews
    
    func setupSubviews()
    {
        backgroundColor = ColorManager.inputBarMessageContainerBackgroundColor
        setupSelfHeightConstraint()
        
        setupTitleLabel()
        setupSubtitleLabel()
        setupSymbolIcon()
        setupSeparator()
        setupCloseButton()
        setupTextInfoStackView()
        setupImageThumbnailView()
    }
    
    func updateTitleLabel(usingText text: String?) {
        if let currentText = titleLabel?.text, let text = text {
            titleLabel?.text = currentText + text
        }
    }
    
    func setTextInfoStackViewLeadingConstraintConstant()
    {
        switch mode {
        case .image(_): textInfoStackViewLeadingConstraint?.constant = 55
        case .reply(let image), .edit(let image):
            if let _ = image { textInfoStackViewLeadingConstraint?.constant = 55 }
        default:
            textInfoStackViewLeadingConstraint?.constant = 10
        }
    }
    
    func setImageThumbnail(_ image: UIImage?)
    {
        self.imageThumbnail?.image = image
    }
    
    func setInputBarHeaderSubtitleMessage(_ text: String?)
    {
        switch mode!
        {
        case .image(_): subtitleMessageLabel?.text = "Photo"
        case .reply(let image), .edit(let image):
            if let _ = image {
                if text == nil {
                    subtitleMessageLabel?.text = "Photo"
                } else {
                    subtitleMessageLabel?.text = text
                }
            }
            else { subtitleMessageLabel?.text = text }
        }
    }
    
    private func setupTextInfoStackView()
    {
        textInfoStackView = UIStackView(arrangedSubviews: [titleLabel! ,subtitleMessageLabel!])
        textInfoStackView?.axis = .vertical
        textInfoStackView?.alignment = .leading
        textInfoStackView?.distribution = .equalCentering
        textInfoStackView?.spacing = 0
        
        textInfoStackView?.translatesAutoresizingMaskIntoConstraints = false
        
        self.addSubview(textInfoStackView!)
        
        textInfoStackView?.topAnchor.constraint(equalTo: self.topAnchor, constant: 8).isActive = true

        textInfoStackView?.trailingAnchor.constraint(equalTo: closeInputBarHeaderView!.leadingAnchor, constant: -40).isActive = true
        
        self.textInfoStackViewLeadingConstraint = textInfoStackView?.leadingAnchor.constraint(
            equalTo: separatorLabel!.trailingAnchor,
            constant: 10)
        textInfoStackViewLeadingConstraint?.isActive = true
        setTextInfoStackViewLeadingConstraintConstant()
        
    }
    
    private func setupImageThumbnailView()
    {
        imageThumbnail = UIImageView()
        self.addSubview(imageThumbnail!)
        
        switch mode {
        case .image(let image):
            imageThumbnail?.image = image
        case .reply(let image), .edit(let image):
            imageThumbnail?.image = image
        default:
            break
        }
        
        imageThumbnail?.translatesAutoresizingMaskIntoConstraints = false
        
        imageThumbnail?.leadingAnchor.constraint(equalTo: self.separatorLabel!.trailingAnchor, constant: 10).isActive = true
        imageThumbnail?.topAnchor.constraint(equalTo: self.topAnchor,
                                             constant: 10).isActive = true

        imageThumbnail?.heightAnchor.constraint(equalTo: separatorLabel!.heightAnchor).isActive = true
        imageThumbnail?.widthAnchor.constraint(equalTo: imageThumbnail!.heightAnchor).isActive = true
    }
    
    private func setupTitleLabel()
    {
        titleLabel = UILabel()
        
        titleLabel?.text                                      = mode?.labelText
        titleLabel?.textColor                                 = ColorManager.actionButtonsTintColor
        titleLabel?.font                                      = UIFont.boldSystemFont(ofSize: 16)
    }
    
    private func setupSubtitleLabel() {
        subtitleMessageLabel                                            = UILabel()
        subtitleMessageLabel?.textColor                                 = .white
        subtitleMessageLabel?.font                                      = UIFont(name: "Helvetica", size: 16)
        subtitleMessageLabel?.lineBreakMode                             = .byTruncatingTail
        subtitleMessageLabel?.adjustsFontSizeToFitWidth                 = false
    }
    
    private func setupSeparator()
    {
        separatorLabel                                            = UILabel()
        separatorLabel?.backgroundColor                           = ColorManager.actionButtonsTintColor
        separatorLabel?.translatesAutoresizingMaskIntoConstraints = false
        self.addSubview(separatorLabel!)
        
        separatorLabel?.topAnchor.constraint(equalTo: self.topAnchor, constant: 10).isActive                                  = true
        separatorLabel?.widthAnchor.constraint(equalToConstant: 2).isActive                                                   = true
        separatorLabel?.heightAnchor.constraint(equalToConstant: 35).isActive                                                 = true
        separatorLabel?.leadingAnchor.constraint(equalTo: symbolIcon!.trailingAnchor, constant: 20).isActive = true
    }
    
    private func setupSymbolIcon() {
        symbolIcon                                            = UIImageView()
        symbolIcon?.tintColor                                 = ColorManager.actionButtonsTintColor
        symbolIcon?.translatesAutoresizingMaskIntoConstraints = false
        symbolIcon?.image                                     = mode?.symbolImage
        self.addSubview(symbolIcon!)
        
        symbolIcon?.leadingAnchor.constraint(equalTo: self.leadingAnchor,
                                             constant: 13).isActive = true
        symbolIcon?.heightAnchor.constraint(equalToConstant: 30).isActive                        = true
//        symbolIcon?.widthAnchor.constraint(equalToConstant: 25).isActive                         = true
        symbolIcon?.widthAnchor.constraint(equalTo: symbolIcon!.heightAnchor).isActive                      = true
        symbolIcon?.topAnchor.constraint(equalTo: self.topAnchor, constant: 10).isActive         = true
    }
    
    private func setupCloseButton() {
        closeInputBarHeaderView                                            = UIImageView()
        closeInputBarHeaderView?.tintColor                                 = ColorManager.actionButtonsTintColor
        closeInputBarHeaderView?.image                                     = UIImage(systemName: "xmark")
        closeInputBarHeaderView?.isUserInteractionEnabled                  = true
        closeInputBarHeaderView?.translatesAutoresizingMaskIntoConstraints = false
        self.addSubview(closeInputBarHeaderView!)
        
        closeInputBarHeaderView?.trailingAnchor.constraint(equalTo: self.trailingAnchor, constant: -18).isActive = true
        closeInputBarHeaderView?.topAnchor.constraint(equalTo: self.topAnchor, constant: 14).isActive            = true
        closeInputBarHeaderView?.heightAnchor.constraint(equalToConstant: 23).isActive                           = true
        closeInputBarHeaderView?.widthAnchor.constraint(equalToConstant: 20).isActive                            = true
    }
    
    func removeSubviews() {
        self.subviews.forEach({ view in
            view.removeFromSuperview()
        })
        titleLabel              = nil
        subtitleMessageLabel             = nil
        separatorLabel          = nil
        symbolIcon              = nil
        closeInputBarHeaderView = nil
    }
}
