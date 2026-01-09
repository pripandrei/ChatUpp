
//
//  MessageUnseenCounterSyncService.swift
//  ChatUpp
//
//  Created by Andrei Pripa on 1/7/26.
//
import Foundation

actor MessageUnseenCounterSyncService
{
    private var unseenCounter: Int = 0
    private var scheduledTask: Task<Void, Never> = .init {}
    
    func updateLocal(
        chat: ThreadSafe<Chat>,
        userID: String,
        delta: Int
    )
    {
        guard delta != 0 else { return }
        
        guard let chat = RealmDatabase.shared.resolveThreadSafeObject(threadSafeObject: chat)
        else { return }
        
        RealmDatabase.shared.update {
            if let participant = chat.getParticipant(byID: userID) {
                participant.unseenMessagesCount = max(0, participant.unseenMessagesCount + delta)
            }
        }
    }
    
    func scheduleRemoteUpdate(
        chatID: String,
        userID: String,
        delta: Int
    ) async
    {
        guard delta != 0 else { return }

        self.scheduledTask.cancel()
        self.unseenCounter += delta

        let task = Task { [weak self] in
            try? await Task.sleep(for: .seconds(1))
            guard !Task.isCancelled else { return }
            
            await self?.flush(chatID: chatID, userID: userID)
        }

        self.scheduledTask = task
    }
    
    private func flush(
        chatID: String,
        userID: String
    ) async
    {
        let delta = self.unseenCounter
        self.unseenCounter = 0
        guard delta != 0 else { return }

        do {
            try await FirebaseChatService.shared.updateUnseenMessagesCount(
                for: [userID],
                inChatWithID: chatID,
                counter: abs(delta),
                shouldIncrement: delta > 0
            )
        } catch {
            // Retry on failure (important!)
            await scheduleRemoteUpdate(chatID: chatID,
                                       userID: userID,
                                       delta: delta)
        }
    }

    func updateRemote(chatID: String,
                      userID: String,
                      numberOfUpdatedMessages: Int,
                      increment: Bool) async
    {
//        Task
//        {
        print("counter read: " , numberOfUpdatedMessages)
            do {
                try await FirebaseChatService.shared.updateUnseenMessagesCount(
                    for: [userID],
                    inChatWithID: chatID,
                    counter: numberOfUpdatedMessages,
                    shouldIncrement: increment
                )
            } catch {
                print("Error updating unseen messages counter remote: ", error)
            }
//        }
    }
    
    func updateParticipantsUnseenCounterRemote(chat: ThreadSafe<Chat>) async
    {
        guard let chat = RealmDatabase.shared.resolveThreadSafeObject(threadSafeObject: chat) else {return}
        
        let currentUserID = AuthenticationManager.shared.authenticatedUser!.uid
        let otherUserIDs = Array(chat.participants
            .map(\.userID)
            .filter { $0 != currentUserID })

        do {
            try await FirebaseChatService.shared.updateUnreadMessageCount(
                for: otherUserIDs,
                inChatWithID: chat.id,
                increment: true
            )
        } catch {
            print("error on updating unseen message count for particiapnts: " , error)
        }
    }
    
}
