//
//  sad.swift
//  ChatUpp
//
//  Created by Andrei Pripa on 4/13/25.
//

import Foundation
import Combine

//MARK: - Users listener

final class ConversationUsersListinerService
{
    private var cancellables = Set<AnyCancellable>()
    
    @Published private(set) var chatUsers: [User] = []
    @Published private(set) var chatParticipants: [ChatParticipant]
    
    init(chatUsers: [ChatParticipant]) {
        self.chatParticipants = chatUsers
    }
    
    func removeSubscribers() {
        cancellables.forEach { $0.cancel() }
    }
    
    /// - Temporary fix while firebase functions are deactivated
    ///
//    func addUserObserver()
//    {
//        let userPublishers = chatParticipants.map { participant in
//            RealtimeUserService.shared.addObserverToUsers(participant.userID)
//        }
//        
//        Publishers.MergeMany(userPublishers)
//            .sink(receiveValue: { [weak self] updatedUser in
//                guard let self = self else { return }
//                
//                if let index = self.chatParticipants.firstIndex(where: { $0.userID == updatedUser.id })
//                {
////                    self.chatUsers[index] = updatedUser // TODO: - shoul save to realm and attache listener to objects
//                    
//                    
////                    let currentUser = self.chatUsers[index]
////                    if updatedUser.isActive != currentUser.isActive {
////                        self.chatUsers[index] = currentUser.updateActiveStatus(lastSeenDate: updatedUser.lastSeen, isActive: updatedUser.isActive)
////                    }
//                }
//            })
//            .store(in: &cancellables)
//    }
//    
//    func addUsersListener()
//    {
//        let usersID = chatParticipants.map { $0.userID }
//        FirestoreUserService
//            .shared
//            .addListenerToUsers(usersID)
//            .sink(receiveValue: { [weak self] userUpdatedObject in
//                if userUpdatedObject.changeType == .modified
//                {
//                    if let index = self?.chatUsers.firstIndex(where: { $0.id == userUpdatedObject.data.id })
//                    {
////                        self?.chatUsers[index] = userUpdatedObject.data // TODO: - shoul save to realm and attache listener to objects
//                    }
//                }
//            }).store(in: &cancellables)
//    }
}
