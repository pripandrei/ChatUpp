//
//  StickersPackCollectionScreen.swift
//  ChatUpp
//
//  Created by Andrei Pripa on 8/30/25.
//

import SwiftUI
import Lottie

struct StickersPackCollectionView: View
{
    @StateObject var stickerPackViewModel: StickersPackCollectionViewModel = .init()

    private let columns = Array(repeating: GridItem(.flexible(), spacing: 1), count: 5)

    var body: some View
    {
        ScrollView
        {
            LazyVGrid(columns: columns, spacing: 1)
            {
                stickersCollectionView()
            }
            .padding()
        }
        .background(Color(ColorManager.navigationBarBackgroundColor))
    }
}

extension StickersPackCollectionView
{
    private func stickersCollectionView() -> some View
    {
        ForEach(stickerPackViewModel.stickersCategory) { category in
            Section(category.title, content: {
                ForEach(category.pack, id: \.self) { stickerURL in
                    if let stickerData = stickerPackViewModel.getStickerData(
                        from: stickerURL,
                        format: category.format)
                    {
                        StickerView(data: stickerData,
                                    format: category.format)
                    }
                }
            })
        }
    }
}

struct StickerView: View
{
    let data: Data
    let format: Stickers.StickerFormat
    //    @ObservedObject var viewModel: StickersPackCollectionViewModel
    
    var body: some View
    {
        switch format {
        case .tgs: LottieView(from: data)
        case .webp: ImageView(from: data)
        }
    }
    
    /// For animated stickers
    @ViewBuilder
    private func LottieView(from data: Data) -> some View
    {
        if let animation = try? Lottie.LottieView(animation: .from(data: data))
        {
            animation.playbackMode(.playing(.toProgress(1, loopMode: .loop)))
                .resizable()
                .frame(height: 75)
        }
    }
    
    /// For static stickers
    @ViewBuilder
    private func ImageView(from data: Data) -> some View
    {
        if let image = UIImage(data: data) {
            Image(uiImage: image)
                .resizable()
                .frame(width: 76, height: 75)
        }
    }
}


#Preview {
    let vm = StickersPackCollectionViewModel()
    StickersPackCollectionView()
}
