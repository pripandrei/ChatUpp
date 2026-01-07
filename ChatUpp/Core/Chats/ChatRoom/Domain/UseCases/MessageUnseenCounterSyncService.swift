//
//  MessageUnseenCounterSyncService.swift
//  ChatUpp
//
//  Created by Andrei Pripa on 1/7/26.
//
import Foundation

actor MessageUnseenCounterSyncService
{
    private var unseenMessagesCount: Int = 0
    private var remoteUpdateTask: Task<Void, Never>?
    
    func updateLocal(chat: ThreadSafe<Chat>,
                     authUserID: String,
                     numberOfUpdatedMessages: Int,
                     increment: Bool) async
    {
        let delta = increment ? numberOfUpdatedMessages : -numberOfUpdatedMessages
        self.unseenMessagesCount = max(0, unseenMessagesCount + delta)
        
        await MainActor.run
        {
            guard let chat = RealmDatabase.shared.resolveThreadSafeObject(threadSafeObject: chat) else {return}

            RealmDatabase.shared.update(object: chat)
            { dbChat in
                if let participant = dbChat.getParticipant(byID: authUserID)
                {
                    let updatedCount = increment ?
                    participant.unseenMessagesCount + numberOfUpdatedMessages
                    :
                    participant.unseenMessagesCount - numberOfUpdatedMessages
                    
                    participant.unseenMessagesCount = max(0, updatedCount)
                }
            }
        }
    }
  
    func scheduleRemoteUpdate(chatID: String,
                              authUserID: String,
                              increment: Bool) async
    {
        remoteUpdateTask?.cancel()
        
        remoteUpdateTask = Task
        {
            try? await Task.sleep(for: .seconds(1))
            
            guard !Task.isCancelled else { return }
            
            await self.updateRemote(chatID: chatID,
                              authUserID: authUserID,
                              numberOfUpdatedMessages: self.unseenMessagesCount,
                              increment: increment)
            self.unseenMessagesCount = 0
        }
    }
    
    func updateRemote(chatID: String,
                      authUserID: String,
                      numberOfUpdatedMessages: Int,
                      increment: Bool) async
    {
//        Task
//        {
            do {
                try await FirebaseChatService.shared.updateUnseenMessagesCount(
                    for: [authUserID],
                    inChatWithID: chatID,
                    counter: numberOfUpdatedMessages,
                    shouldIncrement: increment
                )
            } catch {
                print("Error updating unseen messages counter remote: ", error)
            }
//        }
    }
}
