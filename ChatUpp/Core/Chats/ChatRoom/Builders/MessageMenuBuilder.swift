//
//  MessageMenuBuilder.swift
//  ChatUpp
//
//  Created by Andrei Pripa on 4/10/25.
//

import UIKit
import Foundation

// MARK: - Message Menu Builder
/// Builds the grouped action rows for the custom long-press message menu.
/// Every option body is ported 1:1 from the old `UIMenu`/`UIAction` system
/// context menu implementation; only the rendering wrapper differs.
/// Options whose old `UIAction.attributes` made them hidden are not produced
/// at all.
final class MessageMenuBuilder
{
    private var viewModel: ChatRoomViewModel!
    private var rootView: ChatRoomRootView!
    private var cell: UITableViewCell!

    private var contextMenuSelectedActionHandler: ((_ actionOption: InputBarHeaderView.Mode) -> Void)?

    deinit
    {
        deinitDescription(for: Self.self)
    }

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

    /// Message menu, grouped the same way the old UIMenu sections were:
    /// group 0 – the "Seen" row, group 1 – reply / copy / edit / delete.
    func buildMenuOptionGroups(message: Message) -> [[MessageMenuOption]]
    {
        let isOwner = message.senderId == viewModel.authUser.uid

        let supportsTextActions = ![.audio, .sticker].contains(message.type)

        var seenGroup: [MessageMenuOption] = []
        if isOwner && message.seenBy.count > 1
        {
            seenGroup.append(makeSeenOption(for: message))
        }

        var mainGroup: [MessageMenuOption] = [makeReplyOption(message: message)]
        if supportsTextActions
        {
            mainGroup.append(makeCopyOption(text: message.messageBody))
        }
        if supportsTextActions && isOwner
        {
            mainGroup.append(makeEditOption(for: message, isOwner: isOwner))
        }
        if isOwner
        {
            mainGroup.append(makeDeleteOption(for: message, isOwner: isOwner))
        }

        return [seenGroup, mainGroup].filter { !$0.isEmpty }
    }

    /// Event-cell menu: delete + copy in a single group (as the old menu did).
    func buildMenuOptionGroups(event message: Message) -> [[MessageMenuOption]]
    {
        return [[makeDeleteOption(for: message, isOwner: true),
                 makeCopyOption(text: message.messageBody)]]
    }

    // MARK: Option factories

    private func makeSeenOption(for message: Message) -> MessageMenuOption
    {
        return MessageMenuOption(
            title: "✔️ \(message.seenBy.count - 1) Seen",
            image: UIImage(systemName: "eye.fill"),
            isDestructive: false,
            action: {})
    }

    private func makeReplyOption(message: Message) -> MessageMenuOption
    {
        return MessageMenuOption(
            title: "Reply",
            image: UIImage(systemName: "arrowshape.turn.up.left"),
            isDestructive: false)
        {
            DispatchQueue.main.async { [weak self] in
                guard let self,
                      let sender = self.viewModel.getMessageSender(message.senderId) else {return}
                self.viewModel.currentlyReplyToMessageID = message.id

                let image: UIImage? = (self.cell as? TextImageMessageCell)?.messageImage

                let text = (self.cell as? TextImageMessageCell)?.messageText

                self.contextMenuSelectedActionHandler?(.reply(
                    senderName: sender.name,
                    text: text,
                    image: image)
                )
            }
        }
    }

    private func makeCopyOption(text: String) -> MessageMenuOption
    {
        return MessageMenuOption(
            title: "Copy",
            image: UIImage(systemName: "doc.on.doc"),
            isDestructive: false)
        {
            UIPasteboard.general.string = text
        }
    }

    private func makeEditOption(for message: Message, isOwner: Bool) -> MessageMenuOption
    {
        return MessageMenuOption(
            title: "Edit",
            image: UIImage(systemName: "pencil.and.scribble"),
            isDestructive: false)
        {
            DispatchQueue.main.async { [weak self] in
                guard let self else {return}
                self.rootView.messageTextView.text = message.messageBody

                let image: UIImage? = (self.cell as? TextImageMessageCell)?.messageImage

                let text = (self.cell as? TextImageMessageCell)?.messageText
                self.contextMenuSelectedActionHandler?(.edit(text: text,
                                                             image: image))

                let firstoreService = self.viewModel.firestoreService
                self.viewModel.shouldEditMessage = { editedText in
                    guard !message.isInvalidated else {return}

                    let updatedType :MessageType? = message.type == .image ? .imageText : nil

                    firstoreService?.editMessageFromFirestore(messageID: message.id,
                                                              editedText,
                                                              editedType: updatedType)
                }
            }
        }
    }

    private func makeDeleteOption(for message: Message, isOwner: Bool) -> MessageMenuOption
    {
        return MessageMenuOption(
            title: "Delete",
            image: UIImage(systemName: "trash"),
            isDestructive: true)
        {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { [weak self] in
                // TODO: should also delete locally in case network is off
                self?.viewModel.firestoreService?.deleteMessageFromFirestore(messageID: message.id)
                self?.viewModel.firestoreService?.handleCounterUpdateOnMessageDeletionIfNeeded(message)
            }
        }
    }
}
