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
        case dolphieDolhp
        case duck
        case vaultBoy
        case huskySiberian
        case people
        case lightningBug
        case stealthMoon
        
        var id: String { rawValue }
        
        var title: String
        {
            switch self {
            case .duck: return "Duck"
            case .harryGorilla: return "Harry Gorilla"
            case .vaultBoy: return "Vault Boy"
            case .dolphieDolhp:  return "Dolhpin Dolp"
            case .huskySiberian:  return "Husky Siberian"
            case .people:  return "People"
            case .stealthMoon:  return "Stealth Moon"
            case .lightningBug: return "Lightning Bug"
            }
        }
        
        var prefix: String
        {
            switch self {
            case .duck: return "duck_"
            case .harryGorilla: return "hg_"
            case .vaultBoy: return "vb_"
            case .dolphieDolhp: return "dd_"
            case .huskySiberian: return "hs_"
            case .people: return "people_"
            case .stealthMoon: return "sm_"
            case .lightningBug: return "lb_"
            }
        }
        
        var count: Int {
            switch self {
            case .duck: return 40
            case .harryGorilla: return 27
            case .vaultBoy: return 26
            case .dolphieDolhp: return 27
            case .lightningBug: return 30
            case .people: return 34
            case .huskySiberian: return 24
            case .stealthMoon: return 31
            }
        }
        
        var format: StickerFormat {
//            switch self {
//            case .felloutBoy: return .webp
//            default: return .tgs
//            }
            
            return .webp
        }
        
        private var fileExtension: String {
            switch format {
            case .tgs: "tgs"
            case .webp: "webp"
            }
        }
        
        var pack: [URL]
        {
            return (1...count).compactMap { index in
                Bundle.main.url(forResource: "\(prefix)\(index)",
                                withExtension: "json")
            }
        }
    }
    
    enum StickerFormat
    {
        case tgs
        case webp
    }
}
