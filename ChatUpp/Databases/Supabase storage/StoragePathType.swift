//
//  StoragePathType.swift
//  ChatUpp
//
//  Created by Andrei Pripa on 11/25/25.
//

import Foundation

// MARK: - StoragePathType
enum StoragePathType
{
    case user(String)
    case message(MessagePathType)
    case group(String)
    case themes(String)

    var path: String
    {
        switch self
        {
        case .user(let id):
            return "users/\(id)"
        case .message(let type):
            return "messages/\(type.path)"
        case .group(let id):
            return "groups/\(id)"
        case .themes(let resolution):
            return "themes/\(resolution)"
        }
    }

    enum MessagePathType
    {
        case image(String)
        case audio(String)

        var path: String
        {
            switch self
            {
            case .audio(let name), .image(let name): return "\(directory)/\(name)"
            }
        }

        var directory: String
        {
            switch self
            {
            case .audio: return "voices"
            case .image: return "images"
            }
        }
    }
}

// MARK: - ImageMetadata
struct ImageMetadata {
    let path: String
    let name: String
}
