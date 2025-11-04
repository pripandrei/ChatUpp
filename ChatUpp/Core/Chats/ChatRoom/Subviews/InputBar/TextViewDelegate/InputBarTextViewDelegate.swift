//
//  ConversationTextViewDelegate.swift
//  ChatUpp
//
//  Created by Andrei Pripa on 5/9/24.
//

//import Foundation
import UIKit
import Combine

final class InputBarTextViewDelegate: NSObject, UITextViewDelegate
{
    private var conversationView: ChatRoomRootView!
    private(set) var messageTextViewNumberOfLines = 1
    private(set) var lineNumberModificationSubject = PassthroughSubject<(Int,Int), Never>()
    private(set) var textViewDidBeginEditing = PassthroughSubject<Bool, Never>()
    private var _invalidateTextViewSize: Bool = false
//    private(set) var textViewEmptyStateSubject = PassthroughSubject<Bool, Never>()
    @Published private(set) var isTextViewEmpty = true
    
    convenience init(view: ChatRoomRootView) {
//        self.init(frame: .zero)
        self.init()
        conversationView = view
        setupDelegate()
    }
    
    private func setupDelegate() {
        conversationView.setTextViewDelegate(to: self)
    }
    
    func textViewDidBeginEditing(_ textView: UITextView)
    {
        textViewDidBeginEditing.send(true)
    }

    func textViewDidChange(_ textView: UITextView)
    {
        textView.text.isEmpty != isTextViewEmpty ? self.isTextViewEmpty.toggle() : ()
//        self.textViewEmptyStateSubject.send(textView.text.isEmpty)
        
        // because textView height constraint priority is .required
        // new line will not occur and height will not change
        // so we need to calculate height ourselves using calculateTextViewFrameSize
        let textViewFrameSize = calculateTextViewFrameSize(textView)
        var numberOfLines     = Int(textViewFrameSize.height / textView.font!.lineHeight)
        
        guard numberOfLines != self.messageTextViewNumberOfLines || _invalidateTextViewSize == true
        else {return}
        
        // in case user paste text that exceeds 5 lines
        if numberOfLines > 4
        {
            let initialTextViewHeight   = 31.0
            numberOfLines               = 5
            let hightConstraintConstant = initialTextViewHeight + (textView.font!.lineHeight * CGFloat(numberOfLines - 1))
            
            animateTextViewHeightChange(height: hightConstraintConstant)
            lineNumberModificationSubject.send((numberOfLines, messageTextViewNumberOfLines))
        }
        if numberOfLines <= 4
        {
            animateTextViewHeightChange(height: textViewFrameSize.height)
            lineNumberModificationSubject.send((numberOfLines, messageTextViewNumberOfLines))
        }
        _invalidateTextViewSize = false
    }
    
    private func animateTextViewHeightChange(height: Double)
    {
        UIView.animate(withDuration: 0.15, delay: 0.1) {
            self.conversationView.textViewHeightConstraint.constant = height
            self.conversationView.layoutIfNeeded()
        } completion: { _ in
            let caretPosition = self.conversationView.messageTextView.selectedRange.location
            self.conversationView.messageTextView.scrollRangeToVisible(NSRange(location: caretPosition, length: 0))
        }
    }
}

//MARK: - Helper functions
extension InputBarTextViewDelegate
{
    func getNumberOfLines(from textView: UITextView) -> Int
    {
        let textViewFrameSize = calculateTextViewFrameSize(textView)
        return Int(textViewFrameSize.height / textView.font!.lineHeight)
    }
    
    func updateLinesNumber(_ number: Int) {
        self.messageTextViewNumberOfLines = number
    }
    
    private func calculateTextViewFrameSize(_ textView: UITextView) -> CGSize
    {
        let fixedWidth = textView.frame.size.width
        let newSize    = textView.sizeThatFits(CGSize.init(width: fixedWidth, height: CGFloat(MAXFLOAT)))
        return CGSize.init(width: CGFloat(fmaxf(Float(newSize.width), Float(fixedWidth))), height: newSize.height)
    }
    
    func invalidateTextViewSize() {
        _invalidateTextViewSize = true
    }
}

