//
//  MessageTextViewTrailingItem.swift
//  ChatUpp
//
//  Created by Andrei Pripa on 9/17/25.
//


import SwiftUI

struct MessageTextViewTrailingItemView: View
{
    @ObservedObject var trailingItemState: TrailingItemState
    var onTrailingItemChange: (MessageTextViewTrailingItem) -> Void
    @State var isButtonDisabled: Bool = false
    
    var body: some View {
        Button {
            onTrailingItemChange(trailingItemState.item)
            toggleTextViewItem()
            
            isButtonDisabled = true
            
            Task {
                try await Task.sleep(for: .seconds(1))
                isButtonDisabled = false
            }
        } label: {
            ItemImage()
        }
        .disabled(isButtonDisabled)
    }
    
    private func toggleTextViewItem()
    {
        withAnimation(.none) {
            trailingItemState.item = (trailingItemState.item == .keyboardItem) ? .stickerItem : .keyboardItem
        }
    }
    
    private func ItemImage() -> some View {
        let image = trailingItemState.item == .keyboardItem ? Image(systemName: "keyboard") : Image(.stickerIcon5)
        let imageHeight = trailingItemState.item == .keyboardItem ? 20.0 : 25.0
        let imageWidth = trailingItemState.item == .keyboardItem ? 30.0 : 30.0
        return image
            .resizable()
            .renderingMode(.template)
            .frame(width: imageWidth, height: imageHeight)
            .foregroundStyle(Color(ColorManager.textFieldPlaceholderColor))
    }
}


class TrailingItemState: SwiftUI.ObservableObject
{
    @Published var item: MessageTextViewTrailingItem = .stickerItem
}

enum MessageTextViewTrailingItem
{
    case stickerItem
    case keyboardItem
}

#Preview {
    MessageTextViewTrailingItemView(trailingItemState: .init()) { _ in }
}

