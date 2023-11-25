//
//  ConversationCellViewModel.swift
//  ChatUpp
//
//  Created by Andrei Pripa on 11/22/23.
//

import Foundation


final class ConversationCellViewModel {
    
    private let messageId: String!
    private let timeStamp: Date!
    let imagePath: String?
    let messageText: String!
    var imageData: ObservableObject<Data?> = ObservableObject(nil)
    let senderId: String!
    let imageSize: MessageImageSize?
    
    init(cellMessage: Message) {
        self.timeStamp = cellMessage.timestamp
        self.messageText = cellMessage.messageBody
        self.imagePath = cellMessage.imagePath
        self.messageId = cellMessage.id
        self.senderId = cellMessage.senderId
        self.imageSize = cellMessage.imageSize
    }
    
    var timestamp: String {
        let hoursAndMinutes = timeStamp.formatToHoursAndMinutes()
        return hoursAndMinutes
    }
    
    func fetchImageData() {
        Task {
            do {
                self.imageData.value = try await StorageManager.shared.getMessageImage(messageId: messageId, path: imagePath!)
            } catch {
                print("Error fetching image from storage: ", error)
            }
        }
    }
}

extension ConversationCellViewModel {
    func getCellAspectRatio(forImageSize size: CGSize) -> CGSize {
        let (equalWidth, equalHeight) = (250,250)
        
        let preferredWidth: Double = 300
        let preferredHeight: Double = 350
        
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
