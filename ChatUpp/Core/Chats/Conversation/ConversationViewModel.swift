
//
//  ConversationViewModel.swift
//  ChatUpp
//
//  Created by Andrei Pripa on 10/3/23.
//

import Foundation
import Combine
import RealmSwift

enum MessageValueModification {
    case text
    case seenStatus
}

enum MessageChangeType {
    case modified(IndexPath, MessageValueModification)
    case added
    case removed
}

struct ConversationMessageGroups {
    let date: Date
    var cellViewModels: [ConversationCellViewModel]
}

//MARK: -

extension ConversationViewModel
{
    func setupConversationMessageGroups() {
        guard let messages = conversation?.getMessages() else { return }
        createMessageGroups(messages)
        firstNotSeenMessageIndex = self.findFirstNotSeenMessageIndex()
    }
}

final class ConversationViewModel {
    
    private(set) var conversation: Chat?
    private(set) var memberProfileImage: Data?
    private(set) var messageGroups: [ConversationMessageGroups] = []
    private(set) var (userListener,messageListener): (Listener?, Listener?)
    private(set) var userObserver: RealtimeDBObserver?
    private(set) var authenticatedUserID: String = (try! AuthenticationManager.shared.getAuthenticatedUser()).uid
    private(set) var isSkeletonAnimationActive: Bool = false
    
    @Published private(set) var userMember: DBUser
    @Published var messageChangedType: MessageChangeType?
    @Published var firstNotSeenMessageIndex: IndexPath?
    
    var shouldEditMessage: ((String) -> Void)?
    var updateUnreadMessagesCount: (() async throws -> Void)?
    var currentlyReplyToMessageID: String?
    
    var conversationIsInitiated: Bool {
        return self.conversation != nil
    }
    
    init(userMember: DBUser, conversation: Chat? = nil, imageData: Data?) {
        self.userMember = userMember
        self.conversation = conversation
        self.memberProfileImage = imageData
        
        setupConversationMessageGroups()
        
        addListeners()
    }
    
    private func addListeners() {
        addListenerToMessages()
        addUsersListener()
        addUserObserver()
    }
    
    private func createChat() -> Chat
    {
        let chatId = UUID().uuidString
        let members = [authenticatedUserID, userMember.userId]
        let recentMessageID = messageGroups.first?.cellViewModels.first?.cellMessage.id
        return Chat(id: chatId, members: members, recentMessageID: recentMessageID)
    }
    
    private func addChatToFirestore(_ chat: Chat) async {
        do {
            try await ChatsManager.shared.createNewChat(chat: chat)
            addListenerToMessages()
        } catch {
            print("Error creating conversation", error.localizedDescription)
        }
    }
    
    private func createMessageGroups(_ messages: [Message]) {
        var tempMessageGroups: [ConversationMessageGroups] = messageGroups
        
        messages.forEach { message in
            addConversationCellViewModel(with: message, to: &tempMessageGroups)
        }
        self.messageGroups = tempMessageGroups
    }
    
    private func addConversationCellViewModel(with message: Message, to messageGroups: inout [ConversationMessageGroups])
    {
        guard let date = message.timestamp.formatToYearMonthDay() else { return }
        let conversationCellVM = ConversationCellViewModel(cellMessage: message)
        
        if let index = messageGroups.firstIndex(where: { $0.date == date })
        {
            messageGroups[index].cellViewModels.insert(conversationCellVM, at: 0)
        } else {
            let newGroup = ConversationMessageGroups(date: date, cellViewModels: [conversationCellVM])
            messageGroups.insert(newGroup, at: 0)
        }
    }
    
    private func fetchConversationMessages() {
        guard let conversation = conversation else {return}
        Task {
            do {
                let messages = try await ChatsManager.shared.getAllMessages(fromChatDocumentPath: conversation.id)
                createMessageGroups(messages)
                self.firstNotSeenMessageIndex = self.findFirstNotSeenMessageIndex()
//                delete()
            } catch {
                print("Could not fetch messages from db: ", error.localizedDescription)
            }
        }
    }
   
