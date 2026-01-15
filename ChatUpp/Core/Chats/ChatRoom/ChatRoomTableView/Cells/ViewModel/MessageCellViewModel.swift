
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
    
    private(set) var messageContainerViewModel: MessageContentViewModel?
    
    private(set) var displayUnseenMessagesTitle: Bool?
    private(set) var senderImageDataSubject = PassthroughSubject<Data, Never>()
    private var cancellables: Set<AnyCancellable> = []
    
    private(set) var visibilitySenderAvatarSubject = PassthroughSubject<Bool, Never>()
    
    convenience init(message: Message) {
        self.init()
        self.message = message
        
        self.messageContainerViewModel = MessageContentViewModel(message: message)
    }
    
    convenience init(isUnseenCell: Bool) {
        self.init()
        self.displayUnseenMessagesTitle = isUnseenCell
    }
    
//    deinit
//    {
//        print("MessageCellViewModel deinit")
//    }
    
    lazy var messageSender: User? = {
        guard let key = message?.senderId else { return nil }
        return RealmDatabase.shared.retrieveSingleObject(ofType: User.self, primaryKey: key)
    }()
    
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
    
    func toggleVisibilityOfSenderAvatar(_ value: Bool)
    {
        let authUserID = try? AuthenticationManager.shared.getAuthenticatedUser().uid
        guard self.message?.senderId != authUserID else { return }
        visibilitySenderAvatarSubject.send(value)
    }
}

//MARK: - Image cache
extension MessageCellViewModel
{
    func retrieveSenderAvatarData(ofSize size: String) -> Data?
    {
        guard var path = messageSender?.photoUrl else {return nil}
        path = path.addSuffix(size)
        return CacheManager.shared.retrieveData(from: path)
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
