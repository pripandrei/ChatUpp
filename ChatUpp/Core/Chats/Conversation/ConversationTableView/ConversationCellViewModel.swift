//
//  ConversationCellViewModel.swift
//  ChatUpp
//
//  Created by Andrei Pripa on 11/22/23.
//

import Foundation

final class ConversationCellViewModel {
    
    @Published var imageData: Data?
//    @Published var messageModifiedValue: MessageValueModification?
    var cellMessage: Message 
    var messageToBeReplied: Message?
    var (senderNameOfMessageToBeReplied, textOfMessageToBeReplied): (String?, String?)
    
    init(cellMessage: Message) {
        self.cellMessage = cellMessage
    }
    
    var timestamp: String {
        let hoursAndMinutes = cellMessage.timestamp.formatToHoursAndMinutes()
        return hoursAndMinutes
    }
    
    func updateMessage(_ updatedMessage: Message) {
        cellMessage = updatedMessage
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
    
    func getModifiedValueOfMessage(_ newMessage: Message) -> MessageValueModification? {
        if cellMessage.messageBody != newMessage.messageBody {
            return .text
        } else if cellMessage.messageSeen != newMessage.messageSeen {
            return .seenStatus
        }
        return nil
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
