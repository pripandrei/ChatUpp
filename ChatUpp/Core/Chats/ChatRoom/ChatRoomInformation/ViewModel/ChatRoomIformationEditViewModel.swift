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
    
//    private var imageURL: String
//    {
//        if let chatImageURL = conversation.thumbnailURL {
//            return chatImageURL.replacingOccurrences(of: ".jpg", with: "_medium.jpg")
//        } else {
//            return "default_group_photo"
//        }
//    }
    
    func retrieveImageData() -> Data?
    {
        if let chatImageURL = conversation.thumbnailURL {
            let url = chatImageURL.replacingOccurrences(of: ".jpg", with: "_medium.jpg")
            return CacheManager.shared.retrieveImageData(from: url)
        }
        return nil
    }
}

extension ChatRoomIformationEditViewModel
{
    func updateImageRepository(repository: ImageSampleRepository) {
        self.imageSampleRepository = repository
    }
    
}
