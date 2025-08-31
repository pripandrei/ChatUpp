//
//  StickersPackModel.swift
//  ChatUpp
//
//  Created by Andrei Pripa on 8/31/25.
//

import Foundation



enum Stickers
{
    enum Category: String, CaseIterable, Identifiable
    {
        case harryGorilla
        case duck
        case vaultBoy
        
        var id: String { rawValue }
        
        var title: String
        {
            switch self {
            case .duck: return "Duck"
            case .harryGorilla: return "Harry Gorilla"
            case .vaultBoy: return "Vault Boy"
            }
        }
        
        var prefix: String
        {
            switch self {
            case .duck: return "duck_"
            case .harryGorilla: return "hg_"
            case .vaultBoy: return "vb_"
            }
        }
        
        var count: Int {
            switch self {
            case .duck: return 27
            case .harryGorilla: return 20
            case .vaultBoy: return 49
            }
        }
        
        var format: StickerFormat {
            switch self {
            case .vaultBoy: return .webp
            default: return .tgs
            }
        }
        
        var pack: [URL]
        {
            var _extension = ""
            
            switch self {
            case .vaultBoy: _extension = "webp"
            default: _extension = "tgs"
            }
            
            return (1...count).compactMap { index in
                Bundle.main.url(forResource: "\(prefix)\(index)", withExtension: _extension)
            }
        }
    }
    
    enum StickerFormat
    {
        case tgs
        case webp
    }
}
