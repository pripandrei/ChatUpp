//
//  ConversationCellViewModel.swift
//  ChatUpp
//
//  Created by Andrei Pripa on 11/22/23.
//

import Foundation


final class ConversationCellViewModel {
    
    var cellMessage: Message
    
//    private let messageId: String!
//    private let timeStamp: Date!
//    let imagePath: String?
//    let messageText: String!
    var imageData: ObservableObject<Data?> = ObservableObject(nil)
//    let senderId: String!
//    var imageSize: MessageImageSize?
    
    init(cellMessage: Message) {
//        self.timeStamp = cellMessage.timestamp
//        self.messageText = cellMessage.messageBody
//        self.imagePath = cellMessage.imagePath
//        self.messageId = cellMessage.id
//        self.senderId = cellMessage.senderId
//        self.imageSize = cellMessage.imageSize
        self.cellMessage = cellMessage
    }
    
    var timestamp: String {
        let hoursAndMinutes = cellMessage.timestamp.formatToHoursAndMinutes()
        return hoursAndMinutes
    }
    
    func fetchImageData() {
        Task {
            do {
                self.imageData.value = try await StorageManager.shared.getMessageImage(messageId: cellMessage.id, path: cellMessage.imagePath!)
            } catch {
                print("Error fetching image from storage: ", error)
            }
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
