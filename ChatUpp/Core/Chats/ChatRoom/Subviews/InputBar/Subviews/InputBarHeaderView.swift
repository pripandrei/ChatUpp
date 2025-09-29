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
    
    // MARK: - Properties
    private var mode: Mode?
    
    var inputBarHeightConstraint: NSLayoutConstraint?
    var textInfoStackViewLeadingConstraint: NSLayoutConstraint?
    
    private(set) var closeButton: UIImageView?
    private var titleLabel: UILabel?
    private var subtitleLabel: UILabel?
    private var separator: UILabel?
    private var symbolIcon: UIImageView?
    private var imageThumbnail: UIImageView?
    private var textInfoStackView: UIStackView?
    
    // MARK: - Init
    convenience init(mode: Mode) {
        self.init(frame: .zero)
        setupSubviews()
        applyMode(mode)
    }
    
    private func setupSelfHeightConstraint() {
        inputBarHeightConstraint = heightAnchor.constraint(equalToConstant: 45)
        inputBarHeightConstraint?.isActive = true
    }
    
    // MARK: - Setup
    func setupSubviews() {
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
    
    private func setupTitleLabel() {
        titleLabel = UILabel()
        titleLabel?.textColor = ColorManager.actionButtonsTintColor
        titleLabel?.font = UIFont.boldSystemFont(ofSize: 16)
    }
    
    private func setupSubtitleLabel() {
        subtitleLabel = UILabel()
        subtitleLabel?.textColor = .white
        subtitleLabel?.font = UIFont(name: "Helvetica", size: 16)
        subtitleLabel?.lineBreakMode = .byTruncatingTail
    }
    
    private func setupSymbolIcon() {
        symbolIcon = UIImageView()
        symbolIcon?.tintColor = ColorManager.actionButtonsTintColor
        symbolIcon?.translatesAutoresizingMaskIntoConstraints = false
        addSubview(symbolIcon!)
        
        NSLayoutConstraint.activate([
            symbolIcon!.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 13),
            symbolIcon!.heightAnchor.constraint(equalToConstant: 30),
            symbolIcon!.widthAnchor.constraint(equalTo: symbolIcon!.heightAnchor),
            symbolIcon!.topAnchor.constraint(equalTo: topAnchor, constant: 10)
        ])
        
        symbolIcon?.transform = .init(scaleX: 0.01, y: 0.01)
        executeAfter(seconds: 0.1) {
            self.animateSymbolImage()
        }
    }
    
    private func setupSeparator() {
        separator = UILabel()
        separator?.backgroundColor = ColorManager.actionButtonsTintColor
        separator?.translatesAutoresizingMaskIntoConstraints = false
        addSubview(separator!)
        
        NSLayoutConstraint.activate([
            separator!.topAnchor.constraint(equalTo: topAnchor, constant: 10),
            separator!.widthAnchor.constraint(equalToConstant: 2),
            separator!.heightAnchor.constraint(equalToConstant: 35),
            separator!.leadingAnchor.constraint(equalTo: symbolIcon!.trailingAnchor, constant: 20)
        ])
    }
    
    private func setupCloseButton() {
        closeButton = UIImageView(image: UIImage(systemName: "xmark"))
        closeButton?.tintColor = ColorManager.actionButtonsTintColor
        closeButton?.isUserInteractionEnabled = true
        closeButton?.translatesAutoresizingMaskIntoConstraints = false
        addSubview(closeButton!)
        
        NSLayoutConstraint.activate([
            closeButton!.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -18),
            closeButton!.topAnchor.constraint(equalTo: topAnchor, constant: 14),
            closeButton!.heightAnchor.constraint(equalToConstant: 23),
            closeButton!.widthAnchor.constraint(equalToConstant: 20)
        ])
    }
    
    private func setupTextInfoStackView() {
        textInfoStackView = UIStackView(arrangedSubviews: [titleLabel!, subtitleLabel!])
        textInfoStackView?.axis = .vertical
        textInfoStackView?.alignment = .leading
        textInfoStackView?.spacing = 0
        textInfoStackView?.translatesAutoresizingMaskIntoConstraints = false
        addSubview(textInfoStackView!)
        
        textInfoStackViewLeadingConstraint = textInfoStackView?.leadingAnchor.constraint(equalTo: separator!.trailingAnchor, constant: 10)
        textInfoStackViewLeadingConstraint?.isActive = true
        
        NSLayoutConstraint.activate([
            textInfoStackView!.topAnchor.constraint(equalTo: topAnchor, constant: 8),
            textInfoStackView!.trailingAnchor.constraint(equalTo: closeButton!.leadingAnchor, constant: -40)
        ])
    }
    
    private func setupImageThumbnailView() {
        imageThumbnail = UIImageView()
        imageThumbnail?.translatesAutoresizingMaskIntoConstraints = false
        addSubview(imageThumbnail!)
        
        NSLayoutConstraint.activate([
            imageThumbnail!.leadingAnchor.constraint(equalTo: separator!.trailingAnchor, constant: 10),
            imageThumbnail!.topAnchor.constraint(equalTo: topAnchor, constant: 10),
            imageThumbnail!.heightAnchor.constraint(equalTo: separator!.heightAnchor),
            imageThumbnail!.widthAnchor.constraint(equalTo: imageThumbnail!.heightAnchor)
        ])
    }
    
    // MARK: - Apply Mode
    func applyMode(_ mode: Mode)
    {
        self.mode = mode
        titleLabel?.text = mode.labelText
        subtitleLabel?.text = mode.subtitleText()
        symbolIcon?.image = mode.symbolImage
        imageThumbnail?.image = mode.thumbnail
        textInfoStackViewLeadingConstraint?.constant = mode.leadingInset
    }
    
    // MARK: - Cleanup
    func removeSubviews() {
        subviews.forEach { $0.removeFromSuperview() }
        titleLabel = nil
        subtitleLabel = nil
        separator = nil
        symbolIcon = nil
        closeButton = nil
        imageThumbnail = nil
        textInfoStackView = nil
    }
    
    func updateSubtitle(_ text: String?) {
        guard let mode else { return }
        subtitleLabel?.text = mode.subtitleText(fallback: text)
    }
    
    func updateTitleLabel(usingText text: String?)
    {
        if let currentText = titleLabel?.text,
           let text = text
        {
            titleLabel?.text = currentText + text
        }
    }
    
    private func animateSymbolImage()
    {
//        symbolIcon?.transform = .init(scaleX: 0.01, y: 0.01)
        
        UIView.animate(withDuration: 0.5) {
            self.symbolIcon?.transform = .identity
        }
    }
}

extension InputBarHeaderView
{
    enum Mode: Equatable
    {
        case edit(text: String?, image: UIImage?)
        case reply(text: String?, image: UIImage?)
        case image(UIImage)

        var labelText: String {
            switch self {
            case .edit: return "Edit Message"
            case .reply: return "Reply to "
            case .image: return "Attached image"
            }
        }
        
        var symbolImage: UIImage? {
            switch self {
            case .edit: return UIImage(systemName: "pencil")
            case .reply: return UIImage(systemName: "arrowshape.turn.up.left")
            case .image: return UIImage(systemName: "photo.on.rectangle.angled.fill")
            }
        }
        
        var leadingInset: CGFloat {
            switch self {
            case .image: return 55
            case .edit(_, let image), .reply(_, let image):
                return image != nil ? 55 : 10
            }
        }
        
        func subtitleText(fallback: String? = nil) -> String? {
            switch self {
            case .image:
                return "Photo"
            case .edit(let text, let image), .reply(let text, let image):
                if let _ = image { return text ?? "Photo" }
                return text ?? fallback
            }
        }
        
        var thumbnail: UIImage? {
            switch self {
            case .image(let image): return image
            case .edit(_, let image), .reply(_, let image): return image
            }
        }
    }
}
