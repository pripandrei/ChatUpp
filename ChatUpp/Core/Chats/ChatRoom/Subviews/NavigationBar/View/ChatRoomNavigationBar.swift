//
//  ConversationCustomNavigationBar.swift
//  ChatUpp
//
//  Created by Andrei Pripa on 1/18/25.
//

import UIKit
import Combine


// MARK: - SETUP NAVIGATION BAR ITEMS
final class ChatRoomNavigationBar
{
    private weak var coordinator: Coordinator?
    private weak var viewController: UIViewController!
    
    private var navigationItemsContainer: NavigationTitleContainer?
    private var navImage: NavigationProfileImageView?
    private var viewModel: ChatRoomNavigationBarViewModel
    
    private var cancellables: Set<AnyCancellable> = []
    
    deinit {
        print("ChatRoomNavigationBar ====== deinit")
    }
    
    init(viewController: UIViewController,
         viewModel: ChatRoomNavigationBarViewModel,
         coordinator: Coordinator?)
    {
        self.viewController = viewController
        self.viewModel = viewModel
        self.coordinator = coordinator
        setupNavigationBarItems()
        self.bind()
    }
    
    private func setupNavigationBarItems()
    {
        setupNavigationTitleContainer()
        setupNavigationImage()
        setupNavItemsTarget()
    }
    
    private func setupNavigationTitleContainer()
    {
        self.navigationItemsContainer = NavigationTitleContainer(name: viewModel._title, lastSeen: viewModel._status)
        viewController.navigationItem.titleView = self.navigationItemsContainer
    }
    
    private func setupNavigationImage()
    {
        var image: UIImage?
        
        if let imgUrl = viewModel._imageUrl,
           let imageData = viewModel.getImageFromCache(imgUrl) {
            image = UIImage(data: imageData)
        } else {
            image = viewModel.isGroup ? UIImage(named: "default_group_photo") : UIImage(named: "default_profile_photo")
        }
        let imageView = NavigationProfileImageView(image: image)
        let barButtonItem = UIBarButtonItem(customView: imageView)
        
        viewController.navigationItem.rightBarButtonItem = barButtonItem
        
        self.navImage = imageView
    }
    
    private func setupNavItemsTarget()
    {
        if let _ = viewModel.dataProvider.provider as? Chat
        {
            let gesture1 = UITapGestureRecognizer(target: self, action: #selector(openChatRoomInformationScreen))
            let gesture2 = UITapGestureRecognizer(target: self, action: #selector(openChatRoomInformationScreen))
            
            viewController.navigationItem.rightBarButtonItem?.customView?.addGestureRecognizer(gesture1)
            viewController.navigationItem.titleView?.addGestureRecognizer(gesture2)
        } else {
            navImage?.setupGesture()
        }
    }

    @objc private func openChatRoomInformationScreen()
    {
        guard let chat = viewModel.dataProvider.provider as? Chat else { return }
        let viewModel = ChatRoomInformationViewModel(chat: chat)
        coordinator?.showChatRoomInformationScreen(viewModel: viewModel)
    }

    private func bind()
    {
        viewModel.$_imageUrl
            .compactMap({$0})
            .sink { [weak self] url in
                guard let imageData = self?.viewModel.getImageFromCache(url) else {return}
                self?.navImage?.image = UIImage(data: imageData)
            }.store(in: &cancellables)
        
        viewModel.$_status
            .compactMap({$0})
            .sink { [weak self] status in
                self?.navigationItemsContainer?.statusLabel.text = status
            }.store(in: &cancellables)
        
        viewModel.$_title
            .compactMap({$0})
            .sink { [weak self] title in
                self?.navigationItemsContainer?.titleLabel.text = title
            }.store(in: &cancellables)
    }
}

//MARK: - Navigation items conteiner view
//
extension ChatRoomNavigationBar
{
    final class NavigationTitleContainer: UIView {
        let titleLabel: UILabel
        let statusLabel: UILabel
        
        private var temporaryDimmView: UIView!
        private var temporaryImageView: UIView!
        
        init(name: String?, lastSeen: String?) {
            titleLabel = UILabel()
            statusLabel = UILabel()
            
            super.init(frame: .zero)
            
            setupViews(name: name, lastSeen: lastSeen)
        }
        
        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
        
        private func setupViews(name: String?, lastSeen: String?) {
            titleLabel.text = name
            titleLabel.textColor = .white
            titleLabel.font = UIFont(name:"HelveticaNeue-Bold", size: 17)
            titleLabel.textAlignment = .center
            
            statusLabel.text = lastSeen == "online" ? lastSeen : "last seen \(String(describing: lastSeen))"
            statusLabel.font = UIFont(name:"HelveticaNeue", size: 13)
            statusLabel.textColor = .white

            let stackView = UIStackView(arrangedSubviews: [titleLabel, statusLabel])
            
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
//            let tapGesture = UITapGestureRecognizer(target: self, action: #selector(animateProfileImage))
//            addGestureRecognizer(tapGesture)

            contentMode                               = .scaleToFill
            layer.cornerRadius                        = profileImageSize / 2
            clipsToBounds                             = true
            translatesAutoresizingMaskIntoConstraints = false
            
            widthAnchor.constraint(equalToConstant: profileImageSize).isActive  = true
            heightAnchor.constraint(equalToConstant: profileImageSize).isActive = true
        }
        
        func setupGesture() {
            let tapGesture = UITapGestureRecognizer(target: self, action: #selector(animateProfileImage))
            addGestureRecognizer(tapGesture)
        }
        
        @objc func animateProfileImage() {
            guard let window                      = window else { return }
            temporaryDimmView                     = setupTemporaryDimmView(withFrame: window.frame)
            temporaryImageView                    = setupTemporaryImageView()
            
            self.isHidden = true
            UIView.animate(withDuration: 0.3, animations: {
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
            UIView.animate(withDuration: 0.3) {
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
