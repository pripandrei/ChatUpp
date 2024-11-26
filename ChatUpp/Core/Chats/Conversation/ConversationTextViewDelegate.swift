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
//    private var debounceWorkItem: DispatchWorkItem?
    private var tableContentOffsetSubject = PassthroughSubject<Int,Never>()
    private var cancellables = Set<AnyCancellable>()
    
    convenience init(view: ConversationRootView) {
        self.init(frame: .zero)
        conversationView = view
        setupDelegate()
        setupBinding()
    }
    
    private func setupDelegate() {
        conversationView.setTextViewDelegate(to: self)
    }
    
    private func setupBinding() {
        tableContentOffsetSubject
            .debounce(for: .seconds(0.1), scheduler: DispatchQueue.main)
            .sink { [weak self] numberOfLines in
                self?.applyTableViewAdjustments(basedOn: numberOfLines)
            }
            .store(in: &cancellables)
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
        
        // in case user paste text that exceeds 5 lines
        if numberOfLines > 4
        {
            let initialTextViewHeight   = 31.0
            numberOfLines               = 5
            let hightConstraintConstant = initialTextViewHeight + (textView.font!.lineHeight * CGFloat(numberOfLines - 1))
            
//            textView.isScrollEnabled                           = true
//            conversationView.textViewHeightConstraint.constant = hightConstraintConstant
            animateTextViewHeightChange(height: hightConstraintConstant)
//            adjustTableViewContent(using: textView, numberOfLines: numberOfLines)
            tableContentOffsetSubject.send(numberOfLines)
        }
        if numberOfLines <= 4 {
//            textView.isScrollEnabled                           = false
//            conversationView.textViewHeightConstraint.constant = textViewFrameSize.height
            animateTextViewHeightChange(height: textViewFrameSize.height)
//            adjustTableViewContent(using: textView, numberOfLines: numberOfLines)
            tableContentOffsetSubject.send(numberOfLines)
        }
    }
    
    private func animateTextViewHeightChange(height: Double) 
    {
//        self.conversationView.messageTextView.isScrollEnabled = true
        UIView.animate(withDuration: 0.15, delay: 0.1) {
            self.conversationView.textViewHeightConstraint.constant = height
            self.conversationView.layoutIfNeeded()
        } completion: { _ in
            let caretPosition = self.conversationView.messageTextView.selectedRange.location
            self.conversationView.messageTextView.scrollRangeToVisible(NSRange(location: caretPosition, length: 0))
//            self.conversationView.messageTextView.isScrollEnabled = false
        }
    }

    private func applyTableViewAdjustments(basedOn numberOfLines: Int)
    {
        let textView = conversationView.messageTextView
        let tableView = conversationView.tableView
        let numberOfAddedLines = CGFloat(numberOfLines - messageTextViewNumberOfLines)
        let editViewHeight = conversationView.inputBarHeader?.bounds.height ?? 0
        let updatedContentOffset = tableView.contentOffset.y - (textView.font!.lineHeight * numberOfAddedLines)
        let updatedContentTopInset = conversationView.tableViewInitialTopInset +
        (textView.font!.lineHeight * CGFloat(numberOfLines - 1)) + editViewHeight
        
        UIView.animate(withDuration: 0.15) {
            tableView.setContentOffset(CGPoint(x: 0, y: updatedContentOffset), animated: false)
            tableView.verticalScrollIndicatorInsets.top = updatedContentTopInset
            tableView.contentInset.top = updatedContentTopInset
        }
        messageTextViewNumberOfLines = numberOfLines
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

//
//extension Array where Self == [ConversationViewModel.ConversationMessageGroups] {
//    func sad() {
//        firstIndex(where: { $0.cellViewModels.contains(where: { $0.cellMessage.id == message.id }) })
//    }
//}
