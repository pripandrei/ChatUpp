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
    
    init(viewController: UIViewController, viewModel: ChatRoomNavigationBarViewModel) {
        self.viewController = viewController
        self.viewModel = viewModel
        setupNavigationBarItems()
        self.bind()
        
    }
    
    private func setupNavigationContainer() {
        self.navigationItemsContainer = NavigationTitleContainer(name: viewModel.title, lastSeen: viewModel.status)
        viewController.navigationItem.titleView = self.navigationItemsContainer
    }
    
    private func setupNavigationBarItems()
    {
        setupNavigationContainer()
        
        var image: UIImage?
        
        if let imageData = viewModel.getImageFromCache(viewModel.imageUrl) {
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

extension ChatRoomNavigationBar
{
    final class NavigationTitleContainer: UIView {
        let titleLabel: UILabel
        let statusLabel: UILabel
        
        private var temporaryDimmView: UIView!
        private var temporaryImageView: UIView!
        
        init(name: String, lastSeen: String) {
            titleLabel = UILabel()
            statusLabel = UILabel()
            
            super.init(frame: .zero)
            
            setupViews(name: name, lastSeen: lastSeen)
        }
        
        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
        
        private func setupViews(name: String, lastSeen: String) {
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
    private var conversation: Chat?
    private var participant: User?
    private var cancellables: Set<AnyCancellable> = []
    
    @Published var _title: String?
    @Published var _status: String?
    @Published var _imageUrl: String?

    init(conversation: Chat?) {
        self.conversation = conversation
        updateNavItems(withChat: conversation!)
        addListener()
//        setNavigationBarItems()
//        observeItemsChanges()
    }
    
    init(participant: User?)
    {
        self.participant = participant
        updateNavItems(withUser: participant!)
        addListener()
//        if let participant = participant {
//            self.participant = participant
//        } else {return nil}
//        setNavigationBarItems()
//        observeItemsChanges()
    }
    
    
    private func addListener()
    {
        if let conversation = self.conversation
        {
            addConversationListener(conversation)
        }
        else if let participant = self.participant
        {
            addParticipantListener(participant)
        }
    }
    
    private func addConversationListener(_ conversation: Chat)
    {
        FirebaseChatService.shared.singleChatPublisher(for: conversation.id)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] chatUpdate in
                switch chatUpdate.changeType {
                case .modified: self?.updateNavItems(withChat: chatUpdate.data)
                default: break
                }
            }.store(in: &cancellables)
    }
    
    private func addParticipantListener(_ participant: User)
    {
        
    }
    
    private func updateNavItems(withChat updatedChat: Chat)
    {
        if updatedChat.name != self._title {
            self._title = updatedChat.name
        }
        
        if updatedChat.thumbnailURL != self._imageUrl {
            self._imageUrl = updatedChat.thumbnailURL
        }
        
        let updatedChatStatus = "\(updatedChat.participants.count) participants"
        if updatedChatStatus != status {
            _status = updatedChatStatus
        }
    }
    
    private func updateNavItems(withUser updatedUser: User)
    {
        if updatedUser.name != self._title {
            self._title = updatedUser.name
        }
        
        if updatedUser.photoUrl != self._imageUrl {
            self._imageUrl = updatedUser.photoUrl
        }
        
        if updatedUser.isActive != self.participant?.isActive
        {
            if updatedUser.isActive == true {
                self._status = "Online"
            } else {
                self._status = updatedUser.lastSeen?.formatToYearMonthDayCustomString()
            }
        }
    }
    
    
    
    
    private func setNavigationBarItems() {
        self._title = title
        self._status = status
        self._imageUrl = imageUrl
    }
    
    var otherParticipant: User?
    {
        guard let authUser = try? AuthenticationManager.shared.getAuthenticatedUser(),
              let participant = conversation?.participants.first(where: { $0.userID != authUser.uid })else {return nil}
        let user = RealmDataBase.shared.retrieveSingleObject(ofType: User.self, primaryKey: participant.userID)
        return user
    }
    
    var title: String
    {
        get {
            return conversation?.name ?? otherParticipant?.name ?? "Unknown"
        }
        set {
            self._title = newValue
        }
    }
    
    
    var status: String {
        get {
            if conversation?.isGroup == true {
                return "\(conversation?.participants.count ?? 0) participants"
            }
            
            return getParticipantStatus(user: otherParticipant) ?? "last seen recently"
        }
        set {
            self._status = newValue
        }
    }
    
    var imageUrl: String {
        get {
            if conversation?.isGroup == true {
                return conversation?.thumbnailURL ?? "default_profile_photo"
            }
            return otherParticipant?.photoUrl ?? "default_profile_photo"
        }
        set {
            _imageUrl = newValue
        }
    }
    
    private func getParticipantStatus(user: User?) -> String?
    {
        if user?.isActive == true {
            return "Online"
        }
        return user?.lastSeen?.formatToYearMonthDayCustomString()
    }
    
    private func observeItemsChanges()
    {
        guard let conversation = conversation else {return}
        guard let observeObject = conversation.isGroup ? conversation : otherParticipant else {return}
        
        RealmDataBase.shared.observeChanges(for: observeObject)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] change in
                self?.updateField(changedField: NavigationItemChangeField(rawValue: change.name), typeChangeValue: change.newValue)
            }
            .store(in: &cancellables)
    }
    
    private func updateField(changedField: NavigationItemChangeField?, typeChangeValue: Any?)
    {
        guard let field = changedField else {return}
        
        switch field {
        case .name:
            if let value = typeChangeValue as? String {
                self.title = value
            }
        case .photoUrl:
            if let value = typeChangeValue as? String {
                self.imageUrl = value
            }
        case .isActive:
            if let status = typeChangeValue as? Bool {
                self._status = status ? "Online" : "last seen recently"
            }
        case .lastSeen:
            self.status = (typeChangeValue as? Date)?.formatToYearMonthDayCustomString() ?? self.status
        case .thumbnailURL:
            if let value = typeChangeValue as? String {
                self.imageUrl = value
            }
        }
    }
}

//MARK: - cache retrieve
extension ChatRoomNavigationBarViewModel
{
    func getImageFromCache(_ url: String) -> Data? {
        return CacheManager.shared.retrieveImageData(from: url)
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



extension ChatRoomNavigationBarViewModel {
    var members: [User] {
        let participants = Array( conversation?.participants.map { $0.userID } ?? [] )
        let filter = NSPredicate(format: "id IN %@", argumentArray: participants)
        let users = RealmDataBase.shared.retrieveObjects(ofType: User.self, filter: filter)?.toArray()
        return users ?? []
    }
}
