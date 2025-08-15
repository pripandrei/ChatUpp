//
//  MessageContainerViewModel.swift
//  ChatUpp
//
//  Created by Andrei Pripa on 8/15/25.
//

import Foundation
import Combine

final class MessageContainerViewModel
{
    @Published private(set) var message: Message?
    @Published private(set) var referencedMessage: Message?
    
    private(set) var messageImageDataSubject = PassthroughSubject<Data, Never>()
    private var cancellables: Set<AnyCancellable> = []
    
    convenience init(message: Message)
    {
        self.init()
        self.message = message
        
        self.setupComponents(from: message)
    }

    lazy var messageSender: User? = {
        guard let key = message?.senderId else { return nil }
        return RealmDataBase.shared.retrieveSingleObject(ofType: User.self, primaryKey: key)
    }()
    
    /// use computed property cause name can change
    var referencedMessageSenderName: String?
    {
        guard let referencedMessageID = referencedMessage?.senderId else { return nil }
        
        let user = RealmDataBase.shared.retrieveSingleObject(ofType: User.self,
                                                             primaryKey: referencedMessageID)
        return user?.name
    }
    
    var timestamp: String? {
        let hoursAndMinutes = message?.timestamp.formatToHoursAndMinutes()
        return hoursAndMinutes
    }
    
    var isReplayToMessage: Bool {
        guard referencedMessageSenderName != nil,
              referencedMessage != nil else {return false}
        return true
    }
    
    var resizedMessageImagePath: String? {
        guard let path = message?.imagePath else {return nil}
        return path.replacingOccurrences(of: ".jpg", with: "_resized_test_2.jpg")
    }
    
    var messageAlignment: MessageAlignment
    {
        if message?.type == .title {
            return .center
        }
        let authUserID = AuthenticationManager.shared.authenticatedUser?.uid
        return message?.senderId == authUserID ? .right : .left
    }
    
    /// private functions

    private func setupComponents(from message: Message)
    {
        if let repliedToMessageID = message.repliedTo {
            setReferencedMessage(usingMessageID: repliedToMessageID)
            observeReplyToMessage()
        }
    }
    
    private func setReferencedMessage(usingMessageID messageID: String)
    {
        let referencedMessage = RealmDataBase.shared.retrieveSingleObject(
            ofType: Message.self,
            primaryKey: messageID
        )
        self.referencedMessage = referencedMessage
    }
}

//MARK: - Image fetch
extension MessageContainerViewModel
{
    @MainActor
    func fetchMessageImageData()
    {
        guard let message = message, let imgatePath = message.imagePath else { return }
        Task {
            let imageData = try await FirebaseStorageManager.shared.getImage(from: .message(message.id),
                                                                             imagePath: imgatePath)
            cacheImage(data: imageData)
            messageImageDataSubject.send(imageData)
        }
    }
}

//MARK: - Image cache
extension MessageContainerViewModel
{
    func cacheImage(data: Data)
    {
        guard let path = message?.imagePath else {return}
        CacheManager.shared.saveImageData(data, toPath: path)
    }
    
    @MainActor
    func retrieveImageData() -> Data?
    {
        guard let path = message?.imagePath else {return nil}
        return CacheManager.shared.retrieveImageData(from: path)
    }
    
    func retrieveReferencedImageData() -> Data?
    {
        guard let imagePath = referencedMessage?.imagePath?.addSuffix("small") else {return nil}
        return CacheManager.shared.retrieveImageData(from: imagePath)
    }
}

//MARK: Reply to message listener
extension MessageContainerViewModel
{
    private func observeReplyToMessage()
    {
        guard let replyMessage = referencedMessage else {return}
        RealmDataBase.shared.observerObject(replyMessage)
            .sink { [weak self] objectUpdate in
                guard let self else { return }
                
                switch objectUpdate {
                case .changed(object: let object, property: let properties):
                    properties.forEach { property in
                        if property.name == "messageBody" || property.name == "imagePath"
                        {
                            self.referencedMessage = object as? Message
                        }
                    }
                case .deleted: self.referencedMessage = nil
                }
            }.store(in: &cancellables)
    }
}












/// This currently is not in use,
/// but dont remove before implementing message seen status feature in chatRoomVC
///
//MARK: - realm/firestore message update

extension MessageContainerViewModel
{
    @MainActor
    func updateFirestoreMessageSeenStatus(by userID: String? = nil,
                                          from chatID: String) async
    {
        guard let messageID = message?.id else {return}
        
        Task.detached {
            do {
                guard let userID = userID else {
                    try await FirebaseChatService.shared.updateMessageSeenStatus(messageID: messageID, chatID: chatID)
                    return
                }
                try await FirebaseChatService.shared.updateMessageSeenStatus(by: userID, messageID: messageID, chatID: chatID)
            } catch {
                print("Error updating message seen status in Firestore: ", error.localizedDescription)
            }
        }
    }
    
    @MainActor
    func updateFirestoreMessageSeenStatusTest(by userID: String? = nil,
                                              from chatID: String) async
    {
        guard let messageID = message?.id else {return}
        
        Task.detached {
            do {
                guard let userID = userID else {
                    try await FirebaseChatService.shared.updateMessageSeenStatusTest(messageID: messageID, chatID: chatID)
                    return
                }
                try await FirebaseChatService.shared.updateMessageSeenStatus(by: userID, messageID: messageID, chatID: chatID)
            } catch {
                print("Error updating message seen status in Firestore: ", error.localizedDescription)
            }
        }
    }
    
    func updateRealmMessageSeenStatus(by userID: String? = nil)
    {
        guard let messageID = message?.id else {return}
        
        Task.detached
        {
            guard let message = RealmDataBase.shared.retrieveSingleObjectTest(ofType: Message.self, primaryKey: messageID) else {return}
            
            RealmDataBase.shared.updateTest(object: message) { message in
                if let id = userID {
                    message.seenBy.append(id)
                } else {
                    message.messageSeen = true
                }
            }
        }
    }
    
    func updateRealmMessageSeenStatusTest(by userID: String? = nil)
    {
        guard let messageID = message?.id else {return}
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 5.1) {
            Task.detached
            {
                guard let message = RealmDataBase.shared.retrieveSingleObjectTest(ofType: Message.self, primaryKey: messageID) else {return}
                
                RealmDataBase.shared.updateTest(object: message) { message in
                    if let id = userID {
                        message.seenBy.append(id)
                    } else {
                        message.messageSeen = false
                    }
                }
            }
        }
    }
}
