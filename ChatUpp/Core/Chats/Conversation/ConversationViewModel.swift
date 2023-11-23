//
//  ConversationViewModel.swift
//  ChatUpp
//
//  Created by Andrei Pripa on 10/3/23.
//

import Foundation


final class ConversationViewModel {
    
    private var conversation: Chat
    var memberName: String
    var memberProfileImage: Data?
    var messages: [Message] = []
    var cellViewModels: [ConversationCellViewModel] = []
    
    let authenticatedUserID: String = (try? AuthenticationManager.shared.getAuthenticatedUser())!.uid
    
    var onCellVMLoad: (() -> Void)?
    
    init(memberName: String, conversation: Chat, imageData: Data?) {
        self.memberName = memberName
        self.conversation = conversation
        self.memberProfileImage = imageData
        fetchConversationMessages()
    }
    
    private func createConversationCellViewModels() -> [ConversationCellViewModel] {
        return messages.map { message in
            ConversationCellViewModel(cellMessage: message)
        }
    }
    
    func saveImage(data: Data, size: CGSize) {
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
        Task {
            do {
                self.messages = try await ChatsManager.shared.getAllMessages(fromChatDocumentPath: conversation.id)
                self.cellViewModels = createConversationCellViewModels()
                self.onCellVMLoad?()
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
        do {
            try await ChatsManager.shared.createNewMessageInDataBase(message: message, atChatPath: conversation.id)
        } catch {
            print("error occur while trying to create message: ", error.localizedDescription)
        }
    }
    
    private func createCellViewModel(with message: Message) -> ConversationCellViewModel {
        return ConversationCellViewModel(cellMessage: message)
    }
    
    private func insertNewMessage(_ message: Message) {
        messages.insert(message, at: 0)
        Task {
            await addMessageToDB(message)
        }
    }
    
    func createMessageBubble(_ messageText: String) {
        let message = createNewMessage(messageText)
        insertNewMessage(message)
        cellViewModels.insert(createCellViewModel(with: message), at: 0)
    }
    
    func updateImageSizeOfMessage(size: CGSize) {
        
    }
}















