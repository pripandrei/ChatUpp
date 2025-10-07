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

struct MessageMediaParameters
{
    let imagePath: String?
    let audioPath: String?
    let stickerPath: String?
    let videoPath: String?
    
    init(imagePath: String? = nil,
         audioPath: String? = nil,
         stickerPath: String? = nil,
         videoPath: String? = nil)
    {
        self.imagePath = imagePath
        self.audioPath = audioPath
        self.stickerPath = stickerPath
        self.videoPath = videoPath
    }
}
