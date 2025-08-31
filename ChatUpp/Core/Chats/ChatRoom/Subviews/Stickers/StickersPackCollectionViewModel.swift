//
//  StickersPackCollectionViewModel.swift
//  ChatUpp
//
//  Created by Andrei Pripa on 8/30/25.
//

import Foundation
import SwiftUI
import Gzip

final class StickersPackCollectionViewModel: SwiftUI.ObservableObject
{
    var stickersCategory: [Stickers.Category] {
        return Stickers.Category.allCases
    }
    
    func getStickerData(from url: URL,
                        format: Stickers.StickerFormat) -> Data?
    {
        do {
            let compressedData = try Data(contentsOf: url)
            return try processData(compressedData,
                               withFormat: format)
        } catch {
            print("could not decompress tgs: \(error)")
        }
        return nil
    }
    
    private func processData(_ data: Data,
                             withFormat stickerFormat: Stickers.StickerFormat) throws -> Data
    {
        switch stickerFormat {
        case .tgs: return try data.gunzipped()
        case .webp: return data
        }
    }
}
