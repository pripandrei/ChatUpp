//
//  ChatRoomIformationEditViewModel.swift
//  ChatUpp
//
//  Created by Andrei Pripa on 3/24/25.
//
import SwiftUI


final class ChatRoomInformationEditViewModel: SwiftUI.ObservableObject
{
    private let conversation: Chat
    @Published private(set) var imageSampleRepository: ImageSampleRepository?
    
    @Published var groupTitle: String = ""
    @Published var groupDescription: String = "English study group for beginners"
    
    init (conversation: Chat) {
        self.conversation = conversation
        self.groupTitle = conversation.name ?? "Uknown"
    }
    
    lazy var authenticatedUser: User? = {
        guard let key = AuthenticationManager.shared.authenticatedUser?.uid else { return nil }
        return RealmDatabase.shared.retrieveSingleObject(ofType: User.self, primaryKey: key)
    }()

    func retrieveImageData() -> Data?
    {
        if let chatImageURL = conversation.thumbnailURL {
            let url = chatImageURL
            return CacheManager.shared.retrieveData(from: url)
        }
        return nil
    }
    
    @MainActor
    private func createMessage(text: String) async throws -> Message
    {
        let isGroupChat = conversation.isGroup
        let authUserID = AuthenticationManager.shared.authenticatedUser!.uid
        let seenByValue = isGroupChat ? [authUserID] : nil
        
        return Message(
            id: UUID().uuidString,
            messageBody: text,
            senderId: authUserID,
            timestamp: Date(),
            messageSeen: isGroupChat ? nil : false,
            seenBy: seenByValue,
            isEdited: false,
            imagePath: nil,
            imageSize: nil,
            repliedTo: nil,
            type: .title
        )
    }
}

//MARK: - Save edited data
extension ChatRoomInformationEditViewModel
{
    @MainActor
    func saveEditedData() async throws -> DataUpdate
    {
        try await processImageSamples()
        
        var anyUpdatesMade = false
        
        if conversation.name != groupTitle
        {
            try await handleGroupChange(
                changeDescription: "changed group name to '\(groupTitle)'"
            )
            anyUpdatesMade = true
        }
        
        let newAvatarPath = imageSampleRepository?.imagePath(for: .original)
        if newAvatarPath != nil {
            try await handleGroupChange(
                changeDescription: "changed group avatar"
            )
            anyUpdatesMade = true
        }
        
        if anyUpdatesMade
        {
            updateRealmConversation(newAvatarPath: newAvatarPath)
            try FirebaseChatService.shared.updateChat(conversation)
            return .changed
        }
        return .unchanged
    }

    @MainActor
    private func handleGroupChange(changeDescription: String) async throws
    {
        let message = try await createMessage(text: changeDescription)
        try await addMessageToDatabase(message)
        try await updateUnseenMessageCounterRemote()
        try await FirebaseChatService.shared.updateChatRecentMessage(
            recentMessageID: message.id,
            chatID: conversation.id
        )
        ChatManager.shared.sendNewMessage(message)
    }

    @MainActor
    private func addMessageToDatabase(_ message: Message) async throws
    {
        RealmDatabase.shared.update(object: conversation) { realmChat in
            realmChat.conversationMessages.append(message)
        }
        try await FirebaseChatService.shared.createMessage(
            message: message,
            atChatPath: conversation.id
        )
    }

    @MainActor
    private func updateRealmConversation(newAvatarPath: String?)
    {
        RealmDatabase.shared.update(object: conversation) { realmChat in
            realmChat.name = groupTitle
            if let newAvatarPath
            {
                realmChat.thumbnailURL = newAvatarPath
            }
        }
    }

    @MainActor
    private func updateUnseenMessageCounterRemote() async throws
    {
        let currentUserID = AuthenticationManager.shared.authenticatedUser!.uid
        let otherUserIDs = Array(conversation.participants
            .map(\.userID)
            .filter { $0 != currentUserID })

        try await FirebaseChatService.shared.updateUnreadMessageCount(
            for: otherUserIDs,
            inChatWithID: conversation.id,
            increment: true
        )
    }
}

//MARK: - Image update
extension ChatRoomInformationEditViewModel: ImageRepositoryRepresentable
{
    func updateImageRepository(repository: ImageSampleRepository) {
        self.imageSampleRepository = repository
    }
    
    private func processImageSamples() async throws
    {
        guard let sampleRepository = imageSampleRepository else { return }
        
        for (key, imageData) in sampleRepository.samples {
            let path = sampleRepository.imagePath(for: key)
            try await saveImage(imageData, path: path)
        }
    }
    
    @MainActor
    private func saveImage(_ imageData: Data, path: String) async throws
    {
        try await FirebaseStorageManager.shared.saveImage(data: imageData, to: .group(conversation.id), imagePath: path)
        CacheManager.shared.saveData(imageData, toPath: path)
    }
}

extension ChatRoomInformationEditViewModel
{
    enum DataUpdate
    {
        case changed
        case unchanged
    }
}
