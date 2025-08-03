//
//  Untitled.swift
//  ChatUpp
//
//  Created by Andrei Pripa on 4/12/25.
//

import Foundation
import Combine

final class ChatRoomNavigationBarViewModel
{
    private var cancellables: Set<AnyCancellable> = []
    
    @Published private(set) var _title: String?
    @Published private(set) var _status: String?
    @Published private(set) var _imageUrl: String?
    
    private(set) var dataProvider: NavigationBarDataProvider
    private(set) var isGroup: Bool = false
    
    init(dataProvider: NavigationBarDataProvider)
    {
        self.dataProvider = dataProvider
        
        switch dataProvider {
        case .chat(let chat): setNavigationItems(usingChat: chat); isGroup = chat.isGroup
        case .user(let user): setNavigationItems(usingUser: user); isGroup = false
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
        
        RealtimeUserService.shared.addObserverToUsers(participant.id)
            .sink { [weak self] user in
                self?._status = (user.isActive ?? false) ? "Online" : "last seen \(user.lastSeen?.formatToYearMonthDayCustomString() ?? "Recently")"
            }.store(in: &cancellables)
        
//        RealmDataBase.shared.observeChanges(for: participant)
//            .receive(on: DispatchQueue.main)
//            .sink { (changeType, object) in
//                if changeType.name == "isActive"
//                {
//                    guard let isActive = changeType.newValue as? Bool else {return}
//                    self._status = isActive ? "Online" : "last seen \(participant.lastSeen?.formatToYearMonthDayCustomString() ?? "Recently")"
//                }
//            }.store(in: &cancellables)
    }
    
    // MARK: - Navigation items set
    ///
    private func setNavigationItems(usingChat chat: Chat)
    {
        if chat.name != self._title {
            self._title = chat.name
        }
        
        if chat.thumbnailURL != self._imageUrl {
            self._imageUrl = getThumbnailImagePath(from: chat.thumbnailURL)
//            self._imageUrl = chat.thumbnailURL
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
            self._imageUrl = getThumbnailImagePath(from: user.photoUrl)
//            self._imageUrl = user.photoUrl
        }

        /// Currently will not receive updates (blaze plan needs to be active in firebase).
        if user.isActive == true {
            self._status = "Online"
        } else {
            self._status = "last seen \(user.lastSeen?.formatToYearMonthDayCustomString() ?? "Recently")"
        }
    }
    
    private func getThumbnailImagePath(from url: String?) -> String?
    {
        guard let originalURL = url else {return nil}
        return originalURL.addSuffix("medium")
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
