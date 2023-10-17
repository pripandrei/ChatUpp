//
//  ConversationViewModel.swift
//  ChatUpp
//
//  Created by Andrei Pripa on 10/3/23.
//

import Foundation


final class ConversationViewModel {
    
    var memberName: String
    var conversation: Chat
    var imageData: Data?
    
    init(memberName: String, conversation: Chat, imageData: Data?) {
        self.memberName = memberName
        self.conversation = conversation
        self.imageData = imageData
    }
    
    func createMessage(messageBody: String) async  {
        let authUser = (try? AuthenticationManager.shared.getAuthenticatedUser())!
        let messageID = UUID().uuidString
        
        let message = Message(id: messageID,
                              messageBody: messageBody,
                              senderId: authUser.uid,
                              imageUrl: nil,
                              timestamp: Date(),
                              messageSeen: false,
                              receivedBy: nil)
        do {
            try await ChatsManager.shared.createNewMessage(message: message, atChatPath: conversation.id)
        } catch {
            print("error while trying to create message: ",error.localizedDescription)
        }
        
    }
    
}


