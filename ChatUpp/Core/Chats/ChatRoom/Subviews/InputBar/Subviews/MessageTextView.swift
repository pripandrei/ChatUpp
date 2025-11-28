//
//  MessageTextView.swift
//  ChatUpp
//
//  Created by Andrei Pripa on 11/13/25.
//

import UIKit

final class MessageTextView: UITextView
{
    var isInputDisabled: Bool = false
    
    override func caretRect(for position: UITextPosition) -> CGRect {
        return isInputDisabled ? .zero : super.caretRect(for: position)
    }
    
    private func centerCaret()
    {
        let fittingSize = CGSize(width: bounds.width, height: .greatestFiniteMagnitude)
        let size = sizeThatFits(fittingSize)
        
        // Amount of empty vertical space in the text view
        let verticalSpace = bounds.height - size.height
        
        let topBottomInset = max(0, verticalSpace / 2)
        
        contentInset.top = topBottomInset
        contentInset.bottom = topBottomInset
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
//        centerCaret()
    }
}
