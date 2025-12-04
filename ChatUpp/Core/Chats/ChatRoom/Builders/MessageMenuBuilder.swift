//
//  MessageMenuBuilder.swift
//  ChatUpp
//
//  Created by Andrei Pripa on 4/10/25.
//

import UIKit
import Foundation
import SwiftUI
// MARK: - Context Menu Builder
final class MessageMenuBuilder
{
    private var viewModel: ChatRoomViewModel!
    private var rootView: ChatRoomRootView!
    private var cell: UITableViewCell!
    
    private var contextMenuSelectedActionHandler: ((_ actionOption: InputBarHeaderView.Mode) -> Void)?
    
    init(viewModel: ChatRoomViewModel!,
         rootView: ChatRoomRootView!,
         cell: UITableViewCell,
         contextMenuSelectedActionHandler: ((_: InputBarHeaderView.Mode) -> Void)? = nil)
    {
        self.viewModel = viewModel
        self.rootView = rootView
        self.cell = cell
        self.contextMenuSelectedActionHandler = contextMenuSelectedActionHandler
    }

    func buildUIMenuForMessage(message: Message) -> UIMenu
    {
        let isOwner = message.senderId == viewModel.authUser.uid
        
        let supportsTextActions = ![.audio, .sticker].contains(message.type)
        
        let seen = createSeenAction(for: message, isOwner: isOwner)
        let reply = createReplyAction(message: message)
        let copy = supportsTextActions ? createCopyAction(text: message.messageBody) : nil
        let edit = supportsTextActions ? createEditAction(for: message, isOwner: isOwner) : nil
        let delete = createDeleteAction(for: message, isOwner: isOwner)
        
        let firstSection = UIMenu(
            options: .displayInline,
            children: [seen]
        )
        let secondSection = UIMenu(
            options: .displayInline,
            children: [reply, copy, edit, delete].compactMap {$0}
        )
        
        return UIMenu(children: [firstSection, secondSection])
    }

    func buildUIMenuForEvent(message: Message) -> UIMenu
    {
        let deleteAction = self.createDeleteAction(for: message)
        let copyAction = self.createCopyAction(text: message.messageBody)
        return UIMenu(title: "", children: [deleteAction, copyAction])
    }

    private func createReplyAction(message: Message) -> UIAction
    {
        UIAction(title: "Reply", image: UIImage(systemName: "arrowshape.turn.up.left")) { _ in
            DispatchQueue.main.async { [weak self] in
                guard let sender = self?.viewModel.getMessageSender(message.senderId) else {return}
                self?.viewModel.currentlyReplyToMessageID = message.id
 
                let image: UIImage? = (self?.cell as? ConversationMessageCell)?.messageImage

                let text = (self?.cell as? ConversationMessageCell)?.messageText
                
                self?.contextMenuSelectedActionHandler?(.reply(
                    senderName: sender.name,
                    text: text,
                    image: image)
                )
            }
        }
    }

    private func createCopyAction(text: String) -> UIAction
    {
        UIAction(title: "Copy", image: UIImage(systemName: "doc.on.doc")) { _ in
            UIPasteboard.general.string = text
        }
    }

    private func createEditAction(for message: Message,
                                  isOwner: Bool) -> UIAction
    {
        UIAction(
            title: "Edit",
            image: UIImage(systemName: "pencil.and.scribble"),
            attributes: isOwner ? [] : .hidden
        ) { _ in
            DispatchQueue.main.async {
                self.rootView.messageTextView.text = message.messageBody
 
                let image: UIImage? = (self.cell as? ConversationMessageCell)?.messageImage
                
                let text = (self.cell as? ConversationMessageCell)?.messageText
                self.contextMenuSelectedActionHandler?(.edit(text: text,
                                                             image: image))
                self.viewModel.shouldEditMessage = { [message] editedText in
                    self.viewModel.firestoreService?.editMessageTextFromFirestore(editedText, messageID: message.id)
                }
            }
        }
    }

    private func createDeleteAction(for message: Message,
                                    isOwner: Bool = true) -> UIAction {
        UIAction(
            title: "Delete",
            image: UIImage(systemName: "trash"),
            attributes: isOwner ? .destructive : .hidden
        ) { _ in
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                // TODO: should also delete locally in case network is off
//                let freezedMessage = message.freeze()
//                self.viewModel.realmService?.removeMessageFromRealm(message: message)
                self.viewModel.firestoreService?.deleteMessageFromFirestore(messageID: message.id)
                self.viewModel.firestoreService?.handleCounterUpdateOnMessageDeletionIfNeeded(message)
            }
        }
    }
    
    private func createSeenAction(for message: Message, isOwner: Bool) -> UIAction
    {
        return UIAction(title: "✔️ \(message.seenBy.count - 1) Seen",
                        image: UIImage(systemName: "eye.fill"),
                        attributes: (isOwner && message.seenBy.count > 1) ? [] : .hidden)
        { _ in }
    }
}

