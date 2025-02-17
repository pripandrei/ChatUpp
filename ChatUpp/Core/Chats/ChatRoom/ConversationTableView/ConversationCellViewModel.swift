//
//  ConversationCellViewModel.swift
//  ChatUpp
//
//  Created by Andrei Pripa on 11/22/23.
//

import Foundation
import Combine

//enum ConversationCellType {
//    case message(content: ConversationCellViewModel)
//    case unseenMessagesTitle
//}

final class ConversationCellViewModel
{
    var messageImageDataSubject = PassthroughSubject<Data?, Never>()
    var senderImageDataSubject = PassthroughSubject<Data?, Never>()

    @Published var imagePathURL: URL?
    
    @Published var message: Message?
    var messageToBeReplied: Message?
    var (senderNameOfMessageToBeReplied, textOfMessageToBeReplied): (String?, String?)
    
    var displayUnseenMessagesTitle: Bool?
    
    convenience init(message: Message) {
        self.init()
        self.message = message
    }
    
    convenience init(isUnseenCell: Bool) {
        self.init()
        self.displayUnseenMessagesTitle = isUnseenCell
    }
    
    var timestamp: String? {
        let hoursAndMinutes = message?.timestamp.formatToHoursAndMinutes()
        return hoursAndMinutes
    }
    
    lazy var messageSender: User? = {
        guard let key = message?.senderId else {return nil}
        return RealmDataBase.shared.retrieveSingleObject(ofType: User.self, primaryKey: key)
    }()
    
    var isReplayToMessage: Bool {
        guard senderNameOfMessageToBeReplied != nil,
              textOfMessageToBeReplied != nil else {return false}
        return true
    }
    
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
        Task {
            path = path.replacingOccurrences(of: ".jpg", with: "_medium.jpg")
            let imageData = try await FirebaseStorageManager.shared.getImage(from: .user(user.id), imagePath: path)
            cacheImage(data: imageData)
            senderImageDataSubject.send(imageData)
        }
    }
    
    @MainActor
    func getImagePathURL() async throws -> URL?
    {
        guard let message = self.message,
                let imagePath = message.imagePath else { return nil }
        let url = try await FirebaseStorageManager.shared.getImageURL(from: .message(message.id), imagePath: imagePath)
        return url
    }
    
    func getModifiedValueOfMessage(_ newMessage: Message) -> MessageValueModification?
    {
        if message?.messageBody != newMessage.messageBody {
            return .text
        } else if message?.messageSeen != newMessage.messageSeen {
            return .seenStatus
        }
        return nil
    }
    
    func cacheImage(data: Data)
    {
        guard let path = message?.imagePath else {return}
        CacheManager.shared.saveImageData(data, toPath: path)
    }
    
    func retrieveImageData() -> Data?
    {
        guard let path = message?.imagePath else {return nil}
        return CacheManager.shared.retrieveImageData(from: path)
    }
    
//    func retrieveSenderAvatarData() -> Data?
//    {
//        guard let path = messageSender?.photoUrl else {return nil}
//        return CacheManager.shared.retrieveImageData(from: path)
//    }
    
    func retrieveSenderAvatarData(ofSize size: String) -> Data?
    {
        guard var path = messageSender?.photoUrl else {return nil}
        path = path.replacingOccurrences(of: ".jpg", with: "_\(size).jpg")
        return CacheManager.shared.retrieveImageData(from: path)
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
}


//MARK: - Message update in realm/firestore DB
extension ConversationCellViewModel
{
    @MainActor
    func updateFirestoreMessageSeenStatus(by userID: String? = nil, from chatID: String) async {
        guard let message = message else {return}
        do {
            guard let userID = userID else {
                try await FirebaseChatService.shared.updateMessageSeenStatus(messageID: message.id, chatID: chatID)
                return
            }
            try await FirebaseChatService.shared.updateMessageSeenStatus(by: userID, messageID: message.id, chatID: chatID)
        } catch {
            print("Error updating message seen status in Firestore: ", error.localizedDescription)
        }
    }
    
    func updateRealmMessageSeenStatus(by userID: String? = nil)
    {
        guard let message = message else {return}
        
        RealmDataBase.shared.update(object: message) { message in
            if let id = userID {
                message.seenBy.append(id)
            } else {
                message.messageSeen = true
            }
        }
    }
}


extension ConversationCellViewModel
{
    func getCellAspectRatio(forImageSize size: CGSize) -> CGSize 
    {
        let (equalWidth, equalHeight) = (250,250)
        
        let preferredWidth: Double = 270
        let preferredHeight: Double = 320
        
        let aspectRatioForWidth = Double(size.width) / Double(size.height)
        let aspectRatioForHeight = Double(size.height) / Double(size.width)
        
        if size.width > size.height {
            let newHeight = preferredWidth / aspectRatioForWidth
            return CGSize(width: preferredWidth , height: newHeight)
        } else if size.height > size.width {
            let newWidth = preferredHeight / aspectRatioForHeight
            return CGSize(width: newWidth , height: preferredHeight)
        } else {
            return CGSize(width: equalWidth, height: equalHeight)
        }
    }
}

