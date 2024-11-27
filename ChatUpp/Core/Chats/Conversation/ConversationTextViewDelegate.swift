//
//  ConversationTextViewDelegate.swift
//  ChatUpp
//
//  Created by Andrei Pripa on 5/9/24.
//

//import Foundation
import UIKit
import Combine

final class ConversationTextViewDelegate: UIView, UITextViewDelegate {

    private var conversationView: ConversationRootView!
    private(set) var messageTextViewNumberOfLines = 1
    private(set) var lineNumberModificationSubject = PassthroughSubject<(Int,Int), Never>()
    
    convenience init(view: ConversationRootView) {
        self.init(frame: .zero)
        conversationView = view
        setupDelegate()
    }
    
    private func setupDelegate() {
        conversationView.setTextViewDelegate(to: self)
    }
    
    private func calculateTextViewFrameSize(_ textView: UITextView) -> CGSize
    {
        let fixedWidth = textView.frame.size.width
        let newSize    = textView.sizeThatFits(CGSize.init(width: fixedWidth, height: CGFloat(MAXFLOAT)))
        return CGSize.init(width: CGFloat(fmaxf(Float(newSize.width), Float(fixedWidth))), height: newSize.height)
    }

    func textViewDidChange(_ textView: UITextView)
    {
        // because textView height constraint priority is .required
        // new line will not occur and height will not change
        // so we need to calculate height ourselves using calculateTextViewFrameSize
        let textViewFrameSize = calculateTextViewFrameSize(textView)
        var numberOfLines     = Int(textViewFrameSize.height / textView.font!.lineHeight)
        
//        guard numberOfLines != self.messageTextViewNumberOfLines else {return}
        
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
    
    func updateLinesNumber(_ number: Int) {
        self.messageTextViewNumberOfLines = number
    }
    
//    func adjustTableViewContent(using textView: UITextView, numberOfLines: Int)
//    {
//        debounceWorkItem?.cancel()
//        debounceWorkItem = DispatchWorkItem(block: { [weak self] in
//            guard let self = self else {return}
//            let numberOfAddedLines     = CGFloat(numberOfLines - self.messageTextViewNumberOfLines)
//            let editViewHeight         = self.conversationView.inputBarHeader?.bounds.height != nil ? self.conversationView.inputBarHeader!.bounds.height : 0
//            let updatedContentOffset   = self.conversationView.tableView.contentOffset.y - (textView.font!.lineHeight * numberOfAddedLines)
//            let updatedContentTopInset = self.conversationView.tableViewInitialTopInset + (textView.font!.lineHeight * CGFloat((numberOfLines - 1))) + editViewHeight
//
//            UIView.animate(withDuration: 0.15) {
//                self.conversationView.tableView.setContentOffset(CGPoint(x: 0, y: updatedContentOffset), animated: false)
//                self.conversationView.tableView.verticalScrollIndicatorInsets.top = updatedContentTopInset
//                self.conversationView.tableView.contentInset.top                  = updatedContentTopInset
//                print("one")
//            }
//            self.messageTextViewNumberOfLines = numberOfLines
//        })
//        DispatchQueue.main.asyncAfter(deadline: .now() + 1.1, execute: debounceWorkItem!)
//    }
}