    private func createNewMessage(_ messageBody: String) -> Message {
        let messageID = UUID().uuidString
        
        return Message(id: messageID,
                       messageBody: messageBody,
                       senderId: authenticatedUserID,
                       timestamp: Date(),
                       messageSeen: false,
                       isEdited: false,
                       imagePath: nil,
                       imageSize: nil,
                       repliedTo: currentlyReplyToMessageID)
    }
    
    @MainActor
    private func addMessageToFirestoreDataBase(_ message: Message) async  {
        guard let conversation = conversation else {return}
        do {
            try await ChatsManager.shared.createMessage(message: message, atChatPath: conversation.id)
        } catch {
            print("error occur while trying to create message in DB: ", error.localizedDescription)
        }
    }
    
    @MainActor
    func updateRecentMessageFromFirestoreChat(messageID: String ) async {
        guard let chatID = conversation?.id else { print("chatID is nil") ; return}
        do {
            try await ChatsManager.shared.updateChatRecentMessage(recentMessageID: messageID, chatID: chatID)
        } catch {
            print("Error updating chat last message:", error.localizedDescription)
        }
    }
    
    func createConversationIfNeeded() {
        if !conversationIsInitiated 
        {
            let chat = createChat()
            conversation = chat
            addChatToRealm(chat)
            Task(priority: .high, operation: {
                await addChatToFirestore(chat)
            })
        }
    }
    
    func manageMessageCreation(_ messageText: String) 
    {
        let message = createNewMessage(messageText)
        
        resetCurrentReplyMessageIfNeeded()
        addMessageToRealmChat(message)
        createMessageGroups([message])
        
        Task { @MainActor in
            await addMessageToFirestoreDataBase(message)
            await updateRecentMessageFromFirestoreChat(messageID: message.id)
        }
    }
    
    func resetCurrentReplyMessageIfNeeded() {
        if currentlyReplyToMessageID != nil { 
            currentlyReplyToMessageID = nil
        }
    }
    
    private func findFirstNotSeenMessageIndex() -> IndexPath? {
        var indexOfNotSeenMessageToScrollTo: IndexPath?
        
        for (groupIndex, messageGroup) in messageGroups.enumerated()
        {
            for (viewModelIndex,conversationVM) in messageGroup.cellViewModels.enumerated()
            {
                if isUnseenMessagePresent(in: conversationVM) {
                    indexOfNotSeenMessageToScrollTo = IndexPath(item: viewModelIndex, section: groupIndex)
                } else {
                    return indexOfNotSeenMessageToScrollTo
                }
            }
        }
        return indexOfNotSeenMessageToScrollTo
    }

    private func isUnseenMessagePresent(in conversationVM: ConversationCellViewModel) -> Bool {
        let messageIsUnseen = !conversationVM.cellMessage.messageSeen
        let authUserIsNotOwnerOfMessage = conversationVM.cellMessage.senderId != authenticatedUserID
        
        if messageIsUnseen && authUserIsNotOwnerOfMessage { return true }
        else { return false }
    }
    
    func handleImageDrop(imageData: Data, size: MessageImageSize) {
        self.messageGroups.first?.cellViewModels.first?.imageData = imageData
        self.messageGroups.first?.cellViewModels.first?.cellMessage.imageSize = size
        self.saveImage(data: imageData, size: CGSize(width: size.width, height: size.height))
    }
    
    func saveImage(data: Data, size: CGSize) {
        guard let conversation = conversation else {return}
        guard let messageID = messageGroups.first?.cellViewModels.first?.cellMessage.id else {return}
        Task {
            let (path,name) = try await StorageManager.shared.saveMessageImage(data: data, messageID: messageID)
            try await ChatsManager.shared.updateMessageImagePath(messageID: messageID,
                                                                 chatDocumentPath: conversation.id,
                                                                 path: name)
            
            let imageSize = MessageImageSize(width: Int(size.width), height: Int(size.height))
            try await ChatsManager.shared.updateMessageImageSize(messageID: messageID, chatDocumentPath: conversation.id, imageSize: imageSize)
            print("Success saving image: \(path) \(name)")
        }
    }
    
