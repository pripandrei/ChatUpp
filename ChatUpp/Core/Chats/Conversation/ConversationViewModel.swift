//
//  ConversationViewModel.swift
//  ChatUpp
//
//  Created by Andrei Pripa on 10/3/23.
//

import Foundation
import FirebaseFirestore

final class ConversationViewModel {
    
    private(set) var conversation: Chat?
    private(set) var memberID: String
    private(set) var memberName: String
    private(set) var memberProfileImage: Data?
    private(set) var messages: [Message] = []
//    private(set) var cellViewModels: [ConversationCellViewModel] = []
    private(set) var cellViewModels: [[ConversationCellViewModel]] = [[]]
    
    private(set) var messageGroups: [MessageGroup] = []
    
    let authenticatedUserID: String = (try! AuthenticationManager.shared.getAuthenticatedUser()).uid
    
    var onCellVMLoad: ((IndexPath?) -> Void)?
    var onNewMessageAdded: (() -> Void)?
    private(set) var messageListener: ListenerRegistration?
    var messageWasModified: ((IndexPath) -> Void)?
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
        let chat = Chat(id: chatId, members: members, lastMessage: messages.first?.id)
        self.conversation = chat
        do {
            try await ChatsManager.shared.createNewChat(chat: chat)
            addListenerToMessages()
        } catch {
            print("Error creating conversation", error.localizedDescription)
        }
    }

    private func createConversationCellViewModels() -> [[ConversationCellViewModel]] {
        return messageGroups.map { group in
            group.messages.map { message in
                ConversationCellViewModel(cellMessage: message)
            }
        }
    }
    
    func createMessageGroups(_ messages: [Message]) {
        messages.forEach { message in
            let calendar = Calendar.current
            let components = calendar.dateComponents([.year,.month,.day], from: message.timestamp)
            let date = calendar.date(from: components)!
            
            if let index = self.messageGroups.firstIndex(where: {$0.date == date})  {
                messageGroups[index].messages.append(message)
            } else {
                let newGroup = MessageGroup(date: date, messages: [message])
                messageGroups.append(newGroup)
            }
        }
    }
    
    private func fetchConversationMessages() {
        guard let conversation = conversation else {return}
        Task {
            do {
//                self.messages = try await ChatsManager.shared.getAllMessages(fromChatDocumentPath: conversation.id)
                let messages = try await ChatsManager.shared.getAllMessages(fromChatDocumentPath: conversation.id)
                createMessageGroups(messages)
                self.cellViewModels = createConversationCellViewModels()
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
            
            if self.messageGroups.isEmpty {
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
            messages.forEach { message in
                self.handleAddedMessage(message)
                print("Entered")
            }
        }
    }
    
    private func handleModifiedMessage(_ message: Message) {
        guard let messageGroupIndex = messageGroups.firstIndex(where: { $0.messages.contains(where: { $0.id == message.id }) }) else {return}
        guard let messageIndex = messageGroups[messageGroupIndex].messages.firstIndex(where: {$0.id == message.id}) else {return}
        let indexPath = IndexPath(row: messageIndex, section: messageGroupIndex)
//        guard let indexOfMessageToModify = messages.firstIndex(where: {$0.id == message.id}) else {return}
//        messages[indexOfMessageToModify] = message
        
        cellViewModels[messageGroupIndex][messageIndex].cellMessage = message
//        cellViewModels[indexOfMessageToModify].cellMessage = message
        messageWasModified?(indexPath)
    }
    
    private func handleRemovedMessage(_ message: Message) {

    }
    
    private func handleAddedMessage(_ message: Message) {
        // Check whether message already exists, meaning, you are the sender of it.
        if self.messageGroups.contains(where: {$0.messages.contains(where: {$0.id == message.id})}) {
            return
        }
        let conversationCellVM = ConversationCellViewModel(cellMessage: message)
        
        let calendar = Calendar.current
        let components = calendar.dateComponents([.year,.month,.day], from: message.timestamp)
        let date = calendar.date(from: components)!
        
        if let index = self.messageGroups.firstIndex(where: {$0.date == date})  {
            messageGroups[index].messages.append(message)
            self.cellViewModels[index].insert(conversationCellVM, at: 0)
        } else {
            let newGroup = MessageGroup(date: date, messages: [message])
            messageGroups.append(newGroup)
            self.cellViewModels.append([conversationCellVM])
        }
        
//        self.messages.insert(message, at: 0)
       
//        self.cellViewModels.insert(conversationCellVM, at: 0)
//        self.onNewMessageAdded?()
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
                       imageSize: nil)
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
        handleNewMessageCreation(message)
        Task {
            if self.conversation == nil {
                await createConversation()
            }
            await addMessageToDB(message)
            await updateLastMessageFromDBChat(chatID: conversation?.id, messageID: message.id)
        }
    }
    
    
    private func handleNewMessageCreation(_ message: Message) {
        let conversationCellVM = ConversationCellViewModel(cellMessage: message)
        
        let calendar = Calendar.current
        let components = calendar.dateComponents([.year,.month,.day], from: message.timestamp)
        let date = calendar.date(from: components)!
        
        if let index = self.messageGroups.firstIndex(where: {$0.date == date})  {
            messageGroups[index].messages.append(message)
            self.cellViewModels[index].insert(conversationCellVM, at: 0)
        } else {
            let newGroup = MessageGroup(date: date, messages: [message])
            messageGroups.append(newGroup)
            self.cellViewModels.append([conversationCellVM])
        }
    }
    
    func createMessageBubble(_ messageText: String) {
        let message = createNewMessage(messageText)
        insertNewMessage(message)
    }
    
    func handleImageDrop(imageData: Data, size: MessageImageSize) {
        self.cellViewModels.last?[0].imageData.value = imageData
        self.cellViewModels.last?[0].cellMessage.imageSize = size
//        self.cellViewModels[0].imageData.value = imageData
//        self.cellViewModels[0].cellMessage.imageSize = size
        self.saveImage(data: imageData, size: CGSize(width: size.width, height: size.height))
    }
    
    private func findFirstNotSeenMessageIndex() -> IndexPath? {
        var indexOfNotSeenMessageToScrollTo: IndexPath?
        for (index,message) in messages.enumerated() {
            if !message.messageSeen && message.senderId != authenticatedUserID {
                indexOfNotSeenMessageToScrollTo = IndexPath(item: index, section: 0)
            } else {
                break
            }
        }
        return indexOfNotSeenMessageToScrollTo
    }
    
    func saveImage(data: Data, size: CGSize) {
        guard let conversation = conversation else {return}
        Task {
            let (path,name) = try await StorageManager.shared.saveMessageImage(data: data, messageID: messages.first!.id)
            try await ChatsManager.shared.updateMessageImagePath(messageID: messages.first!.id,
                                                                 chatDocumentPath: conversation.id,
                                                                 path: name)
            
            let imageSize = MessageImageSize(width: Int(size.width), height: Int(size.height))
            try await ChatsManager.shared.updateMessageImageSize(messageID: messages.first!.id, chatDocumentPath: conversation.id, imageSize: imageSize)
            print("Success saving image: \(path) \(name)")
        }
    }
    
    //    private func createConversationCellViewModels() -> [ConversationCellViewModel] {
    //        return messages.map { message in
    //            ConversationCellViewModel(cellMessage: message)
    //        }
    //    }
//
//    private func createCellViewModel(with message: Message) -> ConversationCellViewModel {
//        return ConversationCellViewModel(cellMessage: message)
//    }
    
    //    func delete() {
    //        ChatsManager.shared.testDeleteLastDocuments(documentPath: conversation.id)
    //    }
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










