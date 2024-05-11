//
//  ConversationViewModel.swift
//  ChatUpp
//
//  Created by Andrei Pripa on 10/3/23.
//

import Foundation
import FirebaseFirestore

struct CurrentlyOpenedConversation {
    static var id: String?
    private init() {}
}

final class ConversationViewModel {
    
    struct ConversationMessageGroups {
        let date: Date
        var cellViewModels: [ConversationCellViewModel]
    }
    
    private(set) var conversation: Chat?
    private(set) var memberID: String
    private(set) var memberName: String
    private(set) var memberProfileImage: Data?
    private(set) var cellMessageGroups: [ConversationMessageGroups] = []
    private(set) var messageListener: ListenerRegistration?
    var shouldEditMessage: ((String) -> Void)?
    
    let authenticatedUserID: String = (try! AuthenticationManager.shared.getAuthenticatedUser()).uid
    
    var onCellVMLoad: ((IndexPath?) -> Void)?
    var onNewMessageAdded: (() -> Void)?
    var messageWasModified: ((IndexPath, String) -> Void)?
    var updateUnreadMessagesCount: (() async throws -> Void)?
    
    init(memberID: String ,memberName: String, conversation: Chat? = nil, imageData: Data?) {
        self.memberName = memberName
        self.conversation = conversation
        self.memberProfileImage = imageData
        self.memberID = memberID
        addListenerToMessages()
    }
    
    private func createConversation() async {
        let chatId = UUID().uuidString
        let members = [authenticatedUserID, memberID]
        let chat = Chat(id: chatId, members: members, lastMessage: cellMessageGroups.first?.cellViewModels.first?.cellMessage.id)
        self.conversation = chat
        do {
            try await ChatsManager.shared.createNewChat(chat: chat)
            addListenerToMessages()
        } catch {
            print("Error creating conversation", error.localizedDescription)
        }
    }

    private func createConversationCellViewModels() -> [[ConversationCellViewModel]] {
        return cellMessageGroups.map { group in
            group.cellViewModels.map { cell in
                ConversationCellViewModel(cellMessage: cell.cellMessage)
            }
        }
    }
    
