//
//  ConversationViewModel.swift
//  ChatUpp
//
//  Created by Andrei Pripa on 10/3/23.
//

import Foundation
import Combine

enum MessageValueModification {
    case text
    case seenStatus
}

enum MessageChangeType {
    case modified(IndexPath, MessageValueModification)
    case added
    case removed
}

final class ConversationViewModel {
    
    struct ConversationMessageGroups {
        let date: Date
        var cellViewModels: [ConversationCellViewModel]
    }
    
    private(set) var conversation: Chat?
    private(set) var memberProfileImage: Data?
    private(set) var cellMessageGroups: [ConversationMessageGroups] = []
    private(set) var (userListener,messageListener): (Listener?, Listener?)
    private(set) var userObserver: RealtimeDBObserver?
    
    @Published private(set) var userMember: DBUser
    @Published var messageChangedType: MessageChangeType?
    
    let authenticatedUserID: String = (try! AuthenticationManager.shared.getAuthenticatedUser()).uid
    
    var shouldEditMessage: ((String) -> Void)?
    var onCellVMLoad: ((IndexPath?) -> Void)?
   
    var updateUnreadMessagesCount: (() async throws -> Void)?
    
    var currentlyReplyToMessageID: String?
    
    init(userMember: DBUser, conversation: Chat? = nil, imageData: Data?) {
        self.userMember = userMember
        self.conversation = conversation
        self.memberProfileImage = imageData
        addListenerToMessages()
        addUsersListener()
        addUserObserver()
    }
    
    private func createConversation() async {
        let chatId = UUID().uuidString
        let members = [authenticatedUserID, userMember.userId]
        let chat = Chat(id: chatId, members: members, lastMessage: cellMessageGroups.first?.cellViewModels.first?.cellMessage.id)
        self.conversation = chat
        do {
            try await ChatsManager.shared.createNewChat(chat: chat)
            addListenerToMessages()
        } catch {
            print("Error creating conversation", error.localizedDescription)
        }
    }
    
    private func createMessageGroups(_ messages: [Message]) {
        var tempMessageGroups: [ConversationMessageGroups] = cellMessageGroups
        messages.forEach { message in
            guard let date = message.timestamp.formatToYearMonthDay() else {return}
            
            let conversationCellVM = ConversationCellViewModel(cellMessage: message)
            
            if let index = tempMessageGroups.firstIndex(where: {$0.date == date})  {
                tempMessageGroups[index].cellViewModels.insert(conversationCellVM, at: 0)
            } else {
                let newGroup = ConversationMessageGroups(date: date, cellViewModels: [conversationCellVM])
                tempMessageGroups.insert(newGroup, at: 0)
            }
        }
        self.cellMessageGroups = tempMessageGroups
    }
 
