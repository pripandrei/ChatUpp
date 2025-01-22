//
//  ConversationCustomNavigationBar.swift
//  ChatUpp
//
//  Created by Andrei Pripa on 1/18/25.
//

import UIKit
import Combine


// MARK: - SETUP NAVIGATION BAR ITEMS
final class ChatRoomNavigationBar {
    
    private let viewController: UIViewController!
    var navigationItemsContainer: NavigationTitleContainer?
    var navImage: NavigationProfileImageView?
    var viewModel: ChatRoomNavigationBarViewModel
    
    private var cancellables: Set<AnyCancellable> = []
    
    init(viewController: UIViewController,
         viewModel: ChatRoomNavigationBarViewModel)
    {
        self.viewController = viewController
        self.viewModel = viewModel
        setupNavigationBarItems()
        self.bind()
        
    }
    
    private func setupNavigationBarItems()
    {
        setupNavigationTitleContainer()
        setuoNavigationImage()
    }
    
    private func setupNavigationTitleContainer()
    {
        self.navigationItemsContainer = NavigationTitleContainer(name: viewModel._title, lastSeen: viewModel._status)
        viewController.navigationItem.titleView = self.navigationItemsContainer
    }
    
    private func setuoNavigationImage()
    {
        var image: UIImage?
        
        if let imgUrl = viewModel._imageUrl,
            let imageData = viewModel.getImageFromCache(imgUrl) {
            image = UIImage(data: imageData)
        } else {
            image = UIImage(named: "default_profile_photo")
        }
        let imageView = NavigationProfileImageView(image: image)
        let barButtonItem = UIBarButtonItem(customView: imageView)
        
        viewController.navigationItem.rightBarButtonItem = barButtonItem
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
                self?.navigationItemsContainer?.titleLabel.text = status
            }.store(in: &cancellables)
        
        viewModel.$_title
            .compactMap({$0})
            .sink { [weak self] title in
                self?.navigationItemsContainer?.statusLabel.text = title
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
            
            statusLabel.text = lastSeen == "online" ? lastSeen : "last seen \(lastSeen)"
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


final class ChatRoomNavigationBarViewModel
{
    private var cancellables: Set<AnyCancellable> = []
    
    @Published private(set) var _title: String?
    @Published private(set) var _status: String?
    @Published private(set) var _imageUrl: String?
    
    init(dataProvider: NavigationBarDataProvider)
    {
        switch dataProvider {
        case .chat(let chat): setNavigationItems(usingChat: chat)
        case .user(let user): setNavigationItems(usingUser: user)
        }
        
        addListener(to: dataProvider)
    }
    
    private func addListener(to objectDataProvider: NavigationBarDataProvider)
    {
        switch objectDataProvider {
        case .chat(let chat): addConversationListener(chat)
        case .user(let user): addParticipantListener(user)
        }
    }

    // MARK: - Listeners
    ///
    private func addConversationListener(_ conversation: Chat)
    {
        FirebaseChatService.shared.singleChatPublisher(for: conversation.id)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] chatUpdate in
                switch chatUpdate.changeType {
                case .modified: self?.setNavigationItems(usingChat: chatUpdate.data)
                default: break
                }
            }.store(in: &cancellables)
    }
    
    private func addParticipantListener(_ participant: User)
    {
        FirestoreUserService.shared.addListenerToUsers([participant.id])
            .receive(on: DispatchQueue.main)
            .sink { [weak self] userUpdate in
                switch userUpdate.changeType {
                case .modified: self?.setNavigationItems(usingUser: userUpdate.data)
                default: break
                }
            }.store(in: &cancellables)
    }
    
    // MARK: - Navigation items set
    ///
    private func setNavigationItems(usingChat chat: Chat)
    {
        if chat.name != self._title {
            self._title = chat.name
        }
        
        if chat.thumbnailURL != self._imageUrl {
            self._imageUrl = chat.thumbnailURL
        }
        
        let chatStatus = "\(chat.participants.count) participants"
        if chatStatus != _status {
            _status = chatStatus
        }
    }
    
    private func setNavigationItems(usingUser user: User)
    {
        if user.name != self._title {
            self._title = user.name
        }
        
        if user.photoUrl != self._imageUrl {
            self._imageUrl = user.photoUrl
        }

        if user.isActive == true {
            self._status = "Online"
        } else {
            self._status = "last seen \(user.lastSeen?.formatToYearMonthDayCustomString() ?? "Recently")"
        }
    }
}

//MARK: - cache
extension ChatRoomNavigationBarViewModel
{
    func getImageFromCache(_ url: String) -> Data? {
        return CacheManager.shared.retrieveImageData(from: url)
    }
}

enum NavigationBarDataProvider {
    case chat(Chat)
    case user(User)
    
    var provider: Any {
        switch self {
        case .chat(let chat): return chat
        case .user(let user): return user
        }
    }
}

enum NavigationItemChangeField: String
{
    case name
    case photoUrl
    case isActive
    case lastSeen
    case thumbnailURL
}



//extension ChatRoomNavigationBarViewModel {
//    var members: [User] {
//        let participants = Array( conversation?.participants.map { $0.userID } ?? [] )
//        let filter = NSPredicate(format: "id IN %@", argumentArray: participants)
//        let users = RealmDataBase.shared.retrieveObjects(ofType: User.self, filter: filter)?.toArray()
//        return users ?? []
//    }
//}
