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
}
