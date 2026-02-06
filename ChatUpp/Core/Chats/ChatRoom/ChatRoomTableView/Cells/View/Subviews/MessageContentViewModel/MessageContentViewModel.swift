//
//  MessageContainerViewModel.swift
//  ChatUpp
//
//  Created by Andrei Pripa on 8/15/25.
//

import Foundation
import Combine

//MARK: - View model for all types (text/image/audio...) of messages 

final class MessageContentViewModel
{
    @Published private(set) var updatedText: String?
    
    @Published private(set) var message: Message?
    @Published private(set) var referencedMessage: Message?
    private(set) var messagePropertyUpdateSubject: PassthroughSubject = PassthroughSubject<MessageObservedProperty, Never>()
    
    private(set) var messageImageDataSubject = PassthroughSubject<Data, Never>()
    private var cancellables: Set<AnyCancellable> = []
    
    private(set) var messageComponentsViewModel: MessageComponentsViewModel!
    
    convenience init(message: Message)
    {
        self.init()
        self.message = message
        
        self.observeMainMessage()
        self.messageComponentsViewModel = .init(message: message,
                                                context: messageAlignment == .right ? .outgoing : .incoming)
        self.setupComponents(from: message)
    }

    lazy var messageSender: User? = {
        guard let key = message?.senderId else { return nil }
        return RealmDatabase.shared.retrieveSingleObject(ofType: User.self, primaryKey: key)
    }()
    
    /// use computed property cause name can change
    var referencedMessageSenderName: String?
    {
        guard let referencedMessageID = referencedMessage?.senderId else { return nil }
        
        let user = RealmDatabase.shared.retrieveSingleObject(ofType: User.self,
                                                             primaryKey: referencedMessageID)
        return user?.name
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
    func getTextForReplyToMessage() -> String
    {
        switch referencedMessage?.type
        {
        case .image: return "Photo"
        case .imageText, .text: return referencedMessage?.messageBody ?? ""
        case .sticker: return "Sticker"
        case .audio: return "Voice Message"
        default: return ""
        }
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
        let referencedMessage = RealmDatabase.shared.retrieveSingleObject(
            ofType: Message.self,
            primaryKey: messageID
        )
        self.referencedMessage = referencedMessage
    }
    
    func getImageDataThumbnailFromReferencedMessage() -> Data?
    {
        switch referencedMessage?.type
        {
        case .image, .imageText: return retrieveReferencedImageData()
        case .sticker:
            if let stickerName = referencedMessage?.sticker
            {
                return getStickerThumbnail(name: stickerName + "_thumbnail")
            }
        default: return nil
        }
        return nil
    }
    
    @MainActor func getImageDataThumbnailFromMessage() -> Data?
    {
        switch message?.type
        {
        case .image, .imageText: return retrieveImageData()
        case .sticker:
            if let stickerName = message?.sticker
            {
                return getStickerThumbnail(name: stickerName + "_thumbnail")
            }
        default: return nil
        }
        return nil
    }
    
    private func getStickerThumbnail(name: String) -> Data?
    {
        guard let url = Bundle.main.url(forResource: name, withExtension: "png") else
        { return nil }
        return try? Data(contentsOf: url)
    }
}

//MARK: - Image fetch
extension MessageContentViewModel
{
    @MainActor
    func fetchMessageImageData()
    {
        guard let message = message, let imgatePath = message.imagePath else { return }
        Task {
            let imageData = try await FirebaseStorageManager.shared.getImage(from: .message(.image(message.id)),
                                                                             imagePath: imgatePath)
            cacheImage(data: imageData)
            messageImageDataSubject.send(imageData)
        }
    }
}


//MARK: - Image cache
extension MessageContentViewModel
{
    func cacheImage(data: Data)
    {
        guard let path = message?.imagePath else {return}
        CacheManager.shared.saveData(data, toPath: path)
    }
    
    @MainActor
    func retrieveImageData() -> Data?
    {
        guard let path = message?.imagePath else {return nil}
        return CacheManager.shared.retrieveData(from: path)
    }
    
    func retrieveReferencedImageData() -> Data?
    {
        guard let imagePath = referencedMessage?.imagePath?.addSuffix("small") else {return nil}
        return CacheManager.shared.retrieveData(from: imagePath)
    }
}

//MARK: Main Message listener
extension MessageContentViewModel
{
    private func observeMainMessage()
    {
        guard let message = self.message else {return}
        
        /// message on creation is added to realm after this object is initiated, so check and delay observer
        if message.realm == nil {
            Task { @MainActor in
                try await Task.sleep(for: .seconds(0.3))
                self.observeMainMessage()
            }
            return
        }
        
        RealmDatabase.shared.observerObject(message, keyPaths: Message.observableKeyPaths)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] objectUpdate in
                guard let self else {return}
                
                switch objectUpdate
                {
                case .changed(object: let object, property: let properties):
                    properties.forEach { property in
                        
                        guard let messageProperty = MessageObservedProperty(from: property.name,
                                                                     newValue: property.newValue) else {return}
                        self.messagePropertyUpdateSubject.send(messageProperty)
                    }
                default: break
                }
                
            }.store(in: &cancellables)
    }
}

//MARK: Reply to message listener
extension MessageContentViewModel
{
    private func observeReplyToMessage()
    {
        guard let replyMessage = referencedMessage else {return}
        RealmDatabase.shared.observerObject(replyMessage)
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
                case .deleted:
                    self.referencedMessage = nil
                }
            }.store(in: &cancellables)
    }
}
