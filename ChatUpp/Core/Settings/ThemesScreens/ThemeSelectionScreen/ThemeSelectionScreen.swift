//
//  ThemeSelectionScreen.swift
//  ChatUpp
//
//  Created by Andrei Pripa on 11/29/25.
//

import SwiftUI

struct ThemeSelectionScreen: View
{
    @ObservedObject var viewModel: ThemesPackViewModel
    @Environment(\.dismiss) private var dismiss
    @State var selectedImage: UIImage

    var body: some View
    {
        VStack {
            HStack
            {
                cancelButton()
                    .padding(.leading, 20)
                    .padding(.top, 30)
                Spacer()
            }
            Spacer()

            VStack {
                Spacer()
                ForEach(MessageAligment.allCases) { alignment in
                    HStack {
                        if alignment == .trailing { Spacer() }
                        MessageBubble(alignment: alignment)
                        if alignment == .leading { Spacer() }
                    }
                    .padding(.horizontal, 10)
                }

                ApplyButton()
                    .padding(.top, 40)
            }
            .padding(.bottom, 25)
        }
        .background {
            let screen = UIScreen.main.bounds
            Image(uiImage: selectedImage)
                .resizable()
                .scaledToFill()
                .frame(width: screen.width, height: screen.height)
                .clipped()
                .ignoresSafeArea(.all, edges: .all)
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
        .buttonStyle(.plain)
    }
    
    private func ApplyButton() -> some View
    {
        Button {
            viewModel.applySelectedTheme()
            dismiss()
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
        let color = alignment == .trailing ? Color(ColorScheme.outgoingMessageBackgroundColor) :
        Color(ColorScheme.incomingMessageBackgroundColor)
        
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

struct BlurView: UIViewRepresentable
{
    let style: UIBlurEffect.Style
    
    func makeUIView(context: Context) -> UIVisualEffectView {
        UIVisualEffectView(effect: UIBlurEffect(style: style))
    }
    
    func updateUIView(_ uiView: UIVisualEffectView, context: Context) {}
}


#Preview {
    let image = UIImage(named: "chat_background_theme_24")!
    ThemeSelectionScreen(viewModel: .init(), selectedImage: image)
}
