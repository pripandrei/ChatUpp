//
//  ConversationCellViewModel.swift
//  ChatUpp
//
//  Created by Andrei Pripa on 11/22/23.
//

import Foundation

final class ConversationCellViewModel {
    
    @Published var imageData: Data?
    var cellMessage: Message { willSet {setModifiedValueOfMessage(newValue)} }
    var messageToBeReplied: Message?
    var (senderNameOfMessageToBeReplied, textOfMessageToBeReplied): (String?, String?)
    @Published var messageModifiedValue: MessageValueModification?
    @Published var shouldDeleteSelf: Bool = false
    
    init(cellMessage: Message) {
        self.cellMessage = cellMessage
        addListenerToMessage()
    }
    
    var timestamp: String {
        let hoursAndMinutes = cellMessage.timestamp.formatToHoursAndMinutes()
        return hoursAndMinutes
    }

    func fetchImageData() {
        Task {
            do {
                self.imageData = try await StorageManager.shared.getMessageImage(messageId: cellMessage.id, path: cellMessage.imagePath!)
            } catch {
                print("Error fetching image from storage: ", error)
            }
        }
    }
    
    func updateMessageSeenStatus(_ messageId: String, inChat chatId: String) {
        Task {
            try await ChatsManager.shared.updateMessageSeenStatus(messageID: messageId, chatID: chatId)
            
        }
    }
    
    var messageListener: Listener?
    
    func addListenerToMessage() {
        guard let conversationID = ChatsManager.openedChatID else {return}
        messageListener = ChatsManager.shared.addListenerToMessage(messageID: cellMessage.id, fromChatWithID: conversationID, complition: { [weak self] updatedMessage in
            if let updatedMessage = updatedMessage {
                self?.cellMessage = updatedMessage
            } else {
                self?.shouldDeleteSelf = true
            }
        })
    }
    
    func setModifiedValueOfMessage(_ newMessage: Message) {
        if cellMessage.messageBody != newMessage.messageBody {
            self.messageModifiedValue = .text
        } else if cellMessage.messageSeen != newMessage.messageSeen {
            messageModifiedValue = .seenStatus
        }
    }
}

extension ConversationCellViewModel {
    func getCellAspectRatio(forImageSize size: CGSize) -> CGSize {
        let (equalWidth, equalHeight) = (250,250)
        
        let preferredWidth: Double = 270
        let preferredHeight: Double = 320
        
        let aspectRatioForWidth = Double(size.width) / Double(size.height)
        let aspectRatioForHeight = Double(size.height) / Double(size.width)
        
        if size.width > size.height {
            let newHeight = preferredWidth / aspectRatioForWidth
            return CGSize(width: preferredWidth , height: newHeight)
        } else if size.height > size.width {
            let newWidth = preferredHeight / aspectRatioForHeight
            return CGSize(width: newWidth , height: preferredHeight)
        } else {
            return CGSize(width: equalWidth, height: equalHeight)
        }
    }
}
