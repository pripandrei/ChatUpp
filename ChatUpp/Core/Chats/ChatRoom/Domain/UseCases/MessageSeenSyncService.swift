//
//  MessageSeenSyncService.swift
//  ChatUpp
//
//  Created by Andrei Pripa on 1/7/26.
//

import Foundation


actor MessageSeenSyncService
{
    func updateLocally(chat: ThreadSafe<Chat>,
                       authUserID: String,
                       isGroup: Bool,
                       timestamp: Date) -> Int
    {
        guard let chat = RealmDatabase.shared.resolveThreadSafeObject(threadSafeObject: chat) else
        { return 0 }
        
        var predicate: NSPredicate
        
        if isGroup
        {
            predicate = NSPredicate(format: "NONE seenBy CONTAINS %@ AND timestamp <= %@",
                                    authUserID, timestamp as NSDate)
        } else {
            predicate = NSPredicate(format: "timestamp <= %@ AND messageSeen == false",
                                    timestamp as NSDate)
        }
        
        let messages = chat.conversationMessages
            .filter(predicate)
            .sorted(byKeyPath: "timestamp", ascending: false)
        
        var updateCount: Int = 0
        
        RealmDatabase.shared.update
        {
            for message in messages
            {
                if message.messageSeen == true || message.seenBy.contains(authUserID) { break }
                
                if isGroup {
                    message.seenBy.append(authUserID)
                } else {
                    message.messageSeen = true
                }
                updateCount += 1
            }
        }
        return updateCount
    }
    
    func updateRemote(startingFrom startMessageID: String,
                      chatID: String,
                      seenByUser: String?,
                      limit: Int)
    {
        guard limit > 0 else {return}
        Task
        {
            do {
                try await FirebaseChatService
                    .shared
                    .updateMessagesSeenStatus(startFromMessageID: startMessageID,
                                              seenByUser: seenByUser,
                                              chatID: chatID,
                                              limit: limit)
            } catch {
                print("Could not update messages seen status in firebase: ", error)
            }
        }
    }
}

