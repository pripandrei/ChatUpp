//
//  ConversationViewModel.swift
//  ChatUpp
//
//  Created by Andrei Pripa on 10/3/23.
//

import Foundation
//
//struct Member {
//    let memberID: String
//    let memberName: String
//    var memberProfileImage: Data?
//}

final class ConversationViewModel {
    
    private var conversation: Chat?
    var memberID: String
    var memberName: String
    var memberProfileImage: Data?
    var messages: [Message] = []
    var cellViewModels: [ConversationCellViewModel] = []
    
    let authenticatedUserID: String = (try! AuthenticationManager.shared.getAuthenticatedUser()).uid
    
    var onCellVMLoad: (() -> Void)?
    
    init(memberID: String ,memberName: String, conversation: Chat? = nil, imageData: Data?) {
        self.memberName = memberName
        self.conversation = conversation
        self.memberProfileImage = imageData
        self.memberID = memberID
        
        // 1.Fetching should be done only if conversation: Chat is not nil.
        // 2.Conversation should be transfered to optional
        fetchConversationMessages()
    }
    
    private func createConversation() async {
        let chatId = UUID().uuidString
        let members = [authenticatedUserID, memberID]
        let chat = Chat(id: chatId, members: members, lastMessage: messages.first!.id)
        self.conversation = chat
        do {
            try await ChatsManager.shared.createNewChat(chat: chat)
        } catch {
            print("Error creating conversation", error.localizedDescription)
        }
    }
    
    private func createConversationCellViewModels() -> [ConversationCellViewModel] {
        return messages.map { message in
            ConversationCellViewModel(cellMessage: message)
        }
    }
    
    private func createCellViewModel(with message: Message) -> ConversationCellViewModel {
        return ConversationCellViewModel(cellMessage: message)
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
    
    private func fetchConversationMessages() {
        guard let conversation = conversation else {return}
        Task {
            do {
                self.messages = try await ChatsManager.shared.getAllMessages(fromChatDocumentPath: conversation.id)
                self.cellViewModels = createConversationCellViewModels()
                self.onCellVMLoad?()
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
    
    private func insertNewMessage(_ message: Message) {
        messages.insert(message, at: 0)
        Task {
            //            guard let conversation = self.conversation else { await createConversation(); return }
            if self.conversation == nil {
                await createConversation()
            }
            await addMessageToDB(message)
            await updateLastMessageFromDBChat(chatID: conversation?.id, messageID: message.id)
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
    
    func createMessageBubble(_ messageText: String) {
        let message = createNewMessage(messageText)
        insertNewMessage(message)
        cellViewModels.insert(createCellViewModel(with: message), at: 0)
    }
    
    func handleImageDrop(imageData: Data, size: MessageImageSize) {
        self.cellViewModels[0].imageData.value = imageData
        self.cellViewModels[0].cellMessage.imageSize = size
        self.saveImage(data: imageData, size: CGSize(width: size.width, height: size.height))
    }
    
    //    func delete() {
    //        ChatsManager.shared.testDeleteLastDocuments(documentPath: conversation.id)
    //    }
}















