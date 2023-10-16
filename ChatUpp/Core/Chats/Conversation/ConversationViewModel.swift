//
//  ConversationViewModel.swift
//  ChatUpp
//
//  Created by Andrei Pripa on 10/3/23.
//

import Foundation


final class ConversationViewModel {
    
    var memberName: String
    var conversationID: String
    var imageData: Data?
    
    init(memberName: String, conversationID: String, imageData: Data?) {
        self.memberName = memberName
        self.conversationID = conversationID
        self.imageData = imageData
    }
    
}
