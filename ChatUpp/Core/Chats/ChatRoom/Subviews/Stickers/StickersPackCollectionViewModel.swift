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
    
    init() {
//        getStickerData(from: urlTest, format: .tgs)
    }
    
    func getStickerData(from url: URL,
                        format: Stickers.StickerFormat) -> Data?
    {
        do {
            let compressedData = try Data(contentsOf: url)
            let data = try processData(compressedData,
                                       withFormat: format)
//            saveToDesktop(data: data)
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

extension StickersPackCollectionViewModel
{
    func saveToDesktop(data: Data)
    {
        var url = URL(string: "file:///Users/andrei/Desktop/myFile.json")!
        
        do {
            try data.write(to: url)
            print("Saved JSON to Desktop at: \(url.path)")
        } catch {
            print("Failed to save JSON: \(error)")
        }
    }
    
    var urlTest: URL {
//        let names = ["vb_10", "vb_62", "vb_17", "vb_20"]
//        let names = ["vb_10_600", "vb_6_600", "vb_3_600"]
//        let names = ["vb_10_webb", "vb_6_webb", "vb_3_webb"]
//        let names = ["file_0"]
        let names = ["dd_24"]
        let url = Bundle.main.url(forResource: names.randomElement()!, withExtension: "apng") ?? URL(filePath: "")
        print("URL: ", url)
        return url
    }
}
