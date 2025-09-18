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
    
    var id: String { self.rawValue }
    
    var animationDelay: Double
    {
        switch self {
        case .excited, .celebrating: return 0.15
        case .heart: return 0.20
        case .laughing, .peace: return 0.27
        case .cool, .alien: return 0.35
        }
    }
    
    var animationDamping: Double
    {
        switch self {
        case .excited, .celebrating: return 25
        case .heart: return 20
        case .laughing, .peace: return 15
        case .cool, .alien: return 10
        }
    }
}
