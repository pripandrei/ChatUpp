//
//  ConversationCustomNavigationBar.swift
//  ChatUpp
//
//  Created by Andrei Pripa on 1/18/25.
//

import UIKit

// MARK: - SETUP NAVIGATION BAR ITEMS
final class ConversationCustomNavigationBar {
    
    private let viewController: UIViewController!
    var navigationItemsContainer: NavigationTitleContainer!
    
    init(viewController: UIViewController) {
        self.viewController = viewController
    }
    
    func setupNavigationBarItems(with imageData: Data?, memberName: String, memberActiveStatus: String) {
        
        guard let image = (imageData != nil) ? UIImage(data: imageData!) : UIImage(named: "default_profile_photo") else {return}
        navigationItemsContainer = NavigationTitleContainer(name: memberName, lastSeen: memberActiveStatus, image: image)
        
        let imageView = NavigationProfileImageView(image: image)
        let barButtonItem = UIBarButtonItem(customView: imageView)
        
        viewController.navigationItem.rightBarButtonItem = barButtonItem
        viewController.navigationItem.titleView = navigationItemsContainer
    }
}

//MARK: - Navigation items conteiner view

extension ConversationCustomNavigationBar
{
    final class NavigationTitleContainer: UIView {
        let nameLabel: UILabel
        let lastSeenLabel: UILabel
        
        private var temporaryDimmView: UIView!
        private var temporaryImageView: UIView!
        
        init(name: String, lastSeen: String, image: UIImage) {
            nameLabel = UILabel()
            lastSeenLabel = UILabel()
            
            super.init(frame: .zero)
            
            setupViews(name: name, lastSeen: lastSeen)
        }
        
        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
        
        private func setupViews(name: String, lastSeen: String) {
            nameLabel.text = name
            nameLabel.textColor = .white
            nameLabel.font = UIFont(name:"HelveticaNeue-Bold", size: 17)
            nameLabel.textAlignment = .center
            
            lastSeenLabel.text = lastSeen == "online" ? lastSeen : "last seen \(lastSeen)"
            lastSeenLabel.font = UIFont(name:"HelveticaNeue", size: 13)
            lastSeenLabel.textColor = .white

            let stackView = UIStackView(arrangedSubviews: [nameLabel, lastSeenLabel])
            
            stackView.axis = .vertical
            stackView.alignment = .center
//            stackView.distribution = .fillEqually
            
            stackView.translatesAutoresizingMaskIntoConstraints = false
            addSubview(stackView)
            
            NSLayoutConstraint.activate([
                stackView.topAnchor.constraint(equalTo: topAnchor),
                stackView.bottomAnchor.constraint(equalTo: bottomAnchor),
                stackView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 0),
                stackView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: 0),
                widthAnchor.constraint(equalToConstant: 200)
            ])
        }
    }
    
    class NavigationProfileImageView: UIImageView {
        
        private var temporaryDimmView:  UIView!
        private var temporaryImageView: UIView!
        private var initialImageFrame:  CGRect!
        private let profileImageSize:   CGFloat = 38
        
        override init(image: UIImage?) {
            super.init(image: image)
            setupSelf()
        }
        
        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
        
        private func setupSelf() {
            let tapGesture = UITapGestureRecognizer(target: self, action: #selector(animateProfileImage))
            addGestureRecognizer(tapGesture)

            contentMode                               = .scaleToFill
            layer.cornerRadius                        = profileImageSize / 2
            clipsToBounds                             = true
            translatesAutoresizingMaskIntoConstraints = false
            
            widthAnchor.constraint(equalToConstant: profileImageSize).isActive  = true
            heightAnchor.constraint(equalToConstant: profileImageSize).isActive = true
        }
        
        @objc func animateProfileImage() {
            guard let window                      = window else { return }
            temporaryDimmView                     = setupTemporaryDimmView(withFrame: window.frame)
            temporaryImageView                    = setupTemporaryImageView()
            
            self.isHidden = true
            UIView.animate(withDuration: 0.5, animations: {
                self.temporaryImageView.center    = window.center
                self.temporaryImageView.transform = CGAffineTransform(scaleX: 8, y: 8)
                self.temporaryDimmView.alpha      = 1
            })
        }
        
        private func setupTemporaryImageView() -> UIView {
            initialImageFrame                    = self.convert(self.bounds, to: window)
            
            let animatedImageView                = UIImageView(frame: initialImageFrame)
            animatedImageView.image              = self.image
            animatedImageView.layer.cornerRadius = profileImageSize / 2
            animatedImageView.contentMode        = .scaleToFill
            animatedImageView.clipsToBounds      = true
            window?.addSubview(animatedImageView)
            
            return animatedImageView
        }
        
        private func setupTemporaryDimmView(withFrame frame: CGRect) -> UIView {
            let dimmView             = UIView(frame: frame)
//            dimmView.backgroundColor = .black
            dimmView.alpha           = 0
            window?.addSubview(dimmView)
            
            let blurEffect = UIBlurEffect(style: .systemThickMaterialDark)
            let blurEffectView = UIVisualEffectView(effect: blurEffect)
            blurEffectView.frame = dimmView.bounds
            dimmView.addSubview(blurEffectView)
            
            let tapGesture           = UITapGestureRecognizer(target: self, action: #selector(dismissProfileImage))
            dimmView.addGestureRecognizer(tapGesture)
            
            return dimmView
        }
        
        @objc func dismissProfileImage(_ sender: UITapGestureRecognizer) {
            UIView.animate(withDuration: 0.5) {
                self.temporaryDimmView.alpha        = 0
                self.temporaryImageView.transform.a = 1
                self.temporaryImageView.transform.d = 1
                self.temporaryImageView.frame       = self.initialImageFrame
            } completion: { _ in
                self.temporaryDimmView.removeFromSuperview()
                self.temporaryImageView.removeFromSuperview()
                self.temporaryDimmView  = nil
                self.temporaryImageView = nil
                self.isHidden           = false
            }
        }
    }
}
