
//  ConversationCellViewModel.swift
//  ChatUpp
//
//  Created by Andrei Pripa on 11/22/23.
//

import Foundation
import Combine

extension MessageCellViewModel: Hashable
{
    static func ==(lhs: MessageCellViewModel, rhs: MessageCellViewModel) -> Bool
    {
        return lhs.id == rhs.id
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

final class MessageCellViewModel
{
    let id = UUID()
    
    @Published private(set) var message: Message?
    
    private(set) var messageContainerViewModel: MessageContainerViewModel?
    
    private(set) var displayUnseenMessagesTitle: Bool?
    private(set) var senderImageDataSubject = PassthroughSubject<Data, Never>()
    private var cancellables: Set<AnyCancellable> = []
    
    convenience init(message: Message) {
        self.init()
        self.message = message
        
        self.messageContainerViewModel = MessageContainerViewModel(message: message)
    }
    
    deinit
    {
        print("MessageCellViewModel dienit")
    }
    
    convenience init(isUnseenCell: Bool) {
        self.init()
        self.displayUnseenMessagesTitle = isUnseenCell
    }
    
    lazy var messageSender: User? = {
        guard let key = message?.senderId else { return nil }
        return RealmDataBase.shared.retrieveSingleObject(ofType: User.self, primaryKey: key)
    }()
    
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
    
    func updateMessage(_ message: Message)
    {
        self.message = message
    }
    
}

//MARK: - Image cache
extension MessageCellViewModel
{
    func retrieveSenderAvatarData(ofSize size: String) -> Data?
    {
        guard var path = messageSender?.photoUrl else {return nil}
        path = path.addSuffix(size)
        return CacheManager.shared.retrieveImageData(from: path)
    }
}

//extension MessageCellViewModel
//{
    enum MessageAlignment {
        case left
        case right
        case center
    }
//}
