//
//  MessageType.swift
//  ChatUpp
//
//  Created by Andrei Pripa on 9/18/25.
//

import Foundation
import RealmSwift

//class MessageContent: EmbeddedObject {
//    @Persisted var type: String
//}
//
//class TextContent: MessageContent {
//    @Persisted var text: String = ""
//}
//
//class AudioContent: MessageContent {
//    @Persisted var audioPath: String = ""
//    @Persisted var samples: List<Float>
//}
//
//class ImageContent: MessageContent {
//    @Persisted var imagePath: String = ""
//    @Persisted var width: Float
//    @Persisted var height: Float
//}
//
//class VideoContent: MessageContent {
//    @Persisted var videoPath: String = ""
//    @Persisted var thumbnailPath: String?
//}

enum MessageType: String, PersistableEnum, Codable
{
    case text
    case title
    case image
    case sticker
    case audio
    case video
    case imageText = "image/text"
}

//struct MessageMediaParameters
//{
//    let imagePath: String?
//    let audioPath: String?
//    let stickerPath: String?
//    let videoPath: String?
//    let audioSamples: [Float]?
//    
//    init(imagePath: String? = nil,
//         audioPath: String? = nil,
//         stickerPath: String? = nil,
//         videoPath: String? = nil,
//         audioSamples: [Float]? = nil)
//    {
//        self.imagePath = imagePath
//        self.audioPath = audioPath
//        self.stickerPath = stickerPath
//        self.videoPath = videoPath
//        self.audioSamples = audioSamples
//    }
//}


enum MessageMediaContent
{
    case image(path: String)
    case audio(path: String, samples: [Float])
    case sticker(path: String)
    case video(path: String)
    case imageWithText(path: String, text: String)
    
    var imagePath: String? {
        switch self {
        case .image(let path), .imageWithText(let path, _): return path
        default: return nil
        }
    }
    
    var audioPath: String? {
        if case .audio(let path, _) = self { return path }
        return nil
    }
    
    var audioSamples: [Float]? {
        if case .audio(_, let samples) = self { return samples }
        return nil
    }
    
    var stickerPath: String? {
        if case .sticker(let path) = self { return path }
        return nil
    }
    
    var videoPath: String? {
        if case .video(let path) = self { return path }
        return nil
    }
}
