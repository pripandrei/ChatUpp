//
//  ConversationTextViewDelegate.swift
//  ChatUpp
//
//  Created by Andrei Pripa on 5/9/24.
//

//import Foundation
import UIKit

final class ConversationTextViewDelegate: UIView, UITextViewDelegate {

    private var conversationView: ConversationRootView!
    
    convenience init(view: ConversationRootView) {
        self.init(frame: .zero)
        conversationView = view
        setupDelegate()
    }
    
    private func setupDelegate() {
        conversationView.setTextViewDelegate(to: self)
    }
    
    private func calculateTextViewFrameSize(_ textView: UITextView) -> CGSize {
        let fixedWidth = textView.frame.size.width
        let newSize    = textView.sizeThatFits(CGSize.init(width: fixedWidth, height: CGFloat(MAXFLOAT)))
        return CGSize.init(width: CGFloat(fmaxf(Float(newSize.width), Float(fixedWidth))), height: newSize.height)
    }

    func textViewDidChange(_ textView: UITextView)
    {
        // because textView height constraint priority is .required
        // new line will not occur and height will not change
        // so we need to calculate height ourselves
        let textViewFrameSize = calculateTextViewFrameSize(textView)
        var numberOfLines     = Int(textViewFrameSize.height / textView.font!.lineHeight)
        
        if numberOfLines > 4 && !textView.isScrollEnabled
        {
            // in case user paste text that exceeds 5 lines
            let initialTextViewHeight = 31.0
            numberOfLines             = 5
            let hightConstraintConstant = initialTextViewHeight + (textView.font!.lineHeight * CGFloat(numberOfLines - 1))
            
            textView.isScrollEnabled                                                    = true
            conversationView.textViewHeightConstraint.constant = hightConstraintConstant
            adjustTableViewContent(using: textView, numberOfLines: numberOfLines)
        }
//        textView.constraints.first(where: {$0.firstAttribute == .height})?.constant 
        if numberOfLines <= 4 {
            adjustTableViewContent(using: textView, numberOfLines: numberOfLines)
            conversationView.textViewHeightConstraint.constant = textViewFrameSize.height
            textView.isScrollEnabled                                                    = false
        }
    }
    
    func adjustTableViewContent(using textView: UITextView, numberOfLines: Int) {
        let numberOfAddedLines     = CGFloat(numberOfLines - conversationView.messageTextViewNumberOfLines)
        let editViewHeight         = conversationView.editView?.bounds.height != nil ? conversationView.editView!.bounds.height : 0
        let updatedContentOffset   = conversationView.tableView.contentOffset.y - (textView.font!.lineHeight * numberOfAddedLines)
        let updatedContentTopInset = conversationView.tableViewInitialTopInset + (textView.font!.lineHeight * CGFloat((numberOfLines - 1))) + editViewHeight

        UIView.animate(withDuration: 0.15) {
            self.conversationView.tableView.setContentOffset(CGPoint(x: 0, y: updatedContentOffset), animated: false)
            self.conversationView.tableView.verticalScrollIndicatorInsets.top = updatedContentTopInset
            self.conversationView.tableView.contentInset.top                  = updatedContentTopInset
        }
        conversationView.updateTextViewNumberOfLines(numberOfLines)
    }
}
