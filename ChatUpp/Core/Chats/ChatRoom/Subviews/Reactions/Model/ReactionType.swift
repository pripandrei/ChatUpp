//
//  ReactionModel.swift
//  ChatUpp
//
//  Created by Andrei Pripa on 9/17/25.
//

import Foundation

// MARK: - Models
enum ReactionType: String, CaseIterable, Identifiable
{
    case excited = "🤩"
    case celebrating = "🥳"
    case heart = "❤️"
    case laughing = "🤣"
    case peace = "✌️"
    case cool = "😎"
    case alien = "👽"
    case tongueShow = "😜"
    case creature = "👾"
    case inLove = "🥰"
    case clappingHands = "👏"
    case robot = "🤖"
    case omg = "🤯"
    case handshake = "🤝"
    case angry = "🤬"
    case caring = "🥺"
    
    var id: String { self.rawValue }
    
    /// Mirrored right-to-left reveal order: the rightmost emojis pop first
    /// (with the snappiest spring) and the wave travels toward the leading
    /// edge of the panel.
    var animationDelay: Double
    {
        switch self {
        case .cool, .alien: return 0.15
        case .laughing, .peace: return 0.20
        case .heart: return 0.27
        case .excited, .celebrating: return 0.35
        default: return 0.0 // for rest of emojies (that are not shown initialy)
        }
    }

    var animationDamping: Double
    {
        switch self {
        case .cool, .alien: return 25
        case .laughing, .peace: return 20
        case .heart: return 15
        case .excited, .celebrating: return 10
        default: return 0.0 // for rest of emojies (that are not shown initialy)
        }
    }
}
