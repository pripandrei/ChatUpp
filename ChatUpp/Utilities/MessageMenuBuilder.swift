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
    
    func buildUIMenuForMessage(message: Message) -> UIMenu
    {
//        let selectedText = cell.messageLabel.text ?? "" // TODO: message can be used instead
        let isOwner = message.senderId == viewModel.authUser.uid
        
        let seen = createSeenAction(for: message, isOwner: isOwner)
        let reply = createReplyAction(message: message)
        let copy = createCopyAction(text: message.messageBody)
        let edit = createEditAction(for: message, isOwner: isOwner)
        let delete = createDeleteAction(for: message, isOwner: isOwner)
        
        let firstSection = UIMenu(options: .displayInline, children: [seen])
        let secondSection = UIMenu(options: .displayInline, children: [reply, copy, edit, delete])
        
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
            DispatchQueue.main.async {
//                guard let sender = self.viewModel.getSendeOfMessage(message) else {return}
                guard let sender = self.viewModel.getMessageSender(message.senderId) else {return}
                self.viewModel.currentlyReplyToMessageID = message.id
                
                var image: UIImage?
                
                if message.type == .image || message.type == .imageText
                {
                    guard let path = message.imagePath?.addSuffix("small"),
                          let imageData = self.viewModel.retrieveImageDataFromCache(for: path) else {return}
                    
                    image = UIImage(data: imageData)
                }
                
                self.contextMenuSelectedActionHandler?(.reply(image), message.messageBody)
                self.rootView.inputBarHeader?.updateTitleLabel(usingText: sender.name)
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
                self.contextMenuSelectedActionHandler?(.edit, message.messageBody)
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
        { _ in
            
        }
    }
}



//let freezedMessage = message.freeze()
//self.viewModel.realmService?.removeMessageFromRealm(message: message)
//
//let lastMessageID = self.viewModel.conversation?.getLastMessage()?.id ?? ""
//
//self.viewModel.realmService?.updateRecentMessageFromRealmChat(withID: lastMessageID)
//self.viewModel.firestoreService?.updateLastMessageFromFirestoreChat(lastMessageID)
//
//self.viewModel.firestoreService?.deleteMessageFromFirestore(messageID: freezedMessage.id)
//self.viewModel.firestoreService?.handleCounterUpdateOnMessageDeletionIfNeeded(freezedMessage)



//
//
//func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
//    guard !viewModel.messageClusters.isEmpty else { return }
//
//    if let sixthFromBottom = getVisibleIndexPathForGlobalCell(atGlobalIndex: 5, in: tableView),
//       sixthFromBottom == indexPath {
//
//        Task {
//            if let (newRows, newSections) = await paginationManager.requestPagination(ascending: true, viewModel: viewModel) {
//                self.performeTableViewUpdate(with: newRows, sections: newSections)
//            }
//        }
//    }
//    else if let sixthFromTop = getVisibleIndexPathForGlobalCell(atGlobalIndex: 5, fromEnd: true, in: tableView),
//            sixthFromTop == indexPath {
//
//        Task {
//            if let (newRows, newSections) = await paginationManager.requestPagination(ascending: false, viewModel: viewModel) {
//                self.performeTableViewUpdate(with: newRows, sections: newSections)
//            }
//        }
//    }
//}
