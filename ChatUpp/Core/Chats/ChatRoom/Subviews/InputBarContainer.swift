//
//  InputBarContainer.swift
//  ChatUpp
//
//  Created by Andrei Pripa on 1/18/25.
//

import UIKit


// MARK: - Modified container for gesture trigger
final class InputBarContainer: UIView
{
    // since closeImageView frame is not inside it's super view (inputBarContainer)
    // gesture recognizer attached to it will not get triggered
    // so we need to override point to return true in case it matches the location in coordinate of closeImageView
    
    override func point(inside point: CGPoint, with event: UIEvent?) -> Bool
    {
        if super.point(inside: point, with: event) {return true}
        
        for subview in subviews {
            let subviewPoint = subview.convert(point, from: self)
            if subview.point(inside: subviewPoint, with: event) {
                return true
            }
        }
        return false
    }
}


protocol MessageTextViewTrailingItemProtocol
{
    var textViewTrailingItem: MessageTextViewTrailingItem {get set}
}

import SwiftUI

struct MessageTextViewTrailingItemView: View, MessageTextViewTrailingItemProtocol
{
    @State var textViewTrailingItem: MessageTextViewTrailingItem = .stickerItem
    var onTrailingItemChange: ((MessageTextViewTrailingItem) -> Void)?
    
    var body: some View
    {
        switch textViewTrailingItem
        {
        case .keyboardItem: KeyboardButton()
        case .stickerItem: StickerButton()
        }
    }
    
    private func toggleTextViewItem()
    {
        textViewTrailingItem = (textViewTrailingItem == .keyboardItem) ? .stickerItem : .keyboardItem
    }
}

extension MessageTextViewTrailingItemView
{
    private func StickerButton() -> some View
    {
        Button {
            onTrailingItemChange?(textViewTrailingItem)
            toggleTextViewItem()
        }
        label: {
            ItemImage()
        }
    }
    
    private func KeyboardButton() -> some View
    {
        Button {
            onTrailingItemChange?(textViewTrailingItem)
            toggleTextViewItem()
        }
        label: {
            ItemImage()
        }
    }
    
    private func ItemImage() -> some View
    {
        let itemName = textViewTrailingItem == .keyboardItem ? "keyboard" : "inset.filled.circle.dashed"
        let imageHeight = textViewTrailingItem == .keyboardItem ? 20.0 : 25.0
        let imageWidth = textViewTrailingItem == .keyboardItem ? 30.0 : 25.0
        return Image(systemName: itemName)
            .resizable()
            .frame(width: imageWidth, height: imageHeight)
            .foregroundStyle(Color(ColorManager.navigationBarBackgroundColor))
    }
}



enum MessageTextViewTrailingItem
{
    case stickerItem
    case keyboardItem
}

#Preview {
    MessageTextViewTrailingItemView()
}
