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
    var imageData: Data?
    var messages: ObservableObject<[Message]> = ObservableObject([])
    
    let authenticatedUserID: String = (try? AuthenticationManager.shared.getAuthenticatedUser())!.uid
    
    init(memberName: String, conversation: Chat, imageData: Data?) {
        self.memberName = memberName
        self.conversation = conversation
        self.imageData = imageData
        fetchConversationMessages()
    }
    
    func saveImage(data: Data) {
        Task {
            let (path,name) = try await StorageManager.shared.saveMessageImage(data: data, messageID: messages.value.first!.id)
            try await ChatsManager.shared.updateMessageImagePath(messageID: messages.value.first!.id,
                                                                 chatDocumentPath: conversation.id,
                                                                 path: name)
            print("Success saving image: \(path) \(name)")
        }
    }
    
    private func fetchConversationMessages() {
        Task {
            do {
                self.messages.value = try await ChatsManager.shared.getAllMessages(fromChatDocumentPath: conversation.id)
            } catch {
                print("Could not fetch messages from db: ", error.localizedDescription)
            }
        }
    }
    
    private func createNewMessage(_ messageBody: String) -> Message {
        let messageID = UUID().uuidString
        
        let message = Message(id: messageID,
                              messageBody: messageBody,
                              senderId: authenticatedUserID,
                              imagePath: nil,
                              timestamp: Date(),
                              messageSeen: false,
                              receivedBy: nil)
        return message
    }
    
    private func addMessageToDB(_ message: Message) async  {
        do {
            try await ChatsManager.shared.createNewMessageInDataBase(message: message, atChatPath: conversation.id)
        } catch {
            print("error occur while trying to create message: ", error.localizedDescription)
        }
    }
    
    func addNewCreatedMessage(_ messageBody: String) {
        let message = createNewMessage(messageBody)
        messages.value.insert(message, at: 0)
        Task {
            await addMessageToDB(message)
        }
    }
}















