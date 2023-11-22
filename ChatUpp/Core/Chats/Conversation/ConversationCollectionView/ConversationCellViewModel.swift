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
    private let imagePath: String?
    let messageText: String!
    var imageData: ObservableObject<Data?> = ObservableObject(nil)
    let senderId: String!
    
    init(cellMessage: Message) {
        self.timeStamp = cellMessage.timestamp
        self.messageText = cellMessage.messageBody
        self.imagePath = cellMessage.imagePath
        self.messageId = cellMessage.id
        self.senderId = cellMessage.senderId
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
