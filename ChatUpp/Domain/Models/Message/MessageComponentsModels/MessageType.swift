//
//  MessageType.swift
//  ChatUpp
//
//  Created by Andrei Pripa on 9/18/25.
//

import Foundation
import RealmSwift

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
