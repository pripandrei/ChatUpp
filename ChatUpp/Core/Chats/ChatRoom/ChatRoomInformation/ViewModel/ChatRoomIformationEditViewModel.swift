//
//  ChatRoomIformationEditViewModel.swift
//  ChatUpp
//
//  Created by Andrei Pripa on 3/24/25.
//
import SwiftUI


final class ChatRoomIformationEditViewModel: SwiftUI.ObservableObject
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
    
    func saveEditedData() async throws
    {
        try await processImageSamples()
        
        // Check for group title change
        if conversation.title != groupTitle {
            try await createMessage(messageText: "\(authenticatedUser?.name ?? "-") changed group name to '\(groupTitle)'")
        }
        
        // Check for avatar change
        let newImagePath = imageSampleRepository?.imagePath(for: .original)
        if conversation.thumbnailURL != newImagePath {
            try await createMessage(messageText: "\(authenticatedUser?.name ?? "-") changed group avatar")
        }
                
        await updateRealmConversation()
        try await FirebaseChatService.shared.updateChat(conversation)
    }

    private func createMessage(messageText text: String) async throws
    {
        let message = Message(
            id: UUID().uuidString,
            messageBody: text,
            senderId: AuthenticationManager.shared.authenticatedUser!.uid,
            timestamp: Date(),
            messageSeen: false,
            isEdited: false,
            imagePath: nil,
            imageSize: nil,
            repliedTo: nil
        )
        
        RealmDataBase.shared.add(object: message)
        try await FirebaseChatService.shared.createMessage(message: message, atChatPath: conversation.id)
    }
    
    @MainActor
    private func updateRealmConversation()
    {
        RealmDataBase.shared.update(object: conversation) { realmChat in
            realmChat.name = groupTitle
            realmChat.thumbnailURL = imageSampleRepository?.imagePath(for: .original)
        }
    }
}

//MARK: - Image update
extension ChatRoomIformationEditViewModel: ImageRepositoryRepresentable
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
