//
//  ThemeSelectionScreen.swift
//  ChatUpp
//
//  Created by Andrei Pripa on 11/28/25.
//

import SwiftUI

struct ThemesPackScreen: View
{
    @StateObject var viewModel: ThemeSelectionScreenViewModel = .init()
    @State var showThemeSelectionScreenSheet: Bool = false
    
    let columns: Array = Array(repeating: GridItem(.flexible(),
                                                   spacing: -20,
                                                   alignment: .center),
                               count: 3)
    
    var body: some View
    {
        ScrollView()
        {
            Text("Themes")
                .font(Font.system(size: 18, weight: .semibold))
                .padding([.bottom, .top], 10)
                .foregroundStyle(.white)
            
            LazyVGrid(columns: columns, spacing: 10)
            {
                ForEach(0..<20) { item in
                    
                    let themeName = viewModel.themes[item % viewModel.themes.count]
                    
                    Image(themeName)
                        .resizable()
//                        .scaledToFit()
                        .frame(width: 110, height: 170)
                        .clipShape(.rect(cornerRadius: 10))
                        .overlay {
                            if item == viewModel.selectedTheme
                            {
                                selectionView()
                            }
                        }
                        .onTapGesture {
                            viewModel.selectedTheme = item
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
                ThemeSelectionScreen(viewModel: viewModel)
                    .presentationDetents([.large])
                    .presentationDragIndicator(.hidden)
            }
        }

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

final class ThemeSelectionScreenViewModel: SwiftUI.ObservableObject
{
    let themes = ["chatRoom_background_1",
                  "chatRoom_background_2",
                  "chatRoom_background_3"]
    @Published var selectedTheme = 1
}

struct ThemeSelectionScreen: View
{
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var viewModel: ThemeSelectionScreenViewModel
    
    var body: some View
    {
        ZStack(alignment: .topLeading)
        {
            Image(viewModel.themes.randomElement() ?? "")
                .resizable()
                .scaledToFill()
                .ignoresSafeArea()
            cancelButton()
                .padding(.top, 30)
                .padding(.leading, 20)
            
            VStack
            {
                Spacer()
                
                ForEach(MessageAligment.allCases) { alignment in
                    HStack {
                        if alignment == .trailing {
                            Spacer()
                        }
                        
                        MessageBubble(alignment: alignment)
                        
                        if alignment == .leading {
                            Spacer()
                        }
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 0)
                }
                
                ApplyButton()
                    .padding(.top, 40)
            }
            .padding(.bottom, 25)
        }
    }
}

extension ThemeSelectionScreen
{
    private func cancelButton() -> some View
    {
        Button {
            dismiss.callAsFunction()
        } label: {
            ZStack {
                BlurView(style: .systemThinMaterialDark)
                    .background(Color(ColorScheme.incomingReplyToMessageBackgroundColor).opacity(0.5))
                    .clipShape(Capsule(style: .circular))
                
                Text("Cancel")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(.white)
            }
            .frame(width: 65, height: 25)
        }
        .buttonStyle(.bordered)
    }
    
    private func ApplyButton() -> some View
    {
        Button {
            
        } label: {
            ZStack {
                BlurView(style: .systemThinMaterialDark)
                    .background(Color(ColorScheme.incomingReplyToMessageBackgroundColor).opacity(0.5))
                    .clipShape(RoundedRectangle(cornerRadius: 10.0))
                
                Text("Apply For All Chats")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(.white)
            }
            .frame(height: 45)
            .frame(maxWidth: .infinity)
            .padding(.horizontal, 20)
        }
        .buttonStyle(.plain)
    }
    
    private func MessageBubble(alignment: MessageAligment) -> some View
    {
        let color = alignment == .trailing ? Color(ColorScheme.outgoingMessageBackgroundColor.withAlphaComponent(0.9)) :
        Color(ColorScheme.incomingMessageBackgroundColor.withAlphaComponent(0.9))
        
        let messageText = alignment == .leading ? "Swipe left or right to preview more wallpapers" : "Set wallpaper for all chats"
        
        let paddingBottom = alignment == .leading ? 5.0 : 20.0
        
        return Text(messageText)
            .font(.custom("HelveticaNeue", size: 16))
            .foregroundStyle(.white)
            .padding(.horizontal, 10)
            .padding(.top, 5)
            .padding(.bottom, paddingBottom)
            .background {
                RoundedRectangle(cornerRadius: 15.0)
                    .foregroundStyle(color)
            }
            .overlay(alignment: .bottomTrailing) {
                Timestamp()
                    .padding(.bottom, 4)
                    .padding(.trailing, 9)
            }
            .frame(maxWidth: 230)
    }
    
    private func Timestamp() -> some View
    {
        Text("20:40")
            .font(.system(size: 11, weight: .medium))
            .foregroundStyle(Color(ColorScheme.outgoingMessageComponentsTextColor))
    }
}

extension ThemeSelectionScreen
{
    enum MessageAligment: Int, Identifiable, CaseIterable
    {
        case leading
        case trailing
        
        var id: Int
        {
           return rawValue
        }
    }
}


#Preview {
    ThemesPackScreen()
//    ThemeSelectionScreen(viewModel: .init())
}
struct BlurView2: UIViewRepresentable {
    var style: UIBlurEffect.Style
    var backgroundColor: UIColor?
    var alpha: CGFloat

    func makeUIView(context: Context) -> UIVisualEffectView {
        let blurView = UIVisualEffectView(effect: UIBlurEffect(style: style))
        blurView.backgroundColor = backgroundColor?.withAlphaComponent(alpha)
        return blurView
    }

    func updateUIView(_ uiView: UIVisualEffectView, context: Context) {}
}


struct BlurView: UIViewRepresentable {
    let style: UIBlurEffect.Style
    
    func makeUIView(context: Context) -> UIVisualEffectView {
        UIVisualEffectView(effect: UIBlurEffect(style: style))
    }
    
    func updateUIView(_ uiView: UIVisualEffectView, context: Context) {}
}
