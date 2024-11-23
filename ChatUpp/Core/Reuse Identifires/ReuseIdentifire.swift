//
//  ReuseIdentifire.swift
//  ChatUpp
//
//  Created by Andrei Pripa on 11/23/24.
//

import Foundation

// MARK: - cell identifires

enum ReuseIdentifire
{
    enum ConversationTableCell: String
    {
        case message,
             messageSekeleton,
             unseenTitle
        
        var identifire: String
        {
            switch self {
            case .message: return rawValue.capitalized
            case .messageSekeleton: return rawValue.capitalized
            case .unseenTitle: return rawValue.capitalized
            }
        }
    }
    
    enum SearchRusultsTableCell: String {
        case searchResult
        
        var identifire: String
        {
            switch self {
            case .searchResult: return rawValue.capitalized
            }
        }
    }
    
    enum ChatTableCell: String {
        case chat
        
        var identifire: String
        {
            switch self {
            case .chat: return rawValue.capitalized
            }
        }
    }
    
    enum HeaderFooter: String
    {
        case footer
        
        var identifire: String
        {
            switch self {
            case .footer: return rawValue.capitalized
            }
        }
    }
    
    enum ProfileEditingCollectionCell: String {
        case list
        case header
        
        var identifire: String
        {
            switch self {
            case .header: return rawValue.capitalized
            case .list: return rawValue.capitalized
            }
        }
    }
}
