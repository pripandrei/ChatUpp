//
//  MessageMenuBuilder.swift
//  ChatUpp
//
//  Created by Andrei Pripa on 4/10/25.
//

import UIKit
import Foundation

// MARK: - Context Menu Builder
final class MessageMenuBuilder
{
    private var viewModel: ChatRoomViewModel!
    private var rootView: ChatRoomRootView!
    
    private var contextMenuSelectedActionHandler: ((_ actionOption: InputBarHeaderView.Mode,
                                                    _ text: String?) -> Void)?
    
    init(viewModel: ChatRoomViewModel!,
         rootView: ChatRoomRootView!,
         contextMenuSelectedActionHandler: ((_: InputBarHeaderView.Mode, _: String?) -> Void)? = nil)
    {
        self.viewModel = viewModel
        self.rootView = rootView
        self.contextMenuSelectedActionHandler = contextMenuSelectedActionHandler
    }
    
    func buildUIMenuForMessageCell(_ cell: MessageTableViewCell, message: Message) -> UIMenu {
        let selectedText = cell.messageLabel.text ?? ""
        let isOwner = message.senderId == viewModel.authUser.uid
        
        let reply = createReplyAction(for: cell, message: message, text: selectedText)
        let copy = createCopyAction(text: selectedText)
        let edit = createEditAction(for: cell, message: message, text: selectedText, isOwner: isOwner)
        let delete = createDeleteAction(for: message, isOwner: isOwner)
        
        return UIMenu(title: "", children: [reply, copy, edit, delete])
    }
    
    func buildUIMenuForEventCell(_ cell: MessageEventCell, message: Message) -> UIMenu
    {
        let deleteAction = self.createDeleteAction(for: message)
        let copyAction = self.createCopyAction(text: message.messageBody)
        return UIMenu(title: "", children: [deleteAction, copyAction])
    }

    private func createReplyAction(for cell: MessageTableViewCell, message: Message, text: String) -> UIAction {
        UIAction(title: "Reply", image: UIImage(systemName: "arrowshape.turn.up.left")) { _ in
            DispatchQueue.main.async {
                let senderName = cell.cellViewModel.messageSender?.name
                self.viewModel.currentlyReplyToMessageID = message.id
                self.contextMenuSelectedActionHandler?(.reply, text)
                self.rootView.inputBarHeader?.updateTitleLabel(usingText: senderName)
            }
        }
    }

    private func createCopyAction(text: String) -> UIAction {
        UIAction(title: "Copy", image: UIImage(systemName: "doc.on.doc")) { _ in
            UIPasteboard.general.string = text
        }
    }

    private func createEditAction(for cell: MessageTableViewCell, message: Message, text: String, isOwner: Bool) -> UIAction {
        UIAction(
            title: "Edit",
            image: UIImage(systemName: "pencil.and.scribble"),
            attributes: isOwner ? [] : .hidden
        ) { _ in
            DispatchQueue.main.async {
                self.rootView.messageTextView.text = text
                self.contextMenuSelectedActionHandler?(.edit, text)
                self.viewModel.shouldEditMessage = { [message] editedText in
                    self.viewModel.firestoreService?.editMessageTextFromFirestore(editedText, messageID: message.id)
                }
            }
        }
    }

    private func createDeleteAction(for message: Message, isOwner: Bool = true) -> UIAction {
        UIAction(
            title: "Delete",
            image: UIImage(systemName: "trash"),
            attributes: isOwner ? .destructive : .hidden
        ) { _ in
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                self.viewModel.firestoreService?.deleteMessageFromFirestore(messageID: message.id)
            }
        }
    }
}
