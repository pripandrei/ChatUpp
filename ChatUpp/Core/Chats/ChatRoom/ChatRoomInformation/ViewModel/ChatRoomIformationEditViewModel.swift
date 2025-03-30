//
//  ChatRoomIformationEditViewModel.swift
//  ChatUpp
//
//  Created by Andrei Pripa on 3/24/25.
//
import SwiftUI


final class ChatRoomIformationEditViewModel: SwiftUI.ObservableObject, ImageRepositoryRepresentable
{
    private let conversation: Chat
    @Published private(set) var imageSampleRepository: ImageSampleRepository?
    
    @Published var groupTitle: String = ""
    @Published var groupDescription: String = "English study group for beginners"
    
    init (conversation: Chat) {
        self.conversation = conversation
        self.groupTitle = conversation.title
    }

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
        await updateRealmConversation()
        try await FirebaseChatService.shared.updateChat(conversation)
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
extension ChatRoomIformationEditViewModel
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