    private func createMessageGroups(_ messages: [Message]) {
        var tempMessageGroup: [ConversationMessageGroups] = cellMessageGroups
        messages.forEach { message in
            let conversationCellVM = ConversationCellViewModel(cellMessage: message)

            guard let date = message.timestamp.formatToYearMonthDay() else {return}

            if let index = tempMessageGroup.firstIndex(where: {$0.date == date})  {
                tempMessageGroup[index].cellViewModels.insert(conversationCellVM, at: 0)
            } else {
                let newGroup = ConversationMessageGroups(date: date, cellViewModels: [conversationCellVM])
                tempMessageGroup.insert(newGroup, at: 0)
            }
        }
        self.cellMessageGroups = tempMessageGroup
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
    
    private func handleAddedMessage(_ message: Message) {
        if !checkIfCellMessageGroupsContainsMessage([message]) {
            createMessageGroups([message])
            self.onNewMessageAdded?()
        }
    }
    
    private func checkIfCellMessageGroupsContainsMessage(_ messages: [Message]) -> Bool {
        if self.cellMessageGroups.contains(where: {$0.cellViewModels.contains(where: {$0.cellMessage.id == messages.last?.id})}) {
            return true
        }
        return false
    }
    
    private func handleModifiedMessage(_ message: Message) {
        guard let messageGroupIndex = cellMessageGroups.firstIndex(where: { $0.cellViewModels.contains(where: { $0.cellMessage.id == message.id }) }) else {return}
        guard let messageIndex = cellMessageGroups[messageGroupIndex].cellViewModels.firstIndex(where: {$0.cellMessage.id == message.id}) else {return}
        let indexPath = IndexPath(row: messageIndex, section: messageGroupIndex)
        let oldMessage = cellMessageGroups[messageGroupIndex].cellViewModels[messageIndex].cellMessage
        var modificationType: String = ""
        
        cellMessageGroups[messageGroupIndex].cellViewModels[messageIndex].cellMessage = message
        
        // animation of cell reload based on what field of message was mofidied
        if oldMessage.messageBody != message.messageBody {
            modificationType = "text"
        } else if oldMessage.messageSeen != message.messageSeen {
            modificationType = "seenStatus"
        }
        messageWasModified?(indexPath, modificationType)
    }
    
    var onMessageRemoved: ((IndexPath) -> Void)?
    
    private func handleRemovedMessage(_ message: Message) {
        guard let messageGroupIndex = cellMessageGroups.firstIndex(where: { $0.cellViewModels.contains(where: { $0.cellMessage.id == message.id }) }) else {return}
        guard let messageIndex = cellMessageGroups[messageGroupIndex].cellViewModels.firstIndex(where: {$0.cellMessage.id == message.id}) else {return}
        let indexPath = IndexPath(row: messageIndex, section: messageGroupIndex)
        
        cellMessageGroups[messageGroupIndex].cellViewModels.remove(at: messageIndex)
        
        // if section doesn't contain any messages, remove it
        if cellMessageGroups[messageGroupIndex].cellViewModels.isEmpty {
            cellMessageGroups.remove(at: messageGroupIndex)
        }
        
        // if last message was deleted, update last message for chat
        if messageGroupIndex == 0 && messageIndex == 0 {
            Task {
                await updateLastMessageFromDBChat(chatID: conversation?.id, messageID: cellMessageGroups[0].cellViewModels[0].cellMessage.id)
            }
        }
        onMessageRemoved?(indexPath)
    }
    
    private func createNewMessage(_ messageBody: String) -> Message {
        let messageID = UUID().uuidString
        
        return Message(id: messageID,
                       messageBody: messageBody,
                       senderId: authenticatedUserID,
                       imagePath: nil,
                       timestamp: Date(),
                       messageSeen: false,
                       receivedBy: nil,
                       imageSize: nil,
                       isEdited: false)
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
        insertNewMessage(message)
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
}









//    var unreadMessageUpdateTimer: Timer = Timer()
//
//    func shouldSubtractFromUnreadMessageCount() async {
//        guard let chatID = conversation?.id else { print("chatID is nil") ; return}
//        self.messageCount -= 1
//        unreadMessageUpdateTimer.invalidate()
//        unreadMessageUpdateTimer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: false) { _ in
//                //            print("message count", messageCount)
//            Task {
//                do {
//                    print("unreadMessages count before subtract: ",self.messageCount)
//
//                    try await ChatsManager.shared.updateChatUnreadMessagesCount(chatID: chatID, shouldIncreaseCount: false, messageCount: self.messageCount)
//                } catch {
//                    print("Error updating chat last message:", error.localizedDescription)
//                }
//            }
//        }
//        unreadMessageUpdateTimer.fire()
//    }










//private func createMessageGroups(_ messages: [Message]) {
//    for message in self.messages {
//        let conversationCellVM = ConversationCellViewModel(cellMessage: message)
//        
//        guard let date = message.timestamp.formatToYearMonthDay() else {
//            return
//            
//        }
//        
//        if cellMessageGroups.isEmpty {
//            let newGroup = ConversationMessageGroups(date: date, cellViewModels: [conversationCellVM])
//            cellMessageGroups.append(newGroup)
//            continue
//        }
//        
//        for (index, group) in cellMessageGroups.enumerated() {
//            if group.date == date {
//                cellMessageGroups[index].cellViewModels.append(conversationCellVM)
//                break
//            }
//            if index == cellMessageGroups.endIndex - 1 {
//                let newGroup = ConversationMessageGroups(date: date, cellViewModels: [conversationCellVM])
//                cellMessageGroups.append(newGroup)
//            }
//        }
//
////            if let index = self.cellMessageGroups.firstIndex(where: {$0.date == date})  {
////                print("Before In: ", cellMessageGroups[index].cellViewModels.count)
////                cellMessageGroups[index].cellViewModels.append(conversationCellVM)
////                print("After In: ", cellMessageGroups[index].cellViewModels.count)
////            } else {
////                let newGroup = ConversationMessageGroups(date: date, cellViewModels: [conversationCellVM])
////                print("Before Else: ", cellMessageGroups.count)
////                cellMessageGroups.append(newGroup)
////                print("After Else: ", cellMessageGroups.count)
////            }
//    }
////        messages.forEach { message in
////            let conversationCellVM = ConversationCellViewModel(cellMessage: message)
////
////            guard let date = message.timestamp.formatToYearMonthDay() else {return}
////
////            if let index = self.cellMessageGroups.firstIndex(where: {$0.date == date})  {
////                print("Before In: ", cellMessageGroups[index].cellViewModels.count)
////                cellMessageGroups[index].cellViewModels.insert(conversationCellVM, at: 0)
////                print("After In: ", cellMessageGroups[index].cellViewModels.count)
////            } else {
////                let newGroup = ConversationMessageGroups(date: date, cellViewModels: [conversationCellVM])
////                print("Before Else: ", cellMessageGroups.count)
////                cellMessageGroups.insert(newGroup, at: 0)
////                print("After Else: ", cellMessageGroups.count)
////            }
////        }
//}
