
//  ConversationCellViewModel.swift
//  ChatUpp
//
//  Created by Andrei Pripa on 11/22/23.
//

import Foundation
import Combine

final class MessageCellViewModel
{
    @Published private(set) var imagePathURL: URL?
    @Published private(set) var message: Message?
    
    @Published private(set) var senderName: String?
    
    private(set) var referencedMessage: Message?
    private(set) var displayUnseenMessagesTitle: Bool?
    private(set) var messageImageDataSubject = PassthroughSubject<Data, Never>()
    private(set) var senderImageDataSubject = PassthroughSubject<Data, Never>()
    
    convenience init(message: Message) {
        self.init()
        self.message = message
        
//        self.setupComponents(from: message)
    }
    
    convenience init(isUnseenCell: Bool) {
        self.init()
        self.displayUnseenMessagesTitle = isUnseenCell
    }
    
    lazy var messageSender: User? = {
        guard let key = message?.senderId else { return nil }
        return RealmDataBase.shared.retrieveSingleObject(ofType: User.self, primaryKey: key)
    }()
    
    var referencedMessageSenderName: String?
    {
        guard let referencedMessageID = referencedMessage?.senderId else { return nil }
        
        let user = RealmDataBase.shared.retrieveSingleObject(ofType: User.self, primaryKey: referencedMessageID)
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
    
    /// internal functions
    ///
    
    func getModifiedValueOfMessage(_ newMessage: Message) -> MessageValueModification?
    {
        if message?.messageBody != newMessage.messageBody {
            return .text
        } else if message?.messageSeen != newMessage.messageSeen {
            return .seenStatus
        } else if message?.reactions.count != newMessage.reactions.count {
            return .reactions
        }
        return nil
    }
    
    //Test ---
    
    private func setupComponents(from message: Message)
    {
        if let repliedToMessageID = message.repliedTo {
            setReferencedMessage(usingMessageID: repliedToMessageID)
        }
        
        if message.type == .title {
            setMessageSenderName()
        }
    }
    
    private func setReferencedMessage(usingMessageID messageID: String)
    {
        let referencedMessage = RealmDataBase.shared.retrieveSingleObject(ofType: Message.self, primaryKey: messageID)
        self.referencedMessage = referencedMessage
    }
    
    private func setMessageSenderName()
    {
        guard let senderName = messageSender?.name
        else
        {
            Task {
                do {
                    self.senderName = try await fetchMessageSender().name
                } catch {
                    print("Error fetching sender from message: \(error)")
                }
            }
            return
        }
        self.senderName = senderName
    }
    
    @MainActor
    private func fetchMessageSender() async throws -> User
    {
        return try await FirestoreUserService.shared.getUserFromDB(userID: message!.senderId) // this function is called from init with non nil message value, so yes, we can use !
    }
}

//MARK: - Image fetch
extension MessageCellViewModel
{
    @MainActor
    func fetchMessageImageData()
    {
        guard let message = message, let imgatePath = message.imagePath else { return }
        Task {
            let imageData = try await FirebaseStorageManager.shared.getImage(from: .message(message.id), imagePath: imgatePath)
            cacheImage(data: imageData)
            messageImageDataSubject.send(imageData)
        }
    }
    
    func fetchSenderAvatartImageData()
    {
        guard let user = messageSender, var path = messageSender?.photoUrl else { return }
        Task { @MainActor in
            path = path.addSuffix("medium")
            let imageData = try await FirebaseStorageManager.shared.getImage(from: .user(user.id), imagePath: path)
            cacheImage(data: imageData)
            senderImageDataSubject.send(imageData)
        }
    }
    
//    @MainActor
//    func getImagePathURL() async throws -> URL?
//    {
//        guard let message = self.message,
//              let imagePath = message.imagePath else { return nil }
//        let url = try await FirebaseStorageManager.shared.getImageURL(from: .message(message.id), imagePath: imagePath)
//        return url
//    }
}

//MARK: - Image cache
extension MessageCellViewModel
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

    func retrieveSenderAvatarData(ofSize size: String) -> Data?
    {
        guard var path = messageSender?.photoUrl else {return nil}
        path = path.replacingOccurrences(of: ".jpg", with: "_\(size).jpg")
        return CacheManager.shared.retrieveImageData(from: path)
    }
}


//MARK: - realm/firestore message update

extension MessageCellViewModel
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


extension MessageCellViewModel
{
    func getCellAspectRatio(forImageSize size: CGSize) -> CGSize
    {
        let aspectRatio = size.width / size.height
        
        if aspectRatio > 1 {
            // Landscape: fit to width
            return CGSize(width: 270, height: 270 / aspectRatio)
        } else if aspectRatio < 1 {
            // Portrait: fit to height
            return CGSize(width: 320 * aspectRatio, height: 320)
        } else {
            // Square
            return CGSize(width: 250, height: 250)
        }
    }
}

extension MessageCellViewModel
{
    enum MessageAlignment {
        case left
        case right
        case center
    }
}



//    func retrieveSenderAvatar() -> Data?
//    {
//        guard var path = message?.imagePath else {return nil}
//
//        let mediumSizeImagePath = path.replacingOccurrences(of: ".jpg", with: "_medium.jpg")
//        let smallSizeImagePath = path.replacingOccurrences(of: ".jpg", with: "_small.jpg")
//
//        if let imageData = CacheManager.shared.retrieveImageData(from: mediumSizeImagePath) {
//            return imageData
//        }
//
//        Task { await fetchImageData() }
//
//        if let imageData = CacheManager.shared.retrieveImageData(from: smallSizeImagePath) {
//            return imageData
//        }
//
//        return nil
//    }
//
//    func editMessageTextFromFirestore(_ messageText: String, from chatID: String) {
//        Task {
//            try await ChatsManager.shared.updateMessageText(messageText, messageID: cellMessage.id, chatID: chatID)
//        }
//    }
//
//    func deleteMessageFromFirestore(from chatID: String) {
//        Task {
//            do {
//                try await ChatsManager.shared.removeMessage(messageID: cellMessage.id, conversationID: chatID)
//            } catch {
//                print("Error deleting message: ",error.localizedDescription)
//            }
//        }
//    }