    func deleteMessageFromFirestore(messageID: String) {
        Task {
            do {
                try await ChatsManager.shared.removeMessage(messageID: messageID, conversationID: conversation!.id)
            } catch {
                print("Error deleting message: ",error.localizedDescription)
            }
        }
    }
    
    @MainActor
    func editMessageTextFromFirestore(_ messageText: String, messageID: String) {
        Task {
            try await ChatsManager.shared.updateMessageText(messageText, messageID: messageID, chatID: conversation!.id)
        }
    }
    
    func getMessageSenderName(usingSenderID id: String) -> String? {
        guard let user = try? AuthenticationManager.shared.getAuthenticatedUser() else { return nil }
        if id == user.uid {
            return user.name
        } else {
            return userMember.name
        }
    }
    
    func getRepliedToMessage(messageID: String) -> Message? {
        var repliedMessage: Message?
        messageGroups.forEach { conversationGroups in
            conversationGroups.cellViewModels.forEach { conversationCellViewModel in
                if conversationCellViewModel.cellMessage.id == messageID {
                    repliedMessage = conversationCellViewModel.cellMessage
                    return
                }
            }
        }
        return repliedMessage
    }
    
    func setReplyMessageData(fromReplyMessageID id: String, toViewModel viewModel: ConversationCellViewModel) {
        if let messageToBeReplied = getRepliedToMessage(messageID: id) {
            let senderNameOfMessageToBeReplied = getMessageSenderName(usingSenderID: messageToBeReplied.senderId)
            
            (viewModel.senderNameOfMessageToBeReplied, viewModel.textOfMessageToBeReplied) = (senderNameOfMessageToBeReplied, messageToBeReplied.messageBody)
        }
    }
}

//MARK: - Messages listener
extension ConversationViewModel
{
    func addListenerToMessages() 
    {
        guard let conversation = conversation else {return}
        self.messageListener = ChatsManager.shared.addListenerToChatMessages(conversation.id) { [weak self] messages, docTypes in
            guard let self = self else {return}
            
//            if self.messageGroups.isEmpty {
//                self.fetchConversationMessages()
//                return
//            }

            docTypes.enumerated().forEach { index, type in
                switch type {
                case .added: self.handleAddedMessage(messages[index])
                case .removed: self.handleRemovedMessage(messages[index])
                case .modified: self.handleModifiedMessage(messages[index])
                }
            }
        }
    }
}

//MARK: - Message listener helper functions
extension ConversationViewModel
{
    
    private func handleAddedMessage(_ message: Message) {
        if !messageGroups.contains(elementWithID: message.id)
        {
            addMessageToRealmChat(message)
            createMessageGroups([message])
            messageChangedType = .added
        } else {
            Task {
                updateMessage(message)
            }
        }
    }
    
//    @MainActor 
    private func handleModifiedMessage(_ message: Message) {
        guard let indexPath = indexPath(of: message) else { return }
        let cellVM = messageGroups.getCellViewModel(at: indexPath)
        
        guard let modificationValue = cellVM.getModifiedValueOfMessage(message) else { return }
        
        //TODO: Check if main thread is on this line
        updateMessage(message)
        messageChangedType = .modified(indexPath, modificationValue)
        
//        Task { @MainActor in
//            cellVM.updateMessage(message)
//            messageChangedType = .modified(indexPath, modificationValue)
////            print(RealmDBManager.shared.retrieveSingleObject(ofType: Message.self, primaryKey: message.id))
//        }
    }
    
