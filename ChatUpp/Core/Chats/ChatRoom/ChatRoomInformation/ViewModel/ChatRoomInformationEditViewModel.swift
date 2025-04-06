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
        self.groupTitle = conversation.title
    }
    
    lazy var authenticatedUser: User? = {
        guard let key = AuthenticationManager.shared.authenticatedUser?.uid else { return nil }
        return RealmDataBase.shared.retrieveSingleObject(ofType: User.self, primaryKey: key)
    }()

    func retrieveImageData() -> Data?
    {
        if let chatImageURL = conversation.thumbnailURL {
            let url = chatImageURL.replacingOccurrences(of: ".jpg", with: "_medium.jpg")
            return CacheManager.shared.retrieveImageData(from: url)
        }
        return nil
    }
    
    @MainActor
    private func createMessage(text: String) async throws -> Message
    {
        return Message(
            id: UUID().uuidString,
            messageBody: text,
            senderId: AuthenticationManager.shared.authenticatedUser!.uid,
            timestamp: Date(),
            messageSeen: nil,
            seenBy: [],
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
    func saveEditedData() async throws
    {
        try await processImageSamples()
        
        // Check for group title changes
        try await handleGroupChange(condition: conversation.title != groupTitle,
                                    changeDescription: "changed group name to '\(groupTitle)'"
        )
        
        // Check for group avatar changes
        let newAvatarPath = imageSampleRepository?.imagePath(for: .original)
        try await handleGroupChange(condition: conversation.thumbnailURL != newAvatarPath,
                                    changeDescription: "changed group avatar"
        )
        
        // Update local Realm and Firestore chat data
        updateRealmConversation(newAvatarPath: newAvatarPath)
        try FirebaseChatService.shared.updateChat(conversation)
    }

    @MainActor
    private func handleGroupChange(condition: Bool,
                                   changeDescription: String) async throws
    {
        guard condition else { return }
        
        let message = try await createMessage(text: "\(authenticatedUser?.name ?? "-") \(changeDescription)")
        try await addMessageToDatabase(message)
        try await updateUnseenMessageCounterRemote()
        try await FirebaseChatService.shared.updateChatRecentMessage(
            recentMessageID: message.id,
            chatID: conversation.id
        )
    }

    @MainActor
    private func addMessageToDatabase(_ message: Message) async throws
    {
        RealmDataBase.shared.add(object: message)
        try await FirebaseChatService.shared.createMessage(
            message: message,
            atChatPath: conversation.id
        )
    }

    @MainActor
    private func updateRealmConversation(newAvatarPath: String?)
    {
        RealmDataBase.shared.update(object: conversation) { realmChat in
            realmChat.name = groupTitle
            realmChat.thumbnailURL = newAvatarPath
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
        CacheManager.shared.saveImageData(imageData, toPath: path)
    }
    
}
