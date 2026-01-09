////
////  MessageUnseenCounterSyncService.swift
////  ChatUpp
////
////  Created by Andrei Pripa on 1/7/26.
////
//import Foundation
//
//actor MessageUnseenCounterSyncService
//{
//    struct PendingDelta
//    {
//        var value: Int
//        var task: Task<Void, Never>
//    }
//    
//    // chatID → pending delta
//    private var pending: [String: PendingDelta] = [:]
//    
//    func updateLocal(
//        chat: ThreadSafe<Chat>,
//        userID: String,
//        delta: Int
//    ) async {
//        guard delta != 0 else { return }
//
//        await MainActor.run {
//            guard let chat = RealmDatabase.shared.resolveThreadSafeObject(threadSafeObject: chat)
//            else { return }
//            
////            RealmDatabase.shared.update {
//            RealmDatabase.shared.update(object: chat) { dbChat in
//                if let participant = dbChat.getParticipant(byID: userID) {
//                    participant.unseenMessagesCount = max(0, participant.unseenMessagesCount + delta)
//                }
//            }
//        }
//    }
//    
//    func enqueueRemoteDelta(
//        chatID: String,
//        userID: String,
//        delta: Int
//    ) async
//    {
//        guard delta != 0 else { return }
//
//        // Cancel previous scheduled flush
//        if let existing = pending[chatID]
//        {
//            existing.task.cancel()
//            pending[chatID]?.value += delta
//        } else {
//            pending[chatID] = PendingDelta(
//                value: delta,
//                task: Task {}
//            )
//        }
//
//        let task = Task { [weak self] in
//            try? await Task.sleep(for: .seconds(1))
//            await self?.flush(chatID: chatID, userID: userID)
//        }
//
//        pending[chatID]?.task = task
//    }
//    
//    private func flush(
//        chatID: String,
//        userID: String
//    ) async
//    {
//        guard let pendingDelta = pending[chatID] else { return }
//
//        pending[chatID] = nil
//
//        let delta = pendingDelta.value
//        guard delta != 0 else { return }
//
//        do {
//            try await FirebaseChatService.shared.updateUnseenMessagesCount(
//                for: [userID],
//                inChatWithID: chatID,
//                counter: abs(delta),
//                shouldIncrement: delta > 0
//            )
//        } catch {
//            // Retry on failure (important!)
//            await enqueueRemoteDelta(chatID: chatID, userID: userID, delta: delta)
//        }
//    }
//  
////    func scheduleRemoteUpdate(chatID: String,
////                              userID: String,
////                              increment: Bool) async
////    {
////        remoteUpdateTask?.cancel()
////        
////        remoteUpdateTask = Task
////        {
////            try? await Task.sleep(for: .seconds(1))
////            
////            guard !Task.isCancelled else { return }
////            
////            let counter = self.unseenMessagesCount
////            self.unseenMessagesCount = 0
////            await self.updateRemote(chatID: chatID,
////                                    userID: userID,
////                                    numberOfUpdatedMessages: counter,
////                                    increment: increment)
////        }
////    }
//    
//    func updateRemote(chatID: String,
//                      userID: String,
//                      numberOfUpdatedMessages: Int,
//                      increment: Bool) async
//    {
////        Task
////        {
//        print("counter read: " , numberOfUpdatedMessages)
//            do {
//                try await FirebaseChatService.shared.updateUnseenMessagesCount(
//                    for: [userID],
//                    inChatWithID: chatID,
//                    counter: numberOfUpdatedMessages,
//                    shouldIncrement: increment
//                )
//            } catch {
//                print("Error updating unseen messages counter remote: ", error)
//            }
////        }
//    }
//    
//    func updateParticipantsUnseenCounterRemote(chat: ThreadSafe<Chat>) async
//    {
//        guard let chat = RealmDatabase.shared.resolveThreadSafeObject(threadSafeObject: chat) else {return}
//        
//        let currentUserID = AuthenticationManager.shared.authenticatedUser!.uid
//        let otherUserIDs = Array(chat.participants
//            .map(\.userID)
//            .filter { $0 != currentUserID })
//
//        do {
//            try await FirebaseChatService.shared.updateUnreadMessageCount(
//                for: otherUserIDs,
//                inChatWithID: chat.id,
//                increment: true
//            )
//        } catch {
//            print("error on updating unseen message count for particiapnts: " , error)
//        }
//    }
//    
//}


//
//  MessageUnseenCounterSyncService.swift
//  ChatUpp
//
//  Created by Andrei Pripa on 1/7/26.
//
import Foundation

actor MessageUnseenCounterSyncService
{
    var value: Int = 0
    var scheduledTask: Task<Void, Never> = .init {}
    
    func updateLocal(
        chat: ThreadSafe<Chat>,
        userID: String,
        delta: Int
    ) async {
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

        scheduledTask.cancel()
        value += delta

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
        let delta = self.value
        self.value = 0
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
  
//    func scheduleRemoteUpdate(chatID: String,
//                              userID: String,
//                              increment: Bool) async
//    {
//        remoteUpdateTask?.cancel()
//
//        remoteUpdateTask = Task
//        {
//            try? await Task.sleep(for: .seconds(1))
//
//            guard !Task.isCancelled else { return }
//
//            let counter = self.unseenMessagesCount
//            self.unseenMessagesCount = 0
//            await self.updateRemote(chatID: chatID,
//                                    userID: userID,
//                                    numberOfUpdatedMessages: counter,
//                                    increment: increment)
//        }
//    }
    
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