    private func handleRemovedMessage(_ message: Message) {
        
        guard let indexPath = indexPath(of: message) else { return }
        
        messageGroups.removeCellViewModel(at: indexPath)
        removeMessageGroup(at: indexPath)
        
        if isLastMessage(indexPath) { updateLastMessageFromFirestoreChat() }
        messageChangedType = .removed
    }
    
    private func removeMessageGroup(at indexPath: IndexPath) {
        if messageGroups[indexPath.section].cellViewModels.isEmpty {
            messageGroups.remove(at: indexPath.section)
        }
    }

    private func indexPath(of message: Message) -> IndexPath? {
        guard let date = message.timestamp.formatToYearMonthDay() else { return nil }
        
        for groupIndex in 0..<messageGroups.count {
            let group = messageGroups[groupIndex]
            
            if group.date == date {
                if let messageIndex = group.cellViewModels.firstIndex(where: { $0.cellMessage.id == message.id }) {
                    return IndexPath(row: messageIndex, section: groupIndex)
                }
            }
        }
        return nil
    }
    
    private func updateLastMessageFromFirestoreChat() {
        Task {
            await updateRecentMessageFromFirestoreChat(messageID: messageGroups[0].cellViewModels[0].cellMessage.id)
        }
    }
    
    private func isLastMessage(_ indexPath: IndexPath) -> Bool {
        return indexPath.row == 0 && indexPath.section == 0
    }
    
    func contains(_ message: Message) -> Bool {
        let existingMessageIDs: Set<String> = Set(messageGroups.flatMap { $0.cellViewModels.map { $0.cellMessage.id } })
        return existingMessageIDs.contains(message.id)
    }
}

//MARK: - Users listener
extension ConversationViewModel {
    
    /// - Temporary fix while firebase functions are deactivated
    
    func addUserObserver() {
        userObserver = UserManagerRealtimeDB.shared.addObserverToUsers(userMember.userId) { [weak self] realtimeDBUser in
            guard let self = self else {return}
            if realtimeDBUser.isActive != self.userMember.isActive
            {
                if let date = realtimeDBUser.lastSeen, let isActive = realtimeDBUser.isActive {
                    self.userMember = self.userMember.updateActiveStatus(lastSeenDate: date,isActive: isActive)
                    
                }
            }
        }
    }
    
    func addUsersListener() {
        
        self.userListener = UserManager.shared.addListenerToUsers([userMember.userId]) { [weak self] users, documentsTypes in
            guard let self = self else {return}
            // since we are listening only for one user here
            // we can just get the first user and docType
            guard let docType = documentsTypes.first, let user = users.first, docType == .modified else {return}
            self.userMember = user
        }
    }
}


extension ConversationViewModel {
    private func addMessageToRealmChat(_ message: Message)
    {
        guard let conversation = conversation else { return }
        RealmDBManager.shared.update(object: conversation) { chat in
            chat.conversationMessages.append(message)
        }
    }
    
    private func retrieveMessageFromRealm(_ message: Message) -> Message? {
        return RealmDBManager.shared.retrieveSingleObject(ofType: Message.self, primaryKey: message.id)
    }
    
    private func addChatToRealm(_ chat: Chat) {
        RealmDBManager.shared.add(object: chat)
    }
    
    private func updateMessage(_ message: Message) {
        RealmDBManager.shared.add(object: message)
//        RealmDBManager.shared.realmDB.refresh()
    }
}


extension Array where Element == ConversationMessageGroups
{
    mutating func removeCellViewModel(at indexPath: IndexPath) {
        self[indexPath.section].cellViewModels.remove(at: indexPath.row)
    }
    
    func getCellViewModel(at indexPath: IndexPath) -> ConversationCellViewModel {
        return self[indexPath.section].cellViewModels[indexPath.row]
    }
    
    func contains(elementWithID id: String) -> Bool {
        let existingMessageIDs: Set<String> = Set(self.flatMap { $0.cellViewModels.map { $0.cellMessage.id } })
        return existingMessageIDs.contains(id)
    }
}
