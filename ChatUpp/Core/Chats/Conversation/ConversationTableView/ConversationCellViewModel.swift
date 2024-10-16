//
//  ConversationCellViewModel.swift
//  ChatUpp
//
//  Created by Andrei Pripa on 11/22/23.
//

import Foundation

final class ConversationCellViewModel {
    
    @Published var imageData: Data?
    var cellMessage: Message 
    var messageToBeReplied: Message?
    var (senderNameOfMessageToBeReplied, textOfMessageToBeReplied): (String?, String?)
    
//    var messageID: String
    
    init(cellMessage: Message) {
        self.cellMessage = cellMessage
//        self.messageID = cellMessage.freeze().id
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
    
    func getModifiedValueOfMessage(_ newMessage: Message) -> MessageValueModification? {
        if cellMessage.messageBody != newMessage.messageBody {
            return .text
        } else if cellMessage.messageSeen != newMessage.messageSeen {
            return .seenStatus
        }
        return nil
    }
    
//
//    func editMessageTextFromFirestore(_ messageText: String, from chatID: String) {
//        Task {
//            try await ChatsManager.shared.updateMessageText(messageText, messageID: cellMessage.id, chatID: chatID)
//        }
//    }
//    
//    func deleteMessageFromFirestore(from chatID: String) {
//        Task {
//            do {
//                try await ChatsManager.shared.removeMessage(messageID: cellMessage.id, conversationID: chatID)
//            } catch {
//                print("Error deleting message: ",error.localizedDescription)
//            }
//        }
//    }
}


//MARK: - Message update in realm/firestore DB
extension ConversationCellViewModel
{
    
//    @MainActor
//    func updateMessage(_ message: Message) {
//        RealmDBManager.shared.add(object: message)
////        RealmDBManager.shared.realmDB.refresh()
//    }
    
    
    func updateFirestoreMessageSeenStatus(from chatID: String) async {
        do {
            try await ChatsManager.shared.updateMessageSeenStatus(messageID: "pripa", chatID: chatID)
        } catch {
            print("Error updating message seen status in Firestore: ", error.localizedDescription)
        }
    }
    
//    func updateFirestoreMessageSeenStatus(from chatID: String) {
////        do {
//            ChatsManager.shared.updateMessageSeenStatus2(messageID: messageID, chatID: chatID)
////        } catch {
////            print("Error updating message seen status in Firestore: ", error.localizedDescription)
////        }
//    }

    
    func updateRealmMessageSeenStatus() {
        RealmDBManager.shared.update(object: cellMessage) { message in
            message.messageSeen = true
        }
    }
}


extension ConversationCellViewModel
{
    func getCellAspectRatio(forImageSize size: CGSize) -> CGSize 
    {
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