    private func fetchConversationMessages() {
        guard let conversation = conversation else {return}
        Task {
            do {
                let messages = try await ChatsManager.shared.getAllMessages(fromChatDocumentPath: conversation.id)
                createMessageGroups(messages)
                let indexOfNotSeenMessageToScrollTo = self.findFirstNotSeenMessageIndex()
                self.onCellVMLoad?(indexOfNotSeenMessageToScrollTo)
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
                       receivedBy: nil,
                       imageSize: nil,
                       repliedTo: currentlyReplyToMessageID)
    }
    
    private func addMessageToDB(_ message: Message) async  {
        guard let conversation = conversation else {return}
        do {
            try await ChatsManager.shared.createNewMessageInDataBase(message: message, atChatPath: conversation.id)
        } catch {
            print("error occur while trying to create message in DB: ", error.localizedDescription)
        }
    }
    
    private func updateLastMessageFromDBChat(chatID: String?, messageID: String) async {
        guard let chatID = chatID else { print("chatID is nil") ; return}
        do {
            try await ChatsManager.shared.updateChatRecentMessage(recentMessageID: messageID, chatID: chatID)
        } catch {
            print("Error updating chat last message:", error.localizedDescription)
        }
    }
    
    private func insertNewMessage(_ message: Message) {
        createMessageGroups([message])
        Task {
            if self.conversation == nil {
                await createConversation()
            }
            await addMessageToDB(message)
            await updateLastMessageFromDBChat(chatID: conversation?.id, messageID: message.id)
        }
    }
    
    func createMessageBubble(_ messageText: String) {
        let message = createNewMessage(messageText)
        resetCurrentReplyMessage()
        insertNewMessage(message)
    }
    
    func resetCurrentReplyMessage() {
        if currentlyReplyToMessageID != nil {currentlyReplyToMessageID = nil}
    }
    
    private func findFirstNotSeenMessageIndex() -> IndexPath? {
        var indexOfNotSeenMessageToScrollTo: IndexPath?
        
        cellMessageGroups.forEach { messageGroup in
            for (index,conversationVM) in messageGroup.cellViewModels.enumerated() {
                if !conversationVM.cellMessage.messageSeen && conversationVM.cellMessage.senderId != authenticatedUserID {
                    indexOfNotSeenMessageToScrollTo = IndexPath(item: index, section: 0)
                } else {
                    break
                }
            }
        }
        return indexOfNotSeenMessageToScrollTo
    }
    
    func handleImageDrop(imageData: Data, size: MessageImageSize) {
        self.cellMessageGroups.first?.cellViewModels.first?.imageData.value = imageData
        self.cellMessageGroups.first?.cellViewModels.first?.cellMessage.imageSize = size
        self.saveImage(data: imageData, size: CGSize(width: size.width, height: size.height))
    }
    
    func saveImage(data: Data, size: CGSize) {
        guard let conversation = conversation else {return}
        guard let messageID = cellMessageGroups.first?.cellViewModels.first?.cellMessage.id else {return}
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
    
    func deleteMessageFromDB(messageID: String) {
        Task {
            do {
                try await ChatsManager.shared.removeMessageFromDB(messageID: messageID, conversationID: conversation!.id)
            } catch {
                print("Error deleting message: ",error.localizedDescription)
            }
        }
    }
    
    func editMessageTextFromDB(_ messageText: String, messageID: String) {
        Task {
            try await ChatsManager.shared.updateMessageFromDB(messageText, messageID: messageID, chatID: conversation!.id)
        }
    }
    
    func getMessageSenderName(usingSenderID id: String) -> String? {
        guard let user = try? AuthenticationManager.shared.getAuthenticatedUser() else {return nil}
        if id == user.uid {
            return user.name
        } else {
            return userMember.name
        }
    }
    
    func getRepliedToMessage(messageID: String) -> Message? {
        var repliedMessage: Message?
        cellMessageGroups.forEach { conversationGroups in
            conversationGroups.cellViewModels.forEach { conversationCellViewModel in
                if conversationCellViewModel.cellMessage.id == messageID {
                    repliedMessage = conversationCellViewModel.cellMessage
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
extension ConversationViewModel {
    
    /// - Messages listener
    func addListenerToMessages() {
        guard let conversation = conversation else {return}
        self.messageListener = ChatsManager.shared.addListenerToChatMessages(conversation.id) { [weak self] messages, docTypes in
            guard let self = self else {return}
            
            if self.cellMessageGroups.isEmpty {
                self.fetchConversationMessages()
                return
            }

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
        if !cellMessageGroups.contains(where: { $0.cellViewModels.contains(where: { $0.cellMessage.id == message.id }) }) {
            createMessageGroups([message])
            messageChangedType = .added
        }
    }
    
    private func handleModifiedMessage(_ message: Message) {
        guard let (messageGroupIndex, messageIndex) = findMessageIndices(for: message) else { return }
        let indexPath = IndexPath(row: messageIndex, section: messageGroupIndex)
        let cellVM = cellMessageGroups[messageGroupIndex].cellViewModels[messageIndex]
        
        guard let modificationValue = cellVM.getModifiedValueOfMessage(message) else {return}
        cellVM.updateMessage(message)
        messageChangedType = .modified(indexPath, modificationValue)
    }
    
    private func handleRemovedMessage(_ message: Message) {
        
        guard let (messageGroupIndex, messageIndex) = findMessageIndices(for: message) else { return }

        cellMessageGroups[messageGroupIndex].cellViewModels.remove(at: messageIndex)
        
        if cellMessageGroups[messageGroupIndex].cellViewModels.isEmpty {
            cellMessageGroups.remove(at: messageGroupIndex)
        }
        
        if messageGroupIndex == 0 && messageIndex == 0 {
            Task {
                await updateLastMessageFromDBChat(chatID: conversation?.id, messageID: cellMessageGroups[0].cellViewModels[0].cellMessage.id)
            }
        }
        messageChangedType = .removed
    }
    
    private func findMessageIndices(for message: Message) -> (Int, Int)? {
        guard let date = message.timestamp.formatToYearMonthDay() else { return nil }
               
        for groupIndex in 0..<cellMessageGroups.count {
            var group = cellMessageGroups[groupIndex]
            
            if group.date == date {
                if let messageIndex = group.cellViewModels.firstIndex(where: { $0.cellMessage.id == message.id }) {
                   return (groupIndex, messageIndex)
                }
            }
        }
        return nil
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
                let date = Date(timeIntervalSince1970: realtimeDBUser.lastSeen)
                self.userMember = self.userMember.updateActiveStatus(lastSeenDate: date,isActive: realtimeDBUser.isActive)
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
