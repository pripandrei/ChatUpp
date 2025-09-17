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
    @Published var item: MessageTextViewTrailingItem = .stickerItem {
        didSet {
            print(item)
        }
    }
}

enum MessageTextViewTrailingItem
{
    case stickerItem
    case keyboardItem
}

#Preview {
//    MessageTextViewTrailingItemView(textViewTrailingItem: .constant(.stickerItem)) { _ in }
}






class KeyboardService: NSObject
{
    static var serviceSingleton = KeyboardService()
    var measuredSize: CGRect = CGRect.zero

    private var field: UITextField?
    
    @objc class func keyboardHeight() -> CGFloat
    {
        let keyboardSize = KeyboardService.keyboardSize()
        return keyboardSize.size.height
    }

    @objc class func keyboardSize() -> CGRect
    {
        return serviceSingleton.measuredSize
    }

    private func observeKeyboardNotifications()
    {
        let center = NotificationCenter.default
        center.addObserver(self,
                           selector: #selector(self.keyboardChange),
                           name: UIResponder.keyboardWillShowNotification,
                           object: nil)
    }

    private func observeKeyboard()
    {
        self.field = UITextField()
        UIApplication.shared.windows.first?.addSubview(field!)
        field?.becomeFirstResponder()
    }

    @objc private func keyboardChange(_ notification: Notification)
    {
        guard measuredSize == CGRect.zero,
              let info = notification.userInfo,
              let value = info[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue
        else { return }
        
        measuredSize = value.cgRectValue
        field?.resignFirstResponder()
        field?.removeFromSuperview()
    }

    override init() {
        super.init()
        observeKeyboardNotifications()
        observeKeyboard()
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }
}

//final class KeyboardService
//{
//    static let shared = KeyboardService()
//    
//    private(set) var keyboardHeight: CGFloat = 0
//    
//    private init() {}
//    
//    private func setNotification()
//    {
//        
//    }
//    
//    private func findKeyboardHeight()
//    {
//        
//    }
//}
