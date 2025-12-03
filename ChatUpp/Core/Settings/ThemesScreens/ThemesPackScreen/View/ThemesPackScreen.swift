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
                    ThemeGridItemView(viewModel: .init(themeName: theme))
                    .overlay(content: {
                        if viewModel.selectedTheme == theme
                        {
                            selectionView()
                        }
                    })
                    .onTapGesture {
                        viewModel.selectedTheme = theme
                        showThemeSelectionScreenSheet = true
                    }
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
                        ThemeSelectionScreen(viewModel: viewModel, selectedImage: image)
                            .presentationDetents([.large])
                            .presentationDragIndicator(.hidden)
                    } else {
                        EmptyView()
                    }
                }
            }
        }
        .onDisappear {
            Utilities.setupNavigationBarAppearance()
        }
    }
}

extension ThemesPackScreen
{
    private func GridHeader() -> some View
    {
        Text("Themes")
            .font(Font.system(size: 18, weight: .semibold))
            .padding([.bottom, .top], 10)
            .foregroundStyle(.white)
    }
    
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
