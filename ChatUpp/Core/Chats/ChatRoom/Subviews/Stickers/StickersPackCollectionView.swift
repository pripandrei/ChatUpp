////
////  StickersPackCollectionScreen.swift
////  ChatUpp
////
////  Created by Andrei Pripa on 8/30/25.
////
//
//import SwiftUI
//import Lottie
//import SDWebImageSwiftUI
//import SDWebImageWebPCoder
//
////class TestPublisheVM: SwiftUI.ObservableObject
////{
////    @Published var counter : Int = 0
////    
////    init() {
////        increment()
////    }
////    
////    func increment()
////    {
////        Timer.scheduledTimer(withTimeInterval: 4.0, repeats: true) { timer in
////            self.counter += 1
////        }
////    }
////}
////
////struct TestPublishe: View
////{
////    @StateObject var TestPublisheVM: TestPublisheVM = .init()
////    
////    private var colors: [Color] = [.green,.orange,.indigo]
////    
////    var body: some View
////    {
//////        Rectangle()
////        VStack {}
////            .frame(width: 100, height: 100)
//////            .foregroundStyle(.blue)
//////            .background(Color(.purple))
////            .background(colors.randomElement()!)
////    }
////}
//
//struct StickersPackCollectionView: View {
//    @StateObject var stickerPackViewModel: StickersPackCollectionViewModel = .init()
//    
//    
//    private let gridItems: [GridItem] = Array(repeating: GridItem(.flexible()), count: 4)
//
//    var body: some View {
//        //        ScrollView {
//        //            LazyVGrid(columns: gridItems) {
//        List {
//            ForEach(stickerPackViewModel.stickersCategory) { category in
//                Section(header: Text(category.title)) {
//                    ForEach(chunked(array: category.pack, size: 4), id: \.self) { rowStickers in
//                        HStack(spacing: 10) {
//                            ForEach(rowStickers, id: \.self) { stickerURL in
//                                
//                                LottieView {
//                                    await LottieAnimation.loadedFrom(url: stickerURL)
//                                }
//                                .configure({ animation in
//                                    animation.contentMode = .scaleAspectFit
//                                })
//                                .playing(loopMode: .loop)
//                                .frame(height: 75)
//
//                                
////                                WebImage(url: stickerURL)
////                                    .pausable(true)
////                                    .purgeable(true)
////                                
////                                    .cancelOnDisappear(true)
////                                    .resizable()
////                                    .scaledToFit()
////                                    .frame(width: 75, height: 75)
////                                    .onAppear {
////                                        print("hello")
////                                    }
////                                    .onDisappear {
////                                        print("dissapear")
////                                    }
//                                    
//                                
////                                LottieView(animation: .named(stickerURL.lastPathComponent))
////                                    .playing(loopMode: .loop)
////                                    .frame(width: 75, height: 75)
//                                
//                                
//                            }
//                        }
//                        .padding(.vertical, 5)
//                    }
//                }
//            }
//            //                stickersCollectionView()
//        }
//        .listStyle(PlainListStyle())
//            .background(Color(ColorManager.navigationBarBackgroundColor))
////        }
//    }
//
//    // Helper function to chunk an array into subarrays of given size
//    private func chunked<T>(array: [T], size: Int) -> [[T]] {
//        stride(from: 0, to: array.count, by: size).map { startIndex in
//            let endIndex = min(startIndex + size, array.count)
//            return Array(array[startIndex..<endIndex])
//        }
//    }
//}
//extension StickersPackCollectionView
//{
//    private func stickersCollectionView() -> some View
//    {
//
////        ForEach(1..<100) { index in
////
//////            if let stickerData = stickerPackViewModel.getStickerData(
//////                from: stickerPackViewModel.urlTest,
//////                format: .tgs)
//////            {
//////                StickerView(data: stickerData,
//////                            format: .tgs)
//////            }
//////            if let data = stickerPackViewModel.getStickerData(
//////                from: stickerPackViewModel.urlTest,
//////                format: .webp)
//////            {
//////                StickerView(data: data,
//////                            format: .tgs)
////////                .resizable()
////////                .indicator(.activity)
////////                .scaledToFit()
////////                .frame(width: 140, height: 140)
////                let asda = SDImageWebPCoder(animatedImageData: data, options: nil)
////            
////                WebImage(url: stickerPackViewModel.urlTest)
////                .resizable()
////                .scaledToFit()
////                .frame(width: 75, height: 75)
//////            }
////        }
////        
//        ForEach(stickerPackViewModel.stickersCategory) { category in
//            Section(category.title, content: {
//                ForEach(category.pack, id: \.self) { stickerURL in
////                    WebImage(url: "")
////                        .purgeable(true)
////                        .cancelOnDisappear(true)
//                    
////                    WebImage(url: stickerPackViewModel.urlTest)
////                    .resizable()
////                    .scaledToFit()
////                    .frame(width: 75, height: 75)
//                    
////                    AnimatedImage(url: stickerURL)
////                        .resizable()
////                        .scaledToFit()
////                        .frame(width: 75, height: 75)
////                        .onAppear {
//////                            stickerPackViewModel.storeGif()
////                        }
////
//                    LottieView(animation: .named(stickerURL.lastPathComponent))
//                        .playing(loopMode: .loop)
//                        .frame(width: 75, height: 75)
//                    
////                    if let stickerData = stickerPackViewModel.getStickerData(
////                        from: stickerURL,
////                        format: category.format)
////                    {
////                        StickerView(data: stickerData,
////                                    format: category.format)
////                    }
//                }
//            })
//        }
//    }
//}
//
//struct StickerView: View
//{
//    let data: Data
//    let format: Stickers.StickerFormat
//    //    @ObservedObject var viewModel: StickersPackCollectionViewModel
//    
//    var body: some View
//    {
//        switch format {
//        case .tgs: LottieView(from: data)
//        case .webp: ImageView(from: data)
//        }
//    }
//    
//    /// For animated stickers
//    @ViewBuilder
//    private func LottieView(from data: Data) -> some View
//    {
//        if let animation = try? Lottie.LottieView(animation: .from(data: data))
//        {
//            animation.playbackMode(.playing(.toProgress(1, loopMode: .loop)))
//                .resizable()
//                .frame(height: 75)
//        }
//    }
//    
//    /// For static stickers
//    @ViewBuilder
//    private func ImageView(from data: Data) -> some View
//    {
//        if let image = UIImage(data: data) {
//            Image(uiImage: image)
//                .resizable()
//                .frame(width: 76, height: 75)
//        }
//    }
//}
//
//
//#Preview {
////    TestPublishe()
//    let vm = StickersPackCollectionViewModel()
//    StickersPackCollectionView()
//}
