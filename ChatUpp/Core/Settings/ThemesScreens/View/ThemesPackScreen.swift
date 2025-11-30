//
//  ThemeSelectionScreen.swift
//  ChatUpp
//
//  Created by Andrei Pripa on 11/28/25.
//

import SwiftUI
import UIKit

struct ThemesPackScreen: View
{
    @StateObject var viewModel: ThemesPackViewModel = .init()
    @State var showThemeSelectionScreenSheet: Bool = false
    
    let columns: Array = Array(repeating: GridItem(.flexible(),
                                                   spacing: -20,
                                                   alignment: .center),
                               count: 3)
    
    var body: some View
    {
        ScrollView()
        {
            GridHeader()
            
            LazyVGrid(columns: columns, spacing: 10)
            {
                ForEach(viewModel.themes, id: \.self) { theme in
                    GridImageItem(theme)
                }
            }
        }
        .background(Color(ColorScheme.appBackgroundColor))
        .sheet(isPresented: $showThemeSelectionScreenSheet) {
            showThemeSelectionScreenSheet = false
        } content: {
            NavigationStack
            {
                Group {
                    if let selectedImage = viewModel.retrieveImageData(viewModel.selectedTheme),
                       let image = UIImage(data: selectedImage)
                    {
                        ThemeSelectionScreen(selectedImage: image)
                            .presentationDetents([.large])
                            .presentationDragIndicator(.hidden)
                    } else {
                        EmptyView()
                    }
                }
            }
        }
    }
}


extension ThemesPackScreen
{
    @ViewBuilder
    private func GridImageItem(_ name: String) -> some View
    {
        if let imageData = viewModel.retrieveImageData(name),
           let image = UIImage(data: imageData)
        {
            Image(uiImage: image)
                .resizable()
            //                        .scaledToFit()
                .frame(width: 110, height: 170)
                .clipShape(.rect(cornerRadius: 10))
                .overlay {
                    if name == viewModel.selectedTheme
                    {
                        selectionView()
                    }
                }
                .onTapGesture {
                    viewModel.selectedTheme = name
                    showThemeSelectionScreenSheet = true
                }
        }
        else {
            PlaceholderView()
                .onAppear {
                    Task {
                        try await Task.sleep(for: .seconds(10))
                        await viewModel.fetchImageData(name)
                    }
                }
        }
    }
    
    private func PlaceholderView() -> some View
    {
        RoundedRectangle(cornerRadius: 10)
            .fill(.gray)
            .frame(width: 110, height: 170)
            .overlay {
                ProgressView()
            }
    }
    
    private func GridHeader() -> some View
    {
        Text("Themes")
            .font(Font.system(size: 18, weight: .semibold))
            .padding([.bottom, .top], 10)
            .foregroundStyle(.white)
    }
}


extension ThemesPackScreen
{
    private func selectionView() -> some View
    {
        Circle()
            .frame(width: 45, height: 45)
            .foregroundStyle(Color(ColorScheme.incomingMessageBackgroundColor))
            .overlay {
                Image(systemName: "checkmark")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 18, height: 18)
                    .foregroundStyle(.white)
            }
    }
}


#Preview {
    ThemesPackScreen()
//    ThemeSelectionScreen(viewModel: .init())
}


struct BlurView: UIViewRepresentable {
    let style: UIBlurEffect.Style
    
    func makeUIView(context: Context) -> UIVisualEffectView {
        UIVisualEffectView(effect: UIBlurEffect(style: style))
    }
    
    func updateUIView(_ uiView: UIVisualEffectView, context: Context) {}
}
